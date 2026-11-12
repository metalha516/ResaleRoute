---
phase: 01-database-rls-and-authentication-foundation
plan: 02
subsystem: database
tags: [postgresql, supabase, rls, triggers, pgcrypto, pg_cron, multi-tenant, ledger]

requires: []
provides:
  - "PostgreSQL 15 initial schema migration (supabase/migrations/20261112000001_initial_schema.sql) with pgcrypto and pg_cron extensions"
  - "All 6 enums, 9 tables with integer-cent and basis-point CHECK constraints, and 7 performance indexes"
  - "Auth triggers (handle_new_user, sync_profile_claims, prevent_profile_role_escalation) for zero-join JWT app_metadata RLS and privilege-escalation prevention"
  - "Strict Row-Level Security across all 9 tables, append-only revokes on consignor_ledger & provenance_events, and column-level webhook_secret protection on boutiques"
affects:
  - 01-03-atomic-rpc-functions
  - 01-05-auth-repository-and-shells
  - 02-01-freezed-domain-models
  - 02-03-evaluate-markdowns-edge-function
  - 02-04-multichannel-sync-edge-function
  - 02-05-process-payout-edge-function

actuals:
  tokens: 6638
  tasks: 3
  commits: 3

commits: 3
plan_head_before: 7f6a90c66d63dbf49fe5cdf51ef4fa5740bee5b4
plan_head_after: 4ecfa11df17c3be32143f3d36ef89c74338648b0

tech-stack:
  added:
    - PostgreSQL 15 DDL (pgcrypto, pg_cron)
    - Supabase Row-Level Security (RLS) with JWT app_metadata claims
  patterns:
    - "Integer cents (INTEGER) and basis points (1000..9500 bps) for all monetary & split columns; zero floating-point currency types"
    - "Append-only ledger & provenance enforcement via zero client write policies plus REVOKE INSERT, UPDATE, DELETE FROM anon, authenticated"
    - "Column-level SELECT/UPDATE grants on boutiques requiring explicit non-secret column projection (id, name, slug, default_consignor_split_bps, high_value_auth_threshold_cents, webhook_url, created_at)"

key-files:
  created:
    - supabase/migrations/20261112000001_initial_schema.sql
  modified:
    - docs/06_Plan.md
    - .gsd/STATE.md
    - .planning/STATE.md

key-decisions:
  - "Hardcoded default 'shopper' role in handle_new_user() and enforced prevent_profile_role_escalation() BEFORE UPDATE trigger so client sessions cannot self-escalate role or boutique_id (T-01-03)"
  - "Revoked SELECT on boutiques.webhook_secret from anon/authenticated; downstream PostgREST/client queries must project explicit non-secret columns instead of SELECT * (T-01-05)"
  - "Revoked INSERT, UPDATE, DELETE on consignor_ledger and provenance_events from anon/authenticated so mutations occur exclusively through SECURITY DEFINER RPCs and Edge Functions (T-01-04)"

patterns-established:
  - "Zero-join multi-tenant RLS using (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid and (auth.jwt() -> 'app_metadata' ->> 'role')"
  - "Explicit non-secret column projection when querying public.boutiques from client roles"

requirements-completed: [FOUND-02]

coverage:
  - id: D1
    description: "Extensions (pgcrypto, pg_cron), 6 enums, 9 tables with integer-cent/bps CHECK constraints, and 7 indexes authored in supabase/migrations/20261112000001_initial_schema.sql"
    requirement: "FOUND-02"
    verification:
      - kind: unit
        ref: "node DDL verification (6 enums, 9 tables, 7 indexes, photo_urls >= 4 check) + SQL structural audit (471 lines, balanced parens/quotes, zero floats)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Auth triggers (on_auth_user_created, trg_sync_profile_claims, trg_prevent_profile_role_escalation), 9-table RLS policies, append-only revokes on consignor_ledger/provenance_events, and column-level webhook_secret grants"
    requirement: "FOUND-02"
    verification:
      - kind: unit
        ref: "node RLS, trigger, and REVOKE/GRANT verification across all 9 tables"
        status: pass
    human_judgment: false
  - id: D3
    description: "Dual-state tracking synchronized for Task 1.2 across docs/06_Plan.md, .gsd/STATE.md, and .planning/STATE.md"
    requirement: "FOUND-02"
    verification:
      - kind: integration
        ref: "node check for '- [x] **1.2**' in docs/06_Plan.md"
        status: pass
    human_judgment: false

duration: 4 min
completed: 2026-11-12
status: complete
---

# Phase 01 Plan 02: PostgreSQL Initial Schema, Triggers & RLS Summary

