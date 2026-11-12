# ResaleRoute — Project State

**Specification:** [SPEC.md](file:///d:/ResaleRoute/.gsd/SPEC.md) (`FINALIZED`)  
**Roadmap:** [ROADMAP.md](file:///d:/ResaleRoute/.gsd/ROADMAP.md)  
**Canonical Checklist:** [06_Plan.md](file:///d:/ResaleRoute/docs/06_Plan.md)

## Current Position
- **Active Phase:** Phase 1 — Database, RLS, and Authentication Foundation
- **Next Task:** `1.1` — Initialize Flutter project (`resaleroute`) with locked `pubspec.yaml` dependencies and folder structure from `04_TRD.md`
- **Status:** Ready to plan / execute Phase 1
- **Overall Progress:** `0 / 19` atomic tasks complete (`0%`)
- **Last Activity:** `2026-11-12` — Synthesized all 9 docs into `.gsd/SPEC.md` (`FINALIZED`), mapped 4 phases into `.gsd/ROADMAP.md`, initialized Git & GSD tracking.

## Non-Negotiable Invariants Checklist
- [x] `SPEC.md` status locked as `FINALIZED`
- [ ] Integer cents (`int`) and basis points (`10000 = 100%`) enforced across all models, calculators, RPCs, and Edge Functions (zero `double` for currency)
- [ ] `consignor_ledger` and `provenance_events` strictly append-only (`INSERT` only; zero `UPDATE`/`DELETE`)
- [ ] Dual-state tracking active: every completed `gsd-executor` task updates **both** `.gsd/STATE.md` (plus `.planning/STATE.md`) **and** checks off `[x]` in `docs/06_Plan.md`

## Phase Task Ledger
| Phase | Task | Description | Status |
| :--- | :--- | :--- | :--- |
| Phase 1 | 1.1 | Flutter project & folder structure (`04_TRD.md`) | `[ ]` Pending |
| Phase 1 | 1.2 | Initial PostgreSQL schema, enums, indexes, RLS (`05_Schema.md`) | `[ ]` Pending |
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
- **Last session:** `2026-11-12 23:28`
- **Stopped at:** Project initialization complete; `.gsd/` and `.planning/` artifacts ready for Phase 1 planning/execution.
- **Blockers:** None.
