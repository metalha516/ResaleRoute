# 07 — System Design Documentation (SDD): ResaleRoute

## 1. Architectural Overview & Design Principles
**ResaleRoute** follows a **Client-Serverless Event-Driven Architecture** combining a cross-platform Flutter client (iOS, Android, Web) with a managed PostgreSQL 15 core, Deno-based Edge Functions, and Object Storage via Supabase.

### Core Engineering Tenets
1. **Database-Enforced State & Security:** Role-Based Access Control (RBAC) and Multi-Tenant Boutique isolation are enforced directly at the database layer via PostgreSQL Row-Level Security (RLS) and custom JWT claims.
2. **ACID Financial Integrity:** Every inventory state transition that impacts money (item sale, split allocation, dispute hold, payout settlement) executes inside a single serializable or row-locked PostgreSQL transaction (`SECURITY DEFINER` RPC).
3. **Cryptographic Provenance Chain:** Every physical custody or lifecycle change generates a SHA-256 hash linking the previous event hash (`previous_hash`) to the current payload (`event_hash`), forming a tamper-evident audit trail for luxury goods.
4. **Offline-First In-Store Operations:** Boutique backrooms frequently suffer from spotty Wi-Fi; the intake wizard compresses media on-device and queues drafts locally until upload confirmation.

---

## 2. C4 System Context & Container Architecture

```text
+-----------------------------------------------------------------------------------+
|                            RESALEROUTE ECOSYSTEM (C4)                             |
+-----------------------------------------------------------------------------------+

  +-----------------+   +-----------------+   +-----------------+   +---------------+
  | Boutique Staff  |   |   Consignors    |   | Authenticators  |   |   Shoppers    |
  +--------+--------+   +--------+--------+   +--------+--------+   +-------+-------+
           |                     |                     |                    |
           +---------------------+----------+----------+--------------------+
                                            | HTTPS / WSS (TLS 1.3)
                                            v
                    +-----------------------------------------------+
                    |     Flutter Unified Client (Mobile & Web)     |
                    |  Riverpod State | GoRouter | Offline Queue    |
                    +-------+---------------+---------------+-------+
                            |               |               |
        +-------------------+               |               +-------------------+
        | REST / RPC (PostgREST)            | Signed URLs                       | Edge HTTPS
        v                                   v                                   v
+-------------------------------+   +-------------------------------+   +-------------------------------+
|   PostgreSQL 15 Core DB       |   |   Supabase Object Storage     |   |   Deno Edge Functions         |
| - RLS Multi-Tenant Isolation  |   | - item-media (Public WebP)    |   | - evaluate-markdowns (Cron)   |
| - Atomic Ledger & Order RPCs  |   | - auth-evidence (Private)     |   | - multichannel-sync (Webhook) |
| - pg_cron Scheduler           |   +-------------------------------+   | - process-payout (Settlement) |
+-------------------------------+                                       +---------------+---------------+
                                                                                        |
                                                                +-----------------------+-----------------------+
                                                                | HTTPS Webhook                                 | REST API
                                                                v                                               v
                                                +-------------------------------+               +-------------------------------+
                                                | External Boutique Storefronts |               | Payment & Payout Gateways     |
                                                | (Shopify / WooCommerce)       |               | (Stripe Connect / Banking)    |
                                                +-------------------------------+               +-------------------------------+
```

---

## 3. Subsystem Decomposition

### 3.1 Intake & Condition Grading Engine
* **Responsibility:** Standardizes physical garment inspection, computes condition grades (`mint` through `fair`), generates unique SKU identifiers, and routes items based on counterfeit risk.
* **Routing Rule:** If $\text{base\_price\_cents} \ge \text{boutique.high\_value\_auth\_threshold\_cents}$ (default $25000$ cents / $\$250.00$), initial status is set to `pending_auth` and an `item_authentications` ticket is opened. Otherwise, status transitions directly to `authenticated` and `listed`.

### 3.2 Third-Party Authentication Subsystem
* **Responsibility:** Isolates high-value items from public catalog visibility until a certified `authenticator` inspects macro imagery and serial stamps.
* **Security:** Evidence photos reside in the private `auth-evidence` bucket, served via ephemeral signed URLs ($TTL = 3600\text{ seconds}$).

### 3.3 Dynamic Markdown Engine
* **Responsibility:** Prevents dead stock by systematically discounting aging inventory at $30$, $60$, and $90\text{ days}$ post-listing.
* **Execution Mechanism:** `pg_cron` triggers the `evaluate-markdowns` job daily at `00:00 UTC`. Items where `is_paused = false` and `status IN ('listed', 'marked_down')` have their `current_price_cents` recalculated deterministically from `base_price_cents`.

### 3.4 Double-Entry Consignor Split & Escrow Ledger
* **Responsibility:** Tracks financial obligations between the boutique and consignors with zero ambiguity.
* **Escrow Mechanics:** Upon purchase, funds enter an escrow state (`is_settled = false`) for a $7\text{-day}$ return window (`return_window_expires_at = now() + interval '7 days'`). Only after the window expires without an open dispute can the ledger rows transition to `is_settled = true`.

---

## 4. Scalability, Caching & Reliability Strategy

| Dimension | Architectural Strategy | Target SLA / Metric |
| :--- | :--- | :--- |
| **Database Read Scaling** | Composite B-Tree indexes on `(boutique_id, status)` and partial index on aging inventory. | Query execution $< 15\text{ ms}$ at $100\text{k}$ items. |
| **Concurrency Control** | Pessimistic row locking (`SELECT ... FOR UPDATE NOWAIT`) on `items` during checkout. | Zero double-sells on unique inventory. |
| **Idempotency** | Client-generated UUIDv4 idempotency keys enforced via `UNIQUE` constraints on `consignor_ledger`. | Zero duplicate payouts on network retries. |
| **Media Delivery** | Client-side WebP compression ($\le 400\text{ KB}$) + CDN caching on `item-media` bucket. | Image first-byte latency $< 80\text{ ms}$. |
| **Audit Immutability** | Append-only ledger and provenance tables with SHA-256 hash chaining. | $100\%$ tamper detection. |

---

## 5. Disaster Recovery & Fault Tolerance
* **Point-in-Time Recovery (PITR):** Continuous Write-Ahead Log (WAL) archiving enables recovery to any second within a $7\text{-day}$ rolling window ($RPO \approx 0$, $RTO < 15\text{ minutes}$).
* **Webhook Dead-Letter Handling:** If an external boutique storefront (e.g., Shopify) returns a $5\text{xx}$ error during `multichannel-sync`, the Edge Function retries with exponential backoff:
  $$T_{\text{retry}}(n) = \min\left(60 \times 2^n, 3600\right)\text{ seconds for } n \in \{1, 2, 3, 4, 5\}$$