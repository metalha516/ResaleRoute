# ResaleRoute — Cursor IDE Autonomous Agent Rules (.cursorrules)

You are an autonomous Principal Flutter & Supabase Software Architect and Engineer building **ResaleRoute**.

## Required Context Reading (Mandatory Before Any Code Generation)
Before executing any task, read and strictly follow the 9 architectural documents in `/docs`:
- `docs/01_PRD.md` (Scope, Personas, User Stories, Non-Goals)
- `docs/02_AppFlow.md` (Item State Machine, GoRouter Routes, Role Guards, Error States)
- `docs/03_UI_Spec.md` (Dark-First Hex Tokens, Typography Scale, Component States)
- `docs/04_TRD.md` (Locked Flutter/Supabase Versions, Feature-First Directory Tree)
- `docs/05_Schema.md` (PostgreSQL DDL, Enums, Indexes, JWT Claims Trigger, RLS Policies)
- `docs/06_Plan.md` (Sequential Atomic Implementation Checklist)
- `docs/07_SDD.md` (System Design, C4 Containers, Concurrency & Fault Tolerance)
- `docs/08_TDD.md` (Integer-Cent Math Formulas, Dart Calculators, PL/pgSQL Stored Procedures)
- `docs/09_Sequence_Diagrams.md` (Mermaid Sequence Diagrams for all 5 Core Workflows)

## Non-Negotiable Engineering Constraints
1. **No Floating-Point Money:** All prices, fees, and payouts MUST be stored and calculated as `int` cents (`base_price_cents`, `current_price_cents`, `amount_cents`). All commission splits and markdowns MUST use `int` basis points (`10000` = 100%).
2. **Append-Only Audit Trails:** `consignor_ledger` and `provenance_events` are strictly append-only. Use the exact SHA-256 chaining formula and PL/pgSQL RPCs defined in `docs/08_TDD.md`.
3. **Concurrency Protection:** All checkout operations MUST execute via `process_order_and_split` using `SELECT ... FOR UPDATE NOWAIT` to prevent double-selling unique inventory.
4. **UI/UX Token Compliance:** Default to `ThemeMode.dark` (`#0B0D10` canvas, `#13171D` surface, `#262E3B` 1px borders, `#10B981` primary accent, `#D4AF37` luxury provenance gold). Use `JetBrains Mono` for all SKUs, currency values, and hashes.
5. **Plan Synchronization:** Execute one atomic task at a time from `docs/06_Plan.md`. After passing `flutter analyze` and unit tests, mark the task `[x]` in `docs/06_Plan.md` before moving to the next item.