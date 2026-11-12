---
phase: 01-database-rls-and-authentication-foundation
plan: 03
subsystem: database
tags: [postgresql, supabase, plpgsql, rpc, security-definer, sha256, ledger, escrow, row-locking, firebase-deferred]

requires:
  - phase: 01-database-rls-and-authentication-foundation
    provides: "PostgreSQL 15 initial schema DDL (6 enums, 9 tables, 7 indexes), auth triggers, and 9-table RLS policies (01-02)"
provides:
  - "Atomic SECURITY DEFINER RPC migration (supabase/migrations/20261112000002_rpc_functions.sql) defining complete_item_intake, submit_auth_verdict, process_order_and_split, open_return_dispute, resolve_dispute, and settle_expired_escrows"
  - "Pessimistic checkout row locking (SELECT ... FOR UPDATE NOWAIT), integer-cent half-up rounding (+ 5000) / 10000, and NULL-safe SYSTEM_ESCROW_CRON SHA-256 provenance hash chaining"
  - "Explicit REVOKE ALL ON FUNCTION ... FROM PUBLIC and service_role-only settle_expired_escrows() privilege hardening with daily pg_cron 00:05 UTC schedule"
affects:
  - 02-01-freezed-domain-models
  - 02-02-pure-dart-calculators
  - 02-03-evaluate-markdowns-edge-function
  - 02-05-process-payout-edge-function
  - 03-01-item-intake-wizard
  - 03-02-auth-inspection
  - 03-05-shopper-provenance-checkout
  - 03-06-dispute-resolution

actuals:
  tokens: 8921
  tasks: 3
  commits: 2

commits: 2
plan_head_before: e332a01eb550160649583912c44fa292fc778bae
plan_head_after: 42fff7292701c7b3d1ac80771dd03e83c91c1fbc

tech-stack:
  added:
    - PL/pgSQL SECURITY DEFINER RPCs (PostgreSQL 15 + pgcrypto + pg_cron)
  patterns:
    - "Pessimistic checkout locking via SELECT ... FOR UPDATE NOWAIT raising SQLSTATE 55P03 on concurrent purchase contention"
    - "Integer-cent half-up split arithmetic: ((current_price_cents * consignor_split_bps) + 5000) / 10000"
    - "NULL-safe pg_cron SHA-256 hash chaining using COALESCE(auth.uid()::text, 'SYSTEM_ESCROW_CRON')"
    - "Append-only compensating ledger entries (dispute_hold, dispute_release, escrow_release_debit, escrow_release_credit) with deterministic idempotency keys"

key-files:
  created:
    - supabase/migrations/20261112000002_rpc_functions.sql
  modified:
    - docs/06_Plan.md
    - .gsd/STATE.md
    - .planning/STATE.md

key-decisions:
  - "Enforced SET search_path = public, extensions and internal auth.uid() / app_metadata.role / app_metadata.boutique_id authorization guards inside all 6 SECURITY DEFINER RPCs (T-01-06)"
  - "Used REVOKE ALL ON FUNCTION ... FROM PUBLIC before GRANT EXECUTE ... TO authenticated on user/role RPCs, and restricted settle_expired_escrows() exclusively to service_role"
  - "Skipped/deferred live Supabase CLI push in Task 3 per user direction ('No i will use firebase and i will connect it later. Please skip database work and continue other work as well'); both PostgreSQL migrations remain verified locally on disk while backend connection/migration to Firebase is deferred until user connects it later"

patterns-established:
  - "Compensating append-only ledger adjustments instead of UPDATE/DELETE on consignor_ledger"
  - "Canonical SHA-256 provenance input: H_{k-1} || '|' || item_id || '|' || event_type || '|' || actor_id_or_SYSTEM || '|' || ISO8601_UTC"

requirements-completed: [FOUND-03]

