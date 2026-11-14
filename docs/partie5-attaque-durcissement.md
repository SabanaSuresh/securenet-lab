# Partie 5 : attaque et durcissement

## Objectif
Se mettre dans la peau d'un attaquant ayant accès au réseau de Sabco Industries, pour vérifier que les éléments mis en place dans les parties précédentes (pare-feu, identité) résistent à des attaques simples, et corriger ce qui ne résiste pas.

## Démarche
J'ai installé une machine Kali Linux dans le lab, positionnée sur le réseau 192.168.56.0/24 (celui de l'interface d'administration d'OPNsense et de srv-identite-paris), avec une adresse fixe 192.168.56.20/24. Une reconnaissance avec nmap sur ce réseau a confirmé les services déjà connus : SSH, LDAP, Keycloak sur le port 8080, RADIUS.

## Faille 1 : mot de passe par défaut sur le pare-feu
L'interface d'administration d'OPNsense (192.168.56.103) acceptait encore les identifiants par défaut root / opnsense, jamais changés depuis l'installation. N'importe qui ayant accès à ce réseau aurait pu prendre le contrôle du pare-feu.

## Faille 2 : identifiants Keycloak transmis en clair
La console Keycloak tourne en HTTP, sans chiffrement. En capturant le trafic avec tcpdump pendant une connexion de l'utilisatrice alice, le mot de passe apparaît directement en clair dans la requête (username=alice&password=alice123). N'importe qui sur le même réseau peut récupérer un mot de passe valide au moment de la connexion.

## Faille 3 : interception réseau par ARP spoofing
Avec l'outil arpspoof, je me suis positionnée entre OPNsense-Paris et srv-identite-paris, en empoisonnant les tables ARP des deux machines : chacune croyait parler à l'autre alors qu'elle parlait en réalité à Kali. La table ARP de srv-identite-paris le confirme, avec l'adresse de 192.168.56.103 associée à l'adresse MAC de Kali. Depuis cette position, j'ai capturé un échange RADIUS complet (Access-Request puis Access-Accept) déclenché par un test d'authentification lancé depuis OPNsense, alors que cet échange devrait normalement rester direct entre les deux machines. Le mot de passe RADIUS reste masqué par le secret partagé, donc il n'est pas lisible directement, mais l'attaque montre qu'un attaquant positionné sur ce segment réseau peut intercepter, et potentiellement perturber, les échanges d'authentification entre le pare-feu et le serveur d'identité. Rien n'empêchait cette attaque : pas de protection anti-ARP spoofing, pas de 802.1X sur le réseau filaire.

## Durcissement
Le mot de passe root d'OPNsense a été changé immédiatement après la découverte de la faille 1. Pour les failles 2 et 3, la correction n'a pas été appliquée dans le lab faute de temps, mais les mesures recommandées sont : passer Keycloak en HTTPS avec un certificat, même auto-signé en interne, et rediriger systématiquement le port 8080 vers HTTPS ; activer une protection anti-ARP spoofing sur les switchs réels (Dynamic ARP Inspection, DHCP Snooping) ou généraliser à terme le 802.1X, déjà écarté en partie 4 faute de pouvoir le simuler facilement en virtuel, mais pertinent en production.
