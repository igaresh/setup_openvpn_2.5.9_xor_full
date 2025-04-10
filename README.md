# 📄 setup_openvpn_2.5.9_xor_full

This script automatically installs and configures **OpenVPN 2.5.9** with **XOR patch obfuscation** on Ubuntu servers (tested on 20.04+).  
It is designed to help circumvent censorship and DPI (Deep Packet Inspection) systems.

---

## 📦 Features

- Install latest **Angristan OpenVPN** script first.
- Upgrade to **OpenVPN 2.5.9** (custom build from source).
- Apply **Tunnelblick XOR patches** for simple traffic obfuscation.
- Generate a **secure random XOR key**.
- Automatically **insert XOR settings** into server and client configurations.
- **(Optional)** Smart pinger and hourly OpenVPN restart for extra stealth.
- **Automatic generation** of `.ovpn` client file ready to import.

---

## 🚀 Quick Start

```bash
wget https://raw.githubusercontent.com/igaresh/setup_openvpn_2.5.9_xor_full/main/setup_openvpn_2.5.9_xor_full.sh
chmod +x setup_openvpn_2.5.9_xor_full.sh
sudo ./setup_openvpn_2.5.9_xor_full.sh
```

---

## ⚙️ Requirements

- Ubuntu 20.04 or newer.
- Root or sudo privileges.
- Open ports (default is `1194` or `443` TCP/UDP).

---

## ⚡️ Notes

- **XOR obfuscation** is a lightweight method and can help against basic censorship/DPI systems.
- **TLS-Crypt** is enabled by default for better stealth (through Angristan's script).
- **Traffic Padding** (optional) and **hourly OpenVPN restart** features are available during installation.

---

## 📜 License

This project is licensed under the [MIT License](LICENSE).

---

## 💬 Disclaimer

This script is intended for educational purposes and legal circumvention only.  
Use responsibly according to your local laws.

---

## 🤝 Credits

This project is based on angristan/openvpn-install, a fantastic open-source OpenVPN installer.

We have adapted it to include additional options for circumvention, XOR obfuscation, and other enhancements.

The original openvpn-install is licensed under the MIT License, and we gratefully acknowledge its author.
