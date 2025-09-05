# Testing Guide

This document outlines how to test the sys-btw Hyprland setup to ensure everything works correctly.

## Prerequisites

- Fresh Arch Linux installation or VM
- Internet connection for package downloads
- Basic user account with sudo privileges

## Installation Testing

### 1. Package Installation
```bash
# Run the install script
bash scripts/install.sh

# Check for errors in output
# Verify all packages installed successfully:
pacman -Q hyprland waybar rofi mako alacritty | wc -l  # Should be 5

# Check Go binary installation
ls ~/go/bin/bluetuith  # Should exist
bluetuith --version    # Should show version

# Check GitHub release build
which wlogout         # Should be in /usr/local/bin
wlogout --version     # Should show version
```

### 2. Configuration Linking
```bash
# Link configurations
bash scripts/link.sh

# Verify symlinks created correctly
ls -la ~/.config/hypr        # Should be symlink to repo
ls -la ~/.config/waybar      # Should be symlink to repo
ls -la ~/.config/rofi        # Should be symlink to repo
ls -la ~/.zshrc              # Should be symlink to repo

# Check directories created
ls -d ~/.wallpapers ~/Screenshots  # Both should exist
```

### 3. Wallpaper Setup
```bash
# Test without wallpaper (should handle gracefully)
rm -f ~/.wallpapers/wall.jpg
hyprctl reload  # Should not crash

# Add wallpaper
cp /path/to/test-image.jpg ~/.wallpapers/wall.jpg
hyprctl reload  # Should load wallpaper
```

## Hyprland Configuration Testing

### 1. Config Syntax Validation
```bash
# Start Hyprland (from TTY)
Hyprland

# Test config reload
hyprctl reload  # Should complete without errors

# Check for deprecated syntax warnings
journalctl --user -u hyprland.service --since "5 min ago" | grep -i warning
```

### 2. Visual Elements
- [ ] **Blur effects**: Windows should have subtle blur
- [ ] **Rounded corners**: Windows have 8px rounded corners
- [ ] **Borders**: 2px borders on focused windows
- [ ] **Gaps**: 6px inner gaps, 12px outer gaps
- [ ] **Animations**: Smooth window transitions

### 3. Keybind Testing
Run these key combinations and verify expected behavior:

**Applications:**
- [ ] `Super+Enter` → Opens Alacritty terminal
- [ ] `Super+D` → Opens Rofi application launcher  
- [ ] `Super+E` → Opens Yazi file manager in terminal
- [ ] `Super+Ctrl+L` → Locks screen with hyprlock

**Window Management:**
- [ ] `Super+H/J/K/L` → Focus adjacent windows
- [ ] `Super+Shift+H/J/K/L` → Move windows
- [ ] `Super+Ctrl+H/J/K/L` → Resize windows
- [ ] `Super+Space` → Toggle floating mode
- [ ] `Super+F` → Toggle fullscreen
- [ ] `Super+Q` → Close active window

**Workspaces:**
- [ ] `Super+1-9` → Switch to workspace
- [ ] `Super+Shift+1-9` → Move window to workspace

**Screenshots:**
- [ ] `Super+P` → Region screenshot to clipboard
- [ ] `Super+Shift+P` → Region screenshot to ~/Screenshots
- [ ] `Print` → Region screenshot to clipboard (if Print key exists)
- [ ] `Shift+Print` → Region screenshot to ~/Screenshots

**Media Keys (if available):**
- [ ] `XF86AudioRaiseVolume` → Increase volume with SwayOSD overlay
- [ ] `XF86AudioLowerVolume` → Decrease volume with SwayOSD overlay
- [ ] `XF86AudioMute` → Toggle mute with SwayOSD overlay
- [ ] `XF86MonBrightnessUp/Down` → Adjust brightness with SwayOSD overlay

## Application Testing

### 1. Waybar Status Bar
```bash
# Check if waybar is running
pgrep waybar

# Verify modules display correctly:
```
- [ ] **Workspaces**: Shows numbers 1-9, highlights active
- [ ] **Clock**: Displays current time in format "Mon Jan 01  14:30"
- [ ] **Audio**: Shows volume percentage and icon
- [ ] **Network**: Shows connection status
- [ ] **Bluetooth**: Shows BT status
- [ ] **Battery**: Shows percentage (on laptops)
- [ ] **System tray**: Shows running applications

### 2. Rofi Application Launcher
- [ ] Opens with `Super+D`
- [ ] Shows installed applications with icons
- [ ] Search functionality works
- [ ] Can launch applications
- [ ] Uses Flexoki dark theme

### 3. Mako Notifications
```bash
# Test notification system
notify-send "Test Title" "Test message body"
```
- [ ] Notification appears in top-right corner
- [ ] Uses correct font (Inter with fallbacks)
- [ ] Has proper theming (dark background)
- [ ] Disappears after timeout

