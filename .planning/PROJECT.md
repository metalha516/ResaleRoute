# ResaleRoute

## What This Is

ResaleRoute is a managed resale and consignment backend and multi-role Flutter + Supabase application (iOS, Android, Web) built for independent fashion and luxury boutiques. It automates physical garment intake, condition grading, third-party luxury authentication, multichannel inventory sync, dynamic 30/60/90-day aging markdowns, SHA-256 provenance tracking, 7-day escrow return disputes, and double-entry consignor payout splits.

## Core Value

Guarantee 100% deterministic financial reconciliation, tamper-evident luxury provenance, and zero double-sells across the entire boutique consignment lifecycle.

## Business Context

- **Customer**: Independent fashion and luxury resale boutiques (owners, staff, consignors, authenticators, and shoppers).
- **Revenue model**: Boutique consignment commission split configured in basis points (`1000`–`9500` bps; default `7000` bps to consignor / `3000` bps to boutique).
- **Success metric**: Intake under 180s per garment, >=75% 60-day sell-through, 100% integer-cent ledger accuracy, and 95% high-value authentication turnaround within 24h.
- **Strategy notes**: Locked specifications in [docs/01_PRD.md](file:///d:/ResaleRoute/docs/01_PRD.md) through [docs/09_Sequence_Diagrams.md](file:///d:/ResaleRoute/docs/09_Sequence_Diagrams.md) and [.gsd/SPEC.md](file:///d:/ResaleRoute/.gsd/SPEC.md).

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Multi-tenant PostgreSQL 15 schema with 6 enums, 9 tables, JWT `app_metadata` claims sync, strict RLS, and 4 atomic `SECURITY DEFINER` RPCs
- [ ] Locked Flutter 3.24.3 / Riverpod 2.5.1 / GoRouter 14.2.3 / Freezed 2.5.2 / Supabase 2.6.0 Clean Architecture client with Dark-First Editorial Vault (`#0B0D10`) tokens
- [ ] Pure Dart integer-cent & basis-point calculators (`SplitCalculator`, `MarkdownCalculator`, `ProvenanceHasher`) and 3 Deno Edge Functions (`evaluate-markdowns`, `multichannel-sync`, `process-payout`)
- [ ] Role-based UI workflows for Boutique Staff/Owners, Authenticators, Consignors, and Shoppers across all 12 GoRouter routes
- [ ] Offline intake resilience (`OfflineIntakeQueueService`) and comprehensive unit/widget/integration tests

### Out of Scope

- Direct peer-to-peer marketplace (consignors shipping directly to shoppers) — boutique intake and physical custody are mandatory for MVP
- Autonomous AI authentication — high-value luxury approval requires human authenticator sign-off
- Live auctions or bidding — fixed-price and deterministic 30/60/90-day markdown models only
- Cross-border customs brokerage — restricted to domestic regional couriers per boutique
- Custom POS hardware manufacturing — uses standard OS print dialogs and mobile camera scanners

## Context

All 9 architectural specification files (`docs/01_PRD.md`–`docs/09_Sequence_Diagrams.md`), `main_ai_agent_protocol.md`, and `cursor_ide_rules.md` are finalized and synthesized into `.gsd/SPEC.md` (`FINALIZED`).

## Constraints

- **Financial Math**: Integer cents (`int`) and basis points (`10000 = 100%`) only; `double` is strictly forbidden for currency.
- **Immutability**: `consignor_ledger` and `provenance_events` are strictly append-only (`INSERT` only; never `UPDATE` or `DELETE`).
- **Concurrency**: Checkout MUST use `SELECT ... FOR UPDATE NOWAIT` inside `process_order_and_split`.
- **UI Fidelity**: `ThemeMode.dark` default (`#0B0D10`), `1px` `#262E3B` borders, zero drop shadows in dark mode, `JetBrains Mono` for SKUs/currency/hashes.
- **Dual-State Tracking**: Every completed `gsd-executor` task MUST update both `.gsd/STATE.md` (plus `.planning/STATE.md`) and check off `[x]` in `docs/06_Plan.md`.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Integer cents + basis points (`10000` bps) | Eliminates floating-point drift in split & markdown math | — Pending |
| Append-only `consignor_ledger` & `provenance_events` | Tamper-evident financial audit & luxury chain of custody | — Pending |
| `SELECT ... FOR UPDATE NOWAIT` at checkout | Prevents concurrent double-selling of unique secondhand SKUs | — Pending |
| JWT `app_metadata` sync trigger on `profiles` | Zero-join RLS evaluation across multi-tenant boutique data | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-11-12 after project initialization*
