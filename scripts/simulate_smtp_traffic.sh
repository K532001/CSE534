#!/bin/bash

FAKESMTP_JAR="$HOME/fakesmtp.jar"  # ✅ Correct updated path
EMAIL_COUNT=500
OUTPUT_DIR="$HOME/fakesmtp_emails"
PCAP_FILE="smtp_traffic_$(date +%Y%m%d_%H%M%S).pcap"

echo "[INFO] 📨 Starting FakeSMTP on port 2525..."
java -jar "$FAKESMTP_JAR" --start-server --port 2525 --output-dir "$OUTPUT_DIR" &
FAKESMTP_PID=$!

sleep 3  # allow server to fully initialize

echo "[INFO] 📡 Capturing SMTP traffic to $PCAP_FILE..."
sudo tcpdump -i lo port 2525 -w "$PCAP_FILE" &
TCPDUMP_PID=$!

sleep 2  # ensure tcpdump is ready

echo "[INFO] 📤 Sending $EMAIL_COUNT test emails with variable body + attachment sizes..."
for i in $(seq 1 "$EMAIL_COUNT"); do
  SUBJECT="Test Email $i"
  BODY_SIZE=$(( (RANDOM % 500) + 100 ))
  BODY=$(head -c "$BODY_SIZE" /dev/urandom | base64)

  ATTACH_SIZE=$(( (RANDOM % 2000) + 500 ))
  ATTACHMENT=$(head -c "$ATTACH_SIZE" /dev/urandom | base64)

  EMAIL_CONTENT="Subject: $SUBJECT\n\n$BODY\n\nAttachment:\n$ATTACHMENT"

  swaks --to test@example.com --from kunal@example.com --server localhost:2525 --data "$EMAIL_CONTENT" > /dev/null
done

echo "[INFO] 🛑 Stopping capture and server..."
sleep 3
kill "$TCPDUMP_PID"
kill "$FAKESMTP_PID"

echo "[INFO] ✅ Done! PCAP: $PCAP_FILE"
echo "[INFO] 📁 Emails saved to: $OUTPUT_DIR"

