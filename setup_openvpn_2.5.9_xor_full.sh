#!/bin/bash

set -e

# 1. Download and prepare OpenVPN installer script
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

# 2. Remove existing OpenVPN installation if present
apt remove -y openvpn || true

# 3. Update system and install build dependencies
apt update && apt dist-upgrade -y
apt install -y build-essential libssl-dev iproute2 liblz4-dev liblzo2-dev libpam0g-dev libpkcs11-helper1-dev libsystemd-dev resolvconf pkg-config

# 4. Download and extract OpenVPN 2.5.9 source
cd /usr/local/src
wget https://swupdate.openvpn.org/community/releases/openvpn-2.5.9.tar.gz

# Ensure clean state
rm -rf openvpn-2.5.9

# Extract
 tar xvf openvpn-2.5.9.tar.gz
cd openvpn-2.5.9

# 5. Download XOR patches
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/02-tunnelblick-openvpn_xorpatch-a.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/03-tunnelblick-openvpn_xorpatch-b.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/04-tunnelblick-openvpn_xorpatch-c.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/05-tunnelblick-openvpn_xorpatch-d.diff
wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/06-tunnelblick-openvpn_xorpatch-e.diff

# 6. Apply patches
patch -p1 < 02-tunnelblick-openvpn_xorpatch-a.diff
patch -p1 < 03-tunnelblick-openvpn_xorpatch-b.diff
patch -p1 < 04-tunnelblick-openvpn_xorpatch-c.diff
patch -p1 < 05-tunnelblick-openvpn_xorpatch-d.diff
patch -p1 < 06-tunnelblick-openvpn_xorpatch-e.diff

# 7. Configure, compile, and install OpenVPN
./configure --enable-static=yes --enable-shared --disable-debug --disable-plugin-auth-pam --disable-dependency-tracking
make -j$(nproc)
make install

# 8. Create OpenVPN service file
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

# 9. Enable service
gsystemctl -f enable openvpn@server

# 10. Generate random XOR key and update configurations
KEY=$(openssl rand -hex 20)
echo "Using scramble xormask key: $KEY"

# Update server.conf, client-template.txt, client.ovpn
sed -i "s/^port .*/port 443/" /etc/openvpn/server.conf
sed -i "s/1194/443/g" /etc/openvpn/client-template.txt

# Add XOR scramble key to configs
echo "scramble xormask $KEY" >> /etc/openvpn/server.conf
echo "scramble xormask $KEY" >> /etc/openvpn/client-template.txt
echo "scramble xormask $KEY" >> /root/client.ovpn

# Add pinging and paddling options
grep -q '^ping ' /etc/openvpn/server.conf || echo -e "\nping 10\nping-restart 120\nmssfix 1300\ntun-mtu 1400\nexplicit-exit-notify 1" >> /etc/openvpn/server.conf

# 11. Start OpenVPN service
systemctl restart openvpn@server

# 12. Final info
echo "\nOpenVPN 2.5.9 with XOR scrambling is installed and running!"
echo "XOR key was set to: $KEY"
