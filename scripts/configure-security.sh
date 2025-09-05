#!/usr/bin/env bash
set -euo pipefail

# Security configuration script - run after tailscale up

echo "==> Configuring security settings"

# Check if tailscale is connected
if ! tailscale status >/dev/null 2>&1; then
  echo "Error: Tailscale not connected. Run 'sudo tailscale up' first"
  exit 1
fi

# Get tailscale IP
TAILSCALE_IP=$(tailscale ip -4)
echo "Tailscale IP: $TAILSCALE_IP"

# Configure SSH to only listen on tailscale interface
echo "==> Configuring SSH for tailscale-only access"

# Backup original sshd_config
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

# Create secure SSH config with comprehensive hardening
sudo tee /etc/ssh/sshd_config.d/99-security-hardening.conf >/dev/null <<EOF
# SSH via tailscale only
ListenAddress ${TAILSCALE_IP}
Port 22

# Authentication hardening
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
ChallengeResponseAuthentication no
KbdInteractiveAuthentication no
UsePAM yes

# Disable dangerous features
X11Forwarding no
AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no
AllowAgentForwarding no

# Protocol hardening
Protocol 2
HostKey /etc/ssh/ssh_host_ed25519_key
HostKey /etc/ssh/ssh_host_rsa_key
KexAlgorithms curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com

# Connection limits and timeouts
MaxAuthTries 3
MaxSessions 2
MaxStartups 2:30:10
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2

# Logging
SyslogFacility AUTH
LogLevel VERBOSE

# Environment
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

echo "==> Configuring UFW for tailscale"

# Allow SSH on tailscale interface only
sudo ufw allow in on tailscale0 to any port 22 comment "SSH via tailscale"

# Allow tailscale traffic
sudo ufw allow in on tailscale0 comment "Tailscale interface"

# Enable UFW
sudo ufw --force enable

echo "==> Configuring fail2ban for SSH protection"

# Create fail2ban jail for SSH
sudo tee /etc/fail2ban/jail.d/sshd.local >/dev/null <<EOF
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
banaction = ufw
EOF

# Enable and start fail2ban
sudo systemctl enable --now fail2ban

echo "==> Starting SSH service"
sudo systemctl enable --now sshd

# Test SSH config
if sudo sshd -t; then
  echo "✓ SSH configuration is valid"
  sudo systemctl reload sshd
else
  echo "✗ SSH configuration error - restoring backup"
  sudo cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config
  exit 1
fi

# Configure secure DNS (Cloudflare)
echo "==> Configuring secure DNS (Cloudflare)"

# Backup existing resolv.conf
if [ -f /etc/resolv.conf ] && [ ! -f /etc/resolv.conf.bak ]; then
  sudo cp /etc/resolv.conf /etc/resolv.conf.bak
fi

# Configure systemd-resolved for Cloudflare DNS
sudo tee /etc/systemd/resolved.conf >/dev/null <<EOF
[Resolve]
DNS=1.1.1.1 1.0.0.1 2606:4700:4700::1111 2606:4700:4700::1001
FallbackDNS=8.8.8.8 8.8.4.4
Domains=~.
DNSSEC=yes
DNSOverTLS=opportunistic
Cache=yes
EOF

# Enable and restart systemd-resolved
sudo systemctl enable systemd-resolved
sudo systemctl restart systemd-resolved

# Link resolv.conf to systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

echo "✓ DNS configured to use Cloudflare (1.1.1.1) with DNSSEC and DNS-over-TLS"

# Setup SSH key-based authentication helper  
echo "==> Setting up SSH key authentication"
if [ ! -f "$HOME/.ssh/authorized_keys" ]; then
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  touch "$HOME/.ssh/authorized_keys"
  chmod 600 "$HOME/.ssh/authorized_keys"
  echo "Created ~/.ssh/authorized_keys - add your public keys here"
fi

echo ""
echo "==> Security configuration complete!"
echo ""
echo "SSH access (tailscale only):"
echo "  Internal: ssh $(whoami)@${TAILSCALE_IP}"
echo "  From tailnet: ssh $(whoami)@$(hostname)"
echo ""
echo "Security features enabled:"
echo "  ✓ SSH hardened (key-based auth, protocol restrictions)"
echo "  ✓ UFW firewall (deny all incoming except tailscale)"
echo "  ✓ Fail2ban (automatic IP banning for failed SSH attempts)"
echo "  ✓ Tailscale VPN (encrypted mesh network)"
echo "  ✓ Cloudflare DNS (1.1.1.1) with DNSSEC and DNS-over-TLS"
echo ""
echo "UFW status:"
sudo ufw status
echo ""
echo "IMPORTANT:"
echo "1. SSH is now restricted to tailscale network only!"
echo "2. Add your SSH public key to ~/.ssh/authorized_keys"  
echo "3. Test SSH connection via tailscale before logging out"
echo ""
echo "To add SSH key: echo 'your-ssh-public-key' >> ~/.ssh/authorized_keys"