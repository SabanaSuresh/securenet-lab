# Partie 4 : identité et accès

Dans cette partie, j'ai mis en place les comptes de Sabco et la façon de s'y connecter. Un seul annuaire contient les utilisateurs, et le reste (le SSO, le pare-feu) vérifie les mots de passe à partir de lui.

Tout tourne sur une petite VM Debian, `srv-identite`, avec trois conteneurs Docker : OpenLDAP pour l'annuaire, Keycloak pour le SSO et FreeRADIUS pour RADIUS. Cette VM est reliée au pare-feu de Paris par un réseau privé (192.168.56.10 côté serveur, 192.168.56.103 côté pare-feu).

**L'annuaire.** Le domaine est `sabco.local`. J'ai créé deux comptes de test : alice, dans le groupe compta, et bruno, dans le groupe it. Les données sont dans `lab/sabco.ldif`.

**Le SSO.** Dans Keycloak, j'ai créé le realm `sabco` et je l'ai relié à l'annuaire en lecture seule : Keycloak lit les comptes, mais ne les modifie pas. J'ai ajouté une application de test, `app-compta`, et j'ai vérifié que le jeton d'alice contient bien son groupe, compta.

**RADIUS.** FreeRADIUS lit le mot de passe dans l'annuaire. Avec le bon mot de passe il répond Access-Accept, avec un mauvais il répond Access-Reject. J'ai déclaré le pare-feu OPNsense comme client, avec un secret partagé.

**Le pare-feu.** Dans OPNsense, j'ai ajouté RADIUS comme serveur d'authentification. Le compte bruno existe dans le groupe admins, mais son mot de passe est vérifié par RADIUS. Je me suis connectée à l'interface web avec bruno. Le compte root reste disponible en secours.

**Ce que je corrigerai ensuite.** Les mots de passe de test sont simples et stockés en clair dans l'annuaire. Keycloak et RADIUS ne sont pas chiffrés. Il n'y a pas encore de double authentification. Et le serveur n'est pas encore dans le VLAN 20.
