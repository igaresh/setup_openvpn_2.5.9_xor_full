setup_openvpn_2.5.9_xor_full

🛡️ OpenVPN 2.5.9 + XOR Obfuscation + Smart Hardening

This script installs and configures an OpenVPN 2.5.9 server with:
	•	XOR packet obfuscation (Tunnelblick patches)
	•	Random XOR scramble key (generated securely)
	•	Smart background pinger (to defend against DPI detection)
	•	OpenVPN auto-restart (via cron, interval configurable)
	•	Basic traffic padding (optional)

Built on top of Angristan’s OpenVPN install script (special thanks!).

⸻

⚡ Features
	•	✅ OpenVPN 2.5.9 official source build
	•	✅ Tunnelblick XOR patching
	•	✅ Random XOR key generation (24 or 32 bits)
	•	✅ Automatic patching and building
	•	✅ Smart pinger against deep packet inspection
	•	✅ Cron job to restart OpenVPN automatically
	•	✅ Traffic padding for better camouflage
	•	✅ Full Interactive Mode (choose what you want)

⸻

wget https://raw.githubusercontent.com/igaresh/setup_openvpn_2.5.9_xor_full/main/setup_openvpn_2.5.9_xor_full.sh
chmod +x setup_openvpn_2.5.9_xor_full.sh
sudo ./setup_openvpn_2.5.9_xor_full.sh

⸻

⚙️ How it Works
	1.	Asks you step-by-step what to install (Angristan OpenVPN, XOR patch, Smart Pinger, Traffic Padding, etc.).
	2.	Patches OpenVPN source code with XOR scramble support.
	3.	Compiles and installs OpenVPN 2.5.9 manually.
	4.	Configures OpenVPN server and client files automatically.
	5.	Sets up optional Smart Pinger and restart cron jobs.

⸻

📜 License

MIT License

⸻

Note:
This project is designed to improve privacy and help bypass network restrictions.
It must be used only in compliance with your local laws.
