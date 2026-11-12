<!-- GSD:project-start source:PROJECT.md -->

## Project

**ResaleRoute**

ResaleRoute is a managed resale and consignment backend and multi-role Flutter + Supabase application (iOS, Android, Web) built for independent fashion and luxury boutiques. It automates physical garment intake, condition grading, third-party luxury authentication, multichannel inventory sync, dynamic 30/60/90-day aging markdowns, SHA-256 provenance tracking, 7-day escrow return disputes, and double-entry consignor payout splits.

**Core Value:** Guarantee 100% deterministic financial reconciliation, tamper-evident luxury provenance, and zero double-sells across the entire boutique consignment lifecycle.

### Constraints

- **Financial Math**: Integer cents (`int`) and basis points (`10000 = 100%`) only; `double` is strictly forbidden for currency.
- **Immutability**: `consignor_ledger` and `provenance_events` are strictly append-only (`INSERT` only; never `UPDATE` or `DELETE`).
- **Concurrency**: Checkout MUST use `SELECT ... FOR UPDATE NOWAIT` inside `process_order_and_split`.
- **UI Fidelity**: `ThemeMode.dark` default (`#0B0D10`), `1px` `#262E3B` borders, zero drop shadows in dark mode, `JetBrains Mono` for SKUs/currency/hashes.
- **Dual-State Tracking**: Every completed `gsd-executor` task MUST update both `.gsd/STATE.md` (plus `.planning/STATE.md`) and check off `[x]` in `docs/06_Plan.md`.

<!-- GSD:project-end -->

<!-- GSD:stack-start source:STACK.md -->

## Technology Stack

Technology stack not yet documented. Will populate after codebase mapping or first phase.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->

## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->

## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->

## Project Skills

No project skills found. Add skills to any of: `.agents/skills/`, `.agents/skills/`, `.cursor/skills/`, `.github/skills/`, or `.codex/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->

## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-fast` for a trivial task inline, with no subagents and no PLAN.md
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->

<!-- GSD:profile-start -->

## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
