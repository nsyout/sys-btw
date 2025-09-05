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
  libnotify go tailscale ufw openssh fail2ban
  imagemagick fd ripgrep fzf duf
  chafa ueberzugpp  # Terminal image viewers for wallpaper previews
  greetd greetd-tuigreet
  tmux cliphist xdg-user-dirs jq
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

# Install paru for AUR packages
install_paru() {
  if command -v paru >/dev/null 2>&1; then
    echo "==> paru already installed, skipping"
    return 0
  fi
  
  echo "==> Installing paru AUR helper"
  tmpdir=$(mktemp -d)
  trap "rm -rf '$tmpdir'" EXIT
  
  cd "$tmpdir"
  git clone https://aur.archlinux.org/paru.git
  cd paru
  makepkg -si --noconfirm
  cd /
  rm -rf "$tmpdir"
  
  echo "==> paru installed successfully"
}

install_paru

# Install AUR packages
if command -v paru >/dev/null 2>&1; then
  echo "==> Installing AUR packages"
  AUR_PKGS=(
    waypaper  # GUI wallpaper manager
    timg      # Terminal image viewer with better Wayland support
  )
  
  for pkg in "${AUR_PKGS[@]}"; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
      echo "Installing $pkg from AUR..."
      paru -S --noconfirm "$pkg"
    else
      echo "$pkg already installed"
    fi
  done
fi

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
mkdir -p "$HOME/.config" "$HOME/.wallpapers" "$HOME/screenshots" "$HOME/wallpapers"

# Configure lowercase XDG directories
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  echo "==> Configuring lowercase user directories"
  mkdir -p "$HOME/desktop" "$HOME/downloads" "$HOME/documents" "$HOME/pictures" "$HOME/videos" "$HOME/music" "$HOME/templates" "$HOME/public"
  cat > "$HOME/.config/user-dirs.dirs" << 'EOF'
XDG_DESKTOP_DIR="$HOME/desktop"
XDG_DOWNLOAD_DIR="$HOME/downloads"
XDG_TEMPLATES_DIR="$HOME/templates"
XDG_PUBLICSHARE_DIR="$HOME/public"
XDG_DOCUMENTS_DIR="$HOME/documents"
XDG_MUSIC_DIR="$HOME/music"
XDG_PICTURES_DIR="$HOME/pictures"
XDG_VIDEOS_DIR="$HOME/videos"
EOF
  xdg-user-dirs-update
fi

# Configure snapper for automatic snapshots
if command -v snapper >/dev/null 2>&1; then
  echo "==> Configuring snapper for automatic snapshots"
  
  # Create snapper config for root filesystem if it doesn't exist
  if [ ! -f /etc/snapper/configs/root ]; then
    sudo snapper -c root create-config /
    echo "Created snapper config for root filesystem"
  fi
  
  # Configure snapper settings for reasonable retention
  sudo snapper -c root set-config \
    TIMELINE_CREATE=yes \
    TIMELINE_CLEANUP=yes \
    NUMBER_CLEANUP=yes \
    NUMBER_MIN_AGE=1800 \
    NUMBER_LIMIT=10 \
    NUMBER_LIMIT_IMPORTANT=5
    
  # Enable automatic timeline snapshots
  sudo systemctl enable --now snapper-timeline.timer
  sudo systemctl enable --now snapper-cleanup.timer
  
  echo "Enabled automatic timeline snapshots (hourly) and cleanup"
  
  # Create installation snapshot
  sudo snapper -c root create --description "After sys-btw install"
  echo "Created installation snapshot"
  
  # Offer to setup pacman hooks
  echo ""
  echo "Optional: Setup automatic snapshots for package operations"
  echo "This creates pre/post snapshots for every pacman transaction"
  echo "Run: bash scripts/setup-pacman-hooks.sh"
else
  echo "Snapper not available - install 'snapper' package for automatic snapshots"
fi

echo "==> Checking required services"
services=(NetworkManager bluetooth)
for service in "${services[@]}"; do
  if ! systemctl is-enabled "$service" >/dev/null 2>&1; then
    echo "Warning: $service is not enabled"
    echo "Run: sudo systemctl enable --now $service"
  fi
done

echo "==> Configuring security services"

# Enable and start tailscale
if ! systemctl is-enabled tailscaled >/dev/null 2>&1; then
  echo "Enabling tailscale daemon..."
  sudo systemctl enable --now tailscaled
  echo "Run 'sudo tailscale up' to connect to your tailnet"
fi

# Configure UFW firewall with comprehensive rules
echo "Setting up UFW firewall..."
sudo ufw --force reset >/dev/null 2>&1

# Default policies - deny all incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw default deny forward

# Allow loopback (essential for system operation)
sudo ufw allow in on lo
sudo ufw allow out on lo

# Allow DHCP client (for network configuration)
sudo ufw allow out 67
sudo ufw allow out 68

# Allow DNS (essential for name resolution)
sudo ufw allow out 53

# Allow NTP (time synchronization)
sudo ufw allow out 123

# Enable UFW and set to start on boot
sudo ufw --force enable
sudo systemctl enable ufw

echo "UFW firewall configured and enabled with secure defaults:"
echo "  ✓ Deny all incoming connections"
echo "  ✓ Allow outgoing connections" 
echo "  ✓ Allow loopback interface"
echo "  ✓ Allow essential services (DHCP, DNS, NTP)"
echo "  ✓ Enabled to start on boot"
echo ""
echo "After running 'sudo tailscale up', configure SSH access:"
echo "  sudo ufw allow in on tailscale0 to any port 22"
echo "  sudo systemctl enable --now sshd"

# Note about SSH configuration
echo ""
echo "SECURITY SETUP REQUIRED:"
echo "1. Connect to tailscale: sudo tailscale up"  
echo "2. Configure SSH for tailscale only (see README for details)"
echo "3. Enable UFW: sudo ufw enable"
echo "4. Enable SSH: sudo systemctl enable --now sshd"

echo "==> Configuring greetd with autologin"
sudo systemctl enable greetd

# Configure greetd for autologin to Hyprland
sudo mkdir -p /etc/greetd
sudo tee /etc/greetd/config.toml > /dev/null <<EOF
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-user-session --theme 'border=#343331;text=#CECDC3;prompt=#BC5215;time=#878580;action=#BC5215;button=#4385BE;container=#100F0F;input=#282726;greet=#66800B' --greeting 'Welcome to Arch + Hyprland' --cmd Hyprland"
user = "greeter"

[initial_session]
command = "Hyprland"
user = "$USER"
EOF

echo "Greetd configured with autologin to Hyprland for user: $USER"

echo "==> Done. Run scripts/link.sh to symlink configs."
