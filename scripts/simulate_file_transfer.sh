#!/bin/bash

PCAP_FILE="file_transfer_$(date +%Y%m%d_%H%M%S).pcap"
DOWNLOAD_URL="http://ipv4.download.thinkbroadband.com/100MB.zip"

echo "[INFO] 📡 Capturing traffic on eth0..."
sudo tcpdump -i eth0 -w "$PCAP_FILE" &
TCPDUMP_PID=$!

sleep 2  # allow tcpdump to initialize

echo "[INFO] ⬇️ Downloading test file from internet..."
wget "$DOWNLOAD_URL" -O /tmp/downloaded_file.bin

echo "[INFO] 🛑 Stopping packet capture..."
sudo kill "$TCPDUMP_PID"

echo "[INFO] ✅ Non-VPN file transfer PCAP saved as: $PCAP_FILE"
