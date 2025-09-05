# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a minimal Hyprland desktop environment setup for Arch Linux with comprehensive security hardening, automated deployment scripts, and consistent Flexoki theming across all components.

## Key Commands

### Development & Testing
```bash
# Install packages and configure system
bash scripts/install.sh

# Link configuration files to ~/.config
bash scripts/link.sh

# Apply security hardening (requires Tailscale connection)
sudo tailscale up
bash scripts/configure-security.sh

# Test Hyprland configuration syntax
hyprctl reload

# Check running services
pgrep -x waybar hyprpaper mako hypridle swayosd-server

# Quick system verification
systemctl --user status pipewire wireplumber
systemctl status NetworkManager bluetooth
```

### Configuration Management
```bash
# Reload Hyprland config after changes
hyprctl reload

# Test wallpaper changes
cp image.jpg ~/.wallpapers/wall.jpg && hyprctl reload

# Test Rofi menus
/usr/local/bin/rofi-system-menu
/usr/local/bin/rofi-wallpaper
```

## Architecture & Structure

### Directory Layout
- `scripts/` - Bootstrap and utility scripts (install.sh, link.sh, configure-security.sh, rofi menus)
- `dotfiles/` - Application configurations organized by program (hypr/, waybar/, rofi/, etc.)
- Configuration deployment via symlinks from dotfiles/ to ~/.config/

### Core Scripts

**scripts/install.sh**
- Installs all required packages via pacman and builds from GitHub releases
- Configures greetd display manager with autologin
- Sets up UFW firewall, Tailscale VPN readiness
- Creates BTRFS snapshots if snapper is available
- Creates required directories (~/.wallpapers, ~/screenshots)

**scripts/link.sh**
- Symlinks entire config directories from dotfiles/ to ~/.config/
- Backs up existing configs to *.bak before linking
- Copies Rofi scripts to /usr/local/bin/
- Idempotent - safe to run multiple times

**scripts/configure-security.sh**
- Requires active Tailscale connection before running
- Locks SSH to Tailscale-only access with modern crypto
- Configures fail2ban, UFW firewall rules
- Sets up secure DNS with Cloudflare

### Configuration Patterns

1. **Theming**: All components use Flexoki color scheme defined in dotfiles/rofi/themes/flexoki-dark.rasi
2. **Fonts**: Inter for UI elements, IosevkaTerm Nerd Font for terminals
3. **Keybindings**: Defined in dotfiles/hypr/hyprland.conf
4. **Wallpaper**: Expected at ~/.wallpapers/wall.jpg (referenced in hyprpaper.conf and hyprlock.conf)

### Service Dependencies

Critical services that must be running:
- NetworkManager (network management)
- bluetooth (if using Bluetooth)
- pipewire, pipewire-pulse, wireplumber (audio)
- swayosd-server (volume/brightness OSD)

### Security Architecture

1. **Tailscale-First**: SSH access restricted to Tailscale network only
2. **UFW Firewall**: Deny all incoming by default, allow only essential services
3. **SSH Hardening**: Key-only auth, modern algorithms, fail2ban protection
4. **DNS Security**: Cloudflare DNS with DNSSEC and DNS-over-TLS via systemd-resolved

## Development Guidelines

### When Modifying Configurations

1. **Hyprland configs** (dotfiles/hypr/): Test changes with `hyprctl reload`
2. **Waybar** (dotfiles/waybar/): Restart with `pkill waybar && waybar &`
3. **Rofi themes** (dotfiles/rofi/): Test with `rofi -show drun`
4. **System scripts**: Must be executable and use `#!/bin/bash` shebang

### Adding New Features

1. Package additions go in scripts/install.sh
2. New dotfiles should be added to scripts/link.sh
3. Security-related changes require updating scripts/configure-security.sh
4. Maintain Flexoki color consistency across all components

### Error Handling

All scripts use `set -euo pipefail` for strict error handling. Helper functions:
- `have()` - Check if command exists
- `backup()` - Backup existing files before overwriting
- `install_github_release()` - Download and install from GitHub with fallback build

### Testing Changes

1. Configuration syntax: `hyprctl reload` should complete without errors
2. Service status: All autostart services should be running
3. Keybindings: Test core bindings (Super+Enter for terminal, Super+D for Rofi)
4. Visual elements: Check blur, borders, gaps, animations work correctly

## Important Files

- `dotfiles/hypr/hyprland.conf` - Main Hyprland configuration with all keybindings
- `dotfiles/waybar/config` - Status bar modules and layout
- `dotfiles/rofi/config.rasi` - Rofi launcher configuration
- `scripts/rofi-system-menu` - Comprehensive system management menu
- `scripts/rofi-wallpaper` - Wallpaper selector with nsyout/walls integration