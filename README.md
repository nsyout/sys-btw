# Minimal Hyprland Setup (Arch)

This repo bootstraps a clean Hyprland desktop with sensible defaults, Alacritty, Waybar, Rofi (Wayland), Mako, and a handful of tools. It includes install/link scripts and drop‑in configs.

## What’s Included
- Hyprland: hyprland, hypridle, hyprlock, hyprpaper
- Bar/Launcher/Notify: waybar, rofi-wayland (AUR), mako, swayosd (AUR)
- Media/OSD: PipeWire + WirePlumber, SwayOSD
- Tools: hyprshot (AUR), satty (AUR), wl-clipboard, grim, slurp, yazi, zathura, imv, fastfetch
- System utils: NetworkManager (+ nmtui), BlueZ (+ bluetuith), playerctl, brightnessctl
- Shell: zsh + starship
- Fonts: Inter (UI), IosevkaTerm Nerd Font (terminal)

## Requirements
- Arch Linux (systemd)
- Internet access for pacman + AUR builds
- A user with sudo

The script will install `paru` automatically if missing (requires `base-devel` + `git`).

## Install
```bash
# From the repo root
bash scripts/install.sh   # installs packages and basic security
bash scripts/link.sh      # symlinks configs into ~/.config and ~/.zshrc

# Put a wallpaper at:
cp /path/to/wall.jpg ~/.wallpapers/wall.jpg

# Security setup (after install):
sudo tailscale up                    # connect to your tailnet
bash scripts/configure-security.sh  # lock down SSH and firewall
```

The install script now includes:
- International font support (Noto fonts for CJK and emoji)
- Pinned GitHub releases (no AUR dependencies)
- Service dependency checks (NetworkManager, Bluetooth)
- BTRFS snapshot creation (if snapper available)
- Security setup (Tailscale VPN, UFW firewall, SSH hardening)

Recommended services (if not already enabled):
```bash
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth
```

Start Hyprland:
- TTY: log in and run `Hyprland`
- With uwsm: `uwsm start hyprland`

## Config Paths
- Hyprland: `~/.config/hypr/hyprland.conf`
- Hyprpaper: `~/.config/hypr/hyprpaper.conf` (uses `~/.wallpapers/wall.jpg`)
- Hyprlock: `~/.config/hypr/hyprlock.conf` (same wallpaper)
- Hypridle: `~/.config/hypr/hypridle.conf`
- Waybar: `~/.config/waybar/`
- Rofi: `~/.config/rofi/` (Flexoki-inspired dark theme)
- Mako: `~/.config/mako/config`
- Alacritty: `~/.config/alacritty/alacritty.toml`
- Yazi: `~/.config/yazi/yazi.toml`
- Zsh: `~/.zshrc`

`scripts/link.sh` is idempotent. It backs up non-symlink targets by renaming them to `*.bak` before linking.

## Portals (Screenshare/File Pickers)
The installer adds `xdg-desktop-portal` and `xdg-desktop-portal-hyprland`. Hyprland autostart imports Wayland/desktop env to systemd user so portals pick them up:
```
exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
```

## Keybinds (highlights)
- Apps: `Super+Enter` Alacritty, `Super+D` Rofi, `Super+E` Yazi, `Super+Ctrl+L` Lock
- Window: `Super+H/J/K/L` focus, `Super+Shift+H/J/K/L` move, `Super+Ctrl+H/J/K/L` resize
- Workspaces: `Super+1..9` switch, `Super+Shift+1..9` move
- Floating: `Super+Space` toggle, `Super+F` fullscreen
- Screenshots: `Print`/`Super+P` region→clipboard, `Shift+Print`/`Super+Shift+P` region→`~/Screenshots`
- Media: XF86 keys for volume/brightness/media

Volume is handled via PipeWire (`wpctl`), with SwayOSD overlays:
```
wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
wpctl set-mute   @DEFAULT_AUDIO_SINK@ toggle
```

Optional satty annotate (uncomment in `hyprland.conf`):
```
bind = CTRL, Print, exec, grim -g "$(slurp)" - | satty -f - --copy-command wl-copy
```

## Customization
- Terminal: change `$term` in `hyprland.conf` if you prefer another terminal
- Fonts: Waybar uses Inter; Alacritty uses IosevkaTerm Nerd Font
- Wallpaper: change path in `hyprpaper.conf` and `hyprlock.conf` or replace `~/.wallpapers/wall.jpg`
- Rofi theme: edit `~/.config/rofi/themes/flexoki-dark.rasi` or point to a different theme in `config.rasi`

## Package Lists
Repo (pacman):
- hyprland hypridle hyprlock hyprpaper, waybar, mako, wlogout
- alacritty, wl-clipboard, zathura zathura-pdf-poppler, imv, fastfetch
- grim slurp, playerctl, brightnessctl
- networkmanager nmtui, bluez bluez-utils bluetuith
- yazi, btop iotop iftop bandwhich
- zsh starship, inter-font ttf-iosevkaterm-nerd
- noto-fonts noto-fonts-cjk noto-fonts-emoji (international support)  
- pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
- xdg-desktop-portal xdg-desktop-portal-hyprland
- tailscale ufw openssh fail2ban (security stack)

GitHub Releases (pinned versions):
- bluetuith v0.2.5-rc1 (bluetooth TUI manager)
- wlogout v1.2.2 (logout menu)

## Security Setup

The system includes comprehensive security hardening:
- **Tailscale VPN**: Zero-config mesh networking for secure remote access
- **UFW Firewall**: Deny all incoming by default, auto-starts on boot
- **SSH Hardening**: Key-based auth, modern crypto, tailscale-only access, fail2ban protection
- **DNS Security**: Cloudflare DNS with DNSSEC and DNS-over-TLS
- **System Snapshots**: Automatic BTRFS snapshots with cleanup policies

After installation, complete the security setup:
```bash
sudo tailscale up                    # Connect to your tailnet
bash scripts/configure-security.sh  # Apply full security hardening
bash scripts/setup-pacman-hooks.sh  # Optional: automatic package snapshots
```

**SECURITY WARNING**: This locks down SSH to tailscale-only access - ensure you can connect via tailscale before applying!

## Troubleshooting
- No OSD? Ensure `swayosd-server` is running (it’s autostarted). Try `pkill swayosd-server && swayosd-server --silent &`.
- Screenshare/file pickers fail? Check `xdg-desktop-portal-hyprland` is installed and the env import lines are executed after Hyprland starts.
- No network or BT status? Ensure services are enabled and Waybar modules are present.

## Maintenance & System Automation

Future enhancements being considered:
- **Waybar system indicators**: Update notifications, security alerts (arch-audit), disk usage
- **Automated maintenance**: Daily reflector mirror updates, package cache cleanup  
- **BTRFS integration**: Automatic snapshots before updates, rollback capabilities
- **Package management**: Pin critical AUR packages, cleanup unused dependencies

See `TROUBLESHOOTING.md` for detailed issue resolution and `CLAUDE.md` for development guidance.

---
Configuration follows the Flexoki color scheme for consistent theming across all components.
