#!/usr/bin/env bash
set -euo pipefail

# Setup pacman hooks for automatic snapshots

echo "==> Setting up pacman hooks for automatic snapshots"

# Create hooks directory
sudo mkdir -p /etc/pacman.d/hooks

# Pre-transaction hook (before package operations)
sudo tee /etc/pacman.d/hooks/00-snapper-pre.hook >/dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating pre-transaction snapshot...
When = PreTransaction
Exec = /usr/bin/snapper -c root create --pre-number --print-number --description "pacman pre-transaction"
Depends = snapper
AbortOnFail
EOF

# Post-transaction hook (after package operations)
sudo tee /etc/pacman.d/hooks/95-snapper-post.hook >/dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install  
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating post-transaction snapshot...
When = PostTransaction
Exec = /bin/bash -c '/usr/bin/snapper -c root create --post-number $(cat /tmp/snapper-pre-number 2>/dev/null || echo "") --description "pacman post-transaction"'
Depends = snapper
EOF

# Script to store pre-transaction number
sudo tee /usr/local/bin/snapper-pre-hook >/dev/null <<'EOF'
#!/bin/bash
# Store pre-transaction snapshot number for post hook
PRE_NUMBER=$(/usr/bin/snapper -c root create --pre-number --print-number --description "pacman pre-transaction")
echo "$PRE_NUMBER" > /tmp/snapper-pre-number
EOF

sudo chmod +x /usr/local/bin/snapper-pre-hook

# Update the pre-hook to use the script
sudo tee /etc/pacman.d/hooks/00-snapper-pre.hook >/dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating pre-transaction snapshot...
When = PreTransaction
Exec = /usr/local/bin/snapper-pre-hook
Depends = snapper
AbortOnFail
EOF

echo "✓ Created pacman hooks for automatic pre/post snapshots"
echo "✓ Package operations will now create snapshots automatically"
echo ""
echo "Hooks created:"
echo "  /etc/pacman.d/hooks/00-snapper-pre.hook"  
echo "  /etc/pacman.d/hooks/95-snapper-post.hook"
echo "  /usr/local/bin/snapper-pre-hook"
echo ""
echo "Test with: sudo pacman -S --needed base-devel"