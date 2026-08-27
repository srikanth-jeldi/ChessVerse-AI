#!/usr/bin/env sh
set -eu

repo_root="$(CDPATH= cd -- "$(dirname "$0")/../.." && pwd)"
snapshot_dir="${AI_SNAPSHOT_DIR:-/var/log/chessverse-ai-metrics}"
base_url="${AI_SNAPSHOT_BASE_URL:-https://api.chessverseai.com}"
stamp="$(date -u +%Y%m%dT%H%M%SZ)"
target="${snapshot_dir}/${stamp}.json"
temporary="${target}.tmp"

mkdir -p "${snapshot_dir}"
python3 "${repo_root}/tools/capture_ai_production_snapshot.py" \
  --base-url "${base_url}" \
  --output "${temporary}" >/dev/null
chmod 0640 "${temporary}"
mv "${temporary}" "${target}"
find "${snapshot_dir}" -type f -name '*.json' -mtime +60 -delete

