#  -> source .venv/bin/activate
from requests import get as get_request

from scapy.all import rdpcap
from collections import defaultdict

from typing import Iterator

from glob import glob
from os import path

# Path to your .pcap
PATH_DUMPS: str = '/root/dumps'

# Threshold for flagging an IP as potentially part of a DDoS attack
THRESHOLD: int = 100  # Adjust this based on your specific needs

# IP of the server where the script is located
LOCALIP: str = '45.88.228.55'

# API used to do the localization
IPAPIG: str = 'https://freegeoip.app/json/'


def get_latest_file(folder_path):
    list_of_files = glob(path.join(folder_path, '*'))

    if not list_of_files:
        return None

    # Get the most recently modified file
    latest_file = max(list_of_files, key=path.getmtime)
    return latest_file


def get_geolocation(ip) -> tuple[str, str]:
    try:
        response = get_request(IPAPIG + ip)

        if response.status_code == 200:
            data = response.json()

            country = data.get('country_name', 'Unknown')
            city = data.get('city', 'Unknown')

            return country, city

    except Exception as e:
        print(f"Error getting geolocation for IP {ip}: {e}")

    return 'Unknown', 'Unknown'


def potential_ddos_ips() -> Iterator:
    try:  # Read the .pcap file
        latest_pcapf = get_latest_file(PATH_DUMPS)
        packets = rdpcap(latest_pcapf)

    except AttributeError:
        raise AttributeError('Empty dumps folder, or unable to access the files')

    # Dictionary to store the number of requests per IP
    ip_count = defaultdict(int)

    packet_item: str = 'IP'

    # Process each packet in the .pcap file
    packets_ips = (packet for packet in packets if packet.haslayer(packet_item))

    for packip in packets_ips:
        ip = packip[packet_item].src
        ip_count[ip] += 1

    # Identify IPs that exceed the request threshold
    return (ip for ip, count in
        ip_count.items() if count > THRESHOLD)


def main(ddos_ips) -> None:
    try: is_localIp = next(ddos_ips)
    except StopIteration: is_localIp = None

    if not ddos_ips or is_localIp is None or is_localIp == LOCALIP:
        print(":Proxied| No source IP found")

        return

    if type(is_localIp) != str:
        validate_ips = (ip for ip in ddos_ips if ip != LOCALIP)
    else:
        validate_ips = {is_localIp}

    [print("Location: {1}_{2} | {0}".format(ip, *get_geolocation(ip)))
     for ip in validate_ips]


if "__main__" == __name__:
    ddos_ips = potential_ddos_ips()
    main(ddos_ips)
