# 01 — Product Requirements Document (PRD): ResaleRoute

## 1. Executive Vision & Core Problem
Independent fashion and luxury goods boutiques want to capture high-margin resale revenue but lack the operational infrastructure to manage itemized condition grading, third-party authentication, multichannel inventory synchronization, automated aging markdowns, and multi-party consignor payout splits. Relying on manual spreadsheets creates payout disputes, stale floor inventory, and counterfeit liability.

**ResaleRoute** is a managed resale backend and role-based mobile/web application built with Flutter and Supabase. It automates the entire consignment lifecycle from physical garment intake and authentication to dynamic markdown pricing, provenance tracking, and double-entry consignor payout splits.

---

## 2. Target Personas
* **Boutique Staff & Owners:** In-store operators who inspect incoming garments, assign condition grades, print QR provenance tags, manage floor aging, resolve return disputes, and reconcile store commissions.
* **Consignors (Individual Sellers):** Item owners who supply pre-owned goods to the boutique and require real-time visibility into authentication status, scheduled markdowns, sale events, and split payouts.
* **Authentication Partners:** Certified specialists who review high-resolution macro imagery, serial stamps, and material details to issue digital authenticity verdicts for high-value items.
* **Resale Shoppers:** Eco-conscious buyers who browse verified secondhand inventory, inspect immutable ownership provenance via QR tags, track personal carbon/water savings, and initiate return disputes within policy windows.

---

## 3. MVP User Stories & Acceptance Criteria

| ID | Persona | User Story | Acceptance Criteria |
| :--- | :--- | :--- | :--- |
| **US-01** | Boutique Staff | Standardized 4-step intake and condition grading wizard | Captures consignor ID, minimum 4 compressed WebP photos, condition grade, base price in cents, and split ratio in under 180 seconds. |
| **US-02** | Authenticator | Verification queue for high-value luxury items | Items priced at or above $\$250.00$ ($25000$ cents) or flagged luxury brands route to queue; approval generates a cryptographic provenance event. |
| **US-03** | Boutique Owner | Automated multichannel listing and QR label generation | Approved items publish to storefront and external webhook channels while generating a printable QR SKU tag. |
| **US-04** | Boutique Owner | Dynamic markdown scheduler for aging stock | Unsold items automatically discount at 30, 60, and 90 days based on boutique markdown rules. |
| **US-05** | Consignor | Transparent payout ledger and split tracking | Displays exact sale price, boutique commission, net consignor payout, escrow status, and settlement history. |
| **US-06** | Resale Shopper | Digital provenance timeline and sustainability badge | Scanning or viewing an item reveals chain-of-custody milestones and diverted $\text{CO}_2$ and water metrics. |
| **US-07** | Resale Shopper | Structured return and dispute workflow | Shoppers can open a dispute within 7 days of delivery, freezing consignor escrow payout until resolved. |
| **US-08** | Boutique Owner | Aggregate sustainability impact reporting | Dashboard aggregates total garments diverted, kilograms of $\text{CO}_2$ saved, and liters of water preserved. |

---

## 4. Quantitative Success Metrics
* **Intake Velocity:** Average item intake and grading completion time under $180\text{ seconds}$ per garment.
* **Inventory Sell-Through:** At least $75\%$ sell-through rate within $60\text{ days}$ of listing via automated markdown scheduling.
* **Financial Integrity:** $100\%$ reconciliation accuracy between completed orders and double-entry consignor split ledgers with zero floating-point drift.
* **Authentication Turnaround:** $95\%$ of flagged high-value items verified by authentication partners within $24\text{ hours}$ of intake.

---

## 5. Out of Scope (Strict Non-Goals for MVP)
* **Direct Peer-to-Peer Marketplace:** Consignors cannot list or ship items directly to shoppers without boutique intake and physical custody.
* **Autonomous AI Authentication:** AI image checks cannot approve luxury items without human authenticator sign-off.
* **Live Auction & Bidding:** All listings operate on fixed-price or scheduled markdown models; real-time bidding is excluded.
* **Cross-Border Customs Brokerage:** Shipping and tax calculations are restricted to domestic regional couriers per boutique.
* **Custom POS Hardware Manufacturing:** Barcode and QR printing relies on standard OS print dialogs and mobile camera scanners.