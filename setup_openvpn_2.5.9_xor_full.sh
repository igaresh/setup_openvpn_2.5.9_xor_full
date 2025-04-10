#!/bin/bash
# OpenVPN 2.5.9 + XOR Obfuscation Full Setup Script
# Author: igaresh
# https://github.com/igaresh/setup_openvpn_2.5.9_xor_full

set -e

clear
echo "⚡ OpenVPN 2.5.9 + XOR Full Installer ⚡"
echo

# -------------------
# Step 1: Angristan Install
# -------------------
read -rp "👉 Proceed with Angristan OpenVPN Install? (Y/n): " install_angristan
if [[ $install_angristan =~ ^[Yy]$ || -z $install_angristan ]]; then
  curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
  chmod +x openvpn-install.sh
  ./openvpn-install.sh
fi

# -------------------
# Step 2: Patch with XOR
# -------------------
read -rp "👉 Proceed with XOR patch installation? (Y/n): " install_xor
if [[ $install_xor =~ ^[Yy]$ || -z $install_xor ]]; then
  apt remove -y openvpn
  apt update && apt install -y build-essential libssl-dev iproute2 liblz4-dev liblzo2-dev libpam0g-dev libpkcs11-helper1-dev libsystemd-dev resolvconf pkg-config

  wget https://swupdate.openvpn.net/community/releases/openvpn-2.5.9.tar.gz
  tar xvf openvpn-2.5.9.tar.gz
  cd openvpn-2.5.9

  # Download patches
  for patch in a b c d e; do
    wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/0$((2+${#patch}))-tunnelblick-openvpn_xorpatch-${patch}.diff
  done

  # Apply patches
  for patch in 02 03 04 05 06; do
    patch -p1 < 0$patch-tunnelblick-openvpn_xorpatch-$(echo "$patch" | sed 's/0//')".diff"
  done

  ./configure --enable-static=yes --enable-shared --disable-debug --disable-plugin-auth-pam --disable-dependency-tracking
  make -j$(nproc)
  make install
  cd ..
fi

# -------------------
# Step 3: Generate Random XOR Key
# -------------------
XOR_KEY=$(openssl rand -hex 16)
echo "🔑 Generated random XOR key: $XOR_KEY"

# Insert XOR scramble into server config
if [[ -f /etc/openvpn/server.conf ]]; then
  echo "scramble xormask $XOR_KEY" >> /etc/openvpn/server.conf
  echo 'push "scramble xormask '"$XOR_KEY"'"' >> /etc/openvpn/server.conf
  echo 'push "mssfix 1400"' >> /etc/openvpn/server.conf
  echo "mssfix 1400" >> /etc/openvpn/server.conf
  systemctl restart openvpn@server
fi

# -------------------
# Step 4: Smart Pinger (Optional)
# -------------------
read -rp "👉 Install Smart Pinger (defend against DPI)? (Y/n): " install_pinger
if [[ $install_pinger =~ ^[Yy]$ || -z $install_pinger ]]; then
  cat << EOF > /usr/local/bin/smart-pinger.sh
#!/bin/bash
while true; do
  ping -c1 8.8.8.8 >/dev/null 2>&1
  sleep \$((RANDOM % 900 + 300))
done
EOF
  chmod +x /usr/local/bin/smart-pinger.sh

  cat << EOF > /etc/systemd/system/smart-pinger.service
[Unit]
Description=Smart Pinger to Keep VPN Link Alive
After=network.target

[Service]
ExecStart=/usr/local/bin/smart-pinger.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable smart-pinger
  systemctl start smart-pinger
  echo "✅ Smart Pinger installed and running."
fi

# -------------------
# Step 5: OpenVPN Auto-Restart Cron
# -------------------
read -rp "👉 Enable OpenVPN auto-restart (recommended)? (Y/n): " enable_restart
if [[ $enable_restart =~ ^[Yy]$ || -z $enable_restart ]]; then
  read -rp "🕐 Enter restart interval in minutes (e.g., 60): " restart_minutes
  (crontab -l 2>/dev/null; echo "*/$restart_minutes * * * * systemctl restart openvpn@server") | crontab -
  echo "✅ OpenVPN will auto-restart every $restart_minutes minutes."
fi

# -------------------
# Step 6: Traffic Padding (Optional)
# -------------------
read -rp "👉 Enable basic traffic padding? (Y/n): " enable_padding
if [[ $enable_padding =~ ^[Yy]$ || -z $enable_padding ]]; then
  echo "txqueuelen 1000" >> /etc/network/interfaces
  if [[ -d /etc/openvpn/ ]]; then
    echo "sndbuf 393216" >> /etc/openvpn/server.conf
    echo "rcvbuf 393216" >> /etc/openvpn/server.conf
    systemctl restart openvpn@server
  fi
  echo "✅ Basic traffic padding applied."
fi

# -------------------
# Step 7: Final OVPN File
# -------------------
if [[ -f /root/client.ovpn ]]; then
  echo "scramble xormask $XOR_KEY" >> /root/client.ovpn
  echo "mssfix 1400" >> /root/client.ovpn
  echo "✅ XOR scramble injected into final /root/client.ovpn!"
fi

echo
echo "🎉 DONE! Your OpenVPN server is now installed with XOR obfuscation and hardening options!"
