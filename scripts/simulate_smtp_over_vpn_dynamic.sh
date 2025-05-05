#!/bin/bash

# --- CONFIGURATION ---
FAKESMTP_JAR="$HOME/fakesmtp.jar"                   # Path to your FakeSMTP jar file
EMAIL_COUNT=500                                      # Number of emails to send
OUTPUT_DIR="$HOME/fakesmtp_emails"                   # Where the FakeSMTP server will save emails
VPN_CONFIG="$HOME/pcap_dataset/vpnbook_configs/vpnbook-us16-tcp443.ovpn"  # Default VPN config (adjust path as needed)
VPN_USER="vpnbook"                                   # Typically "vpnbook" for VPNBook

# --- Prompt for VPN password ---
read -s -p "Enter VPNBook Password: " VPN_PASS
echo

# --- Generate a timestamped PCAP filename ---
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PCAP_FILE="smtp_traffic_vpn_${TIMESTAMP}.pcap"

# --- STEP 1: Connect to VPN ---
echo "[INFO] 🌐 Connecting to VPN using: $VPN_CONFIG"
sudo openvpn --config "$VPN_CONFIG" --auth-user-pass <(echo -e "${VPN_USER}\n${VPN_PASS}") --daemon > /dev/null 2>&1
echo "[INFO] Waiting 10 seconds for VPN to establish..."
sleep 10

# --- Note: SMTP traffic (FakeSMTP and swaks) communicates locally ---
# So even with VPN active, we'll capture on the loopback interface (lo)

# --- STEP 2: Start FakeSMTP (bound to all interfaces) ---
echo "[INFO] 📨 Starting FakeSMTP on port 2525..."
java -jar "$FAKESMTP_JAR" --start-server --bind-address 0.0.0.0 --port 2525 --output-dir "$OUTPUT_DIR" > /dev/null 2>&1 &
FAKESMTP_PID=$!
sleep 3

# --- STEP 3: Start Packet Capture on lo (local loopback) ---
echo "[INFO] 📡 Capturing SMTP traffic on lo to $PCAP_FILE..."
sudo tcpdump -i lo port 2525 -w "$PCAP_FILE" > /dev/null 2>&1 &
TCPDUMP_PID=$!
sleep 2

# --- STEP 4: Send Emails via swaks ---
echo "[INFO] 📤 Sending $EMAIL_COUNT test emails with variable body sizes and attachments..."
for i in $(seq 1 "$EMAIL_COUNT"); do
  SUBJECT="VPN Test Email $i"
  BODY_SIZE=$(( (RANDOM % 500) + 100 ))
  ATTACH_SIZE=$(( (RANDOM % 2000) + 500 ))
  BODY=$(head -c "$BODY_SIZE" /dev/urandom | base64)
  ATTACHMENT=$(head -c "$ATTACH_SIZE" /dev/urandom | base64)
  
  EMAIL_CONTENT="Subject: $SUBJECT\n\n$BODY\n\nAttachment:\n$ATTACHMENT"
  swaks --to test@example.com --from kunal@example.com --server localhost:2525 --data "$EMAIL_CONTENT" > /dev/null
done

# --- STEP 5: Cleanup ---
echo "[INFO] 🛑 Stopping packet capture and FakeSMTP..."
sleep 3
sudo kill "$TCPDUMP_PID"
kill "$FAKESMTP_PID"

# Disconnect VPN
sudo killall openvpn

echo "[INFO] ✅ Done! PCAP saved as: $PCAP_FILE"
echo "[INFO] 📁 Emails saved to: $OUTPUT_DIR"
