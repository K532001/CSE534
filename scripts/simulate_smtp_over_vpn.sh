#!/bin/bash

# === CONFIGURATION ===
FAKESMTP_JAR="$HOME/fakesmtp.jar"
EMAIL_COUNT=500
OUTPUT_DIR="$HOME/fakesmtp_emails"
VPN_CONFIG="$1"  # Pass path to .ovpn file as the first argument

if [ -z "$VPN_CONFIG" ]; then
  echo "[ERROR] ❌ Please provide the path to a .ovpn VPN config file."
  echo "Usage: $0 /path/to/config.ovpn"
  exit 1
fi

# === STEP 1: Connect to VPN ===
echo "[INFO] 🌐 Connecting to VPN using $VPN_CONFIG..."
sudo openvpn --config "$VPN_CONFIG" --daemon
sleep 10  # Wait for connection

# === STEP 2: Detect tunX interface ===
TUN_IFACE=$(ip a | grep -o 'tun[0-9]*' | head -n 1)
if [ -z "$TUN_IFACE" ]; then
  echo "[ERROR] ❌ No tun interface found. VPN may not have connected properly."
  exit 1
fi
echo "[INFO] ✅ VPN connected on interface $TUN_IFACE"

# === STEP 3: Start FakeSMTP bound to all interfaces ===
echo "[INFO] 📨 Starting FakeSMTP on port 2525 (0.0.0.0)..."
java -jar "$FAKESMTP_JAR" --start-server --bind-address 0.0.0.0 --port 2525 --output-dir "$OUTPUT_DIR" &
FAKESMTP_PID=$!
sleep 3

# === STEP 4: Start Packet Capture ===
PCAP_FILE="smtp_traffic_20250504_162211.pcap"
echo "[INFO] 📡 Capturing SMTP traffic to $PCAP_FILE on $TUN_IFACE..."
sudo tcpdump -i "$TUN_IFACE" port 2525 -w "$PCAP_FILE" &
TCPDUMP_PID=$!
sleep 2

# === STEP 5: Send Emails ===
echo "[INFO] 📤 Sending $EMAIL_COUNT test emails with variable sizes and attachments..."
for i in $(seq 1 $EMAIL_COUNT); do
  SUBJECT="VPN Test Email $i"
  BODY_SIZE=$(( (RANDOM % 500) + 100 ))
  BODY=$(head -c $BODY_SIZE /dev/urandom | base64)

  ATTACH_SIZE=$(( (RANDOM % 2000) + 500 ))
  ATTACHMENT=$(head -c $ATTACH_SIZE /dev/urandom | base64)

  EMAIL_CONTENT="Subject: $SUBJECT\n\n$BODY\n\nAttachment:\n$ATTACHMENT"

  swaks --to test@example.com --from kunal@example.com --server 127.0.0.1:2525 --data "$EMAIL_CONTENT" > /dev/null
done

# === STEP 6: Cleanup ===
echo "[INFO] 🛑 Stopping capture and FakeSMTP..."
sleep 2
kill $TCPDUMP_PID
kill $FAKESMTP_PID

echo "[INFO] ✅ Done! PCAP: $PCAP_FILE"
echo "[INFO] 📁 Emails saved to: $OUTPUT_DIR"
