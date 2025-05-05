from pathlib import Path

from scapy.layers.dns import DNS
from scapy.layers.inet import TCP
from scapy.packet import Padding
from scapy.utils import PcapReader


PREFIX_TO_TRAFFIC_ID = {
    # Chat
    "telegram_chat": 0,
   
    # Email
    "email1a": 1,
  
    "sftp1": 2,
   
    "youtube1": 3,
 
    # VoIP
    "whatsapp_audio": 4,
   
    # VPN: Chat
    "vpn_telegram_chat": 5,
   
    "vpn_sftp_a": 6,
   
    # VPN VoIP
    "vpn_whatsapp_audio": 7,
   
    "vpn_youtube_a": 8,
}

ID_TO_TRAFFIC = {
    0: "Chat",
    1: "Email",
    2: "File Transfer",
    3: "Streaming",
    4: "Voip",
    5: "VPN: Chat",
    6: "VPN: File Transfer",
    7: "VPN: Voip",
    8: "VPN: Streaming",
}


def read_pcap(path: Path):
    packets = PcapReader(str(path))

    return packets


def should_omit_packet(packet):
    # SYN, ACK or FIN flags set to 1 and no payload
    if TCP in packet and (packet.flags & 0x13):
        # not payload or contains only padding
        layers = packet[TCP].payload.layers()
        if not layers or (Padding in layers and len(layers) == 1):
            return True

    # DNS segment
    if DNS in packet:
        return True

    return False
