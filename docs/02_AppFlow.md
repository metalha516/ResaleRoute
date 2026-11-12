# 02 — Application Flow & State Machine: ResaleRoute

## 1. Deterministic Item Lifecycle State Machine
Every physical item ingested into ResaleRoute follows a strict deterministic state machine enforced at both the Flutter presentation layer and PostgreSQL trigger level:

```text
[DRAFT]
  +---> (Low Value / Pre-Verified) ----------------------> [AUTHENTICATED]
  +---> (High Value / Brand Flagged) --> [PENDING_AUTH]
                                           +---> (Approved) --> [AUTHENTICATED]
                                           +---> (Rejected) --> [AUTH_REJECTED] --> [RETURNED_TO_CONSIGNOR]

[AUTHENTICATED] ---> (Auto-List Trigger) ---> [LISTED]
  +---> (30/60/90d Cron) ---> [MARKED_DOWN] ---> (Purchased) ---> [SOLD_ESCROW]
  +---> (Purchased) --------------------------------------------> [SOLD_ESCROW]

[SOLD_ESCROW]
  +---> (7-Day Return Window Expires) ---> [SETTLED] ---> (Ledger Credited & Paid Out)
  +---> (Shopper Files Claim) -----------> [DISPUTED]
                                             +---> (Claim Denied) ---> [SETTLED]
                                             +---> (Claim Approved) -> [REFUNDED_RELISTED]
```

---

## 2. Navigation Routes & Role-Based Access Guards
Navigation is managed via `go_router` with a reactive redirect guard evaluating authentication state and JWT `app_metadata.role`.

| Route Path | Screen Widget | Allowed Roles | Route Parameters |
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

---

## 3. Screen-by-Screen State Transitions & Button Actions

### 3.1 `ItemIntakeWizardScreen`
* **Step 1 (Consignor Lookup):** Search existing consignor by phone or email, or trigger modal to create a new consignor profile.
* **Step 2 (Media Capture):** Capture front, back, brand label, and defect macro photos. Minimum $4$ photos required to unlock the `Next` button.
* **Step 3 (Condition Grading):** Interactive checklist (stitching, hardware, odor, lining) computes suggested Condition Grade (`mint`, `excellent`, `very_good`, `good`, `fair`).
* **Step 4 (Pricing & Split):** Input base price, select markdown tier, and confirm consignor split basis points. Tapping `Complete Intake` calls the `complete_item_intake` RPC, routing the item to `pending_auth` (if `base_price_cents` $\ge 25000$) or `authenticated`.

### 3.2 `AuthInspectionScreen`
* Displays interactive pinch-to-zoom macro gallery, serial number verification field, and material inspection checklist.
* **Approve Button:** Opens digital signature confirmation, transitions item to `authenticated`, inserts a signed `provenance_events` record, and triggers the `multichannel-sync` Edge Function to list the item.
* **Reject Button:** Requires structured rejection reason (`Counterfeit`, `Unrepairable Damage`, `Mismatched SKU`), transitions item to `auth_rejected`, and notifies the consignor for pickup.

### 3.3 `InventoryMarkdownScreen`
* Displays active inventory cards with countdown badges indicating days remaining until the next scheduled markdown ($30$, $60$, or $90\text{ days}$).
* **Pause Timer Toggle:** Allows `boutique_owner` to set `markdown_schedules.is_paused = true`.
* **Force Markdown Action:** Immediately applies the next discount tier and logs a `manual_markdown` provenance event.

### 3.4 `ConsignorLedgerScreen`
* Displays 3 financial summary cards: **Escrow Balance** (items within the 7-day return window), **Available Payout Balance** (settled items), and **Lifetime Earnings**.
* **Request Payout Button:** Enabled strictly when $\text{Available Balance} \ge 2000\text{ cents}$ ($\$20.00$) and zero open disputes exist on the consignor's settled items.

---

## 4. Error & Empty-State Handling Rules
* **Offline Intake Recovery:** If network connectivity drops during photo upload in `ItemIntakeWizardScreen`, form state and compressed local WebP paths persist in local storage (`shared_preferences` / local JSON queue). A non-blocking retry banner appears automatically upon reconnection.
* **Tampered or Unrecognized QR Scan:** Scanning an invalid QR code in `ProductProvenanceScreen` renders a modal alert with a direct input field for manual SKU lookup.
* **Empty Verification Queue:** Displays a clean empty-state card reading *"All high-value items verified — zero pending inspections"* with a pull-to-refresh trigger.
* **Concurrent Checkout Race Condition:** If two shoppers submit payment for the same unique secondhand item simultaneously, PostgreSQL row-level locking (`SELECT ... FOR UPDATE NOWAIT`) awards the item to the first transaction and returns an immediate `"Item Just Sold"` snackbar state to the second shopper.