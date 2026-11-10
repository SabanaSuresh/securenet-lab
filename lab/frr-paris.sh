#!/bin/sh
# Routeur de Paris (FRR-1) : VLAN, liaison vers Lyon, OSPF
# Prérequis fait une seule fois : ospfd=yes dans /etc/frr/daemons
ip link set eth0 up
ip link add link eth0 name eth0.10 type vlan id 10
ip addr add 10.1.10.1/24 dev eth0.10
ip link set eth0.10 up
ip link add link eth0 name eth0.20 type vlan id 20
ip addr add 10.1.20.1/24 dev eth0.20
ip link set eth0.20 up
ip link add link eth0 name eth0.30 type vlan id 30
ip addr add 10.1.30.1/24 dev eth0.30
ip link set eth0.30 up
ip link add link eth0 name eth0.99 type vlan id 99
ip addr add 10.1.99.1/24 dev eth0.99
ip link set eth0.99 up
ip addr add 10.255.0.1/30 dev eth1
ip link set eth1 up
# Attendre que zebra soit démarré
until ps | grep -q "[/]usr/lib/frr/zebra"; do sleep 5; done
vtysh <<'FIN'
configure terminal
router ospf
ospf router-id 1.1.1.1
network 10.1.10.0/24 area 0
network 10.1.20.0/24 area 0
network 10.1.30.0/24 area 0
network 10.1.99.0/24 area 0
network 10.255.0.0/30 area 0
passive-interface eth0.10
passive-interface eth0.20
passive-interface eth0.30
passive-interface eth0.99
end
FIN
