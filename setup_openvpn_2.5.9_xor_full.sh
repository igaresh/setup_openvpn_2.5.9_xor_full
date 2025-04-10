#!/bin/bash

# ===============================
# OpenVPN 2.5.9 Installer + XOR Patch
# ===============================
# Author: Custom Script for Turkmenistan use
# License: MIT
# ===============================

echo "📦 Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y build-essential libssl-dev iproute2 liblz4-dev liblzo2-dev libpam0g-dev \
    libpkcs11-helper1-dev libsystemd-dev resolvconf pkg-config curl wget

# ----------------------------------------
# Step 1. Download Angristan OpenVPN installer
# ----------------------------------------
echo "⬇️ Downloading Angristan OpenVPN installer..."
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

# ----------------------------------------
# Step 2. Run Angristan script
# ----------------------------------------
echo "🚀 Starting OpenVPN installation..."
./openvpn-install.sh

# ----------------------------------------
# Step 3. Apply XOR scramble settings
# ----------------------------------------
echo "🔧 Applying XOR scramble settings..."

# Generate random 24-character HEX key
XOR_KEY=$(openssl rand -hex 12)

# Insert XOR scramble into server and client configs
echo "scramble xormask $XOR_KEY" >> /etc/openvpn/server.conf
echo "scramble xormask $XOR_KEY" >> /etc/openvpn/client-template.txt
echo "scramble xormask $XOR_KEY" >> /root/client.ovpn

# ----------------------------------------
# Step 4. Remove default OpenVPN
# ----------------------------------------
echo "🧹 Removing default OpenVPN..."
apt remove -y openvpn

# ----------------------------------------
# Step 5. Compile and install OpenVPN 2.5.9 with XOR patches
# ----------------------------------------
echo "🔧 Downloading OpenVPN 2.5.9 source..."
wget https://swupdate.openvpn.org/community/releases/openvpn-2.5.9.tar.gz
tar xvf openvpn-2.5.9.tar.gz
cd openvpn-2.5.9

echo "📥 Downloading XOR patches..."
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/02-tunnelblick-openvpn_xorpatch-a.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/03-tunnelblick-openvpn_xorpatch-b.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/04-tunnelblick-openvpn_xorpatch-c.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/05-tunnelblick-openvpn_xorpatch-d.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/06-tunnelblick-openvpn_xorpatch-e.diff

# Apply patches
patch -p1 < 02-tunnelblick-openvpn_xorpatch-a.diff
patch -p1 < 03-tunnelblick-openvpn_xorpatch-b.diff
patch -p1 < 04-tunnelblick-openvpn_xorpatch-c.diff
patch -p1 < 05-tunnelblick-openvpn_xorpatch-d.diff
patch -p1 < 06-tunnelblick-openvpn_xorpatch-e.diff

# Configure and install
echo "⚙️ Configuring OpenVPN 2.5.9..."
./configure --enable-static=yes --enable-shared --disable-debug --disable-plugin-auth-pam --disable-dependency-tracking
make -j$(nproc)
make install

# ----------------------------------------
# Step 6. Create OpenVPN service
# ----------------------------------------
echo "🛠️ Creating OpenVPN systemd service..."

cat << EOF > /etc/systemd/system/openvpn@server.service
[Unit]
Description=OpenVPN Robust And Highly Flexible Tunneling Application On %I
After=syslog.target network.target

[Service]
Type=forking
PrivateTmp=true
ExecStart=/usr/local/sbin/openvpn --daemon --cd /etc/openvpn/ --config /etc/openvpn/server.conf
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl enable openvpn@server
systemctl start openvpn@server

# ----------------------------------------
# Step 7. Final Message
# ----------------------------------------
echo "✅ OpenVPN 2.5.9 with XOR obfuscation installed!"
echo "🚀 Your XOR Key: $XOR_KEY"
echo "ℹ️ Client .ovpn config saved at: /root/client.ovpn (already modified with XOR key)"