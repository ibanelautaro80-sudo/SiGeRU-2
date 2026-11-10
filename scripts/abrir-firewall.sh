#!/bin/sh
# Abre los puertos del proyecto en firewalld (RHEL).
cd "$(dirname "$0")/.." || exit 1
H=$(grep -E '^HTTP_PORT=' .env 2>/dev/null | cut -d= -f2); H=${H:-8080}
S=$(grep -E '^HTTPS_PORT=' .env 2>/dev/null | cut -d= -f2); S=${S:-8443}
if ! systemctl is-active --quiet firewalld; then echo "firewalld no esta activo, nada que abrir."; exit 0; fi
sudo firewall-cmd --permanent --add-port=$H/tcp --add-port=$S/tcp
sudo firewall-cmd --reload
echo "Puertos $H y $S abiertos."
