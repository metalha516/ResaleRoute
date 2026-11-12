# ResaleRoute — Project State

**Specification:** [SPEC.md](file:///d:/ResaleRoute/.gsd/SPEC.md) (`FINALIZED`)  
**Roadmap:** [ROADMAP.md](file:///d:/ResaleRoute/.gsd/ROADMAP.md)  
**Canonical Checklist:** [06_Plan.md](file:///d:/ResaleRoute/docs/06_Plan.md)

## Current Position
- **Active Phase:** Phase 1 — Database, RLS, and Authentication Foundation
- **Next Task:** `1.4` — Implement `app_colors.dart`, `app_typography.dart`, and `app_theme.dart` with exact dark/light hex tokens from `03_UI_Spec.md` (after `01-03` Task 3 live `supabase db push` checkpoint resolution)
- **Status:** Executing Phase 1 (Plan 01-03 Tasks 1 & 2 complete; awaiting Task 3 blocking checkpoint for live `supabase db push`)
- **Overall Progress:** `3 / 19` atomic tasks complete (`16%`)
- **Last Activity:** `2026-11-12` — Completed Task `1.3` SQL authoring & local invariant verification (Plan `01-03`, `FOUND-03`): Authored `supabase/migrations/20261112000002_rpc_functions.sql` with all 6 `SECURITY DEFINER` RPCs (`complete_item_intake`, `submit_auth_verdict`, `process_order_and_split`, `open_return_dispute`, `resolve_dispute`, `settle_expired_escrows`), `FOR UPDATE NOWAIT`, integer-cent half-up rounding, `SYSTEM_ESCROW_CRON` NULL-safe SHA-256 chaining, and explicit `REVOKE ALL ... FROM PUBLIC` / `GRANT EXECUTE` hardening.

## Non-Negotiable Invariants Checklist
- [x] `SPEC.md` status locked as `FINALIZED`
- [ ] Integer cents (`int`) and basis points (`10000 = 100%`) enforced across all models, calculators, RPCs, and Edge Functions (zero `double` for currency)
- [x] `consignor_ledger` and `provenance_events` strictly append-only (`INSERT` only; zero `UPDATE`/`DELETE` in DB schema & RPCs)
- [x] Dual-state tracking active: every completed `gsd-executor` task updates **both** `.gsd/STATE.md` (plus `.planning/STATE.md`) **and** checks off `[x]` in `docs/06_Plan.md`

## Phase Task Ledger
| Phase | Task | Description | Status |
| :--- | :--- | :--- | :--- |
| Phase 1 | 1.1 | Flutter project & folder structure (`04_TRD.md`) | `[x]` Complete |
| Phase 1 | 1.2 | Initial PostgreSQL schema, enums, indexes, RLS (`05_Schema.md`) | `[x]` Complete |
| Phase 1 | 1.3 | Atomic RPC functions (`08_TDD.md`, `09_Sequence_Diagrams.md`) | `[x]` Complete (SQL authored & verified; remote push checkpoint pending) |
| Phase 1 | 1.4 | Design tokens & theme (`03_UI_Spec.md`) | `[ ]` Pending |
| Phase 1 | 1.5 | AuthRepository, authStateProvider, GoRouter guards (`02_AppFlow.md`) | `[ ]` Pending |
| Phase 2 | 2.1 | Freezed domain models | `[ ]` Pending |
| Phase 2 | 2.2 | Pure Dart calculators (`split`, `markdown`, `provenance_hasher`) | `[ ]` Pending |
| Phase 2 | 2.3 | Edge Function `evaluate-markdowns` + `pg_cron` | `[ ]` Pending |
| Phase 2 | 2.4 | Edge Function `multichannel-sync` (HMAC-SHA256) | `[ ]` Pending |
| Phase 2 | 2.5 | Edge Function `process-payout` (idempotent debit) | `[ ]` Pending |
| Phase 3 | 3.1 | `ItemIntakeWizardScreen` + QR modal | `[ ]` Pending |
| Phase 3 | 3.2 | `AuthReviewQueueScreen` & `AuthInspectionScreen` | `[ ]` Pending |
| Phase 3 | 3.3 | `InventoryMarkdownScreen` | `[ ]` Pending |
| Phase 3 | 3.4 | `ConsignorPortalScreen` & `ConsignorLedgerScreen` | `[ ]` Pending |
| Phase 3 | 3.5 | `ShopperCatalogScreen` & `ProductProvenanceScreen` | `[ ]` Pending |
| Phase 3 | 3.6 | `DisputeResolutionScreen` & `SustainabilityReportScreen` | `[ ]` Pending |
| Phase 4 | 4.1 | `OfflineIntakeQueueService` | `[ ]` Pending |
| Phase 4 | 4.2 | Unit tests (`test/unit/`) | `[ ]` Pending |
| Phase 4 | 4.3 | Widget & integration tests (`test/widget/`) | `[ ]` Pending |

## Session Continuity
- **Last session:** `2026-11-12T18:28:00Z`
- **Stopped at:** Completed `01-03-PLAN.md` Tasks 1 & 2 (`supabase/migrations/20261112000002_rpc_functions.sql`); paused at Task 3 blocking checkpoint (`supabase db push`).
- **Blockers:** Awaiting Supabase CLI linking and `supabase db push` (or explicit `deferred-local` confirmation).
