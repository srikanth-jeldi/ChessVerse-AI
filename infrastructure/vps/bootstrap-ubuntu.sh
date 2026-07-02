#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get upgrade -y
apt-get install -y \
  ca-certificates \
  curl \
  docker-compose-v2 \
  docker.io \
  fail2ban \
  git \
  openssl \
  ufw

systemctl enable --now docker
systemctl enable --now fail2ban

ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw --force enable

echo "Ubuntu VPS bootstrap complete."
echo "Next: add a non-root deploy user with an SSH key before disabling root login."
