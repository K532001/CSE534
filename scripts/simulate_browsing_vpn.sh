#!/bin/bash

# === CONFIGURATION ===
CONFIG="vpnbook_configs/vpnbook-us16-tcp80.ovpn"
PCAP_FILE="vpn_browsing_$(date +%Y%m%d_%H%M%S).pcap"
USERNAME="vpnbook"

echo "[INFO] 🔐 Enter VPNBook password (copy from https://vpnbook.com/freevpn):"
read -s PASSWORD

# === Create a temporary file with VPN credentials ===
CRED_FILE=$(mktemp)
echo -e "$USERNAME\n$PASSWORD" > "$CRED_FILE"

# === Start VPN connection ===
echo "[INFO] 🌐 Connecting to VPN..."
sudo openvpn --config "$CONFIG" --auth-user-pass "$CRED_FILE" --daemon

# === Wait and detect the tunX interface ===
echo "[INFO] ⏳ Waiting for VPN tunnel to establish (tunX)..."
for i in {1..10}; do
    TUN_IFACE=$(ip a | grep -o "tun[0-9]" | head -n 1)
    if [[ -n "$TUN_IFACE" ]]; then
        echo "[INFO] ✅ Detected VPN interface: $TUN_IFACE"
        break
    fi
    sleep 5
done

if [[ -z "$TUN_IFACE" ]]; then
    echo "[ERROR] ❌ VPN tunnel not found after waiting. Exiting."
    sudo killall openvpn
    rm "$CRED_FILE"
    exit 1
fi

# === Start tcpdump ===
echo "[INFO] 📡 Starting packet capture on $TUN_IFACE..."
sudo tcpdump -i "$TUN_IFACE" -w "$PCAP_FILE" &
TCPDUMP_PID=$!

# === Run browsing simulation ===
echo "[INFO] 🧪 Simulating browsing activity over VPN..."
./simulate_browsing.sh

# === Stop capture and VPN ===
echo "[INFO] 🛑 Stopping tcpdump and VPN..."
sudo kill "$TCPDUMP_PID"
sudo killall openvpn
rm "$CRED_FILE"

# === Done ===
echo "[INFO] 🎉 VPN-browsing PCAP saved as: $PCAP_FILE"
