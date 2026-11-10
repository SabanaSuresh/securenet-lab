# Dossier d'architecture – SecureNet Lab

Ce projet consiste à monter en laboratoire le réseau d'une entreprise fictive à deux sites, à le sécuriser, puis à tester sa sécurité en simulant des attaques et à corriger les failles trouvées.

## 1. Présentation de l'entreprise

Sabco Industries est une PME industrielle fictive d'environ 150 salariés, répartis sur deux sites :

- **Site A – Siège (Paris)** : environ 100 personnes. On y trouve le service informatique, les serveurs internes, la zone exposée à Internet (DMZ) et la sortie Internet de l'entreprise.
- **Site B – Agence (Lyon)** : environ 50 personnes, reliée au siège par un VPN site à site.

## 2. Besoins

| Réf. | Besoin | Type |
|---|---|---|
| B1 | Les deux sites partagent les mêmes outils et fichiers, comme s'ils étaient sur un même réseau | Métier |
| B2 | Le site vitrine de l'entreprise est accessible depuis Internet | Métier |
| B3 | Les salariés en télétravail accèdent aux ressources internes de façon sécurisée | Métier |
| B4 | Les postes, les serveurs internes et le serveur exposé à Internet sont séparés | Sécurité |
| B5 | Chaque salarié a un seul compte pour accéder aux applications (SSO), avec un second facteur sur les accès sensibles | Sécurité |
| B6 | Seules les personnes autorisées administrent le pare-feu et les équipements réseau | Sécurité |
| B7 | Les équipements sont surveillés et les événements de sécurité sont enregistrés | Sécurité |
| B8 | Une panne ou une attaque est repérée rapidement | Exploitation |
| B9 | L'infrastructure peut être redéployée à l'identique | Exploitation |

## 3. Architecture réseau

![Schéma réseau logique](schema-reseau-sabco.png)

Le schéma source est disponible dans [schema-reseau-sabco.drawio](schema-reseau-sabco.drawio).

- Chaque site a son **pare-feu** (OPNsense), qui sert de point d'entrée et de sortie du réseau.
- Un **tunnel VPN site à site** chiffré relie les deux pare-feu.
- Derrière chaque pare-feu, un **routeur** (FRRouting) échange les routes entre les sites avec le protocole OSPF.
- Chaque type de machine est placé dans son propre **VLAN** :

| VLAN | Zone | Contenu |
|---|---|---|
| 10 | Postes | Ordinateurs des salariés |
| 20 | Serveurs | Annuaire, SSO, supervision (siège uniquement) |
| 30 | DMZ | Site vitrine exposé à Internet (siège uniquement) |
| 99 | Administration | Administration des équipements réseau |

Le site B ne contient que les VLAN 10 et 99 : les serveurs et la DMZ sont centralisés à Paris.

Le choix de l'équipement qui filtre les échanges entre VLAN sera précisé lors de la mise en place du pare-feu.

## 4. Plan d'adressage

On utilise la plage privée `10.0.0.0/8`. Les adresses suivent la règle `10.site.VLAN.machine` : le deuxième nombre indique le site (1 = Paris, 2 = Lyon) et le troisième le numéro de VLAN. Exemple : `10.1.20.15` est un serveur (VLAN 20) du siège.

**Réseaux des sites**

| Zone | Site | Réseau | Passerelle |
|---|---|---|---|
| Postes | A (Paris) | 10.1.10.0/24 | 10.1.10.1 |
| Serveurs | A | 10.1.20.0/24 | 10.1.20.1 |
| DMZ | A | 10.1.30.0/24 | 10.1.30.1 |
| Administration | A | 10.1.99.0/24 | 10.1.99.1 |
| Postes | B (Lyon) | 10.2.10.0/24 | 10.2.10.1 |
| Administration | B | 10.2.99.0/24 | 10.2.99.1 |

**Liens entre équipements**

| Lien | Réseau |
|---|---|
| Pare-feu A ↔ Routeur A | 10.0.1.0/30 |
| Pare-feu B ↔ Routeur B | 10.0.2.0/30 |
| Tunnel VPN (A ↔ B) | 10.255.0.0/30 |
| Internet (A ↔ B) | 203.0.113.0/29 |

La plage `203.0.113.0/24` est réservée par les normes à la documentation : elle ne risque pas d'entrer en conflit avec un vrai réseau et joue le rôle des adresses publiques.
