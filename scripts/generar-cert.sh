#!/bin/sh
# Regenera el certificado autofirmado incluyendo la IP/hostname con que se accede.
# Uso: ./scripts/generar-cert.sh 192.168.56.10 [otro-host ...]
cd "$(dirname "$0")/.." || exit 1
SAN="DNS:localhost,IP:127.0.0.1"
for h in "$@"; do
  case "$h" in
    *[!0-9.]*) SAN="$SAN,DNS:$h" ;;
    *)         SAN="$SAN,IP:$h" ;;
  esac
done
openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
  -keyout certs/sigeru.key -out certs/sigeru.crt \
  -subj "/CN=localhost" -addext "subjectAltName=$SAN"
chmod 644 certs/sigeru.key
echo "Certificado generado con SAN: $SAN"
echo "Reconstrui el gateway: docker compose up -d --build gateway"
