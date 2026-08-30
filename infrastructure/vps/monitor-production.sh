#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${ENV_FILE:-${SCRIPT_DIR}/vps.env}"
COMPOSE_FILE="${COMPOSE_FILE:-${SCRIPT_DIR}/docker-compose.prod.yml}"
STATE_FILE="${MONITOR_STATE_FILE:-${SCRIPT_DIR}/.monitor-state}"

[[ -f "${ENV_FILE}" ]] || { echo "Missing ${ENV_FILE}." >&2; exit 1; }
set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

notify_monitor() {
  local status="${1}"
  [[ -z "${APP_HEARTBEAT_URL:-}" ]] && return 0
  local url="${APP_HEARTBEAT_URL%/}"
  [[ "${status}" == "failure" ]] && url="${url}/fail"
  curl --fail --silent --show-error --max-time 15 --retry 2 --output /dev/null "${url}" || true
}

fail() {
  echo "MONITOR_FAILURE: $*" >&2
  notify_monitor failure
  exit 1
}

metrics="$(docker compose --env-file "${ENV_FILE}" -f "${COMPOSE_FILE}" exec -T backend \
  curl --fail --silent --show-error --max-time 15 http://127.0.0.1:8080/actuator/prometheus)" ||
  fail "backend metrics endpoint is unavailable"

metric_total() {
  local name="${1}"
  awk -v metric="${name}" '$1 ~ ("^" metric "({.*})?$") { total += $2 } END { printf "%.0f", total + 0 }' <<<"${metrics}"
}

current_failures="$(metric_total chessverse_auth_login_failures_total)"
current_lockouts="$(metric_total chessverse_auth_account_lockouts_total)"
current_5xx="$(awk '$1 ~ /^http_server_requests_seconds_count\{/ && $1 ~ /status="5[0-9][0-9]"/ { total += $2 } END { printf "%.0f", total + 0 }' <<<"${metrics}")"

previous_failures="${current_failures}"
previous_lockouts="${current_lockouts}"
previous_5xx="${current_5xx}"
if [[ -f "${STATE_FILE}" ]]; then
  # shellcheck disable=SC1090
  source "${STATE_FILE}"
fi

delta_failures=$((current_failures - previous_failures))
delta_lockouts=$((current_lockouts - previous_lockouts))
delta_5xx=$((current_5xx - previous_5xx))
(( delta_failures < 0 )) && delta_failures="${current_failures}"
(( delta_lockouts < 0 )) && delta_lockouts="${current_lockouts}"
(( delta_5xx < 0 )) && delta_5xx="${current_5xx}"

umask 077
printf 'previous_failures=%s\nprevious_lockouts=%s\nprevious_5xx=%s\n' \
  "${current_failures}" "${current_lockouts}" "${current_5xx}" > "${STATE_FILE}"

max_login_failures="${MONITOR_MAX_LOGIN_FAILURES_PER_INTERVAL:-25}"
max_lockouts="${MONITOR_MAX_LOCKOUTS_PER_INTERVAL:-3}"
max_5xx="${MONITOR_MAX_5XX_PER_INTERVAL:-10}"

(( delta_failures > max_login_failures )) && fail "password-login failures spiked (${delta_failures})"
(( delta_lockouts > max_lockouts )) && fail "account lockouts spiked (${delta_lockouts})"
(( delta_5xx > max_5xx )) && fail "HTTP 5xx responses spiked (${delta_5xx})"

notify_monitor success
echo "MONITOR_OK failures=${delta_failures} lockouts=${delta_lockouts} http_5xx=${delta_5xx}"
