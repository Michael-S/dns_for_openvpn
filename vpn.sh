#!/bin/bash
# This script assumes client.ovpn has your VPN connection
# you have openvpn_dns_fix.lisp in the specified location,
# and you have openvpn and sbcl installed
# I've only tested it on Fedora and Ubuntu Linux.
openvpn --config client.ovpn --script-security 2 \
 --route-up "/usr/bin/sbcl --script /root/openvpn_dns_fix.lisp start" \
 --down "/usr/bin/sbcl --script /root/openvpn_dns_fix.lisp stop"

