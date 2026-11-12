---
phase: 01-database-rls-and-authentication-foundation
plan: 05
subsystem: auth
tags: [flutter, riverpod, supabase-auth, rbac, app-metadata, editorial-vault]

# Dependency graph
requires:
  - phase: 01-database-rls-and-authentication-foundation
    plan: 01
    provides: Flutter clean architecture scaffold and locked flutter_riverpod / supabase_flutter packages
  - phase: 01-database-rls-and-authentication-foundation
    plan: 04
    provides: AppColors.of(context), AppTypography, AppSpacing, and AppTheme.cardShadows tokens
provides:
  - UserRole enum covering all 5 PostgreSQL user_role values and defaultHomeRoute mapping
  - AppUser immutable entity parsing role and boutiqueId strictly from Supabase user.appMetadata
  - AuthRepository interface, SupabaseAuthRepository implementation, and Riverpod providers (authRepositoryProvider, authStateProvider, currentUserProvider)
  - All 11 navigable protected and storefront Editorial Vault route screen shells with exact docs/02_AppFlow.md parameter contracts
affects:
  - 01-06 (GoRouter wiring, AuthLoginScreen, app.dart, main.dart, and router_guard_test.dart)
  - Phase 3 (Role-based UI workflow implementations building on the 11 screen shells)
  - Phase 4 (Unit and widget tests overriding authRepositoryProvider)

# Actuals (#2632)
actuals:
  tokens: 11647
  tasks: 3
  commits: 3

commits: 3
plan_head_before: 62a17628d59515d53035399dfc0162d0d7636b67
plan_head_after: b140ffc5239872d462d4269c9998e19fcb72a0a3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Abstract interface AuthRepository with SupabaseAuthRepository implementation enabling Riverpod ProviderScope overrides"
    - "Strict JWT app_metadata claim parsing in AppUser.fromSupabaseUser (role and boutique_id never read from client-writable userMetadata)"
    - "Editorial Vault route shell styling using AppColors.of(context), AppTypography, AppSpacing, and AppTheme.cardShadows"

key-files:
  created:
    - lib/features/auth/domain/app_user.dart
    - lib/features/auth/data/auth_repository.dart
    - lib/features/auth/presentation/auth_providers.dart
    - lib/features/intake_grading/presentation/boutique_dashboard_screen.dart
    - lib/features/intake_grading/presentation/item_intake_wizard_screen.dart
    - lib/features/inventory_markdown/presentation/inventory_markdown_screen.dart
    - lib/features/authentication_partner/presentation/auth_review_queue_screen.dart
    - lib/features/authentication_partner/presentation/auth_inspection_screen.dart
    - lib/features/consignor_ledger/presentation/consignor_portal_screen.dart
    - lib/features/consignor_ledger/presentation/consignor_ledger_screen.dart
    - lib/features/provenance_storefront/presentation/shopper_catalog_screen.dart
    - lib/features/provenance_storefront/presentation/product_provenance_screen.dart
    - lib/features/returns_disputes/presentation/dispute_resolution_screen.dart
    - lib/features/sustainability/presentation/sustainability_report_screen.dart
  modified: []

key-decisions:
  - "AppUser.fromSupabaseUser reads role and boutique_id exclusively from user.appMetadata (server-synced by sync_profile_claims()), safely defaulting unknown roles to UserRole.shopper."
  - "authRepositoryProvider wraps Supabase.instance.client access and throws an explicit StateError if Supabase is uninitialized so tests must explicitly override authRepositoryProvider rather than failing silently."

patterns-established:
  - "Auth testability boundary: UI and router providers depend on abstract interface AuthRepository rather than SupabaseClient directly."
  - "Route shell parameter contract: all 11 screens accept typed optional query or required path parameters matching docs/02_AppFlow.md §2."

requirements-completed: [FOUND-05]

coverage:
  - id: D1
    description: "UserRole enum maps all 5 PostgreSQL user_role values and defaultHomeRoute, and AppUser.fromSupabaseUser parses role and boutiqueId strictly from user.appMetadata"
    requirement: "FOUND-05"
    verification:
      - kind: other
        ref: "node role & appMetadata check on lib/features/auth/domain/app_user.dart && flutter analyze"
        status: pass
    human_judgment: false
  - id: D2
    description: "AuthRepository interface, SupabaseAuthRepository, and Riverpod providers (authRepositoryProvider, authStateProvider, currentUserProvider) expose reactive session state"
    requirement: "FOUND-05"
    verification:
      - kind: other
        ref: "node authStateProvider check on lib/features/auth/presentation/auth_providers.dart && flutter analyze"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 11 protected and storefront route screen shells compile cleanly with Editorial Vault tokens (AppColors.of, AppTypography) and exact docs/02_AppFlow.md parameter signatures"
    requirement: "FOUND-05"
    verification:
      - kind: other
        ref: "node class & AppColors.of check across all 11 screen files && flutter analyze"
        status: pass
    human_judgment: false

# Metrics
duration: 5 min
completed: 2026-11-12
status: complete
---

# Phase 01 Plan 05: Auth Foundation & 11 Navigable Route Screen Shells Summary

