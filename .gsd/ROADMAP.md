# ResaleRoute — Implementation Roadmap

**Specification:** [SPEC.md](file:///d:/ResaleRoute/.gsd/SPEC.md) (`FINALIZED`)  
**Source Plan:** [06_Plan.md](file:///d:/ResaleRoute/docs/06_Plan.md)

## Non-Negotiable Invariants (Enforced Across All Phases)
- **Financial Math:** Integer cents (`int`) and basis points (`10000 = 100%`) only. Never use `double` for currency.
- **Immutability:** `consignor_ledger` and `provenance_events` are strictly append-only (`INSERT` only; never `UPDATE` or `DELETE`).
- **Dual-State Tracking:** On completion of any task, `gsd-executor` MUST update both `.gsd/STATE.md` (plus `.planning/STATE.md`) AND check off `[x]` with modified file paths in `docs/06_Plan.md`.

---

## Phase 1: Database, RLS, and Authentication Foundation
**Goal:** Establish the locked Flutter Clean Architecture project skeleton, PostgreSQL schema with JWT claims & RLS, atomic financial/lifecycle RPCs, Exact Dark-First UI design tokens, and role-guarded GoRouter authentication.  
**Depends on:** Nothing (Foundation Phase)

### Tasks (`docs/06_Plan.md` 1.1 – 1.5)
- [ ] **1.1** Initialize Flutter project (`resaleroute`) with locked `pubspec.yaml` dependencies and folder structure from `04_TRD.md`.
- [ ] **1.2** Apply `supabase/migrations/20261112000001_initial_schema.sql` containing enums, tables, indexes, and RLS policies from `05_Schema.md`.
- [ ] **1.3** Apply `supabase/migrations/20261112000002_rpc_functions.sql` containing atomic stored procedures (`complete_item_intake`, `submit_auth_verdict`, `process_order_and_split`, `resolve_dispute`) from `08_TDD.md` and `09_Sequence_Diagrams.md`.
- [ ] **1.4** Implement `app_colors.dart`, `app_typography.dart`, and `app_theme.dart` with exact dark/light hex tokens from `03_UI_Spec.md`.
- [ ] **1.5** Build `AuthRepository`, Riverpod `authStateProvider`, and `app_router.dart` with role-based redirect guards matching `02_AppFlow.md`.

### Verification Criteria
1. `flutter analyze` passes with zero errors or warnings.
2. SQL migrations define all 6 enums, 9 tables, 7 indexes, `sync_profile_claims()` trigger, strict RLS policies (including append-only enforcement), and 4 atomic `SECURITY DEFINER` RPCs.
3. Unauthenticated users and unauthorized roles are deterministically redirected by `app_router.dart` according to `app_metadata.role`.

---

## Phase 2: Core Backend Logic, Calculators, and Edge Functions
**Goal:** Implement immutable Freezed domain models, pure Dart integer-cent & SHA-256 calculators, and the three Deno Edge Functions (`evaluate-markdowns`, `multichannel-sync`, `process-payout`).  
**Depends on:** Phase 1

### Tasks (`docs/06_Plan.md` 2.1 – 2.5)
- [ ] **2.1** Generate immutable Freezed models (`ItemModel`, `AuthenticationModel`, `LedgerEntryModel`, `ProvenanceEventModel`, `DisputeModel`) in `lib/features/*/domain/`.
- [ ] **2.2** Implement pure Dart domain utilities: `split_calculator.dart` (basis points to integer cents), `markdown_calculator.dart` (30/60/90-day discount math), and `provenance_hasher.dart` (SHA-256 chain hashing).
- [ ] **2.3** Implement Supabase Edge Function `supabase/functions/evaluate-markdowns/index.ts` and schedule daily `00:00 UTC` execution via `pg_cron`.
- [ ] **2.4** Implement Supabase Edge Function `supabase/functions/multichannel-sync/index.ts` with HMAC-SHA256 webhook signing and exponential backoff retries.
- [ ] **2.5** Implement Supabase Edge Function `supabase/functions/process-payout/index.ts` with idempotent ledger debit handling.

### Verification Criteria
1. `dart run build_runner build --delete-conflicting-outputs` and `flutter analyze` succeed cleanly.
2. Zero floating-point (`double`) types used in any monetary model or calculator field.
3. Edge functions implement exact integer half-up math, HMAC-SHA256 signatures, and idempotent append-only ledger debits.

---

## Phase 3: Flutter UI Integration and Role Workflows
**Goal:** Build all role-specific Flutter presentation screens and feature repositories adhering strictly to the Dark-First Editorial Vault design system and deterministic item state machine.  
**Depends on:** Phase 2

### Tasks (`docs/06_Plan.md` 3.1 – 3.6)
- [ ] **3.1** Build `ItemIntakeWizardScreen` (4-step stepper, EXIF-stripped WebP compression `<= 400KB`, condition grading checklist, split preview, and printable QR tag modal).
- [ ] **3.2** Build `AuthReviewQueueScreen` and `AuthInspectionScreen` with pinch-to-zoom macro gallery (`auth-evidence` signed URLs) and cryptographic certificate issuance.
- [ ] **3.3** Build `InventoryMarkdownScreen` for boutique staff with aging filters, countdown pills, and owner markdown pause toggles / force markdown action.
- [ ] **3.4** Build `ConsignorPortalScreen` and `ConsignorLedgerScreen` featuring item status pipelines, `LedgerSplitRow` visualization bars, and payout request triggers (`>= 2000` cents, zero open disputes).
- [ ] **3.5** Build `ShopperCatalogScreen` and `ProductProvenanceScreen` with QR scanner integration (plus manual SKU fallback), chain-of-custody timeline, concurrent checkout handling, and carbon/water impact badges.
- [ ] **3.6** Build `DisputeResolutionScreen` (7-day return claim intake, escrow freeze indicator, and owner resolution actions) and `SustainabilityReportScreen` using `fl_chart`.

### Verification Criteria
1. All 12 GoRouter routes render with `AppColors`, `AppTypography`, `1px` borders in Dark Mode, and `JetBrains Mono` for all financial/SKU/hash figures.
2. Every role workflow integrates end-to-end with Supabase repositories and atomic RPCs.
3. `flutter analyze` passes cleanly across all features.

---

## Phase 4: Edge-Case Hardening and Automated Tests
**Goal:** Deliver offline intake resilience and comprehensive unit, widget, and integration tests covering financial math, provenance chaining, RBAC guards, concurrency locks, and dispute escrow freezes.  
**Depends on:** Phase 3

### Tasks (`docs/06_Plan.md` 4.1 – 4.3)
- [ ] **4.1** Implement `OfflineIntakeQueueService` so interrupted intake sessions persist locally (`DraftIntakeJob` + WebP paths) and sync idempotently upon network restoration.
- [ ] **4.2** Write unit tests in `test/unit/` verifying integer-cent split calculations, basis-point half-up rounding, SHA-256 provenance chaining, and 30/60/90-day markdown transitions.
- [ ] **4.3** Write widget and integration tests in `test/widget/` verifying role guard isolation, concurrent purchase locking (`FOR UPDATE NOWAIT` / `"Item Just Sold"`), and dispute escrow freezes.

### Verification Criteria
1. `flutter test` passes 100% of unit and widget tests.
2. `OfflineIntakeQueueService` handles offline persistence and idempotent retry without duplicate items or lost media.
3. `flutter analyze` reports zero issues across `lib/` and `test/`.
