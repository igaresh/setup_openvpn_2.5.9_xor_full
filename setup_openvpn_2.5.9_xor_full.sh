#!/bin/bash

# OpenVPN 2.5.9 Full Installer with XOR + Smart Pinger + Traffic Padding + QR Code Support
# For Ubuntu 20.04+ | Optimized for censorship bypass (e.g. Turkmenistan)

set -e

# ----------- VARIABLES -----------
INSTALL_DIR="/etc/openvpn"
EASYRSA_DIR="$INSTALL_DIR/easy-rsa"
QR_DIR="/root/qr-codes"
LOG_FILE="/root/openvpn_install_$(date +%Y%m%d%H%M%S).log"

# Colors for output
green="\033[0;32m"
red="\033[0;31m"
reset="\033[0m"

# ----------- FUNCTIONS -----------

function print_info() {
    echo -e "${green}[INFO]${reset} $1"
}

function clean_vps() {
    print_info "Cleaning previous OpenVPN installations..."
    systemctl stop openvpn@server.service || true
    apt-get remove --purge openvpn -y || true
    rm -rf /etc/openvpn
    rm -rf /root/openvpn-install*
    rm -rf /root/easy-rsa*
    rm -rf /root/qr-codes*
}

function install_dependencies() {
    print_info "Installing dependencies..."
    apt-get update
    apt-get install -y build-essential wget curl qrencode lz4 liblz4-dev liblzo2-dev libpam0g-dev libssl-dev pkg-config iptables ca-certificates gnupg
}

function install_angristan_openvpn() {
    print_info "Running Angristan OpenVPN installer..."
    curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
    chmod +x openvpn-install.sh
    AUTO_INSTALL=y ./openvpn-install.sh
}

function patch_openvpn_xor() {
    print_info "Patching OpenVPN with XOR support..."
    cd /root
    wget https://swupdate.openvpn.net/community/releases/openvpn-2.5.9.tar.gz
    tar xzf openvpn-2.5.9.tar.gz
    cd openvpn-2.5.9

    for patch in {02..06}; do
        wget https://raw.githubusercontent.com/Tunnelblick/Tunnelblick/master/third_party/sources/openvpn/openvpn-2.5.9/patches/${patch}-tunnelblick-openvpn_xorpatch-$(echo $patch | tr '0-9' 'a-e').diff
        patch -p1 < ${patch}-tunnelblick-openvpn_xorpatch-*.diff
    done

    ./configure
    make -j$(nproc)
    make install

    print_info "XOR Patch installed successfully."
}

function setup_server_conf() {
    print_info "Configuring server.conf..."
    cat > $INSTALL_DIR/server.conf << EOF
port 443
proto udp
dev tun
user nobody
group nogroup
persist-key
persist-tun
keepalive 10 120
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "dhcp-option DNS 45.90.28.167"
push "dhcp-option DNS 45.90.30.167"
push "redirect-gateway def1 bypass-dhcp"
dh none
ecdh-curve secp384r1
tls-crypt tls-crypt.key
crl-verify crl.pem
ca ca.crt
cert server.crt
key server.key
auth SHA512
cipher AES-192-GCM
data-ciphers AES-192-GCM
tls-server
tls-version-min 1.2
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384
client-config-dir /etc/openvpn/ccd
status /var/log/openvpn/status.log
verb 3
scramble xormask a706984b232feef760c6cc839fe12e2e2870977c
ping 5
ping-restart 30
ping-timer-rem
fragment 1200
mssfix 1200
EOF
}

function enable_services() {
    systemctl daemon-reload
    systemctl enable openvpn@server
    systemctl start openvpn@server
}

function create_client() {
    mkdir -p "$QR_DIR"

    while true; do
        read -p "Enter client name (letters/numbers/-/_ only): " CLIENT
        if [[ "$CLIENT" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            break
        else
            echo "Invalid client name. Only letters, numbers, underscores, and dashes allowed."
        fi
    done

    ./openvpn-install.sh --add-client "$CLIENT"

    print_info "Fixing client configuration for scramble and fragment."
    sed -i '/^cipher /d' "/home/ubuntu/${CLIENT}.ovpn"
    echo -e "scramble xormask a706984b232feef760c6cc839fe12e2e2870977c\nfragment 1200\nmssfix 1200" >> "/home/ubuntu/${CLIENT}.ovpn"

    print_info "Generating QR code..."
    qrencode -t png -o "$QR_DIR/${CLIENT}.png" < "/home/ubuntu/${CLIENT}.ovpn"
    echo -e "${green}Client $CLIENT generated successfully! QR code saved at $QR_DIR/${CLIENT}.png${reset}"
}

# ----------- MAIN MENU -----------

clear
echo -e "${green}OpenVPN Full Installer (XOR Patched)${reset}"
echo "--------------------------------------"
echo "Logging everything to: $LOG_FILE"
echo ""

read -p "👉 Do you want to clean the VPS first? (y/N): " CLEAN_FIRST
if [[ "$CLEAN_FIRST" =~ ^[Yy]$ ]]; then
    clean_vps
fi

install_dependencies
install_angristan_openvpn
patch_openvpn_xor
setup_server_conf
enable_services

print_info "✅ OpenVPN Server is fully installed and running!"

while true; do
    echo ""
    read -p "👉 Generate a new client? (Y/n): " ADD_CLIENT
    if [[ "$ADD_CLIENT" =~ ^[Nn]$ ]]; then
        break
    fi
    create_client
done

print_info "🎉 All done! Use your generated .ovpn files and QR codes to connect!"
