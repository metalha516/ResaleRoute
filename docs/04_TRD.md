# 04 — Technical Requirements Document (TRD): ResaleRoute

## 1. Locked Technology Stack & Versions

| Architectural Layer | Package / Technology | Locked Version | Purpose |
| :--- | :--- | :--- | :--- |
| **Client Framework** | Flutter / Dart | `3.24.3` / `3.5.3` | Cross-platform iOS, Android, and Web application |
| **State Management** | `flutter_riverpod` + `riverpod_annotation` | `^2.5.1` | Reactive state management and dependency injection |
| **Declarative Routing** | `go_router` | `^14.2.3` | Deep-linking and role-based route protection |
| **Immutable Models** | `freezed` + `json_serializable` | `^2.5.2` / `^6.8.0` | Value equality, copyWith, and JSON serialization |
| **Backend & Database** | `supabase_flutter` (PostgreSQL 15) | `^2.6.0` | Auth JWTs, Postgres RPC, Realtime, and Storage |
| **QR & Barcode Engine** | `mobile_scanner` + `qr_flutter` | `^5.1.1` / `^4.1.0` | Physical inventory tag scanning and generation |
| **Media Pipeline** | `image_picker` + `flutter_image_compress` | `^1.1.2` / `^2.3.0` | Camera intake and EXIF-stripped WebP compression |
| **Analytics Charts** | `fl_chart` | `^0.68.0` | Sustainability metrics and revenue split charts |
| **Typography** | `google_fonts` | `^6.2.1` | Plus Jakarta Sans, Inter, and JetBrains Mono |
| **Local Persistence** | `shared_preferences` + `crypto` | `^2.3.2` / `^3.0.5` | Offline intake draft caching and SHA-256 hashing |

---

## 2. Project Directory Architecture (Feature-First Clean Architecture)

```text
resaleroute/
├── docs/
│   ├── 01_PRD.md
│   ├── 02_AppFlow.md
│   ├── 03_UI_Spec.md
│   ├── 04_TRD.md
│   ├── 05_Schema.md
│   ├── 06_Plan.md
│   ├── 07_SDD.md
│   ├── 08_TDD.md
│   └── 09_Sequence_Diagrams.md
├── supabase/
│   ├── migrations/
│   │   └── 20261112000001_initial_schema.sql
│   └── functions/
│       ├── evaluate-markdowns/index.ts
│       ├── multichannel-sync/index.ts
│       └── process-payout/index.ts
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_typography.dart
│   │   │   └── sustainability_constants.dart
│   │   ├── router/
│   │   │   └── app_router.dart
│   │   ├── theme/
│   │   │   └── app_theme.dart
│   │   └── utils/
│   │       ├── markdown_calculator.dart
│   │       ├── split_calculator.dart
│   │       └── provenance_hasher.dart
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── intake_grading/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── authentication_partner/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── inventory_markdown/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── consignor_ledger/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── provenance_storefront/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       ├── returns_disputes/
│       │   ├── data/
│       │   ├── domain/
│       │   └── presentation/
│       └── sustainability/
│           ├── data/
│           ├── domain/
│           └── presentation/
├── test/
│   ├── unit/
│   └── widget/
├── Main.md
├── .cursorrules
└── pubspec.yaml
```

---

## 3. External Integrations & Supabase Edge Functions
* **Storage Buckets:**
  * `item-media`: Public read, authenticated boutique staff write. Stores compressed WebP garment photos.
  * `auth-evidence`: Private bucket accessible only to `boutique_staff`, `boutique_owner`, and `authenticator` roles via $60\text{-minute}$ signed URLs.
* **`evaluate-markdowns` (Edge Function + `pg_cron`):** Invoked daily at `00:00 UTC` to evaluate unsold inventory age ($30, 60, 90\text{ days}$) and apply scheduled basis-point discounts.
* **`multichannel-sync` (Edge Function):** Dispatches HMAC-SHA256 signed webhook payloads to external storefronts (Shopify / WooCommerce) whenever an item transitions to `listed`, `marked_down`, or `sold_escrow`.
* **`process-payout` (Edge Function):** Executes idempotent payout transfers to consignor accounts for settled ledger rows.

---

## 4. Non-Negotiable Security & Financial Constraints
* **Integer Cents & Basis Points Only:** All monetary amounts are stored and calculated as 64-bit integers representing cents (`base_price_cents`, `current_price_cents`, `amount_cents`). All percentage splits and discounts use integer basis points ($10000\text{ bps} = 100.00\%$). Floating-point types (`double` / `float`) are strictly forbidden for financial math.
* **Append-Only Financial Ledger:** The `consignor_ledger` and `provenance_events` tables revoke `UPDATE` and `DELETE` privileges from all client roles. Corrections require inserting compensating adjustment rows.
* **EXIF Metadata Stripping:** All photos captured during intake or dispute filing are re-encoded to WebP ($\le 400\text{ KB}$) on-device, stripping GPS coordinates and camera serial metadata prior to upload.