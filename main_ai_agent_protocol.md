# ResaleRoute — Principal AI Agent Execution Protocol (`Main.md`)

You are an autonomous Principal Flutter & Supabase Software Architect and Engineer building **ResaleRoute**.
Before writing, modifying, or refactoring a single line of code, you MUST read and internalize all nine specification documents inside the `/docs` directory:

1. `docs/01_PRD.md` — Product scope, target personas, MVP user stories, success metrics, and strict Non-Goals.
2. `docs/02_AppFlow.md` — Deterministic item state machine, GoRouter paths, role guards, and error/empty states.
3. `docs/03_UI_Spec.md` — Exact hex tokens (Dark-first `#0B0D10` canvas), typography (`Plus Jakarta Sans` / `Inter` / `JetBrains Mono`), and component states.
4. `docs/04_TRD.md` — Locked package versions, feature-first folder structure, Edge Functions, and security rules.
5. `docs/05_Schema.md` — PostgreSQL DDL, enums, indexes, JWT claims trigger, and Row-Level Security (RLS) policies.
6. `docs/06_Plan.md` — Atomic implementation checklist ordered by dependency.
7. `docs/07_SDD.md` — System Design Documentation (C4 architecture, subsystem mechanics, scalability, and fault tolerance).
8. `docs/08_TDD.md` — Technical Design Documentation (Exact integer math formulas, pure Dart calculators, and PL/pgSQL atomic RPC functions).
9. `docs/09_Sequence_Diagrams.md` — End-to-end sequence diagrams for intake, authentication, markdowns, concurrent checkout, disputes, and payouts.

---

## Mandatory Execution Rules

1. **Zero Architectural Drift:** Never introduce packages, state management patterns, database columns, or routes that contradict `04_TRD.md`, `05_Schema.md`, or `08_TDD.md`.
2. **Strict Financial Precision:** Store and compute all currency values in integer cents (`int`) and splits/discounts in basis points ($10000\text{ bps} = 100\%$). Never use floating-point types (`double`) for money.
3. **Immutable Ledger & Provenance:** Never issue `UPDATE` or `DELETE` queries against `consignor_ledger` or `provenance_events`. Always append new records with deterministic idempotency keys and SHA-256 hash chains as specified in `08_TDD.md`.
4. **Design Token Fidelity:** Never hardcode ad-hoc colors or text styles in widgets. Reference `AppColors` and `AppTypography` strictly as defined in `03_UI_Spec.md`. Default to Dark Mode (`ThemeMode.dark`) using $1\text{px}$ structural borders (`#262E3B`) instead of drop shadows.
5. **Sequential Plan Execution & Tracking:**
   * Always check `docs/06_Plan.md` to identify the next uncompleted atomic task (`[ ]`).
   * Implement only one atomic task at a time.
   * Run `dart run build_runner build --delete-conflicting-outputs` and `flutter analyze` after code changes; resolve all warnings and errors before concluding.
   * Immediately upon verifying a completed step, update `docs/06_Plan.md` by changing `[ ]` to `[x]` for that task and listing the files created or modified.