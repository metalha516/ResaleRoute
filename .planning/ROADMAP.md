# Roadmap: ResaleRoute

## Overview

ResaleRoute delivers an end-to-end managed resale and consignment platform across 4 sequential phases mapped directly from `docs/06_Plan.md`: establishing the PostgreSQL/RLS/Auth/Theme foundation (Phase 1), building deterministic integer-cent domain models, calculators, and Deno Edge Functions (Phase 2), delivering all multi-role Flutter workflows (Phase 3), and hardening offline resilience plus unit/widget verification (Phase 4).

## Phases

- [ ] **Phase 1: Database, RLS, and Authentication Foundation** - Flutter project scaffold, Postgres schema & RLS, atomic RPCs, Dark-First theme tokens, and GoRouter role guards (Tasks 1.1–1.5).
- [ ] **Phase 2: Core Backend Logic, Calculators, and Edge Functions** - Freezed domain models, pure Dart integer-cent/SHA-256 calculators, and `evaluate-markdowns` / `multichannel-sync` / `process-payout` Edge Functions (Tasks 2.1–2.5).
- [ ] **Phase 3: Flutter UI Integration and Role Workflows** - All 6 role-workflow screen groups (`ItemIntakeWizard`, `AuthInspection`, `InventoryMarkdown`, `ConsignorPortal/Ledger`, `ShopperCatalog/Provenance`, `DisputeResolution/Sustainability`) (Tasks 3.1–3.6).
- [ ] **Phase 4: Edge-Case Hardening and Automated Tests** - `OfflineIntakeQueueService` idempotent sync, `test/unit/` math/hash suite, and `test/widget/` RBAC/concurrency/escrow suite (Tasks 4.1–4.3).

## Phase Details

### Phase 1: Database, RLS, and Authentication Foundation
**Goal**: Deliver the locked Flutter Clean Architecture scaffold, PostgreSQL 15 schema with JWT claims sync and RLS, atomic financial/lifecycle RPCs, Dark-First Editorial Vault design tokens, and role-guarded GoRouter auth.
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, FOUND-04, FOUND-05
**Success Criteria** (what must be TRUE):
  1. Flutter project initializes with exact locked dependency versions from `04_TRD.md` and `flutter analyze` passes cleanly.
  2. SQL migrations create all 6 enums, 9 tables, 7 indexes, `sync_profile_claims()` trigger, strict RLS (append-only `consignor_ledger` and `provenance_events`), and 4 atomic `SECURITY DEFINER` RPCs.
  3. `AppColors`, `AppTypography`, and `AppTheme` match `03_UI_Spec.md` with `ThemeMode.dark` default and zero drop shadows in dark mode.
  4. `app_router.dart` enforces role guards across all 12 routes using `authStateProvider` and `app_metadata.role`.
**Plans**: 1/6 plans executed covering 5 atomic tasks (`1.1` – `1.5` from `docs/06_Plan.md`)

Plans:
**Wave 1**
- [x] 01-01: Task 1.1 — Initialize Flutter project (`resaleroute`) with locked `pubspec.yaml` dependencies and folder structure (`04_TRD.md`)
- [ ] 01-02: Task 1.2 — Apply `supabase/migrations/20261112000001_initial_schema.sql` (`05_Schema.md`)

**Wave 2** *(blocked on Wave 1 completion)*
- [ ] 01-03: Task 1.3 — Apply `supabase/migrations/20261112000002_rpc_functions.sql` (`08_TDD.md`, `09_Sequence_Diagrams.md`)
- [ ] 01-04: Task 1.4 — Implement `app_colors.dart`, `app_typography.dart`, and `app_theme.dart` (`03_UI_Spec.md`)

**Wave 3** *(blocked on Wave 2 completion)*
- [ ] 01-05: Task 1.5a — Build `AppUser`/`UserRole`, `AuthRepository`, Riverpod `authStateProvider`, and 11 navigable route screen shells (`02_AppFlow.md`)

**Wave 4** *(sequentially after 01-05)*
- [ ] 01-06: Task 1.5b — Build `AuthLoginScreen`, `app_router.dart` (12 routes + 5-role guards), `app.dart`, `main.dart`, and `router_guard_test.dart` (`02_AppFlow.md`)

### Phase 2: Core Backend Logic, Calculators, and Edge Functions
**Goal**: Implement immutable Freezed models, pure Dart integer-cent/basis-point/SHA-256 calculators, and all three Supabase Deno Edge Functions.
**Depends on**: Phase 1
**Requirements**: CORE-01, CORE-02, CORE-03, CORE-04, CORE-05
**Success Criteria** (what must be TRUE):
  1. All 5 Freezed domain models generate cleanly via `build_runner` using `int` cents/bps exclusively (zero `double` currency fields).
  2. `SplitCalculator`, `MarkdownCalculator`, and `ProvenanceHasher` match exact formulas in `08_TDD.md`.
  3. `evaluate-markdowns` runs on daily `00:00 UTC` `pg_cron` schedule, `multichannel-sync` signs webhooks with HMAC-SHA256 and exponential backoff, and `process-payout` enforces idempotent `payout_debit` ledger inserts.
