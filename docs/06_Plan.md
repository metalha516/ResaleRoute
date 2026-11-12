# 06 — Atomic Implementation Plan: ResaleRoute

> **Agent Instruction:** Execute tasks strictly in sequential order. After completing and verifying each task via `flutter analyze` and tests, mark `[ ]` as `[x]` and append the modified file paths.

## Phase 1: Database, RLS & Authentication Foundation
- [ ] **1.1** Initialize Flutter project (`resaleroute`) with locked `pubspec.yaml` dependencies and folder structure from `04_TRD.md`.
- [ ] **1.2** Apply `supabase/migrations/20261112000001_initial_schema.sql` containing enums, tables, indexes, and RLS policies from `05_Schema.md`.
- [ ] **1.3** Apply `supabase/migrations/20261112000002_rpc_functions.sql` containing atomic stored procedures (`complete_item_intake`, `submit_auth_verdict`, `process_order_and_split`, `resolve_dispute`) from `08_TDD.md`.
- [ ] **1.4** Implement `app_colors.dart`, `app_typography.dart`, and `app_theme.dart` with exact dark/light hex tokens from `03_UI_Spec.md`.
- [ ] **1.5** Build `AuthRepository`, Riverpod `authStateProvider`, and `app_router.dart` with role-based redirect guards matching `02_AppFlow.md`.

## Phase 2: Core Domain Models, Calculators & Edge Functions
- [ ] **2.1** Generate immutable Freezed models (`ItemModel`, `AuthenticationModel`, `LedgerEntryModel`, `ProvenanceEventModel`, `DisputeModel`) in `lib/features/*/domain/`.
- [ ] **2.2** Implement pure Dart domain utilities: `split_calculator.dart` (basis points to integer cents), `markdown_calculator.dart` (30/60/90-day discount math), and `provenance_hasher.dart` (SHA-256 chain hashing).
- [ ] **2.3** Implement Supabase Edge Function `supabase/functions/evaluate-markdowns/index.ts` and schedule daily `00:00 UTC` execution via `pg_cron`.
- [ ] **2.4** Implement Supabase Edge Function `supabase/functions/multichannel-sync/index.ts` with HMAC-SHA256 webhook signing.
- [ ] **2.5** Implement Supabase Edge Function `supabase/functions/process-payout/index.ts` with idempotent ledger debit handling.

## Phase 3: Flutter Role-Based UI Workflows
- [ ] **3.1** Build `ItemIntakeWizardScreen` (4-step stepper, WebP photo compression, condition grading checklist, split preview, and printable QR tag modal).
- [ ] **3.2** Build `AuthReviewQueueScreen` and `AuthInspectionScreen` with pinch-to-zoom macro gallery and cryptographic certificate issuance.
- [ ] **3.3** Build `InventoryMarkdownScreen` for boutique staff with aging filters, countdown pills, and manual markdown pause toggles.
- [ ] **3.4** Build `ConsignorPortalScreen` and `ConsignorLedgerScreen` featuring item status pipelines, split visualization bars, and payout request triggers.
- [ ] **3.5** Build `ShopperCatalogScreen` and `ProductProvenanceScreen` with QR scanner integration, chain-of-custody timeline, and carbon/water impact badges.
- [ ] **3.6** Build `DisputeResolutionScreen` (return claim intake, escrow freeze indicator, and owner resolution actions) and `SustainabilityReportScreen` using `fl_chart`.

## Phase 4: Offline Resilience, Edge-Case Hardening & Automated Tests
- [ ] **4.1** Implement `OfflineIntakeQueueService` so interrupted intake sessions persist locally and sync idempotently upon network restoration.
- [ ] **4.2** Write unit tests in `test/unit/` verifying integer-cent split calculations, basis-point rounding, SHA-256 provenance chaining, and 30/60/90-day markdown transitions.
- [ ] **4.3** Write widget and integration tests in `test/widget/` verifying role guard isolation, concurrent purchase locking, and dispute escrow freezes.