# Encrypted backup restore drill — 2026-08-30

## Result

**Pass.** An age-encrypted production backup was restored into an isolated,
temporary PostgreSQL 16 database on a workstation. The production database and
containers were not modified or restarted.

## Evidence

- Backup: `chessverse-20260830T015431Z.dump.age`
- Source: production VPS backup directory after successful Cloudflare R2 upload
- Ciphertext checksum: pass
- Age decryption with the offline-held identity: pass
- PostgreSQL custom-archive validation: pass
- `pg_restore --exit-on-error --no-owner --no-privileges`: pass
- Restored Flyway schema version: 32
- Restored public tables: 37
- Restored constraints: 113
- Aggregate `player_account` row-count query: 181
- Measured local download, decrypt and restore time: 7 seconds

Only aggregate counts were recorded. No player records, credentials, tokens,
messages or attachments were printed or copied into this evidence.

## Isolation and cleanup

The age private identity stayed on the workstation and was never copied to the
VPS or backup provider. The decrypted dump was readable only by the temporary
local PostgreSQL account. On completion, the drill dropped the temporary
database, securely removed the plaintext dump and stopped the local PostgreSQL
cluster. A final database-list check showed no restore-drill database.

## Recovery objective

- Current backup schedule gives a maximum planned database RPO of 24 hours.
- Initial startup RTO target: restore service within 4 hours of declaring a
  recoverable database incident.

The measured time is not a full outage RTO test because DNS, a replacement VPS,
container images, attachments and application smoke testing were not rebuilt.
Repeat the drill quarterly and after material backup/schema changes. A future
full disaster-recovery exercise should provision a replacement host, restore
database and attachments, deploy the recorded Git revision, and execute the
production smoke suite before traffic cutover.
