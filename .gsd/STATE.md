# ResaleRoute — Project State

**Specification:** [SPEC.md](file:///d:/ResaleRoute/.gsd/SPEC.md) (`FINALIZED`)  
**Roadmap:** [ROADMAP.md](file:///d:/ResaleRoute/.gsd/ROADMAP.md)  
**Canonical Checklist:** [06_Plan.md](file:///d:/ResaleRoute/docs/06_Plan.md)

## Current Position
- **Active Phase:** Phase 1 — Database, RLS, and Authentication Foundation
- **Next Task:** `1.3` — Apply `supabase/migrations/20261112000002_rpc_functions.sql` containing atomic stored procedures (`complete_item_intake`, `submit_auth_verdict`, `process_order_and_split`, `resolve_dispute`) from `08_TDD.md`
- **Status:** Executing Phase 1 (Plan 01-02 complete; proceeding to Plan 01-03)
- **Overall Progress:** `2 / 19` atomic tasks complete (`11%`)
- **Last Activity:** `2026-11-12` — Completed Task `1.2` (Plan `01-02`, `FOUND-02`): Authored `supabase/migrations/20261112000001_initial_schema.sql` with extensions, 6 enums, 9 tables, 7 indexes, `sync_profile_claims()`, `on_auth_user_created`, `prevent_profile_role_escalation()`, strict 9-table RLS, and append-only revokes.

## Non-Negotiable Invariants Checklist
- [x] `SPEC.md` status locked as `FINALIZED`
- [ ] Integer cents (`int`) and basis points (`10000 = 100%`) enforced across all models, calculators, RPCs, and Edge Functions (zero `double` for currency)
- [ ] `consignor_ledger` and `provenance_events` strictly append-only (`INSERT` only; zero `UPDATE`/`DELETE`)
- [x] Dual-state tracking active: every completed `gsd-executor` task updates **both** `.gsd/STATE.md` (plus `.planning/STATE.md`) **and** checks off `[x]` in `docs/06_Plan.md`

## Phase Task Ledger
| Phase | Task | Description | Status |
| :--- | :--- | :--- | :--- |
| Phase 1 | 1.1 | Flutter project & folder structure (`04_TRD.md`) | `[x]` Complete |
| Phase 1 | 1.2 | Initial PostgreSQL schema, enums, indexes, RLS (`05_Schema.md`) | `[x]` Complete |
| Phase 1 | 1.3 | Atomic RPC functions (`08_TDD.md`, `09_Sequence_Diagrams.md`) | `[ ]` Pending |
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
- **Last session:** `2026-11-12T18:22:00Z`
- **Stopped at:** Completed `01-02-PLAN.md` (`supabase/migrations/20261112000001_initial_schema.sql`).
- **Blockers:** None.