### 4. Terminal (Alacritty)
- [ ] Opens with `Super+Enter`
- [ ] Uses IosevkaTerm Nerd Font (or fallback)
- [ ] Has correct opacity (0.97)
- [ ] Background color matches theme
- [ ] Nerd Font icons display correctly

## Lock Screen & Idle Testing

### 1. Hypridle Behavior
```bash
# Check hypridle is running
pgrep hypridle

# Test timeout sequence (you may want to temporarily reduce timeouts):
```
- [ ] **5 minutes**: Screen dims to 10%
- [ ] **9 minutes**: Warning notification appears
- [ ] **10 minutes**: Screen locks automatically
- [ ] **15 minutes**: Display turns off (DPMS)
- [ ] **30 minutes**: System suspends

### 2. Hyprlock Screen
- [ ] Manual lock works (`Super+Ctrl+L`)
- [ ] Shows wallpaper with blur overlay
- [ ] Password field appears centered
- [ ] Clock displays correctly
- [ ] Can unlock with password

## Font and Internationalization Testing

### 1. Font Availability
```bash
# Check installed fonts
fc-list | grep -E "(Inter|IosevkaTerm|JetBrains|Noto)"
```

### 2. Font Fallback Testing
```bash
# Temporarily rename primary font to test fallbacks
sudo mv /usr/share/fonts/TTF/Inter* /tmp/
fc-cache -f

# Check if UI still displays correctly:
```
- [ ] Waybar uses Noto Sans fallback
- [ ] Rofi uses sans-serif fallback  
- [ ] Mako notifications still readable

```bash
# Restore fonts
sudo mv /tmp/Inter* /usr/share/fonts/TTF/
fc-cache -f
```

### 3. International Character Support
- [ ] Emoji display correctly: 🎉 📱 ⚡
- [ ] CJK characters display: 你好 こんにちは 안녕하세요
- [ ] Special characters: áéíóú ñ ü

## Service Integration Testing

### 1. Audio System
```bash
# Check PipeWire services
systemctl --user status pipewire pipewire-pulse wireplumber

# Test audio
wpctl status  # Should show available sinks
```

### 2. Bluetooth
```bash
# Check bluetooth service
systemctl status bluetooth

# Test with bluetuith
bluetuith  # Should show bluetooth interface
```

### 3. Network Management
```bash
# Check NetworkManager
systemctl status NetworkManager

# Test network tools
nmtui  # Should open network configuration
```

## Edge Case Testing

### 1. Missing Dependencies
- [ ] **No wallpaper**: System handles missing `~/.wallpapers/wall.jpg`
- [ ] **Missing Go**: Falls back to GitHub release for bluetuith
- [ ] **Build failure**: Script continues if wlogout build fails
- [ ] **Service disabled**: Proper warnings shown for NetworkManager/Bluetooth

### 2. Configuration Errors
- [ ] **Invalid config**: Hyprland handles syntax errors gracefully
- [ ] **Missing binary**: Error messages are clear and helpful
- [ ] **Broken symlinks**: `scripts/link.sh` can re-run safely

## Performance Testing

### 1. Boot and Startup
- [ ] Hyprland starts within reasonable time
- [ ] All autostart applications launch correctly
- [ ] No excessive CPU usage during startup

### 2. Runtime Performance
- [ ] Smooth animations during window operations
- [ ] No stuttering during blur effects
- [ ] Responsive keybind reactions
- [ ] Stable memory usage over time

## System Integration Testing

### 1. Desktop Portals
```bash
# Test screenshare/file picker portals
echo $XDG_CURRENT_DESKTOP  # Should be "Hyprland"
```

### 2. BTRFS/Snapshots (if applicable)
```bash
# Check if snapshot was created during install
snapper list | tail -5
```

## Troubleshooting During Testing

If tests fail, check:

1. **Service status**: `systemctl --user status service-name`
2. **Log files**: `journalctl --user -f` for real-time logs
3. **Configuration syntax**: `hyprctl reload` for immediate feedback
4. **Missing dependencies**: Use diagnostic commands from `TROUBLESHOOTING.md`

## Test Environment Setup

For consistent testing, consider:

- **VM snapshot** before running tests
- **Clean user account** without existing dotfiles
- **Standard test wallpaper** for consistent results
- **Document system specs** for performance comparisons

## Automated Testing Script

Create a quick verification script:
```bash
#!/bin/bash
echo "==> Quick system check"
pgrep hyprpaper && echo "✓ hyprpaper" || echo "✗ hyprpaper"
pgrep waybar && echo "✓ waybar" || echo "✗ waybar"
pgrep mako && echo "✓ mako" || echo "✗ mako"
pgrep hypridle && echo "✓ hypridle" || echo "✗ hypridle"
pgrep swayosd-server && echo "✓ swayosd" || echo "✗ swayosd"
command -v bluetuith && echo "✓ bluetuith" || echo "✗ bluetuith"
command -v wlogout && echo "✓ wlogout" || echo "✗ wlogout"
[ -f ~/.wallpapers/wall.jpg ] && echo "✓ wallpaper" || echo "✗ wallpaper"
```