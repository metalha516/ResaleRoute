# ResaleRoute — Project State

**Specification:** [SPEC.md](file:///d:/ResaleRoute/.gsd/SPEC.md) (`FINALIZED`)  
**Roadmap:** [ROADMAP.md](file:///d:/ResaleRoute/.gsd/ROADMAP.md)  
**Canonical Checklist:** [06_Plan.md](file:///d:/ResaleRoute/docs/06_Plan.md)

## Current Position
- **Active Phase:** Phase 1 — Database, RLS, and Authentication Foundation
- **Next Task:** `1.5` — Build `AuthRepository`, Riverpod `authStateProvider`, and `app_router.dart` with role-based redirect guards matching `02_AppFlow.md`
- **Status:** Executing Phase 1 (Plan 01-04 complete; proceeding to `01-05`)
- **Overall Progress:** `4 / 19` atomic tasks complete (`21%`)
- **Last Activity:** `2026-11-12` — Completed Plan `01-04` (`FOUND-04`, Task `1.4`): Implemented `app_colors.dart`, `app_typography.dart`, `sustainability_constants.dart`, and `app_theme.dart` with Dark-First Editorial Vault hex tokens, zero dark-mode shadows, and `1px` `#262E3B` borders; `flutter analyze` passed with zero issues.

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
| Phase 1 | 1.3 | Atomic RPC functions (`08_TDD.md`, `09_Sequence_Diagrams.md`) | `[x]` Complete (SQL verified locally; remote DB push skipped/deferred for Firebase later) |
| Phase 1 | 1.4 | Design tokens & theme (`03_UI_Spec.md`) | `[x]` Complete |
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
- **Last session:** `2026-11-12T18:43:00Z`
- **Stopped at:** Completed `01-04-PLAN.md` (`FOUND-04`, Task `1.4`). Design tokens, typography scale, spacing/sustainability constants, and `AppTheme` (`darkTheme` zero-shadow + `lightTheme` subtle elevation) verified via `flutter analyze`.
- **Blockers:** None (remote DB push from Task 1.3 remains deferred until Firebase connection; proceeding with `01-05` auth/router).
