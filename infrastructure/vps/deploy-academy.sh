#!/usr/bin/env bash
# Run from infrastructure/vps after updating to the reviewed academy commit.
# Existing consumer backend and published Flutter assets are preserved.
set -Eeuo pipefail
umask 077
cd "$(dirname "$0")"
compose=(docker compose --env-file vps.env -f docker-compose.prod.yml)
release="$(date -u +%Y%m%dT%H%M%SZ)"
backup="/root/chessverse-backups/academy-$release"
mkdir -p "$backup"
chmod 700 "$backup"
"${compose[@]}" config --quiet
backend_id="$("${compose[@]}" ps -q backend)"
web_id="$("${compose[@]}" ps -q web)"
test -n "$backend_id" && test -n "$web_id"
docker inspect --format '{{.Id}} {{.Image}} {{.State.StartedAt}}' "$backend_id" > "$backup/backend-before.txt"
old_web="$(docker inspect --format '{{.Image}}' "$web_id")"
docker tag "$old_web" "chessverse-web:before-academy-$release"
docker cp "$web_id:/etc/caddy/Caddyfile" "$backup/Caddyfile"
docker exec chessverse-postgres-1 sh -c 'pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc' > "$backup/database.dump"
test -s "$backup/database.dump"
docker exec -i chessverse-postgres-1 pg_restore --list < "$backup/database.dump" > "$backup/database-contents.txt"
echo "Verified database backup: $backup/database.dump"

"${compose[@]}" build academy
"${compose[@]}" up -d --no-deps academy
ready=false
for attempt in $(seq 1 36); do
  if "${compose[@]}" exec -T academy curl -fsS http://localhost:8080/actuator/health/readiness > /dev/null; then ready=true; break; fi
  sleep 5
done
if [[ "$ready" != true ]]; then echo 'Academy readiness failed; web and consumer backend are unchanged.'; exit 1; fi

# Layer only the routing config over the exact running web image.
mkdir -p "$backup/web-build"
cp web/Caddyfile "$backup/web-build/Caddyfile"
printf 'FROM chessverse-web:before-academy-%s\nCOPY Caddyfile /etc/caddy/Caddyfile\n' "$release" > "$backup/web-build/Dockerfile"
docker build -t "chessverse-web:academy-$release" "$backup/web-build"
docker run --rm --env-file vps.env --entrypoint caddy "chessverse-web:academy-$release" validate --config /etc/caddy/Caddyfile
printf 'services:\n  web:\n    image: chessverse-web:academy-%s\n' "$release" > "$backup/web-override.yml"
rollback() {
  echo 'Verification failed; restoring previous web image.'
  printf 'services:\n  web:\n    image: chessverse-web:before-academy-%s\n' "$release" > "$backup/rollback.yml"
  "${compose[@]}" -f "$backup/rollback.yml" up -d --no-deps --no-build web
}
trap rollback ERR
"${compose[@]}" -f "$backup/web-override.yml" up -d --no-deps --no-build web
curl -fsS --retry 12 --retry-delay 5 --retry-all-errors https://academy.chessverseai.com/academy/index.html > "$backup/portal.html"
curl -fsS https://api.chessverseai.com/api/v1/health
curl -fsS https://chessverseai.com/play/ > /dev/null
docker inspect --format '{{.Id}} {{.Image}} {{.State.StartedAt}}' "$backend_id" > "$backup/backend-after.txt"
cmp "$backup/backend-before.txt" "$backup/backend-after.txt"
# Keep the conventional tag in sync for subsequent compose runs.
docker tag "chessverse-web:academy-$release" chessverse-web:latest
trap - ERR
echo "Academy HTTPS verified; consumer backend unchanged. Release: $release"
