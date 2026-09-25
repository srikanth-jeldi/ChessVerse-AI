# Academy and school portal — phase one

The Spring Boot application now serves a responsive B2B workspace at `/academy/index.html` (also `/academy/`). The reference designs guide its dark navigation, light cards, indigo accents, admin dashboard, coach view, student profiles, batch schedules and billing/report layouts. No Flutter consumer screens are replaced.

## Run and review

### Approved reference layout update (September 26)

`workflow.js` and `workflow.css` refine the existing portal around the approved
navy sidebar, light workspace, blue/teal charts and gold training CTA. The supplied
king logo is retained byte-for-byte. Coach priorities link to student profiles;
chart points open their recorded session evidence with mouse or keyboard; profile
assignment actions preselect that student. Batch creation and assignment forms
open as side drawers. Assignment status filters and manual workspace refresh are
available, with a successful-refresh timestamp. Reports and billing stay separate.

This is a local UI/workflow update. It does not deploy DNS or production services,
enable automatic game-event synchronization, or turn recorded sessions into live
game analysis. Demo data is labelled synthetic. Live mode uses the existing
authorized workspace endpoints; automatic game ingestion remains outstanding.

- Start the existing backend normally; Flyway applies `V62__organization_portal.sql`.
- Open `/academy/` and sign in with an existing verified ChessVerse account.
- Open `/academy/?demo` for an explicitly labelled, synthetic, in-memory workspace. Demo writes never call live APIs. Reloading resets the data. The role picker is exclusive to demo mode.
- For frontend-only review: `node tools/serve_web_preview.js backend/src/main/resources/static/academy 8094`, then open `http://127.0.0.1:8094/?demo`. This preview server has no backend API.
- Java 21 is required. Run `mvn -Dtest=AcademyControllerTest,AcademyWebBoundaryTest,ServiceBoundaryFilterTest test` in `backend`, and `node --test tools/academy_portal_test.cjs` from the repository root.

The supplied black-king blue/gold icon is the product brand asset. Its unmodified source is stored at `mobile/assets/branding/app_icon.png` and `backend/src/main/resources/static/academy/app-icon.png`. Android, iOS, web and Windows launcher variants are regenerated with the existing `flutter_launcher_icons` configuration; the consumer web favicon now points to this icon instead of the old horse icon. Portal sidebar, login and feature banner use the same source. Organization-specific white-label logos remain an explicit branding setting.

## Provisioning and access

There is deliberately no public endpoint that grants Super Admin. A trusted database operator must provision the first platform account, using its verified account UUID:

```sql
INSERT INTO academy_super_admin(account_id)
SELECT id FROM player_account
WHERE id = '<verified-account-uuid>' AND verified = TRUE;
```

After signing in, this account can open **Super Admin → Create organization**. Select academy/school and supply its first administrator's account UUID. The platform operator can obtain that UUID through the existing account administration process; `/api/v1/academy/me` also returns the signed-in user's UUID. Organizations start with 25 seats and Trial status.

The Organization Admin adds members using their verified account emails, creates batches and student records, then links Student members using the student form's account selector. Parent access requires an explicit parent/child link. Unlinking removes access immediately. Deactivating a student blocks that student's and linked parents' student data access; inactive memberships cannot enter the workspace. Coaches must be reassigned before their role can be removed. Admins cannot remove their own admin access.

## Implemented workflows

| Area | Behavior |
| --- | --- |
| Organization / school dashboard | Student counts, practicing students, coaches, shared games, training hours, progress trends, weakness distribution, activity, schedules, plan and quick actions |
| Coach dashboard | Assigned students only, low-accuracy attention list, retries, phase mistakes, game records, recommendations and training actions |
| Students | Add/edit, activate/deactivate, account linking, batch and personal coach assignment, atomic CSV import (200 rows maximum) |
| Batches | Beginner/intermediate/advanced, coach allocation, editable human-readable schedule including timezone |
| Student analytics | Recorded rating/accuracy trends, tactics, opening/middlegame/endgame errors, coach notes, streak, retry success and change |
| Assignments | Puzzles, positions, openings, master games; one student or all in-scope students in a batch; due dates and completion |
| Reports | Weekly/monthly immutable per-student snapshots, parent-friendly browser Print / Save as PDF, CSV export |
| Engagement | Visible-student ratings, batch filtering, rating improvement, recorded practice streaks, completed assignments |
| Branding | Tenant name, HTTPS logo URL, accent color and organization name in place of product branding |
| Billing | Seats used, plan, status, renewal date, recorded invoices exported as CSV, seat request and platform approval |
| Roles | Admin-managed verified members and explicit parent links; role enforcement on the server |
| EpitomeHub | Organizations, usage counts, licenses, seat approvals, support tickets, suspension and stored feature flag metadata |

## Tenant isolation

All B2B students, coaches/members, batches, assignments, observations, reports, games, support and billing records have `organization_id`. Every tenant endpoint validates active server-side membership for the authenticated account. A UUID in the URL is a selection, never authorization. No browser-provided role is accepted.

