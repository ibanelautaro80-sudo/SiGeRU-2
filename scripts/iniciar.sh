#!/bin/sh
# Prepara .env (si no existe), levanta todo y verifica. Uso: ./scripts/iniciar.sh [--reset]
cd "$(dirname "$0")/.." || exit 1

if ! docker info >/dev/null 2>&1; then
  echo "Docker no esta corriendo o tu usuario no tiene permisos (probá con sudo o agregate al grupo docker)."; exit 1
fi

if [ ! -f .env ]; then
  echo "Creando .env con claves aleatorias..."
  cp .env.example .env
  rnd() { openssl rand -hex "$1"; }
  sed -i "s|^MYSQL_ROOT_PASSWORD=.*|MYSQL_ROOT_PASSWORD=$(rnd 12)|" .env
  sed -i "s|^MYSQL_PASSWORD=.*|MYSQL_PASSWORD=$(rnd 12)|" .env
  sed -i "s|^JWT_SECRET=.*|JWT_SECRET=$(rnd 32)|" .env
fi

if [ "$1" = "--reset" ]; then
  echo "Borrando contenedores y datos..."
  docker compose down -v --remove-orphans
fi

# El override monta el codigo local (desarrollo). Para produccion: COMPOSE_FILE=docker-compose.yml
docker compose up -d --build || exit 1

HTTP_PORT=$(grep -E '^HTTP_PORT=' .env | cut -d= -f2); HTTP_PORT=${HTTP_PORT:-8080}
echo "Esperando a las APIs..."
OK=0
for i in $(seq 1 60); do
  OK=0
  for s in usuarios gestion recoleccion; do
    c=$(curl -s -o /dev/null -w '%{http_code}' "http://localhost:$HTTP_PORT/api/$s/estado.php")
    [ "$c" = "200" ] && OK=$((OK+1))
  done
  [ "$OK" = "3" ] && break
  sleep 3
done

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ "$OK" = "3" ]; then
  echo ""
  echo "Todo OK. Usuario: admin@gmail.com / Sigeru2026!"
  echo "  En la VM:           http://localhost:$HTTP_PORT/app/login.html"
  echo "  Desde Windows:      ver README (NAT -> port forwarding) o http://$IP:$HTTP_PORT/app/login.html si hay red alcanzable"
else
  echo "Alguna API no responde. Revisá: docker compose logs --tail 50"
  exit 1
fi
