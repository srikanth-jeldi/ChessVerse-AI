#!/usr/bin/env bash
set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <backup.dump.age> <age-identity-file>" >&2
  exit 2
fi

backup_file="$(realpath "$1")"
identity_file="$(realpath "$2")"
test -s "${backup_file}"
test -s "${identity_file}"
sha256sum --check "${backup_file}.sha256"

temporary="$(mktemp --suffix=.dump)"
trap 'shred -u "${temporary}" 2>/dev/null || rm -f "${temporary}"' EXIT
umask 077
age --decrypt --identity "${identity_file}" --output "${temporary}" "${backup_file}"
pg_restore --list "${temporary}" >/dev/null
echo "Encrypted backup integrity and PostgreSQL archive verified."
