import sys, os.path, argparse
from scapy.all import *

def parse_args():
	parser = argparse.ArgumentParser()
	parser.add_argument('--o', metavar='output_path', dest='output_path', help='specify path of output *.pcap file', default='out_pkts.pcap',  required=False)
	parser.add_argument('input_path', metavar='input_path',  help='specify path of input file traffic dump')
	args = parser.parse_args()
	return(args)

def wr_dump(in_txt, out_pcap):
	text_dump = open(in_txt, 'r')
	for i in text_dump:
		hex_str = i.split('\n')[0]
		hex_str = hex_str.replace('\r', '')
		current_packet = Ether(hex_bytes(hex_str))
		wrpcap(out_pcap, current_packet, append=True)

if __name__ == '__main__':
	args = parse_args()
	wr_dump(args.input_path, args.output_path)