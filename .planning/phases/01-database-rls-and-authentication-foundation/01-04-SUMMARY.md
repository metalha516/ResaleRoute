---
phase: 01-database-rls-and-authentication-foundation
plan: 04
subsystem: ui
tags: [flutter, material3, theme-extension, google-fonts, design-tokens, dark-mode]

# Dependency graph
requires:
  - phase: 01-database-rls-and-authentication-foundation
    plan: 01
    provides: Flutter clean architecture scaffold and locked google_fonts ^6.2.1 dependency
provides:
  - AppColorPalette ThemeExtension and AppColors.dark / AppColors.light exact hex palettes
  - AppTypography (Plus Jakarta Sans, Inter, JetBrains Mono) and Material TextTheme builder
  - AppSpacing 4px layout scale, radii, breakpoints, and SustainabilityConstants defaults
  - AppTheme.darkTheme (zero drop shadows, 1px #262E3B borders) and AppTheme.lightTheme
affects:
  - 01-05 (AuthLoginScreen and navigable shell screens)
  - 01-06 (app.dart ThemeMode.dark wiring)
  - Phase 3 (all role-based UI workflow screens)

# Actuals (#2632)
actuals:
  tokens: 5804
  tasks: 3
  commits: 3

commits: 3
plan_head_before: db08528e6ded7293f08958fe195ee1aee799594e
plan_head_after: f6c1bf538ad5112844686f0f84b567520eec1c1a

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "ThemeExtension<AppColorPalette> with AppColors.of(context) lookup defaulting to dark palette"
    - "Zero-shadow dark mode via Colors.transparent and elevation: 0 across ThemeData surfaces"
    - "JetBrains Mono monoData token enforced for SKUs, integer-cent currency, basis points, and SHA-256 hashes"

key-files:
  created:
    - lib/core/constants/app_colors.dart
    - lib/core/constants/app_typography.dart
    - lib/core/constants/sustainability_constants.dart
    - lib/core/theme/app_theme.dart
  modified:
    - docs/06_Plan.md
    - .gsd/STATE.md
    - .planning/STATE.md

key-decisions:
  - "Exposed AppTheme.cardShadows(context) returning empty const <BoxShadow>[] in dark mode and lightCardShadow (0 2px 8px rgba(0,0,0,0.04)) in light mode so custom containers uphold zero dark-mode shadows."
  - "Represented category sustainability defaults via const CategoryImpact entries while keeping all monetary thresholds (minPayoutThresholdCents=2000, defaultHighValueAuthThresholdCents=25000) strictly integer cents."

patterns-established:
  - "Design token isolation: feature widgets resolve palette tokens via AppColors.of(context) and spacing via AppSpacing rather than hardcoding hex literals."
  - "Button state styling: FilledButtonThemeData enforces 48px minimum height, 8px radius, #10B981 fill, #059669 pressed/focused fill, #34D399 2px focus ring, and #1C222B/#4B5563 disabled states."

requirements-completed: [FOUND-04]

coverage:
  - id: D1
    description: "AppColors exposes exact Dark and Light hex tokens from docs/03_UI_Spec.md via AppColorPalette ThemeExtension"
    requirement: "FOUND-04"
    verification:
      - kind: other
        ref: "node hex token check on lib/core/constants/app_colors.dart && flutter analyze"
        status: pass
    human_judgment: false
  - id: D2
    description: "AppTypography exposes Plus Jakarta Sans, Inter, and JetBrains Mono text styles and AppSpacing/SustainabilityConstants define 4px grid and integer-cent thresholds"
    requirement: "FOUND-04"
    verification:
      - kind: other
        ref: "node font family check on lib/core/constants/app_typography.dart && flutter analyze"
        status: pass
    human_judgment: false
  - id: D3
    description: "AppTheme.darkTheme enforces zero drop shadows (elevation: 0, Colors.transparent) and 1px #262E3B borders while AppTheme.lightTheme provides 1px #E5E7EB borders and subtle elevation"
    requirement: "FOUND-04"
    verification:
      - kind: other
        ref: "node theme check on lib/core/theme/app_theme.dart && flutter analyze"
        status: pass
    human_judgment: false

# Metrics
duration: 6 min
completed: 2026-11-12
status: complete
---

# Phase 01 Plan 04: Dark-First Editorial Vault Design System Summary

**Implemented `AppColors` (`AppColorPalette` `ThemeExtension`), `AppTypography` (`Plus Jakarta Sans` / `Inter` / `JetBrains Mono`), `AppSpacing`/`SustainabilityConstants`, and `AppTheme` (`darkTheme` zero-shadow + `1px` `#262E3B` borders, `lightTheme` subtle elevation), passing `flutter analyze` with zero issues.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-11-12T18:39:12Z
- **Completed:** 2026-11-12T18:45:02Z
- **Tasks:** 3
- **Files modified:** 7 (4 created, 3 state/plan docs updated)

## Accomplishments
- Implemented `AppColorPalette` `ThemeExtension` and exact Dark/Light hex palettes (`#0B0D10` canvas, `#13171D` surface, `#1C222B` elevated, `#10B981` emerald primary, `#D4AF37` luxury gold, `#262E3B` border, plus semantic Light counterparts) in `lib/core/constants/app_colors.dart`.
- Implemented `AppTypography` in `lib/core/constants/app_typography.dart` with `displayLg`, `headingMd`, `titleSm`, `bodyMd`, `labelSm`, and `monoData` (`JetBrains Mono`) mapped onto Material 3 `TextTheme`.
- Implemented `AppSpacing` (`4px` grid, `12px`/`8px`/`999px` radii, `600px` responsive padding helper) and `SustainabilityConstants` (`2000` cent payout threshold, `25000` cent high-value auth threshold, `7` day return window, `6.50` kg CO2 / `1800` L water defaults, and 7 category impact mappings) in `lib/core/constants/sustainability_constants.dart`.
- Implemented `AppTheme.darkTheme` (zero drop shadows via `elevation: 0` & `Colors.transparent`, `1px` `#262E3B` borders) and `AppTheme.lightTheme` (`1px` `#E5E7EB` borders, `0 2px 8px rgba(0,0,0,0.04)` shadow helper) in `lib/core/theme/app_theme.dart`.
- Verified `flutter pub get` and `flutter analyze` (`No issues found!`), and updated dual-state tracking in `docs/06_Plan.md`, `.gsd/STATE.md`, and `.planning/STATE.md`.

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement AppColors, AppTypography, and SustainabilityConstants** - `9d7f3a9` (feat)
2. **Task 2: Implement AppTheme (darkTheme zero-shadow + lightTheme subtle elevation)** - `01cf2b2` (feat)
3. **Task 3: Run flutter pub get + flutter analyze and update dual-state tracking** - `f6c1bf5` (docs)

## Files Created/Modified
- `lib/core/constants/app_colors.dart` - `AppColorPalette` `ThemeExtension` and `AppColors.dark` / `AppColors.light` hex token palettes + `AppColors.of(context)`.
- `lib/core/constants/app_typography.dart` - `AppTypography` scale (`Plus Jakarta Sans`, `Inter`, `JetBrains Mono`) and `buildTextTheme`.
- `lib/core/constants/sustainability_constants.dart` - `AppSpacing`, `CategoryImpact`, and `SustainabilityConstants`.
- `lib/core/theme/app_theme.dart` - `AppTheme.darkTheme`, `AppTheme.lightTheme`, and `AppTheme.cardShadows(context)`.
- `docs/06_Plan.md` - Checked off Task `1.4` (`[x]`) with created file paths.
- `.gsd/STATE.md` - Marked Task `1.4` Complete (`4/19`, `21%`) and updated Next Task to `1.5`.
- `.planning/STATE.md` - Recorded Plan `01-04` (`FOUND-04`) completion context.

## Decisions Made
- Exposed `AppTheme.cardShadows(BuildContext context)` returning `const <BoxShadow>[]` in dark mode and `lightCardShadow` in light mode so custom containers consistently enforce zero dark-mode shadows.
- Modeled per-category CO2/water estimates with `CategoryImpact` while strictly keeping all financial thresholds (`minPayoutThresholdCents`, `defaultHighValueAuthThresholdCents`) and commission ratios (`defaultConsignorSplitBps`, `totalBasisPoints`) as integers.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Design tokens, typography scale, spacing constants, and `AppTheme` (`darkTheme`/`lightTheme`) are ready for Wave 3 Plan `01-05` (`AuthRepository`, `authStateProvider`, and navigable screen shells) and Plan `01-06` (`AuthLoginScreen`, `app_router.dart`, `app.dart`, `main.dart`).
- Remote Supabase DB push from Plan `01-03` remains intentionally deferred per user instruction to connect Firebase later.

---
*Phase: 01-database-rls-and-authentication-foundation*
*Completed: 2026-11-12*

## Self-Check: PASSED
- All 4 created source files (`lib/core/constants/app_colors.dart`, `lib/core/constants/app_typography.dart`, `lib/core/constants/sustainability_constants.dart`, `lib/core/theme/app_theme.dart`) verified present on disk.
- All 3 task commits (`9d7f3a9`, `01cf2b2`, `f6c1bf5`) verified in git history (`HEAD`).