**Implemented `UserRole`/`AppUser` (`appMetadata`-only RBAC claims), `AuthRepository`/`SupabaseAuthRepository`, Riverpod `authStateProvider`/`currentUserProvider`, and all 11 Editorial Vault navigable route screen shells passing `flutter analyze` with zero issues.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-11-12T18:49:15Z
- **Completed:** 2026-11-12T18:53:59Z
- **Tasks:** 3
- **Files modified:** 14 created

## Accomplishments
- Implemented `UserRole` enum (`boutiqueOwner`, `boutiqueStaff`, `consignor`, `authenticator`, `shopper`) with exact PostgreSQL `dbValue` mappings, safe `fromString` fallback to `shopper`, `defaultHomeRoute` resolution, and immutable `AppUser.fromSupabaseUser` reading `role` and `boutique_id` strictly from `user.appMetadata` (T-01-10).
- Implemented `AuthRepository` interface, `SupabaseAuthRepository` (`onAuthStateChange`, `currentUser`, `signInWithEmailAndPassword`, `signUp`, `signOut`), and Riverpod providers (`authRepositoryProvider`, `authStateProvider`, `currentUserProvider`).
- Implemented the first 6 protected route screen shells (`BoutiqueDashboardScreen`, `ItemIntakeWizardScreen`, `InventoryMarkdownScreen`, `AuthReviewQueueScreen`, `AuthInspectionScreen`, `ConsignorPortalScreen`) using `AppColors.of(context)`, `AppTypography`, `AppSpacing`, and `AppTheme.cardShadows(context)`.
- Implemented the remaining 5 route screen shells (`ConsignorLedgerScreen`, `ShopperCatalogScreen`, `ProductProvenanceScreen`, `DisputeResolutionScreen`, `SustainabilityReportScreen`) and verified the full workspace with `flutter analyze` (`No issues found!`).

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement AppUser/UserRole, AuthRepository, and Riverpod authStateProvider** - `4c905a2` (feat)
2. **Task 2: Implement first 6 navigable route screen shells (staff, auth-partner, consignor portal)** - `c8ad6af` (feat)
3. **Task 3: Implement remaining 5 navigable route screen shells and verify flutter analyze** - `b140ffc` (feat)

## Files Created/Modified
- `lib/features/auth/domain/app_user.dart` - `UserRole` enum and `AppUser` entity parsing `appMetadata` claims.
- `lib/features/auth/data/auth_repository.dart` - `AuthRepository` interface and `SupabaseAuthRepository`.
- `lib/features/auth/presentation/auth_providers.dart` - `authRepositoryProvider`, `authStateProvider`, and `currentUserProvider`.
- `lib/features/intake_grading/presentation/boutique_dashboard_screen.dart` - `/staff/dashboard` shell (`boutiqueId`).
- `lib/features/intake_grading/presentation/item_intake_wizard_screen.dart` - `/staff/intake` shell (`consignorId`).
- `lib/features/inventory_markdown/presentation/inventory_markdown_screen.dart` - `/staff/inventory` shell (`filterStatus`).
- `lib/features/authentication_partner/presentation/auth_review_queue_screen.dart` - `/auth-partner/queue` shell (`priorityFilter`).
- `lib/features/authentication_partner/presentation/auth_inspection_screen.dart` - `/auth-partner/review/:id` shell (`itemId`).
- `lib/features/consignor_ledger/presentation/consignor_portal_screen.dart` - `/consignor/overview` shell.
- `lib/features/consignor_ledger/presentation/consignor_ledger_screen.dart` - `/consignor/ledger` shell (`payoutStatus`).
- `lib/features/provenance_storefront/presentation/shopper_catalog_screen.dart` - `/shop/catalog` shell (`category`, `grade`).
- `lib/features/provenance_storefront/presentation/product_provenance_screen.dart` - `/shop/item/:id` shell (`itemId`, `qrToken`).
- `lib/features/returns_disputes/presentation/dispute_resolution_screen.dart` - `/disputes/:id` shell (`disputeId`).
- `lib/features/sustainability/presentation/sustainability_report_screen.dart` - `/impact` shell (`timeframe`).

## Decisions Made
- `AppUser.fromSupabaseUser` reads `role` and `boutique_id` strictly from `user.appMetadata` (never `user.userMetadata`), falling back safely to `UserRole.shopper` if missing or unrecognized.
- `authRepositoryProvider` catches uninitialized `Supabase.instance` errors and throws an explicit `StateError` instructing callers or tests to initialize Supabase or override `authRepositoryProvider`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Ready for Plan `01-06`: GoRouter reactive redirect guards (`app_router.dart`), `AuthLoginScreen`, `app.dart`, `main.dart`, and `test/widget/router_guard_test.dart`, which will also check off `docs/06_Plan.md` Task `1.5` and finalize `FOUND-05`.
- Remote `supabase db push` from Plan `01-03` remains deferred per user direction until backend connection.

---
*Phase: 01-database-rls-and-authentication-foundation*
*Completed: 2026-11-12*

## Self-Check: PASSED
- All 14 created source files verified present on disk.
- All 3 task commits (`4c905a2`, `c8ad6af`, `b140ffc`) verified in git history (`HEAD`).
