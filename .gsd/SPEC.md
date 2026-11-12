# ResaleRoute — Master Technical & Product Specification

**Status:** `FINALIZED`  
**Date:** 2026-11-12  
**Sources Synthesized:** `docs/01_PRD.md` through `docs/09_Sequence_Diagrams.md`, `main_ai_agent_protocol.md`, `cursor_ide_rules.md`

---

## 1. Non-Negotiable Invariants (Enforced Across All Phases & Subagents)

1. **Financial Math Precision:** All monetary values MUST be stored and computed strictly as integer cents (`int` / `INTEGER`: `base_price_cents`, `current_price_cents`, `amount_cents`, `final_price_cents`). All commission splits and markdown discounts MUST use integer basis points (`10000` bps = `100.00%`). Floating-point types (`double` / `float` / `NUMERIC` for currency) are **strictly forbidden** for monetary amounts or calculations.
2. **Append-Only Immutability:** `consignor_ledger` and `provenance_events` are strictly append-only (`INSERT` only). `UPDATE` and `DELETE` privileges are revoked from all client roles; corrections require compensating adjustment rows with deterministic idempotency keys (`idempotency_key`) and SHA-256 hash chaining (`previous_hash` → `event_hash`).
3. **Concurrency Control:** All unique-inventory checkout operations MUST execute inside `process_order_and_split` using PostgreSQL pessimistic row-level locking (`SELECT ... FOR UPDATE NOWAIT`) to prevent double-selling.
4. **UI & Design Token Fidelity:** Default to `ThemeMode.dark` (`#0B0D10` canvas, `#13171D` surface, `#1C222B` elevated, `#262E3B` 1px structural borders). Drop shadows are **strictly forbidden** in Dark Mode. `JetBrains Mono` is mandatory for SKUs, currency amounts, basis-point splits, and cryptographic hashes. Never hardcode ad-hoc colors or text styles in widgets.
5. **EXIF Metadata Stripping:** All photos captured during intake or dispute filing MUST be re-encoded on-device to WebP (`<= 400 KB`), stripping GPS coordinates and camera serial metadata before upload.
6. **Zero Architectural Drift:** Only use locked package versions (`docs/04_TRD.md`), exact schema tables/columns/enums (`docs/05_Schema.md`), and exact routes (`docs/02_AppFlow.md`).
7. **Dual-State Tracking:** Every time a `gsd-executor` subagent completes a task, it MUST update `.gsd/STATE.md` (and `.planning/STATE.md`) AND check off `[x]` with modified file paths in `docs/06_Plan.md`.

---

## 2. Product Scope, Personas & MVP User Stories (`01_PRD.md`)

### 2.1 Vision & Core Problem
**ResaleRoute** is a managed resale/consignment backend and multi-role Flutter + Supabase application (iOS, Android, Web) for independent fashion and luxury boutiques. It automates physical garment intake, condition grading, third-party authentication, multichannel inventory sync, dynamic 30/60/90-day aging markdowns, cryptographic provenance tracking, 7-day escrow return disputes, and double-entry consignor split payouts.

### 2.2 Target Personas & Roles (`user_role` enum)
- **Boutique Owner (`boutique_owner`) & Boutique Staff (`boutique_staff`):** Perform 4-step garment intake, condition grading, QR tag printing, floor markdown management, return dispute resolution (owner), and sustainability reporting (owner).
- **Consignor (`consignor`):** Supplies pre-owned goods; tracks item authentication status, scheduled markdowns, escrow holds, settled ledger balances, and payout withdrawals (`>= 2000` cents / `$20.00`).
- **Authentication Partner (`authenticator`):** Inspects high-value items (`base_price_cents >= 25000` / `$250.00` or boutique threshold) via private macro imagery & serial checks to approve (issuing signed provenance certificates) or reject.
- **Resale Shopper (`shopper`, plus Public storefront):** Browses verified catalog, scans QR provenance tags, views chain-of-custody & CO2/water impact metrics, purchases items with 7-day escrow, and files return disputes within the 7-day return window.

