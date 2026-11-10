# SiGeRU

Stack: gateway (nginx) + landing + frontend + 3 APIs PHP + MySQL 8, todo en Docker Compose.

## 1. Levantar en Linux

```bash
./scripts/instalar-docker.sh     # solo si no tenes Docker
./scripts/iniciar.sh             # crea .env con claves aleatorias, build, up y verifica
./scripts/iniciar.sh --reset     # igual, pero borrando antes la base de datos
```

Manual: `cp .env.example .env`, editar claves (`JWT_SECRET` >= 32 caracteres, `MYSQL_DATABASE=proyecto`) y `docker compose up -d --build`.

Usuario de prueba: `admin@gmail.com` / `Sigeru2026!`

## 2. Abrir desde Windows con la VM en NAT

En NAT la VM no es alcanzable desde Windows por su IP; hay que **reenviar puertos** (port forwarding).

### VirtualBox
Configuración de la VM → Red → Adaptador 1 (NAT) → Avanzado → Reenvío de puertos:

| Nombre | Protocolo | IP anfitrión | Puerto anfitrión | IP invitado | Puerto invitado |
|--------|-----------|--------------|------------------|-------------|-----------------|
| http   | TCP | 127.0.0.1 | 8080 | (IP de la VM, `hostname -I`) | 8080 |
| https  | TCP | 127.0.0.1 | 8443 | (IP de la VM) | 8443 |

Por CLI (VM apagada o con `controlvm` si está corriendo):
```
VBoxManage modifyvm "NOMBRE_VM" --natpf1 "http,tcp,127.0.0.1,8080,,8080"
VBoxManage modifyvm "NOMBRE_VM" --natpf1 "https,tcp,127.0.0.1,8443,,8443"
```
Luego en Windows: **http://localhost:8080/app/login.html**

### VMware (Workstation/Player)
Editar → Editor de red virtual → VMnet8 (NAT) → Configuración de NAT → Reenvío de puertos → Agregar: 8080 → `IP_VM:8080` y 8443 → `IP_VM:8443`.
Luego en Windows: `http://localhost:8080/app/login.html`.

### WSL2
Funciona directo: `http://localhost:8080/app/login.html`. Si no, usar la IP de `hostname -I` dentro de WSL.

### Alternativa sin tocar la VM
Cambiar el adaptador a **Puente (Bridge)** o agregar uno **Host-only** y entrar con `http://IP_VM:8080/app/login.html`.
Poné esa URL en `APP_URL` del `.env` (se usa en los links de los emails) y reiniciá: `docker compose up -d`.

## 3. Red Hat: firewall, SELinux y Docker
- `./scripts/instalar-docker.sh` instala Docker CE desde el repo oficial (RHEL/Rocky/Alma/CentOS/Fedora) y quita `podman-docker` si estaba.
- Firewall (firewalld): `./scripts/abrir-firewall.sh` (abre 8080 y 8443).
- SELinux: los volúmenes del override ya llevan `:z`, no hace falta desactivarlo. Si ves `Permission denied` en los contenedores: `ls -Z` y `sudo journalctl -t setroubleshoot`.
- Si ya usabas Podman y querés mantenerlo: `sudo dnf install podman-compose` y `podman-compose up -d --build` (menos probado).
- En Ubuntu/Debian: `sudo ufw allow 8080/tcp && sudo ufw allow 8443/tcp`.
Los puertos se publican en `0.0.0.0` (variable `BIND_IP`). Para exponer solo localmente: `BIND_IP=127.0.0.1`.

## 4. HTTPS
El certificado incluido es autofirmado para `localhost` (el navegador mostrará advertencia). Si accedés por IP/host:
```bash
./scripts/generar-cert.sh 192.168.56.10
docker compose up -d --build gateway
```
Entrá por `https://localhost:8443/app/login.html` y aceptá la advertencia.

## 5. Tests
```bash
./scripts/ejecutar-tests.sh              # los 3 servicios
./scripts/ejecutar-tests.sh usuarios     # uno solo
```

## 6. Problemas comunes
- `docker compose logs --tail 50 <servicio>` para ver errores. Servicios: `gateway api-usuarios api-gestion api-recoleccion db`.
- Cambiaste `.env` o `database.sql` y no se refleja → `./scripts/iniciar.sh --reset` (MySQL solo ejecuta el SQL con volumen vacío).
- `estado.php` devuelve 503 → revisar `JWT_SECRET` (>= 32 chars) y que la base tenga tablas.
- El mapa y los gráficos cargan Leaflet/Chart.js/OpenStreetMap desde internet: la VM/Windows necesita salida a internet.
- Producción: `COMPOSE_FILE=docker-compose.yml docker compose up -d --build` (ignora el override que monta el código local).
- Mails: `MAIL_ENABLED=true` + datos SMTP en `.env` (Gmail requiere contraseña de aplicación).