coverage:
  - id: D1
    description: "6 atomic SECURITY DEFINER PL/pgSQL RPCs authored in supabase/migrations/20261112000002_rpc_functions.sql with FOR UPDATE NOWAIT, integer-cent half-up rounding, NULL-safe SHA-256 chaining, append-only ledger/provenance inserts, and REVOKE ALL FROM PUBLIC hardening"
    requirement: "FOUND-03"
    verification:
      - kind: unit
        ref: "node RPC invariant check (6 functions, FOR UPDATE NOWAIT, + 5000) / 10000, SYSTEM_ESCROW_CRON fallback, REVOKE ALL ON FUNCTION, zero UPDATE/DELETE on consignor_ledger or provenance_events)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Local SQL structural audit (balanced $$ dollar-quoted blocks, zero floating-point types) and dual-state tracking across docs/06_Plan.md, .gsd/STATE.md, and .planning/STATE.md"
    requirement: "FOUND-03"
    verification:
      - kind: integration
        ref: "node $$ balance & docs/06_Plan.md Task 1.3 check-off verification"
        status: pass
    human_judgment: false
  - id: D3
    description: "Remote database migration push (Task 3 checkpoint) deferred per user directive to skip live database work and transition backend to Firebase later"
    requirement: "FOUND-03"
    verification: []
    human_judgment: true
    rationale: "User explicitly skipped live Supabase DB push and noted planned Firebase integration later; local SQL migration readiness verified on disk."

duration: 11 min
completed: 2026-11-12
status: complete
---

# Phase 01 Plan 03: Atomic SECURITY DEFINER RPC Functions Summary

**Authored `supabase/migrations/20261112000002_rpc_functions.sql` with all 6 atomic `SECURITY DEFINER` PL/pgSQL RPCs (`complete_item_intake`, `submit_auth_verdict`, `process_order_and_split`, `open_return_dispute`, `resolve_dispute`, `settle_expired_escrows`), pessimistic `FOR UPDATE NOWAIT` checkout locking, integer-cent half-up division, NULL-safe `SYSTEM_ESCROW_CRON` SHA-256 provenance chaining, and `PUBLIC` execute hardening; remote Supabase push deferred per user direction to use Firebase later.**

## Performance

- **Duration:** 11 min
- **Started:** 2026-11-12T18:24:03Z
- **Completed:** 2026-11-12T18:35:00Z
- **Tasks:** 3 (Tasks 1–2 implemented & verified locally; Task 3 checkpoint resolved as `deferred-local` per user direction)
- **Files modified:** 4 (`supabase/migrations/20261112000002_rpc_functions.sql`, `docs/06_Plan.md`, `.gsd/STATE.md`, `.planning/STATE.md`)

## Accomplishments
- Created `supabase/migrations/20261112000002_rpc_functions.sql` (1,059 lines) implementing all 6 `SECURITY DEFINER` stored procedures (`complete_item_intake`, `submit_auth_verdict`, `process_order_and_split`, `open_return_dispute`, `resolve_dispute`, and `settle_expired_escrows`) with `SET search_path = public, extensions` and caller role/tenant guards.
- Enforced `SELECT ... FOR UPDATE NOWAIT` in `process_order_and_split` along with integer-cent half-up rounding (`((current_price_cents * consignor_split_bps) + 5000) / 10000`), idempotent `consignor_ledger` double-entry inserts, and `COALESCE(auth.uid()::text, 'SYSTEM_ESCROW_CRON')` NULL-safe SHA-256 `provenance_events` chaining in `settle_expired_escrows()`.
- Hardened function privileges by executing `REVOKE ALL ON FUNCTION ... FROM PUBLIC` before `GRANT EXECUTE ... TO authenticated` on the 5 user/role RPCs, restricting `settle_expired_escrows()` to `service_role`, and scheduling daily `00:05 UTC` execution via `pg_cron`.
- Verified balanced `$$` PL/pgSQL blocks, zero floating-point currency types, zero `UPDATE`/`DELETE` statements on `consignor_ledger` or `provenance_events`, and migration readiness on disk (`20261112000001_initial_schema.sql` and `20261112000002_rpc_functions.sql`).

## Task Commits

Each completed implementation/verification task was committed atomically:

