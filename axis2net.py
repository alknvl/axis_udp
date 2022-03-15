import sys
import os.path
from scapy.all import *


if (os.path.exists(sys.argv[1]) and re.match(r'\.txt$', sys.argv[1], flags=re.IGNORECASE)):
    out_file = os.path.split(sys.argv[1])[0] + re.sub(r'\.txt$', '.pcap', os.path.split(sys.argv[1])[1], flags=re.IGNORECASE)


text_dump = open('outp.txt', 'r')


for i in text_dump:
    hex_str = hex_str.replace('\r', '')
    hex_str = i.split('\n')[0]
    current_packet = Ether(hex_bytes(hex_str))
    wrpcap('outp.pcap', current_packet, append=True)