Composite foreign keys `(organization_id, id)` reject foreign-tenant coaches, batches, students, parents and report creators. Queries constrain organization first, then response/mutation checks constrain coaches to personally assigned students and parents/students to their linked records. Reports and game bodies follow the same scope. PostgreSQL RLS is not enabled; isolation is enforced by the service and composite constraints. Direct database credentials remain privileged.

Organization administrators see all their tenant's records. Super Admin is a separate database grant and provides no implicit access to individual student records. Cross-tenant operations are limited to the dedicated platform endpoints. School Admin uses the Organization Admin role with organization kind `SCHOOL`.

The app uses its existing bearer-token authentication. Tokens live only in page memory, so reload requires another sign-in. Tenant switches clear visible data before loading. Portal/API responses use `Cache-Control: no-store`, and the portal sets a restrictive script policy. CSV exports neutralize formula prefixes; rendered user content is escaped.

Seat allocation and imports lock the organization row; imports and multi-student assignments are transactional. Repeated seat approval cannot grant extra seats twice. Tests exercise tenant probing, parent/coach boundaries, foreign references, rollback, membership revocation, private game sharing, report scope and quotas.

## Consumer game and analytics boundary

Consumer history remains personal. It is not automatically copied to any academy, including when a member joins multiple organizations. A Student can explicitly select one of their 100 most recent saved computer games and share it with one organization. The backend reads the game using the authenticated player's ID and stores a tenant-bound snapshot; arbitrary game bodies and another player's IDs are rejected. Only in-scope staff, the student, and linked parents can view the snapshot. Phase one presents the saved position, players, result and move history; interactive move-by-move replay is not included.

Training metrics currently come from coach-recorded sessions, not automatic aggregation of all consumer game analysis. These records are labelled accordingly. Do not interpret recorded ratings as certified FIDE ratings, shared-game counts as analyzed-game counts, or practice activity as attendance. Enrollment does not expose historical consumer analysis, social records or gameplay APIs.

## AI guidance

Always-available dashboard insights use deterministic rules. **Student Profile → AI guidance** optionally uses the configured OpenAI-compatible provider when `chessverse.academy.ai.enabled=true`, together with existing `chessverse.coach.language.endpoint`, `api-key` and `model` settings. The endpoint must use HTTPS. This separate opt-in avoids sending organization training data merely because consumer AI was enabled.

Only numeric aggregates of up to 60 recent sessions within 30 days are sent: accuracy, minutes, tactics, phase mistakes and retries. Names, student IDs, organization IDs, emails, free-text notes and tokens are excluded. The UI distinguishes actual AI output from disabled/unavailable-provider rules-based fallback. Guidance is limited to ten requests per member per organization per UTC day, and must be reviewed by the coach. Provider errors and credentials are not exposed. No live provider call is made in the test suite.

## Hostinger VPS subdomain

Production Caddy routes `academy.{$APP_DOMAIN}` to a dedicated `academy` container.
With `APP_DOMAIN=chessverseai.com`, this is `academy.chessverseai.com`.
The root redirects to `/academy/`. Portal assets, `/api/auth/login`, and
`/api/v1/academy` use the same origin; unrelated routes return 404.
Login proxies to the existing backend; tenant endpoints and assets proxy to
`academy:8080`. The academy process uses the `platform` service role, preventing
consumer matchmaking, purchase reconciliation and analysis recovery schedulers
from running there. It has a 1 GiB memory limit, half a CPU and a five-connection
database pool. The database remains shared; tenant access is enforced by the
academy service and composite constraints.

Before rollout, back up the database and retain the current backend/web images.
Run `bash infrastructure/vps/deploy-academy.sh` from the repository root on the
VPS. It verifies a private database dump, builds/tests the academy service,
applies Flyway V62, checks readiness, and layers routing over the exact current
web image. It verifies that the consumer backend container and start time stay
unchanged. Failed web verification restores the previous web image; additive
academy tables and their data are retained. Provision memberships explicitly;
deployment itself does not grant users academy access.

In Hostinger DNS, create an `A` record named `academy` pointing to the existing
VPS public IPv4 address, checking for conflicting records first. Only configure
AAAA when the server serves IPv6. Verify the server APP_DOMAIN value. Caddy can
obtain HTTPS certificates once DNS resolves and ports 80/443 reach the server.

After rollout verify HTTPS, the root redirect, assets, login, membership checks,
cross-tenant denial, and the existing main app/API. These local changes do not
deploy the server or modify DNS. Local Docker validation requires a running
Docker engine; it was unavailable during preparation.

## Deployment boundaries and remaining integrations

The platform service now accepts `/academy/` and `/api/v1/academy`; the microservice gateway routes both to it. Existing `/api/auth` still routes to identity. Monolithic deployments need no extra frontend host or build step.

Payments, automatic invoice issuance, email delivery of reports, custom domains, attendance tracking, automatic consumer analytics synchronization and interactive game replay are separate integrations. The current billing UI never claims to charge a payment method. Invoices display records populated by a trusted billing integration; the portal does not fabricate live invoices. Feature flags are persisted operational metadata, not a runtime entitlement engine. Schedule text is not an automatic calendar/reminder system. No production migration or deployment is performed by adding these files.
