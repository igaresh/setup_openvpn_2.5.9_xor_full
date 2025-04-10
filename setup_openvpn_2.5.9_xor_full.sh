#!/bin/bash

# =======================================================
#  Ultimate OpenVPN XOR Scramble Installer for Turkmenistan
#  Created for Ubuntu 20.04/22.04 - Full Interactive Mode
# =======================================================

set -e

LOGFILE="/root/openvpn-install-$(date +%Y%m%d%H%M%S).log"
echo "[INFO] Logging to $LOGFILE"
exec > >(tee -i "$LOGFILE") 2>&1

# ========= CLEANUP OLD INSTALLATIONS ===========
echo "\n[INFO] 🧹 Cleaning previous OpenVPN installations..."
apt remove --purge -y openvpn || true
rm -rf /etc/openvpn
rm -rf /root/openvpn-*

# ========= INSTALL ANGRISTAN OPENVPN ============
echo "\n👉 Proceed with Angristan OpenVPN Install? (Y/n)"
read -r install_angristan
if [[ $install_angristan != "n" ]]; then
  echo "[INFO] Downloading and running Angristan OpenVPN installer..."
  wget https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh -O openvpn-install.sh
  chmod +x openvpn-install.sh
  AUTO_INSTALL=y ./openvpn-install.sh
fi

# ========= APPLY XOR PATCH TO OPENVPN ===========
echo "\n👉 Proceed with XOR Patch installation? (Y/n)"
read -r install_xor
if [[ $install_xor != "n" ]]; then
  echo "[INFO] Installing build dependencies..."
  apt update
  apt install -y build-essential libssl-dev liblzo2-dev liblz4-dev libpam0g-dev pkg-config

  echo "[INFO] Downloading OpenVPN 2.5.9 source..."
  wget https://swupdate.openvpn.net/community/releases/openvpn-2.5.9.tar.gz
  tar -xzf openvpn-2.5.9.tar.gz
  cd openvpn-2.5.9

  echo "[INFO] Downloading XOR patches..."
  wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/openvpn/patches/02.diff
  wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/openvpn/patches/03.diff
  wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/openvpn/patches/04.diff
  wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/openvpn/patches/05.diff
  wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/openvpn/patches/06.diff

  echo "[INFO] Applying patches..."
  patch -p1 < 02.diff
  patch -p1 < 03.diff
  patch -p1 < 04.diff
  patch -p1 < 05.diff
  patch -p1 < 06.diff

  echo "[INFO] Configuring and building OpenVPN with XOR..."
  ./configure
  make
  make install
  cd ..

  XOR_KEY=$(openssl rand -hex 24)
  echo "[INFO] 🔑 Generated random XOR key: $XOR_KEY"
  sed -i "/^tls-crypt tls-crypt.key/a scramble xormask $XOR_KEY" /etc/openvpn/server.conf
fi

# ========= INSTALL SMART PINGER ===========
echo "\n👉 Install Smart Pinger? (Y/n)"
read -r install_smart_pinger
if [[ $install_smart_pinger != "n" ]]; then
  echo "[INFO] Installing smart pinger..."
  cat <<EOF > /usr/local/bin/openvpn-pinger.sh
#!/bin/bash
ping -c 3 1.1.1.1 >/dev/null || systemctl restart openvpn@server
EOF
  chmod +x /usr/local/bin/openvpn-pinger.sh
  (crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/openvpn-pinger.sh") | crontab -
fi

# ========= INSTALL TRAFFIC PADDING (FRAGMENT) ===========
echo "\n[INFO] ✅ Enabling Traffic Padding (Fragmentation Obfuscation)..."
cat <<EOF >> /etc/openvpn/server.conf
push "fragment 1200"
push "mssfix 1200"
EOF

systemctl daemon-reload
systemctl restart openvpn@server || echo "[WARN] OpenVPN server might need manual check!"

# ========= CLIENT TEMPLATE AUTO CREATION ===========
echo "\n[INFO] 🛠️ Preparing client template..."
mkdir -p /etc/openvpn/clients
cp /home/ubuntu/client.ovpn /etc/openvpn/clients/base.ovpn
sed -i "/^remote/c remote YOUR_SERVER_IP 443 udp" /etc/openvpn/clients/base.ovpn
sed -i "/^tls-crypt tls-crypt.key/a scramble xormask $XOR_KEY" /etc/openvpn/clients/base.ovpn
sed -i '/^auth/a fragment 1200\nmssfix 1200' /etc/openvpn/clients/base.ovpn

# ========= CLIENT GENERATION TOOL ===========
echo "\n👉 Generate new VPN Client? (Y/n)"
read -r generate_client
while [[ $generate_client != "n" ]]; do
  echo "Enter client name (only letters, numbers, underscores):"
  read -r clientname

  ./openvpn-install.sh --add-client "$clientname"
  mkdir -p /root/clients
  cp /home/ubuntu/"$clientname".ovpn /root/clients/"$clientname".ovpn
  qrencode -t ansiutf8 < /root/clients/"$clientname".ovpn

  echo "\n👉 Generate another VPN Client? (Y/n)"
  read -r generate_client
done

# ========= FINAL MESSAGE ===========
echo "\n⚡ All done! OpenVPN is ready with Obfuscation, Smart Pinger, Fragmentation, and Client QR Codes! ⚡"
echo "Clients saved in /root/clients/"

exit 0
