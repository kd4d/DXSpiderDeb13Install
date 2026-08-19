#!/bin/bash
set -e

echo "=== 1. Updating System & Installing Prerequisites ==="
apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release git telnet

echo "=== 2. Configuring Official Docker Repository ==="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== 3. Cleaning Up Default User & Creating Sysop User ==="
deluser --remove-home debian 2>/dev/null || true

# Create sysop user if it doesn't already exist
if ! id "sysop" &>/dev/null; then
  useradd -m -u 1000 -s /bin/bash sysop
  echo "Please set a password for the sysop user:"
  passwd sysop
fi

# Ensure sudo and docker group memberships are applied unconditionally
usermod -aG sudo sysop
usermod -aG docker sysop

echo ""
echo "========================================================================"
echo " Root setup complete!"
echo " Please log out completely and log back in as 'sysop'"
echo " then execute setup_sysop.sh"
echo "========================================================================"
