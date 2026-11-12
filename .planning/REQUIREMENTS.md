# Requirements: ResaleRoute

**Defined:** 2026-11-12  
**Core Value:** Guarantee 100% deterministic financial reconciliation, tamper-evident luxury provenance, and zero double-sells across the entire boutique consignment lifecycle.

## v1 Requirements

### Phase 1: Foundation, Database, RLS & Auth
- [ ] **FOUND-01**: Initialize Flutter project (`resaleroute`) with locked dependencies and feature-first folder tree (`04_TRD.md`, Task 1.1)
- [ ] **FOUND-02**: Apply `20261112000001_initial_schema.sql` with 6 enums, 9 tables, 7 indexes, `sync_profile_claims()` trigger, and strict RLS (`05_Schema.md`, Task 1.2)
- [ ] **FOUND-03**: Apply `20261112000002_rpc_functions.sql` with atomic RPCs (`complete_item_intake`, `submit_auth_verdict`, `process_order_and_split`, `resolve_dispute`) (`08_TDD.md`, Task 1.3)
- [ ] **FOUND-04**: Implement `app_colors.dart`, `app_typography.dart`, and `app_theme.dart` matching Dark/Light tokens and zero dark-mode shadows (`03_UI_Spec.md`, Task 1.4)
- [ ] **FOUND-05**: Build `AuthRepository`, Riverpod `authStateProvider`, and `app_router.dart` with role-based redirect guards across all 12 routes (`02_AppFlow.md`, Task 1.5)

### Phase 2: Domain Models, Calculators & Edge Functions
- [ ] **CORE-01**: Generate immutable Freezed models (`ItemModel`, `AuthenticationModel`, `LedgerEntryModel`, `ProvenanceEventModel`, `DisputeModel`) in `lib/features/*/domain/` (Task 2.1)
- [ ] **CORE-02**: Implement pure Dart integer-cent & SHA-256 utilities (`split_calculator.dart`, `markdown_calculator.dart`, `provenance_hasher.dart`) (Task 2.2)
- [ ] **CORE-03**: Implement `evaluate-markdowns` Deno Edge Function + daily `00:00 UTC` `pg_cron` schedule (`US-04`, Task 2.3)
- [ ] **CORE-04**: Implement `multichannel-sync` Deno Edge Function with HMAC-SHA256 webhook signing & backoff retries (`US-03`, Task 2.4)
- [ ] **CORE-05**: Implement `process-payout` Deno Edge Function with idempotent `payout_debit` ledger handling (`US-05`, Task 2.5)

### Phase 3: Role-Based UI Workflows
- [ ] **UI-01**: Build `ItemIntakeWizardScreen` (4-step stepper, EXIF-stripped WebP `<= 400KB`, condition checklist, split preview, QR tag modal) (`US-01`, `US-03`, Task 3.1)
- [ ] **UI-02**: Build `AuthReviewQueueScreen` & `AuthInspectionScreen` (pinch-to-zoom macro gallery, serial check, signed provenance certificate) (`US-02`, Task 3.2)
- [ ] **UI-03**: Build `InventoryMarkdownScreen` (aging filters, 30/60/90d countdown pills, pause toggles, force markdown) (`US-04`, Task 3.3)
- [ ] **UI-04**: Build `ConsignorPortalScreen` & `ConsignorLedgerScreen` (status pipelines, `LedgerSplitRow` bars, `>= 2000` cents payout request) (`US-05`, Task 3.4)
- [ ] **UI-05**: Build `ShopperCatalogScreen` & `ProductProvenanceScreen` (QR scanner + manual SKU fallback, custody timeline, checkout lock handling, CO2/water badges) (`US-06`, Task 3.5)
- [ ] **UI-06**: Build `DisputeResolutionScreen` & `SustainabilityReportScreen` (7-day return claims, escrow freeze indicator, `fl_chart` impact aggregates) (`US-07`, `US-08`, Task 3.6)

### Phase 4: Hardening & Automated Verification
- [ ] **QUAL-01**: Implement `OfflineIntakeQueueService` for local draft persistence and idempotent sync on reconnection (`08_TDD.md`, Task 4.1)
- [ ] **QUAL-02**: Write unit tests in `test/unit/` for integer-cent splits, basis-point half-up rounding, SHA-256 chaining, and 30/60/90d markdowns (Task 4.2)
- [ ] **QUAL-03**: Write widget/integration tests in `test/widget/` for role guard isolation, concurrent purchase locking, and dispute escrow freezes (Task 4.3)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Direct P2P marketplace | Physical boutique intake & custody required for MVP (`01_PRD.md`) |
| Autonomous AI authentication | Human authenticator verdict required for luxury items |
| Live auction & bidding | Fixed-price + scheduled markdowns only |
| Cross-border customs brokerage | Domestic regional couriers per boutique |
| Custom POS hardware | Standard OS print dialogs & camera scanners |

## Traceability

| Requirement | Phase | Task | Status |
|-------------|-------|------|--------|
| FOUND-01 | Phase 1 | 1.1 | Pending |
| FOUND-02 | Phase 1 | 1.2 | Pending |
| FOUND-03 | Phase 1 | 1.3 | Pending |
| FOUND-04 | Phase 1 | 1.4 | Pending |
| FOUND-05 | Phase 1 | 1.5 | Pending |
| CORE-01 | Phase 2 | 2.1 | Pending |
| CORE-02 | Phase 2 | 2.2 | Pending |
| CORE-03 | Phase 2 | 2.3 | Pending |
| CORE-04 | Phase 2 | 2.4 | Pending |
| CORE-05 | Phase 2 | 2.5 | Pending |
| UI-01 | Phase 3 | 3.1 | Pending |
| UI-02 | Phase 3 | 3.2 | Pending |
| UI-03 | Phase 3 | 3.3 | Pending |
| UI-04 | Phase 3 | 3.4 | Pending |
| UI-05 | Phase 3 | 3.5 | Pending |
| UI-06 | Phase 3 | 3.6 | Pending |
| QUAL-01 | Phase 4 | 4.1 | Pending |
| QUAL-02 | Phase 4 | 4.2 | Pending |
| QUAL-03 | Phase 4 | 4.3 | Pending |

**Coverage:**
- v1 requirements: 19 total
- Mapped to phases: 19
- Unmapped: 0 ✓

---
*Requirements defined: 2026-11-12*  
*Last updated: 2026-11-12 after initial synthesis from docs/*
