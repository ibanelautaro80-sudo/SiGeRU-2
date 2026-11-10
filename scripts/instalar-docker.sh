#!/bin/sh
# Instala Docker Engine + compose en RHEL / Rocky / Alma / CentOS Stream / Fedora.
set -e
if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1 \
   && ! docker --version 2>/dev/null | grep -qi podman; then
  echo "Docker y compose ya estan instalados."; exit 0
fi

. /etc/os-release
if [ "$ID" = "fedora" ]; then REPO=fedora; else REPO=rhel; fi   # RHEL/Rocky/Alma/CentOS usan el repo "rhel"

# Podman/buildah/docker-compat chocan con docker-ce
sudo dnf remove -y podman-docker docker docker-client docker-common docker-engine 2>/dev/null || true

sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo "https://download.docker.com/linux/$REPO/docker-ce.repo"
sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
echo "Listo. Cerra sesion y volve a entrar (o: newgrp docker) para usar docker sin sudo."
