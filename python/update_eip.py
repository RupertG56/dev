#!/usr/bin/env python3

## export REQUESTS_CA_BUNDLE=/etc/pki/tls/certs/ca-bundle.crt

## pip install --upgrade pip
## pip install requests ipaddress

import os
import sys
import json
import requests
import ipaddress

from pathlib import Path

CF_API_BASE = "https://api.cloudflare.com/client/v4"
CF_API_TOKEN = os.environ["CF_API_TOKEN"]



def cf_get(cf_token, suffix, params):
    headers = {
        "Authorization": f"Bearer {cf_token}",
        "Content-Type": "application/json"
    }

    url = CF_API_BASE + "/" + suffix
    r = requests.get(url, headers=headers, params=params)
    r.raise_for_status()
    return r.json()


def cf_put(cf_token, suffix, payload):
    headers = {
        "Authorization": f"Bearer {cf_token}",
        "Content-Type": "application/json"
    }

    url = CF_API_BASE + "/" + suffix
    r = requests.put(url, headers=headers, json=payload)
    r.raise_for_status()
    return json.loads(r.content)


def main():
    ip_version=sys.argv[1]
    domain=sys.argv[2]
    ip=sys.argv[3]
    if ip_version == "IPV4":
        ipaddress.IPv4Address(ip)
    elif ip_version == "IPV6":
        ipaddress.IPv6Address(ip)

    print(f"{ip_version} {domain} {ip}")

    cf_token = CF_API_TOKEN

    base_domain = ".".join(domain.split(".")[-2:])
    zone = cf_get(cf_token, "zones", {"name": base_domain})["result"][0]
    name_servers = " ".join(["@"+v for v in zone["name_servers"]])
    print(f"dig +short {name_servers} {domain}")
    zone_id = zone["id"]
    record_type = "A" if ip_version == "IPV4" else "AAAA"
    record = cf_get(cf_token, f"zones/{zone_id}/dns_records", {"type": record_type, "name": domain})["result"][0]

    if record["content"] != ip:
        record_id = record["id"]
        print(f"eip has changed old: {record['content']}, new: {ip}")
        suffix = f"zones/{zone_id}/dns_records/{record_id}"
        params = {"type": record_type, "name": domain, "content": ip, "ttl": 1, "proxied": False}
        view = cf_put(cf_token, suffix, params)

        print(f"new eip: {ip}")
    else:
        print(f"eip is correct: {ip}")


if __name__ == "__main__":
    main()


