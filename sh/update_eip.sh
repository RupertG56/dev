#!/bin/bash

#if [ "$(id -u)" -ne 0 ]; then
#    echo "must be run as root"
#    exit 1
#fi

#EIPv4=$(ip -4 -o addr show dev wan | awk '{print $4}' | cut -d/ -f1)
EIPv4=$(dig +short -4 myip.opendns.com @resolver1.opendns.com)
STOREDv4=$(dig +short @cartman.ns.cloudflare.com @kristina.ns.cloudflare.com home.jonesclanonline.com)
STOREDv6_1=$(dig +short @cartman.ns.cloudflare.com @kristina.ns.cloudflare.com home.jonesclanonline.com AAAA)
STOREDv6_2=$(dig +short @cartman.ns.cloudflare.com @kristina.ns.cloudflare.com ipv6.jonesclanonline.com AAAA)
EIPv6=$(ip -6 -o addr show br-main)

if [[ $EIPv6 =~ ([a-f0-9]{1,4}:){7}[a-f0-9]{1,4} ]]; then
    EIPv6=${BASH_REMATCH[0]}
    
    if [ "$STOREDv6_1" != "$EIPv6" ] || [ "$STOREDv6_2" != "$EIPv6" ]; then
        #cd /etc/NetworkManager/dispatcher.d
        #. .venv/bin/activate
        export REQUESTS_CA_BUNDLE=/etc/pki/tls/certs/ca-bundle.crt
        if [ -z "$CF_API_TOKEN" ]; then
            export CF_API_TOKEN=$(sudo systemd-creds decrypt /etc/systemd/credstore/env.CF_API_TOKEN)
        fi
        ${0%/*}/update_eip.py IPV6 home.jonesclanonline.com $EIPv6
        ${0%/*}/update_eip.py IPV6 ipv6.jonesclanonline.com $EIPv6
    else
        echo "no change: $EIPv6"
    fi

fi

if [ "$STOREDv4" != "$EIPv4" ]; then
    #cd /etc/NetworkManager/dispatcher.d
    #. .venv/bin/activate
    export REQUESTS_CA_BUNDLE=/etc/pki/tls/certs/ca-bundle.crt
    if [ -z "$CF_API_TOKEN" ]; then
        export CF_API_TOKEN=$(sudo systemd-creds decrypt /etc/systemd/credstore/env.CF_API_TOKEN)1
    fi
    ${0%/*}/update_eip.py IPV4 home.jonesclanonline.com $EIPv4
else
    echo "no change: $EIPv4"
fi

