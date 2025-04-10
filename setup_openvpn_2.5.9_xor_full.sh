#!/bin/bash
# ⚡ OpenVPN 2.5.9 + XOR Full Installer ⚡
# Based on Angristan's OpenVPN installer and Tunnelblick XOR patches
# https://github.com/angristan/openvpn-install
# https://github.com/Tunnelblick/Tunnelblick

set -e

# Functions
function warn() {
  echo -e "\e[31m[ERROR]\e[0m $1"
}

function info() {
  echo -e "\e[32m[INFO]\e[0m $1"
}

function download_or_exit() {
  local url="$1"
  local output="$2"

  if ! wget -q --show-progress "$url" -O "$output"; then
    warn "Failed to download $url"
    exit 1
  fi
}

# Ask to install Angristan OpenVPN
read -rp "👉 Proceed with Angristan OpenVPN Install? (Y/n): " install_openvpn
install_openvpn=${install_openvpn:-y}

if [[ "$install_openvpn" =~ ^[Yy]$ ]]; then
  wget https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh -O openvpn-install.sh
  chmod +x openvpn-install.sh
  bash openvpn-install.sh
else
  info "Skipping Angristan OpenVPN install."
fi

# Ask to install XOR patch
read -rp "👉 Proceed with XOR patch installation? (Y/n): " install_xor
install_xor=${install_xor:-y}

if [[ "$install_xor" =~ ^[Yy]$ ]]; then
  info "Installing build dependencies..."
  apt update
  apt install -y build-essential libssl-dev liblzo2-dev libpam0g-dev libpkcs11-helper1-dev libsystemd-dev pkg-config liblz4-dev resolvconf

  info "Downloading OpenVPN 2.5.9 source..."
  wget https://swupdate.openvpn.net/community/releases/openvpn-2.5.9.tar.gz
  tar -xzf openvpn-2.5.9.tar.gz
  cd openvpn-2.5.9 || exit 1

  info "Downloading Tunnelblick XOR patches..."

  download_or_exit "https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/02-tunnelblick-openvpn_xorpatch-a.diff" "02.diff"
  download_or_exit "https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/03-tunnelblick-openvpn_xorpatch-b.diff" "03.diff"
  download_or_exit "https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/04-tunnelblick-openvpn_xorpatch-c.diff" "04.diff"
  download_or_exit "https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/05-tunnelblick-openvpn_xorpatch-d.diff" "05.diff"
  download_or_exit "https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/06-tunnelblick-openvpn_xorpatch-e.diff" "06.diff"

  info "Applying patches..."
  patch -p1 < 02.diff
  patch -p1 < 03.diff
  patch -p1 < 04.diff
  patch -p1 < 05.diff
  patch -p1 < 06.diff

  info "Configuring and building OpenVPN with XOR support..."
  ./configure
  make -j$(nproc)
  make install

  cd ~ || exit 1

  info "✅ OpenVPN 2.5.9 with XOR patch installed."
else
  info "Skipping XOR patch installation."
fi

# Generate random XOR key
XOR_KEY=$(xxd -p -l 16 /dev/urandom)
echo "🔑 Generated random XOR key: $XOR_KEY"

# Add scramble directive to server config if it exists
if [ -f /etc/openvpn/server.conf ]; then
  echo "scramble xormask $XOR_KEY" >> /etc/openvpn/server.conf
  systemctl restart openvpn@server || warn "OpenVPN service restart failed."
fi

info "⚡ Installation complete!"