### 2.3 MVP User Stories & Quantitative Targets
| ID | Persona | Capability | Acceptance Criteria |
| :--- | :--- | :--- | :--- |
| **US-01** | Boutique Staff | 4-step intake & grading wizard | Consignor ID, `>= 4` compressed WebP photos, condition grade, integer-cent base price, split bps in `< 180s`. |
| **US-02** | Authenticator | High-value verification queue | Items `>= 25000` cents route to queue; approval writes cryptographic `provenance_events` certificate. |
| **US-03** | Boutique Owner | Multichannel listing & QR labels | Approved items publish to storefront + HMAC-signed external webhooks & printable QR SKU tag. |
| **US-04** | Boutique Owner | Dynamic markdown scheduler | Unsold items auto-discount at 30, 60, 90 days per `markdown_schedules` (unless paused). |
| **US-05** | Consignor | Transparent payout ledger | Shows exact sale price, boutique fee, net credit, escrow vs. available vs. lifetime earnings. |
| **US-06** | Resale Shopper | Digital provenance & sustainability | QR scan/view displays immutable custody timeline + CO2 (kg) and water (L) saved. |
| **US-07** | Resale Shopper | Return & dispute workflow | Dispute within 7 days of purchase freezes consignor escrow until owner resolves. |
| **US-08** | Boutique Owner | Aggregate sustainability reporting | Dashboard aggregates total garments diverted, kg CO2 saved, and liters of water preserved. |

**Metrics:** Intake `< 180s`; `>= 75%` 60-day sell-through; `100%` ledger reconciliation accuracy (zero float drift); `95%` auth turnaround `< 24h`.

### 2.4 Strict Non-Goals (Out of Scope for MVP)
- Direct peer-to-peer marketplace (no consignor-to-shopper shipping without boutique custody).
- Autonomous AI authentication (human authenticator sign-off required for high-value items).
- Live auctions/bidding (fixed-price and scheduled markdowns only).
- Cross-border customs brokerage (domestic regional shipping/tax per boutique).
- Custom POS hardware manufacturing (relies on OS print dialogs and mobile camera scanners).

---

## 3. Deterministic Item State Machine & Routing (`02_AppFlow.md`)

### 3.1 11-State Lifecycle (`item_status` enum)
1. `draft` → Low Value (`< threshold`): directly `listed` (or `authenticated` → `listed`)
2. `draft` → High Value (`>= 25000` cents): `pending_auth`
3. `pending_auth` → Approved: `authenticated` → Auto-List → `listed`
4. `pending_auth` → Rejected: `auth_rejected` → `returned_to_consignor`
5. `listed` → 30/60/90d Cron: `marked_down`
6. `listed` or `marked_down` → Purchased (`FOR UPDATE NOWAIT`): `sold_escrow`
7. `sold_escrow` → 7-Day Window Expires (no dispute): `settled` (ledger settled)
8. `sold_escrow` → Shopper Files Claim (`<= 7 days`): `disputed` (escrow frozen via `dispute_hold`)
9. `disputed` → Claim Denied (`denied_closed`): `settled` (ledger released via `dispute_release`)
10. `disputed` → Claim Approved (`approved_refund`): `refunded_relisted`
11. Terminal pickup state: `returned_to_consignor`

### 3.2 GoRouter Paths & Role Guards (`app_metadata.role`)
| Route | Screen | Allowed Roles | Params |
| :--- | :--- | :--- | :--- |
| `/login` | `AuthLoginScreen` | Public | `redirectUrl` |
| `/staff/dashboard` | `BoutiqueDashboardScreen` | `boutique_staff`, `boutique_owner` | `boutiqueId` |
| `/staff/intake` | `ItemIntakeWizardScreen` | `boutique_staff`, `boutique_owner` | `consignorId` (optional) |
| `/staff/inventory` | `InventoryMarkdownScreen` | `boutique_staff`, `boutique_owner` | `filterStatus` |
| `/auth-partner/queue` | `AuthReviewQueueScreen` | `authenticator` | `priorityFilter` |
| `/auth-partner/review/:id` | `AuthInspectionScreen` | `authenticator` | `itemId` |
| `/consignor/overview` | `ConsignorPortalScreen` | `consignor` | none |
| `/consignor/ledger` | `ConsignorLedgerScreen` | `consignor` | `payoutStatus` |
| `/shop/catalog` | `ShopperCatalogScreen` | `shopper`, Public | `category`, `grade` |
| `/shop/item/:id` | `ProductProvenanceScreen` | `shopper`, Public | `itemId`, `qrToken` |
| `/disputes/:id` | `DisputeResolutionScreen` | `boutique_owner`, `shopper` | `disputeId` |
| `/impact` | `SustainabilityReportScreen` | `boutique_owner`, `shopper` | `timeframe` |