1. **Task 1: Author atomic SECURITY DEFINER RPCs in 20261112000002_rpc_functions.sql** - `157b065` (feat)
2. **Task 2: Validate SQL invariants locally and update dual-state tracking** - `42fff72` (docs)
3. **Task 3: [BLOCKING] Link Supabase CLI and push migrations to live PostgreSQL 15 instance** - Deferred/skipped per user directive (`deferred-local` / Firebase planned later; verified local migration readiness on disk)

**Plan metadata:** Committed in `docs(01-03)` metadata commit (see git log).

## Files Created/Modified
- `supabase/migrations/20261112000002_rpc_functions.sql` - 6 atomic `SECURITY DEFINER` PL/pgSQL procedures, privilege hardening (`REVOKE ALL ... FROM PUBLIC`), and `pg_cron` escrow settlement schedule.
- `docs/06_Plan.md` - Task `1.3` checked off `[x]` with `supabase/migrations/20261112000002_rpc_functions.sql` appended.
- `.gsd/STATE.md` - Task `1.3` marked complete and documented remote DB push deferral / Firebase plan.
- `.planning/STATE.md` - Recorded Plan `01-03` (`FOUND-03`) decisions, metrics, and deferred remote DB push note.

## Decisions Made
- Enforced `SET search_path = public, extensions` and explicit `auth.uid()` / `app_metadata.role` / `app_metadata.boutique_id` checks at the top of every `SECURITY DEFINER` RPC (`T-01-06`).
- Revoked default `PUBLIC` execute rights on all 6 RPCs and restricted `settle_expired_escrows()` to `service_role`.
- **Remote Database Push Deferred (User Direction):** Live Supabase CLI linking and `supabase db push` in Task 3 were skipped/deferred per explicit user instruction: *"No i will use firebase and i will connect it later. Please skip database work and continue other work as well"*. Both PostgreSQL migrations (`20261112000001_initial_schema.sql` and `20261112000002_rpc_functions.sql`) remain verified locally on disk; backend connection/migration to Firebase is deferred until the user connects it later.

## Deviations from Plan

None in SQL implementation — Tasks 1 and 2 executed as written. Task 3 (`checkpoint:human-action`) resolved via `deferred-local` per user instruction to skip live Supabase DB work and connect Firebase later.

## Issues Encountered

None.

## User Setup Required

**Remote database push skipped/deferred by user.**
- Per user instruction (*"No i will use firebase and i will connect it later. Please skip database work and continue other work as well"*), no live Supabase project was linked and `supabase db push` was not executed.
- Both SQL migration files (`supabase/migrations/20261112000001_initial_schema.sql` and `supabase/migrations/20261112000002_rpc_functions.sql`) remain verified locally on disk as reference schemas/contracts.
- Backend connection and migration to Firebase are deferred until the user connects Firebase later.

## Next Phase Readiness
- Wave 2 Plan `01-03` (`FOUND-03`) is closed out cleanly; Wave 2 Plan `01-04` (`app_colors.dart`, `app_typography.dart`, `app_theme.dart`) is unblocked and ready to execute sequentially.
- Downstream client and backend plans continue offline/local-first until Firebase connection is configured by the user later.

---
*Phase: 01-database-rls-and-authentication-foundation*
*Completed: 2026-11-12*

## Self-Check: PASSED
- Verified `supabase/migrations/20261112000001_initial_schema.sql`, `supabase/migrations/20261112000002_rpc_functions.sql`, `docs/06_Plan.md`, `.gsd/STATE.md`, `.planning/STATE.md`, and `01-03-SUMMARY.md` exist on disk.
- Verified commits `157b065` and `42fff72` are ancestors of `HEAD`.
- Verified all 6 RPC signatures, `FOR UPDATE NOWAIT`, integer half-up math (`+ 5000) / 10000`), `SYSTEM_ESCROW_CRON` fallback, `REVOKE ALL ON FUNCTION` hardening, balanced `$$` blocks, and zero `UPDATE`/`DELETE` mutations on `consignor_ledger` or `provenance_events`.
