#!/bin/sh
# Redéploie les services d'identité sur la VM srv-identite (Debian 13 avec Docker)
# À lancer en root, dans le dossier qui contient sabco.ldif

# 1. Annuaire LDAP
docker run -d --name ldap --restart unless-stopped -p 389:389 \
  -e LDAP_ORGANISATION="Sabco Industries" -e LDAP_DOMAIN="sabco.local" \
  -e LDAP_ADMIN_PASSWORD="admin" osixia/openldap:1.5.0
sleep 20
docker exec -i ldap ldapadd -x -H ldap://localhost -D "cn=admin,dc=sabco,dc=local" -w admin < sabco.ldif

# 2. Keycloak (le realm, la fédération LDAP et le client se règlent ensuite dans la console, http://127.0.0.1:8080)
docker run -d --name keycloak --restart unless-stopped -p 8080:8080 \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin -e KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
  -e JAVA_OPTS_KC_HEAP="-Xms256m -Xmx768m" \
  quay.io/keycloak/keycloak:26.0.8 start-dev

# 3. FreeRADIUS relié à l'annuaire
docker run -d --name radius --restart unless-stopped -p 1812:1812/udp -p 1813:1813/udp \
  freeradius/freeradius-server:latest
cat > ldap-radius.conf << 'EOF'
ldap {
	server = '172.17.0.1'
	port = 389
	identity = 'cn=admin,dc=sabco,dc=local'
	password = admin
	base_dn = 'dc=sabco,dc=local'
	update {
		control:Cleartext-Password := 'userPassword'
	}
	user {
		base_dn = "ou=users,${..base_dn}"
		filter = "(uid=%{%{Stripped-User-Name}:-%{User-Name}})"
	}
}
EOF
docker cp ldap-radius.conf radius:/etc/freeradius/mods-available/ldap
docker exec radius ln -sf /etc/freeradius/mods-available/ldap /etc/freeradius/mods-enabled/ldap
docker exec radius sh -c "printf 'client opnsense-paris {\n\tipaddr = 192.168.56.103\n\tsecret = opnsense123\n}\n' >> /etc/freeradius/clients.conf"
docker restart radius

# Test : doit répondre Access-Accept
docker exec radius radtest alice alice123 127.0.0.1 0 testing123
