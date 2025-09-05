#!/usr/bin/env bash
set -euo pipefail

# Minimal Arch setup for Hyprland + tools

have() { command -v "$1" >/dev/null 2>&1; }

if ! have sudo; then
  echo "This script expects sudo to install packages." >&2
  exit 1
fi

PAC_PKGS=(
  hyprland hypridle hyprlock hyprpaper
  waybar mako
  alacritty
  wl-clipboard
  zathura zathura-pdf-poppler
  imv fastfetch
  grim slurp
  playerctl brightnessctl
  networkmanager
  bluez bluez-utils
  yazi
  btop iotop iftop bandwhich
  zsh starship
  inter-font ttf-iosevkaterm-nerd ttf-jetbrains-mono
  noto-fonts noto-fonts-cjk noto-fonts-emoji
  pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber
  xdg-desktop-portal xdg-desktop-portal-hyprland
  rofi swayosd hyprshot satty uwsm wiremix impala
  libnotify go
)

# GitHub release packages (pinned versions)
install_github_release() {
  local name="$1" url="$2" binary="$3" build_cmd="$4"
  echo "==> Installing $name from GitHub release"
  
  if command -v "$binary" >/dev/null 2>&1; then
    echo "$name already installed, skipping"
    return 0
  fi
  
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT
  
  echo "Downloading $url"
  if ! curl -L "$url" -o "$tmpdir/archive.tar.gz"; then
    echo "Failed to download $name" >&2
    return 1
  fi
  
  cd "$tmpdir"
  tar -xzf archive.tar.gz --strip-components=1
  
  # Try to find pre-built binary first
  if find . -name "$binary" -type f -executable 2>/dev/null | head -1 | xargs -I {} sudo cp {} /usr/local/bin/ 2>/dev/null; then
    echo "Installed $name to /usr/local/bin/$binary"
  elif [ -n "$build_cmd" ]; then
    echo "No pre-built binary found, building from source..."
    if eval "$build_cmd" && [ -f "$binary" ]; then
      sudo cp "$binary" /usr/local/bin/
      echo "Built and installed $name to /usr/local/bin/$binary"
    else
      echo "Failed to build $name" >&2
      return 1
    fi
  else
    echo "Failed to find binary $binary in archive" >&2
    return 1
  fi
}

echo "==> Installing repo packages via pacman"
sudo pacman -Syu --needed --noconfirm "${PAC_PKGS[@]}"

echo "==> Installing GitHub release packages"

# Install Go packages
if command -v go >/dev/null 2>&1; then
  echo "==> Installing bluetuith via go install"
  
  # Ensure ~/go/bin is in PATH for current session
  export PATH="$HOME/go/bin:$PATH"
  
  if ! command -v bluetuith >/dev/null 2>&1; then
    go install github.com/darkhz/bluetuith@latest
    echo "Installed bluetuith to ~/go/bin/"
    echo "Note: Ensure ~/go/bin is in your PATH"
  else
    echo "bluetuith already installed, skipping"
  fi
else
  echo "Go not found, falling back to GitHub release"
  install_github_release "bluetuith" \
    "https://github.com/bluetuith-org/bluetuith/releases/download/v0.2.5-rc1/bluetuith_0.2.5-rc1_Linux_x86_64.tar.gz" \
    "bluetuith"
fi

install_github_release "wlogout" \
  "https://github.com/ArtsyMacaw/wlogout/releases/download/1.2.2/wlogout.tar.gz" \
  "wlogout" \
  "meson setup build && ninja -C build"

echo "==> Creating common directories"
mkdir -p "$HOME/.config" "$HOME/.wallpapers" "$HOME/Screenshots"

# Optional: Create snapshot if snapper is available
if command -v snapper >/dev/null 2>&1; then
  echo "==> Creating pre-install snapshot"
  snapper create --description "After sys-btw install" || true
fi

echo "==> Checking required services"
services=(NetworkManager bluetooth)
for service in "${services[@]}"; do
  if ! systemctl is-enabled "$service" >/dev/null 2>&1; then
    echo "Warning: $service is not enabled"
    echo "Run: sudo systemctl enable --now $service"
  fi
done

echo "==> Done. Run scripts/link.sh to symlink configs."