**Authored `supabase/migrations/20261112000001_initial_schema.sql` with `pgcrypto`/`pg_cron`, all 6 enums, 9 integer-cent/basis-point tables, 7 performance indexes, JWT `app_metadata` sync + privilege-escalation guards, strict 9-table RLS, and append-only ledger/provenance revokes.**

## Performance

- **Duration:** 4 min
- **Started:** 2026-11-12T18:18:57Z
- **Completed:** 2026-11-12T18:22:52Z
- **Tasks:** 3
- **Files modified:** 4 (`supabase/migrations/20261112000001_initial_schema.sql`, `docs/06_Plan.md`, `.gsd/STATE.md`, `.planning/STATE.md`)

## Accomplishments
- Created `supabase/migrations/20261112000001_initial_schema.sql` (471 lines) defining `pgcrypto` and `pg_cron` extensions, all 6 enums (`user_role`, `condition_grade`, `item_status`, `auth_verdict`, `ledger_tx_type`, `dispute_status`), all 9 core tables with exact CHECK constraints (`photo_urls >= 4`, `consignor_split_bps BETWEEN 1000 AND 9500`, `default_consignor_split_bps BETWEEN 1000 AND 9500`, `applied_tier IN (0, 30, 60, 90)`, positive integer-cent prices), and all 7 performance indexes from `docs/05_Schema.md`.
- Implemented `sync_profile_claims()` (`trg_sync_profile_claims`), `handle_new_user()` (`on_auth_user_created`), and `prevent_profile_role_escalation()` (`trg_prevent_profile_role_escalation`) so signups default to `'shopper'` and client sessions cannot mutate `role` or `boutique_id`.
- Enabled Row-Level Security with explicit multi-tenant policies across all 9 tables, revoked `INSERT`, `UPDATE`, and `DELETE` on `consignor_ledger` and `provenance_events` from `anon, authenticated`, and restricted `public.boutiques` column `SELECT` grants to exclude `webhook_secret`.
- Passed structural SQL audit (balanced parentheses/quotes, zero floating-point column declarations) and updated dual-state tracking across `docs/06_Plan.md`, `.gsd/STATE.md`, and `.planning/STATE.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author extensions, 6 enums, 9 tables with CHECK constraints, and 7 indexes** - `bf5879b` (feat)
2. **Task 2: Add triggers, strict RLS policies for all 9 tables, and append-only revokes** - `e258f6a` (feat)
3. **Task 3: Validate SQL migration structure and update dual-state tracking** - `4ecfa11` (docs)

## Files Created/Modified
- `supabase/migrations/20261112000001_initial_schema.sql` - Complete PostgreSQL 15 DDL, auth triggers, 9-table RLS policies, append-only revokes, and column-level secret grants.
- `docs/06_Plan.md` - Task `1.2` marked `[x]` with migration file path appended.
- `.gsd/STATE.md` - Task `1.2` marked `[x] Complete`, progress updated to `2 / 19` (`11%`), next task set to `1.3`.
- `.planning/STATE.md` - Recorded Plan `01-02` (`FOUND-02`) architectural decisions and progress context.

## Decisions Made
- Hardcoded `'shopper'` role assignment in `handle_new_user()` and blocked client-side `role`/`boutique_id` mutations in `prevent_profile_role_escalation()` to satisfy threat mitigation `T-01-03`.
- Protected `boutiques.webhook_secret` via column-level `REVOKE ALL` + explicit `GRANT SELECT (...)` excluding `webhook_secret`; all client/PostgREST reads of `boutiques` must explicitly project non-secret columns instead of `SELECT *` (`T-01-05`).
- Enforced append-only immutability on `consignor_ledger` and `provenance_events` using both zero client write RLS policies and explicit `REVOKE INSERT, UPDATE, DELETE FROM anon, authenticated` (`T-01-04`).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Wave 1 complete (`01-01` and `01-02` finished sequentially).
- Wave 2 Plan `01-03` (`supabase/migrations/20261112000002_rpc_functions.sql` atomic RPCs) and Plan `01-04` (design tokens & theme) are unblocked.

---
*Phase: 01-database-rls-and-authentication-foundation*
*Completed: 2026-11-12*

## Self-Check: PASSED
- Verified `supabase/migrations/20261112000001_initial_schema.sql`, `docs/06_Plan.md`, `.gsd/STATE.md`, `.planning/STATE.md`, and `01-02-SUMMARY.md` exist on disk.
- Verified commits `bf5879b`, `e258f6a`, and `4ecfa11` are ancestors of `HEAD`.
- Verified DDL (6 enums, 9 tables, 7 indexes), triggers, 9-table RLS policies, `REVOKE UPDATE, DELETE` immutability, and zero floating-point column declarations.
