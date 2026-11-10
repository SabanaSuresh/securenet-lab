#!/bin/sh
# Routeur de Lyon (FRR-2) : VLAN, liaison vers Paris, OSPF
# Prérequis fait une seule fois : ospfd=yes dans /etc/frr/daemons
ip link set eth0 up
ip link add link eth0 name eth0.10 type vlan id 10
ip addr add 10.2.10.1/24 dev eth0.10
ip link set eth0.10 up
ip link add link eth0 name eth0.99 type vlan id 99
ip addr add 10.2.99.1/24 dev eth0.99
ip link set eth0.99 up
ip addr add 10.255.0.2/30 dev eth1
ip link set eth1 up
# Attendre que zebra soit démarré
until ps | grep -q "[/]usr/lib/frr/zebra"; do sleep 5; done
vtysh <<'FIN'
configure terminal
router ospf
ospf router-id 2.2.2.2
network 10.2.10.0/24 area 0
network 10.2.99.0/24 area 0
network 10.255.0.0/30 area 0
passive-interface eth0.10
passive-interface eth0.99
end
FIN
# DHCP et DNS du site de Lyon (nécessite : apk add dnsmasq, une seule fois)
killall dnsmasq 2>/dev/null
cat > /etc/dnsmasq.conf <<'CONF'
interface=eth0.10
bind-interfaces
domain=sabco.local
local=/sabco.local/
dhcp-range=10.2.10.100,10.2.10.200,255.255.255.0,12h
dhcp-option=option:router,10.2.10.1
dhcp-option=option:dns-server,10.2.10.1
dhcp-leasefile=/tmp/dnsmasq.leases
address=/routeur-lyon.sabco.local/10.2.10.1
CONF
dnsmasq -C /etc/dnsmasq.conf