**Plans**: 5 atomic tasks (Tasks 2.1 – 2.5 from `docs/06_Plan.md`)

Plans:
- [ ] 02-01: Task 2.1 — Generate Freezed domain models (`ItemModel`, `AuthenticationModel`, `LedgerEntryModel`, `ProvenanceEventModel`, `DisputeModel`)
- [ ] 02-02: Task 2.2 — Implement pure Dart calculators (`split_calculator.dart`, `markdown_calculator.dart`, `provenance_hasher.dart`)
- [ ] 02-03: Task 2.3 — Implement `evaluate-markdowns` Edge Function + `pg_cron` schedule
- [ ] 02-04: Task 2.4 — Implement `multichannel-sync` Edge Function with HMAC-SHA256 signing
- [ ] 02-05: Task 2.5 — Implement `process-payout` Edge Function with idempotent ledger debits

### Phase 3: Flutter UI Integration and Role Workflows
**Goal**: Deliver all role-based Flutter workflows adhering strictly to `03_UI_Spec.md` tokens, `02_AppFlow.md` state transitions, and Supabase backend integration.
**Depends on**: Phase 2
**Requirements**: UI-01, UI-02, UI-03, UI-04, UI-05, UI-06
**Success Criteria** (what must be TRUE):
  1. Boutique staff can complete 4-step garment intake with >=4 EXIF-stripped WebP photos (`<= 400KB`), condition grading, split preview, and printable QR tag modal.
  2. Authenticators can inspect private signed-URL macro imagery and issue/reject cryptographic authenticity certificates.
  3. Boutique staff/owners can filter aging stock, view 30/60/90d countdowns, toggle pause, and force markdowns.
  4. Consignors can view status pipelines, dual-segment `LedgerSplitRow` bars, and trigger payouts (`>= 2000` cents, zero open disputes).
  5. Shoppers can browse catalog, scan QR tags (with manual SKU fallback), inspect provenance & impact badges, purchase with concurrent lock handling, and open 7-day return disputes; owners can resolve disputes and view `fl_chart` sustainability analytics.
**Plans**: 6 atomic tasks (Tasks 3.1 – 3.6 from `docs/06_Plan.md`)

Plans:
- [ ] 03-01: Task 3.1 — `ItemIntakeWizardScreen`
- [ ] 03-02: Task 3.2 — `AuthReviewQueueScreen` & `AuthInspectionScreen`
- [ ] 03-03: Task 3.3 — `InventoryMarkdownScreen`
- [ ] 03-04: Task 3.4 — `ConsignorPortalScreen` & `ConsignorLedgerScreen`
- [ ] 03-05: Task 3.5 — `ShopperCatalogScreen` & `ProductProvenanceScreen`
- [ ] 03-06: Task 3.6 — `DisputeResolutionScreen` & `SustainabilityReportScreen`

### Phase 4: Edge-Case Hardening and Automated Tests
**Goal**: Add offline intake queue persistence/sync and verify financial, cryptographic, RBAC, concurrency, and escrow invariants through automated unit and widget tests.
**Depends on**: Phase 3
**Requirements**: QUAL-01, QUAL-02, QUAL-03
**Success Criteria** (what must be TRUE):
  1. Interrupted intake sessions persist locally via `OfflineIntakeQueueService` and sync idempotently without duplicate SKUs when connectivity returns.
  2. `test/unit/` verifies integer-cent splits, basis-point half-up rounding, SHA-256 hash chaining, and 30/60/90d markdown transitions.
  3. `test/widget/` verifies role guard isolation, concurrent purchase locking (`"Item Just Sold"`), and dispute escrow freezes.
**Plans**: 3 atomic tasks (Tasks 4.1 – 4.3 from `docs/06_Plan.md`)

Plans:
- [ ] 04-01: Task 4.1 — `OfflineIntakeQueueService`
- [ ] 04-02: Task 4.2 — Unit tests in `test/unit/`
- [ ] 04-03: Task 4.3 — Widget & integration tests in `test/widget/`

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Database, RLS, and Authentication Foundation | 1/6 | In Progress | - |
| 2. Core Backend Logic, Calculators, and Edge Functions | 0/5 | Not started | - |
| 3. Flutter UI Integration and Role Workflows | 0/6 | Not started | - |
| 4. Edge-Case Hardening and Automated Tests | 0/3 | Not started | - |
