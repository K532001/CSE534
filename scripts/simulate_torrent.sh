#!/bin/bash

# File: simulate_torrent.sh
# Location: ~/pcap_dataset

TORRENT_FILE=~/torrent_simulation/archlinux.torrent
OUTPUT_DIR=/tmp
DURATION=300  # Capture for 5 minutes

timestamp=$(date +%Y%m%d_%H%M%S)
PCAP_NAME="torrent_traffic_${timestamp}.pcap"
LOG_NAME="torrent_log_${timestamp}.log"

echo "[INFO] 📡 Starting tcpdump on eth0..."
sudo timeout ${DURATION}s tcpdump -i eth0 -w "${PCAP_NAME}" &
TCPDUMP_PID=$!

sleep 2  # Ensure tcpdump is ready

echo "[INFO] 🧲 Launching torrent download for ${DURATION}s..."
transmission-cli "$TORRENT_FILE" -w "$OUTPUT_DIR" > "$LOG_NAME" 2>&1 &

TRANSMISSION_PID=$!
sleep ${DURATION}

echo "[INFO] ⏹ Stopping transmission and tcpdump..."
kill $TRANSMISSION_PID 2>/dev/null
sudo kill $TCPDUMP_PID 2>/dev/null

echo "[INFO] ✅ Torrent traffic PCAP saved as: ${PCAP_NAME}"
echo "[INFO] 📝 Torrent log saved as: ${LOG_NAME}"
