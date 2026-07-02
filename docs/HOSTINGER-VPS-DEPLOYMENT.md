# Hostinger VPS deployment

This deployment targets a budget Hostinger KVM 1 or KVM 2 server running
Ubuntu 24.04 LTS. It keeps PostgreSQL private, limits container resources for a
small VPS, serves Flutter Web, proxies the Spring Boot API, and obtains HTTPS
certificates automatically through Caddy.

## Architecture

- `play.example.com`: Flutter Web static files
- `api.example.com`: Spring Boot API
- PostgreSQL 16: internal Docker network only
- Stockfish: installed inside the backend image, configured for one thread
- Caddy: ports 80 and 443, automatic HTTPS and certificate renewal

Android and iOS release builds use the same `https://api.example.com` endpoint.
The production container allows a longer engine startup timeout for a
low-cost VPS while each Stockfish calculation remains limited to one thread.

## 1. DNS

Create two DNS `A` records pointing to the VPS public IPv4 address:

```text
play.example.com  -> VPS_IP
api.example.com   -> VPS_IP
```

Wait until both names resolve to the VPS before starting the web container.

## 2. Initial Ubuntu setup

Connect through Hostinger's browser terminal or SSH, clone the repository, and
run the bootstrap script:

```bash
git clone https://github.com/srikanth-jeldi/ChessVerse-AI.git
cd ChessVerse-AI
sudo bash infrastructure/vps/bootstrap-ubuntu.sh
```

Add a non-root deployment user and SSH key before disabling SSH password and
root login. Do not close the original SSH session until key login works in a
second terminal.

## 3. Production secrets

```bash
cd infrastructure/vps
cp vps.env.example vps.env
chmod 600 vps.env
openssl rand -base64 32
```

Put the generated value in `POSTGRES_PASSWORD`. Set the real application/API
domains, ACME contact email, Gmail account, Gmail app password and sender.
Never commit `vps.env`.

## 4. Validate and deploy

```bash
docker compose --env-file vps.env -f docker-compose.prod.yml config
docker compose --env-file vps.env -f docker-compose.prod.yml build
docker compose --env-file vps.env -f docker-compose.prod.yml up -d
docker compose --env-file vps.env -f docker-compose.prod.yml ps
```

Smoke tests:

```bash
curl --fail https://api.example.com/actuator/health/readiness
curl --head https://play.example.com
```

The API must not publish ports `5432` or `8080` to the internet. Only SSH,
HTTP, HTTPS and HTTP/3 are allowed through the host firewall.

## 5. Daily database backup

The included script creates a private PostgreSQL custom-format dump, checksum,
14-day local retention, and optionally copies each backup to an rclone remote:

```bash
chmod 700 backup-postgres.sh
./backup-postgres.sh
```

Test a restore before depending on backups. A local VPS snapshot is not a
substitute for an off-server database copy.

After a successful manual run, add a daily root cron entry:

```cron
15 2 * * * cd /opt/chessverse/infrastructure/vps && ./backup-postgres.sh >> /var/log/chessverse-backup.log 2>&1
```

Use an external rclone destination by setting `BACKUP_REMOTE` in `vps.env`.

## 6. Updating production

```bash
git pull --ff-only
cd infrastructure/vps
docker compose --env-file vps.env -f docker-compose.prod.yml build
docker compose --env-file vps.env -f docker-compose.prod.yml up -d
docker image prune -f
```

Run `backup-postgres.sh` immediately before database migrations or major
upgrades.

## 7. Mobile release endpoint

Build Android releases with:

```bash
flutter build appbundle --release \
  --dart-define=API_BASE_URL=https://api.example.com
```

iOS uses the same define but must be built and signed on macOS with Xcode.
