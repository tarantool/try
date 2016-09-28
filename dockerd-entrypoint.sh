#!/bin/sh
set -e

#iptables -I FORWARD -j DROP
#iptables -t filter -A INPUT -i eth+ -j ACCEPT
#iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
#iptables -A INPUT -i docker0 -j DROP

echo 0 > /proc/sys/net/ipv4/ip_forward

exec "$@"