### 3.3 Key Screen Rules & Error States
- **`ItemIntakeWizardScreen`:** 4-step stepper (Consignor lookup/modal → >=4 WebP photos → Condition checklist → Pricing/split + `complete_item_intake` RPC + QR modal). Offline drop persists draft + compressed WebP paths locally (`OfflineIntakeQueueService`).
- **`AuthInspectionScreen`:** Pinch-to-zoom macro gallery (`auth-evidence` 60-min signed URLs), serial check, digital signature approval (`submit_auth_verdict` + `multichannel-sync`) or structured rejection (`Counterfeit`, `Unrepairable Damage`, `Mismatched SKU`).
- **`InventoryMarkdownScreen`:** Aging countdown badges (30/60/90d), `boutique_owner` pause timer toggle (`is_paused = true`), force markdown action logging `manual_markdown`.
- **`ConsignorLedgerScreen`:** Escrow Balance, Available Payout Balance, Lifetime Earnings; Request Payout enabled strictly when `Available >= 2000` cents and zero open disputes on settled items.
- **Error / Empty States:** Invalid QR scan opens manual SKU lookup modal; empty auth queue shows `"All high-value items verified — zero pending inspections"` with pull-to-refresh; concurrent checkout race returns `"Item Just Sold"` snackbar.

---

## 4. UI & Design System (`03_UI_Spec.md`)

- **Theme:** `ThemeMode.dark` default; full Light Mode support. Zero drop shadows in Dark Mode (1px `#262E3B` borders + luminance shift); Light Mode uses 1px `#E5E7EB` + `0 2px 8px rgba(0,0,0,0.04)`.
- **Palette (Dark / Light):**
  - `bg.canvas`: `#0B0D10` / `#F8F9FA`
  - `bg.surface`: `#13171D` / `#FFFFFF`
  - `bg.elevated`: `#1C222B` / `#F1F3F5`
  - `text.primary`: `#F3F4F6` / `#111827`
  - `text.secondary`: `#9CA3AF` / `#4B5563`
  - `accent.primary`: `#10B981` / `#059669`
  - `accent.luxury`: `#D4AF37` / `#B48A1E`
  - `status.warning`: `#F59E0B` / `#D97706`
  - `status.danger`: `#EF4444` / `#DC2626`
  - `border.subtle`: `#262E3B` / `#E5E7EB`
- **Typography:** `Plus Jakarta Sans` (`display.lg` 28/36 w700 -0.5, `heading.md` 20/28 w600 -0.3, `title.sm` 16/24 w600), `Inter` (`body.md` 14/20 w400, `label.sm` 12/16 w500 +0.2), `JetBrains Mono` (`mono.data` 13/18 w500).
- **Spacing & Radii:** `4px` base grid (`4, 8, 12, 16, 24, 32, 48`), horizontal padding `16px` (`<600px`) / `32px` (`>=600px`). Radii: `12px` cards/modals, `8px` buttons/inputs, `999px` pills.
- **Core Components:** `ResaleButton` (48px height, 8px radius, `#10B981` default / `#059669` + `#34D399` focus ring / `#1C222B` disabled / 20px spinner loading), `GradeBadge` (15% alpha tinted border/bg), `LedgerSplitRow` (dual-segment share bar + `JetBrains Mono` currency + `ESCROW`/`AVAILABLE`/`PAID`/`FROZEN` pill).

---

## 5. Locked Stack, Architecture & Infrastructure (`04_TRD.md`, `07_SDD.md`)

- **Client Stack:** Flutter `3.24.3` / Dart `3.5.3`; `flutter_riverpod` + `riverpod_annotation` (`^2.5.1`), `go_router` (`^14.2.3`), `freezed` (`^2.5.2`) + `json_serializable` (`^6.8.0`), `supabase_flutter` (`^2.6.0`), `mobile_scanner` (`^5.1.1`), `qr_flutter` (`^4.1.0`), `image_picker` (`^1.1.2`), `flutter_image_compress` (`^2.3.0`), `fl_chart` (`^0.68.0`), `google_fonts` (`^6.2.1`), `shared_preferences` (`^2.3.2`), `crypto` (`^3.0.5`).
- **Folder Structure:** Feature-first Clean Architecture (`lib/core/{constants,router,theme,utils}` and `lib/features/{auth,intake_grading,authentication_partner,inventory_markdown,consignor_ledger,provenance_storefront,returns_disputes,sustainability}/{data,domain,presentation}`), `supabase/{migrations,functions}`, `test/{unit,widget}`.
- **Storage Buckets:** `item-media` (public read, boutique staff write, WebP `<= 400 KB`), `auth-evidence` (private, `boutique_staff`/`boutique_owner`/`authenticator` via 3600s signed URLs).
- **Deno Edge Functions:**
  - `evaluate-markdowns`: `pg_cron` daily `00:00 UTC`; discounts `listed`/`marked_down` items where `is_paused = false`, updates `applied_tier`, appends `AUTO_MARKDOWN` provenance, triggers `multichannel-sync`.
  - `multichannel-sync`: HMAC-SHA256 webhook dispatch on `listed`, `marked_down`, `sold_escrow`; exponential backoff retries $T(n) = \min(60 \times 2^n, 3600)$s for $n \in \{1..5\}$.
  - `process-payout`: Verifies settled balance `>= 2000` cents and zero open disputes, invokes payout gateway with `idempotency_key`, inserts `payout_debit` row (`is_settled = true`).

