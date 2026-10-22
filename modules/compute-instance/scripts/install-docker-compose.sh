#!/bin/bash
set -euo pipefail

LOG="/var/log/install-docker-compose.log"
exec > >(tee -a "${LOG}") 2>&1

echo "==> Startup script started at $(date -Is)"

if systemctl is-active --quiet firewalld; then
  echo "==> Opening SSH in firewalld"
  firewall-cmd --permanent --add-service=ssh
  firewall-cmd --reload
fi

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "==> Docker and Docker Compose already installed"
  exit 0
fi

echo "==> Installing Docker Engine and Docker Compose plugin"
dnf -y update
dnf -y install dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "==> Docker version: $(docker --version)"
echo "==> Docker Compose version: $(docker compose version)"
echo "==> Startup script finished at $(date -Is)"
