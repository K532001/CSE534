# Deep‑Learning‑Based VPN & Non‑VPN Network Traffic Classification  
### Re‑implementing and Extending **Deep Packet**

> **Course**: CSE 534 — Network Security & Applied ML  
> **Institution**: Stony Brook University  
> **Author**: Kunal Garg, Kanav Talwar, Anshul Deshmukh
> **Date**: May 2025  

---

## 1&nbsp;&nbsp;Overview

Deep Packet (Lotfollahi *et al.*, 2019) introduced a purely data‑driven, end‑to‑end deep‑learning pipeline that classifies network traffic directly from raw packets.  
While most follow‑up work tunes architectures or loss functions, *our* focus is **dataset realism**: we capture and label fresh traffic across nine application classes, each recorded **with and without VPN encapsulation**.  
We then re‑implement Deep Packet from scratch, train on the new data, and analyse performance gaps—especially on encrypted flows.

---

## 2&nbsp;&nbsp;Project Goals

* **G‑1** Build a balanced, labelled dataset of real network traces (VPN & plain).  
* **G‑2** Re‑code Deep Packet’s CNN architecture in PyTorch and train from scratch.  
* **G‑3** Quantitatively compare class‑wise performance and confusion patterns.  
* **G‑4** Highlight challenges unique to VPN traffic and propose mitigation ideas.

---

## 3&nbsp;&nbsp;Dataset Construction

| Traffic Type | Tooling & Scripts | Key Variations | VPN Capture? |
|--------------|------------------|----------------|--------------|
| **Browsing** | `simulate_browsing.sh` (`curl`/`wget`) | Randomised site list | ✅ |
| **Email (SMTP)** | `simulate_email.sh` (`swaks` + FakeSMTP) | 500 + mails, random subjects & attachments | ✅ |
| **File Transfer** | `simulate_file_dl.sh` (`wget`) | 100 MB test blobs | ✅ |
| **Torrent** | `simulate_torrent.sh` (`transmission-cli`) | 5 min peer exchange | – |
| **VoIP** | `simulate_voip.sh` (SIP + RTP) | Short calls, dynamic ports | ✅ |
| **Chat** | `simulate_chat.sh` (XMPP/IRC + Slack‑like HTTPS) | Bursty text sessions | ✅ |
| **Streaming** | `simulate_streaming.sh` (YouTube/Twitch) | Variable bitrate & buffering | ✅ |

**Capture protocol**

```bash
# generic pattern inside each script
sudo tcpdump -i <iface> -w "pcaps/<label>_$(date +%s).pcap" &
TCPDUMP_PID=$!
<simulate traffic>
sudo kill $TCPDUMP_PID
```
## 📂 PCAP Dataset Access

[Click here to access the full PCAP dataset](https://drive.google.com/drive/folders/1zzQViHs5SzAYK_nfCxWjaI6-jUvZx0ka?usp=drive_link)

