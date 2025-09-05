#!/bin/bash
# Secure clipboard filter for cliphist
# Filters out sensitive data from password managers and auth tokens

# Read from stdin - use timeout to prevent hanging
input=$(timeout 0.1 cat 2>/dev/null) || exit 0

# Skip empty input
[ -z "$input" ] && exit 0

# Get the active window class (with timeout to prevent hanging)
window_class=$(timeout 0.1 hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty' 2>/dev/null | tr '[:upper:]' '[:lower:]')

# Skip password managers and sensitive apps
case "$window_class" in
    *1password* | *bitwarden* | *keepass* | *keepassxc* | *password* | *vault* | *lastpass* | *dashlane*)
        exit 0  # Don't store
        ;;
esac

# Check for patterns that look like secrets/tokens
# Base64 tokens, hex hashes, JWTs, GitHub tokens, SSH keys, GPG keys
if echo "$input" | grep -qE '(^[A-Za-z0-9+/]{40,}={0,2}$|^[a-f0-9]{64}$|^ey[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$|^ghp_[a-zA-Z0-9]{36}$|^ghs_[a-zA-Z0-9]{36}$|^gh[pousr]_[A-Za-z0-9_]{36,255}$|^-----BEGIN|^ssh-rsa |^ssh-ed25519 )'; then
    exit 0  # Don't store tokens, keys, JWTs, etc.
fi

# Check for OTP codes (6-8 digit numbers)
if echo "$input" | grep -qE '^[0-9]{6,8}$'; then
    exit 0  # Don't store 2FA codes
fi

# Check for credit card numbers (basic check)
if echo "$input" | grep -qE '^[0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4}[\s-]?[0-9]{4}$'; then
    exit 0  # Don't store credit card numbers
fi

# Check length - skip very long strings (likely keys/certs)
if [ ${#input} -gt 5000 ]; then
    exit 0
fi

# Store it to cliphist
echo "$input" | cliphist store