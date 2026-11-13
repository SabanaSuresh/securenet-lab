# Partie 3 : pare-feu, NAT, DMZ et VPN

## Ce qui est en place
- Un pare-feu OPNsense par site (fw-paris et fw-lyon), placé entre le routeur FRR et le réseau « Internet » (203.0.113.0/29).
- Un tunnel WireGuard entre les deux pare-feu (10.255.0.0/30, port UDP 51820). Il transporte le trafic Paris-Lyon (10.1.0.0/16 et 10.2.0.0/16).
- Le NAT remplace l'adresse interne par celle du pare-feu à la sortie : 203.0.113.1 pour Paris, 203.0.113.2 pour Lyon.
- La DMZ est le VLAN 30 (10.1.30.0/24), portée par fw-paris (10.1.30.1).

## Règles sur l'interface FRR de Paris (dans l'ordre)
| N° | Action | Source | Destination | Rôle |
|---|---|---|---|---|
| 1 | Pass | 10.0.1.0/30 | tout | lien entre le routeur et le pare-feu |
| 2 | Pass | 10.1.99.0/24 | tout | administration |
| 3 | Pass TCP 80 | 10.1.10.0/24 | 10.1.30.0/24 | postes vers la DMZ en HTTP |
| 4 | Pass TCP 443 | 10.1.10.0/24 | 10.1.30.0/24 | postes vers la DMZ en HTTPS |
| 5 | Pass | 10.1.10.0/24 | 10.1.20.0/24 | postes vers serveurs |
| 6 | Block | 10.1.0.0/16 | 10.1.0.0/16 | tout autre passage entre VLAN |
| 7 | Pass | 10.1.0.0/16 | tout | sortie vers Internet et Lyon |

## Règles sur l'interface FRR de Lyon (dans l'ordre)
| N° | Action | Source | Destination | Rôle |
|---|---|---|---|---|
| 1 | Pass | 10.0.2.0/30 | tout | lien entre le routeur et le pare-feu |
| 2 | Pass | 10.2.99.0/24 | tout | administration |
| 3 | Block | 10.2.0.0/16 | 10.2.0.0/16 | blocage entre VLAN |
| 4 | Pass | 10.2.0.0/16 | tout | sortie vers Internet et Paris |

## Règles de la DMZ (fw-paris)
1. Block : DMZ vers 10.0.0.0/8 (la DMZ ne peut pas atteindre le réseau interne).
2. Pass : DMZ vers tout (la DMZ peut sortir vers Internet).

## Tests réalisés
| Test | Résultat |
|---|---|
| Poste de Paris vers Lyon, par le tunnel | réussi |
| Poste de Paris vers Internet | réussi, source vue côté Lyon : 203.0.113.1 (NAT) |
| Poste de Paris vers la DMZ en ping | bloqué (seul le web est autorisé) |
| Poste de Lyon vers Paris, par le tunnel | réussi |
| Poste de Lyon vers Internet | réussi avec le NAT de Lyon |

## Ce que j'ai retenu
- Une interface OPNsense autre que le LAN bloque tout ce qui entre, tant qu'aucune règle ne l'autorise.
- L'ordre des règles compte : la première qui correspond s'applique.
- Un câble réseau virtuel décoché dans VirtualBox se voit par une prise rouge dans Interfaces, Assignments.
