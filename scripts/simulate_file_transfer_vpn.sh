#!/bin/bash

CONFIG="vpnbook_configs/vpnbook-us16-tcp80.ovpn"
PCAP_FILE="vpn_file_transfer_$(date +%Y%m%d_%H%M%S).pcap"
USERNAME="vpnbook"
DOWNLOAD_URL="http://ipv4.download.thinkbroadband.com/100MB.zip"

echo "[INFO] 🔐 Enter VPNBook password (from https://vpnbook.com/freevpn):"
read -s PASSWORD

# Create temporary credentials file
CRED_FILE=$(mktemp)
echo -e "$USERNAME\n$PASSWORD" > "$CRED_FILE"

# Start VPN in the background
echo "[INFO] 🌐 Connecting to VPN..."
sudo openvpn --config "$CONFIG" --auth-user-pass "$CRED_FILE" --daemon

# Wait for VPN tunnel to appear (e.g., tun0, tun1, etc.)
echo "[INFO] ⏳ Waiting for VPN interface (tunX)..."
for i in {1..10}; do
    TUN_IFACE=$(ip a | grep -o "tun[0-9]" | head -n 1)
    if [[ -n "$TUN_IFACE" ]]; then
        echo "[INFO] ✅ Detected interface: $TUN_IFACE"
        break
    fi
    sleep 5
done

if [[ -z "$TUN_IFACE" ]]; then
    echo "[ERROR] ❌ VPN not established. Exiting."
    sudo killall openvpn
    rm "$CRED_FILE"
    exit 1
fi

# Start tcpdump on VPN tunnel interface
echo "[INFO] 📡 Capturing traffic on $TUN_IFACE to $PCAP_FILE..."
sudo tcpdump -i "$TUN_IFACE" -w "$PCAP_FILE" &
TCPDUMP_PID=$!

sleep 2  # let tcpdump initialize

# Perform the file download
echo "[INFO] ⬇️ Downloading test file over VPN..."
wget "$DOWNLOAD_URL" -O /tmp/downloaded_vpn_file.bin

# Cleanup
echo "[INFO] 🛑 Stopping packet capture and VPN..."
sudo kill "$TCPDUMP_PID"
sudo killall openvpn
rm "$CRED_FILE"

echo "[INFO] ✅ VPN file transfer PCAP saved as: $PCAP_FILE"
