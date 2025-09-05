#!/usr/bin/env python3
import json, re, sys, urllib.request
from pathlib import Path

install = Path('scripts/install.sh').read_text()

def parse_array(name: str):
    m = re.search(rf"{name}\s*=\s*\((.*?)\)", install, re.S)
    if not m:
        return []
    body = m.group(1)
    toks = re.findall(r"[^\s]+", body)
    return [t for t in toks if not t.startswith('#')]

pac = parse_array('PAC_PKGS')
aur = parse_array('AUR_PKGS')
all_pkgs = pac + aur

OFFICIAL_URL = 'https://archlinux.org/packages/search/json/?name={}'
AUR_URL = 'https://aur.archlinux.org/rpc/?v=5&type=info&arg[]={}'

def http_json(url: str):
    with urllib.request.urlopen(url, timeout=20) as r:
        return json.load(r)

def check_official(name: str):
    try:
        data = http_json(OFFICIAL_URL.format(name))
        for res in data.get('results', []):
            if res.get('pkgname') == name:
                return f"{res.get('repo')}/{res.get('arch')}"
    except Exception:
        return ''
    return ''

def check_aur(name: str):
    try:
        data = http_json(AUR_URL.format(name))
        if data.get('resultcount') == 1 and data['results'][0].get('Name') == name:
            return 'AUR'
    except Exception:
        return ''
    return ''

rows = []
for name in all_pkgs:
    off = check_official(name)
    aurhit = check_aur(name)
    rows.append((name, off, aurhit))

print(f"{'Package':<24}\tOfficial\tAUR")
for name, off, aurhit in rows:
    print(f"{name:<24}\t{off}\t{aurhit}")

# Identify likely misplacements
wrong_pac = [n for (n,o,a) in rows if n in pac and not o and a]
wrong_aur = [n for (n,o,a) in rows if n in aur and o]
not_found = [n for (n,o,a) in rows if (not o) and (not a)]

print('\nSummary:')
if wrong_pac:
    print(' - In PAC_PKGS but AUR only:', ', '.join(wrong_pac))
if wrong_aur:
    print(' - In AUR_PKGS but official:', ', '.join(wrong_aur))
if not_found:
    print(' - Not found in official or AUR (check names):', ', '.join(not_found))
print('Done.')