---

## 6. Relational Schema, RLS & Atomic RPCs (`05_Schema.md`, `08_TDD.md`, `09_Sequence_Diagrams.md`)

### 6.1 PostgreSQL Schema (`20261112000001_initial_schema.sql`)
- **Extensions:** `pgcrypto`, `pg_cron`.
- **Enums:** `user_role`, `condition_grade`, `item_status`, `auth_verdict`, `ledger_tx_type`, `dispute_status`.
- **9 Tables:** `boutiques`, `profiles`, `items` (`CHECK (array_length(photo_urls, 1) >= 4)`, `CHECK (consignor_split_bps BETWEEN 1000 AND 9500)`), `item_authentications`, `markdown_schedules`, `provenance_events`, `orders`, `consignor_ledger`, `disputes`.
- **7 Indexes:** `idx_items_boutique_status`, `idx_items_consignor`, `idx_items_qr_hash`, `idx_items_aging` (partial `WHERE status IN ('listed', 'marked_down')`), `idx_auth_queue`, `idx_ledger_consignor_settled`, `idx_provenance_item_time`.
- **JWT Claims Trigger:** `sync_profile_claims()` (`AFTER INSERT OR UPDATE ON public.profiles`) syncs `role` and `boutique_id` into `auth.users.raw_app_meta_data`.
- **RLS:** Enabled on all 9 tables; append-only enforcement on `consignor_ledger` and `provenance_events` (no `UPDATE`/`DELETE` policies or client privileges).

### 6.2 Deterministic Mathematical Formulas (`08_TDD.md`)
- **Dynamic Markdown:**
  $$P_{\text{current}} = \left\lfloor \frac{P_{\text{base}} \times (10000 - D_{\text{bps}}) + 5000}{10000} \right\rfloor$$
- **Revenue Split:**
  $$\text{ConsignorCredit}_{\text{cents}} = \left\lfloor \frac{P_{\text{final}} \times S_{\text{bps}} + 5000}{10000} \right\rfloor, \quad \text{BoutiqueFee}_{\text{cents}} = P_{\text{final}} - \text{ConsignorCredit}_{\text{cents}}$$
  Invariant: $\text{ConsignorCredit}_{\text{cents}} + \text{BoutiqueFee}_{\text{cents}} \equiv P_{\text{final}}$.
- **Provenance Hash Chain:**
  $$H_k = \text{SHA256}(H_{k-1} \parallel \text{"|"} \parallel \text{item\_id} \parallel \text{"|"} \parallel \text{event\_type} \parallel \text{"|"} \parallel \text{actor\_id} \parallel \text{"|"} \parallel \text{occurred\_at\_iso8601})$$
  Genesis $H_{-1} = \text{"GENESIS\_RESALEROUTE\_V1"}$.

### 6.3 Atomic PL/pgSQL RPCs (`20261112000002_rpc_functions.sql`)
1. `complete_item_intake(...)`: Checks `boutiques.high_value_auth_threshold_cents` (default `25000`); sets `pending_auth` (and opens `item_authentications` ticket) or `listed`; inserts `items`, `markdown_schedules`, and genesis `provenance_events` (`INTAKE_GRADED`).
2. `submit_auth_verdict(...)`: Authenticator approves (sets item `authenticated` → `listed`, `listed_at = now()`, records `certificate_hash` & signed `provenance_events`) or rejects (sets `auth_rejected` with reason).
3. `process_order_and_split(p_item_id, p_idempotency_key)`: `SELECT ... FOR UPDATE NOWAIT`, verifies `status IN ('listed', 'marked_down')`, computes integer-cent split, transitions to `sold_escrow`, inserts `orders` (`return_window_expires_at = now() + 7 days`), inserts double-entry `consignor_ledger` rows (`sale_credit`, `boutique_fee`, `is_settled = false`), appends `SOLD_ESCROW` provenance event.
4. `resolve_dispute(p_dispute_id, p_resolution, p_notes)`: Handles `denied_closed` (inserts `dispute_release`, settles escrow ledger rows, transitions item to `settled`) or `approved_refund` (transitions item to `refunded_relisted`, `listed_at = now()`, appends `RETURN_ACCEPTED_RELISTED` provenance event). Also paired with dispute-filing transaction checking `now() <= orders.return_window_expires_at`, setting `items.status = 'disputed'`, and inserting negative `dispute_hold` ledger row.
