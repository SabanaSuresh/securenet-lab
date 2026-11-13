# FRR-1 (Paris) : à taper après chaque démarrage du routeur
ip addr add 10.0.1.2/30 dev eth2
ip link set eth2 up
ip route add default via 10.0.1.1
ip link add link eth0 name eth0.10 type vlan id 10
ip addr add 10.1.10.1/24 dev eth0.10
ip link set eth0.10 up
