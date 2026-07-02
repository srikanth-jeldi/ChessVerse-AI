#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

ENV_FILE="${ENV_FILE:-vps.env}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.prod.yml}"
BACKUP_DIR="${BACKUP_DIR:-${SCRIPT_DIR}/backups}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}. Copy vps.env.example to vps.env first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

umask 077
mkdir -p "${BACKUP_DIR}"

timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
backup_file="${BACKUP_DIR}/chessverse-${timestamp}.dump"

docker compose \
  --env-file "${ENV_FILE}" \
  -f "${COMPOSE_FILE}" \
  exec -T postgres \
  sh -c 'pg_dump --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --format=custom' \
  > "${backup_file}"

test -s "${backup_file}"
sha256sum "${backup_file}" > "${backup_file}.sha256"

retention_days="${BACKUP_RETENTION_DAYS:-14}"
find "${BACKUP_DIR}" -type f \
  \( -name 'chessverse-*.dump' -o -name 'chessverse-*.dump.sha256' \) \
  -mtime "+${retention_days}" -delete

if [[ -n "${BACKUP_REMOTE:-}" ]]; then
  if ! command -v rclone >/dev/null 2>&1; then
    echo "BACKUP_REMOTE is set, but rclone is not installed." >&2
    exit 1
  fi
  rclone copy "${backup_file}" "${backup_file}.sha256" "${BACKUP_REMOTE}"
fi

echo "Created ${backup_file}"
