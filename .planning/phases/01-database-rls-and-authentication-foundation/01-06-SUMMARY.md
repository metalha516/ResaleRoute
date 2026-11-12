---
phase: 01-database-rls-and-authentication-foundation
plan: 06
subsystem: auth
tags: [flutter, riverpod, go-router, rbac, theme-mode-dark, widget-tests]

# Dependency graph
requires:
  - phase: 01-database-rls-and-authentication-foundation
    plan: 01
    provides: Flutter project scaffold, pubspec dependencies, and strict analysis_options.yaml
  - phase: 01-database-rls-and-authentication-foundation
    plan: 02
    provides: PostgreSQL user_role enum and sync_profile_claims() JWT app_metadata contract
  - phase: 01-database-rls-and-authentication-foundation
    plan: 04
    provides: AppColors.of(context), AppTypography, AppSpacing, and AppTheme.darkTheme/lightTheme
  - phase: 01-database-rls-and-authentication-foundation
    plan: 05
    provides: UserRole, AppUser, AuthRepository, Riverpod auth providers, and 11 Editorial Vault route screen shells
provides:
  - Editorial Vault AuthLoginScreen with duplicate-tap lock and generic AuthException error handling
  - 12-route GoRouter configuration (appRouterProvider) with reactive currentUserProvider refreshListenable
  - Pure resolveRoleRedirect guard enforcing public routes, 5-role RBAC matrix, and open-redirect prevention
  - ResaleRouteApp root MaterialApp.router defaulting to ThemeMode.dark (#0B0D10) and main.dart ProviderScope bootstrap
  - Standalone test/widget/router_guard_test.dart verifying all 5 roles, public access, open-redirect blocks, and ThemeMode.dark
affects:
  - Phase 2 (domain models and calculators build cleanly inside verified Flutter workspace)
  - Phase 3 (all 12 GoRouter routes and role-guarded screens ready for full workflow integration)
  - Phase 4 (widget/integration tests extend router_guard_test.dart patterns with authRepositoryProvider overrides)

# Actuals (#2632)
actuals:
  tokens: 10302
  tasks: 3
  commits: 3

commits: 3
plan_head_before: ca3d88ccf9977dcf81756c91849f2b3e27679e84
plan_head_after: cce98f6110e180df2dbf231c5cf7ee384b92e920

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pure unit-testable resolveRoleRedirect helper separated from GoRouter widget lifecycle"
    - "Single GoRouter instance in appRouterProvider listening to currentUserProvider via ChangeNotifier refreshListenable"
    - "Strict open-redirect validation on /login?redirectUrl=... requiring single leading slash, no scheme/authority/backslash, and target role permission"

key-files:
  created:
    - lib/features/auth/presentation/auth_login_screen.dart
    - lib/core/router/app_router.dart
    - lib/app.dart
    - test/widget/router_guard_test.dart
  modified:
    - lib/main.dart
    - docs/06_Plan.md
    - .gsd/STATE.md

key-decisions:
  - "appRouterProvider listens directly to currentUserProvider and caches the latest AppUser before triggering refreshListenable, preventing stale user reads during Riverpod StreamProvider notification propagation."
  - "main.dart uses Supabase.initialize(..., publishableKey: ...) matching supabase_flutter 2.x non-deprecated API and only initializes when SUPABASE_URL and SUPABASE_ANON_KEY dart-defines are both non-empty."
  - "resolveRoleRedirect enforces exact path-segment matching and blocks scheme, authority, '//', and backslash open-redirect vectors before falling back to user.role.defaultHomeRoute."

patterns-established:
  - "Router testability pattern: pure resolveRoleRedirect unit tests paired with ProviderScope(overrides: [authRepositoryProvider.overrideWithValue(...)]) widget integration tests."
  - "GoogleFonts.config.allowRuntimeFetching = false in widget test setUpAll to avoid offline HTTP font-fetch failures in headless test environments."

requirements-completed: [FOUND-05]

coverage:
  - id: D1
    description: "AuthLoginScreen, 12-route GoRouter with 5-role reactive guards (resolveRoleRedirect), ResaleRouteApp (ThemeMode.dark), and main.dart (ProviderScope) compile cleanly"
    requirement: "FOUND-05"
    verification:
      - kind: other
        ref: "flutter analyze (No issues found!)"
        status: pass
    human_judgment: false
  - id: D2
    description: "router_guard_test.dart verifies unauthenticated public access, all 5 UserRole RBAC matrices, safe redirectUrl validation, ThemeMode.dark (#0B0D10) rendering, and reactive auth transitions"
    requirement: "FOUND-05"
    verification:
      - kind: unit
        ref: "test/widget/router_guard_test.dart#resolveRoleRedirect & ResaleRouteApp widget integration (flutter test: 11/11 passed)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Task 1.5 marked complete in docs/06_Plan.md and synchronized across .gsd/STATE.md and .planning/STATE.md"
    requirement: "FOUND-05"
    verification:
      - kind: other
        ref: "docs/06_Plan.md Task 1.5 checkoff verification + flutter pub get && flutter analyze && flutter test"
        status: pass
    human_judgment: false

# Metrics
duration: 7 min
completed: 2026-11-13
status: complete
---

# Phase 01 Plan 06: GoRouter Role Guards, AuthLoginScreen & Dark-First Bootstrap Summary

**Wired `AuthLoginScreen`, all 12 `docs/02_AppFlow.md` GoRouter routes with pure 5-role `resolveRoleRedirect` guards, `ResaleRouteApp` (`ThemeMode.dark`), `main.dart` (`ProviderScope`), and `test/widget/router_guard_test.dart` passing `flutter analyze` (`No issues found!`) and `flutter test` (`11/11` passed).**

## Performance

- **Duration:** 7 min
- **Started:** 2026-11-13T00:57:22Z
- **Completed:** 2026-11-13T01:04:09Z
- **Tasks:** 3
- **Files modified:** 7 (4 created, 3 modified)

## Accomplishments
- Implemented `AuthLoginScreen` (`lib/features/auth/presentation/auth_login_screen.dart`) with Editorial Vault dark card styling (`AppColors.of(context)`, `AppTypography`, `AppSpacing`, `1px` `borderSubtle`, zero dark-mode shadows), email/password form validation, duplicate-tap loading lock, generic `AuthException` error banner (T-01-12), and public catalog navigation.
- Implemented `app_router.dart` (`lib/core/router/app_router.dart`) registering all 12 `RoutePaths` from `docs/02_AppFlow.md` §2, a pure unit-testable `resolveRoleRedirect` helper enforcing public access (`/login`, `/shop/catalog`, `/shop/item/:id`), protected `/login?redirectUrl=...` redirects, 5-role RBAC isolation, and open-redirect mitigation (T-01-11).
- Implemented `ResaleRouteApp` (`lib/app.dart`) defaulting to `ThemeMode.dark` with `AppTheme.darkTheme` / `AppTheme.lightTheme` and `ProviderScope` + `Supabase.initialize` bootstrap in `lib/main.dart`.
- Created standalone `test/widget/router_guard_test.dart` covering unauthenticated public/protected routes, all 5 `UserRole` matrices, open-redirect prevention, `ThemeMode.dark` (`#0B0D10`) rendering, reactive auth transitions, and `AuthLoginScreen` sign-in navigation.
- Synchronized `docs/06_Plan.md` (checked off Task `1.5`), `.gsd/STATE.md`, and `.planning/STATE.md` after verifying `flutter pub get`, `flutter analyze`, and `flutter test`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement AuthLoginScreen, app_router.dart (12 routes + 5-role guards), app.dart, and main.dart** - `8455eab` (feat)
2. **Task 2: Create test/widget/router_guard_test.dart covering all 5 roles, public routes, and ThemeMode.dark** - `d83b4e3` (test)
3. **Task 3: Run flutter pub get + flutter analyze + flutter test and update dual-state tracking** - `cce98f6` (chore)

## Files Created/Modified
- `lib/features/auth/presentation/auth_login_screen.dart` - Editorial Vault sign-in screen accepting optional `redirectUrl`.
- `lib/core/router/app_router.dart` - `RoutePaths`, pure `resolveRoleRedirect` guard, and `appRouterProvider` across all 12 routes.
- `lib/app.dart` - `ResaleRouteApp` `MaterialApp.router` defaulting to `ThemeMode.dark`.
- `lib/main.dart` - `ProviderScope` bootstrap with guarded `Supabase.initialize(url: ..., publishableKey: ...)`.
- `test/widget/router_guard_test.dart` - Standalone RBAC guard, open-redirect, `ThemeMode.dark`, and reactive auth widget tests.
- `docs/06_Plan.md` - Checked off Task `1.5` with all created/modified auth, router, screen, and test paths.
- `.gsd/STATE.md` - Updated Phase Task Ledger (`1.5` complete, Phase 1 complete, next task `2.1`) while preserving deferred DB push note.

## Decisions Made
- Listened directly to `currentUserProvider` inside `appRouterProvider` and updated the captured `currentUser` before invoking `refreshNotifier.notify()` so `GoRouter.redirect` immediately observes newly emitted users during Riverpod `StreamProvider` updates.
- Used `publishableKey:` instead of deprecated `anonKey:` in `Supabase.initialize` to satisfy `flutter analyze` zero-warning requirements on `supabase_flutter` 2.6.0+.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Updated `Supabase.initialize` parameter from `anonKey` to `publishableKey`**
- **Found during:** Task 1 (`flutter analyze` verification)
- **Issue:** `supabase_flutter` 2.x flagged `anonKey` with `deprecated_member_use` (`'anonKey' is deprecated and shouldn't be used. Use publishableKey instead.`).
- **Fix:** Replaced `anonKey: supabaseAnonKey` with `publishableKey: supabaseAnonKey` in `lib/main.dart`.
- **Files modified:** `lib/main.dart`
- **Verification:** `flutter analyze` exited 0 with `No issues found!`.
- **Committed in:** `8455eab` (Task 1 commit)

**2. [Rule 1 - Bug] Fixed reactive GoRouter redirect reading stale `currentUserProvider` during `authStateProvider` emission**
- **Found during:** Task 2 (widget integration test in `test/widget/router_guard_test.dart`)
- **Issue:** Listening to `authStateProvider` and reading `currentUserProvider` synchronously inside `GoRouter.redirect` left `GoRouter` on `/shop/catalog` when `fakeAuth.emitUser(authenticator)` fired.
- **Fix:** Switched `appRouterProvider` listener to `ref.listen<AppUser?>(currentUserProvider, (_, next) { currentUser = next; refreshNotifier.notify(); })` and passed `currentUser` directly to `resolveRoleRedirect`.
- **Files modified:** `lib/core/router/app_router.dart`
- **Verification:** `flutter test test/widget/router_guard_test.dart` passed all 10 tests including reactive auth transitions and `AuthLoginScreen` sign-in.
- **Committed in:** `d83b4e3` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (2 Rule 1 bugs)
**Impact on plan:** Both fixes were essential for zero-warning analysis and reactive router correctness caught by automated verification. No scope creep.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required (remote DB push from Plan `01-03` remains deferred per user direction to use Firebase later).

## Next Phase Readiness
- Phase 1 (`01-01` through `01-06` / Tasks `1.1`–`1.5`) is complete with `flutter analyze` (`No issues found!`) and `flutter test` (`11/11` passed).
- Ready to plan and execute Phase 2 (`2.1` Freezed domain models, `2.2` pure Dart calculators, and `2.3`–`2.5` Edge Functions).

---
*Phase: 01-database-rls-and-authentication-foundation*
*Completed: 2026-11-13*

## Self-Check: PASSED
- All 8 created/modified source, test, and planning files verified present on disk.
- All 3 task commits (`8455eab`, `d83b4e3`, `cce98f6`) verified in git history (`HEAD`).
