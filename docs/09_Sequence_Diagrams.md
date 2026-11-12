# 09 — Sequential Design Diagrams: ResaleRoute

## 1. Item Intake & Conditional High-Value Authentication Sequence

This sequence illustrates how an item is graded by boutique staff, evaluated against the boutique's high-value threshold ($\$250.00$), verified by a third-party authenticator, and automatically published to external channels.

```mermaid
sequenceDiagram
    autonumber
    actor Staff as Boutique Staff
    participant App as Flutter App (Intake/Auth)
    participant Storage as Supabase Storage
    participant DB as PostgreSQL (RPC & RLS)
    actor Auth as Authenticator
    participant Edge as Edge Function (multichannel-sync)

    Staff->>App: Complete 4-Step Intake Wizard (Photos, Grade, Price, Split)
    App->>App: Compress 4+ Photos to WebP (<400KB, Strip EXIF)
    App->>Storage: Upload WebP Photos to bucket `item-media`
    Storage-->>App: Return Public Media URLs
    App->>DB: RPC `complete_item_intake(payload)`
    
    alt base_price_cents >= 25000 ($250.00 High-Value Threshold)
        DB->>DB: Insert `items` (status = 'pending_auth')
        DB->>DB: Insert `provenance_events` (Genesis Hash H_0)
        DB->>DB: Insert `item_authentications` (verdict = 'pending')
        DB-->>App: Return item_id (Status: PENDING_AUTH)
        
        Auth->>App: Open `AuthReviewQueueScreen`
        App->>DB: SELECT pending `item_authentications`
        DB-->>App: Return High-Value Item Details & Macro Photos
        Auth->>App: Inspect Serial/Stitching & Tap "Approve Authenticity"
        App->>DB: RPC `submit_auth_verdict(item_id, 'approved', cert_hash)`
        DB->>DB: Update `items` (status = 'listed', listed_at = now())
        DB->>DB: Append `provenance_events` (Hash H_1 = SHA256(H_0 + payload))
        DB->>Edge: Trigger Webhook Sync (`listed`)
        Edge-->>DB: 200 OK (Storefront Synced)
        DB-->>App: Return Digital Certificate Issued
    else base_price_cents < 25000 (Standard Value)
        DB->>DB: Insert `items` (status = 'listed', listed_at = now())
        DB->>DB: Insert `provenance_events` (Genesis Hash H_0)
        DB->>Edge: Trigger Webhook Sync (`listed`)
        DB-->>App: Return item_id (Status: LISTED + Printable QR Tag)
    end
```

---

## 2. Automated Aging Markdown Cron Sequence

This sequence details the daily `00:00 UTC` scheduled job that evaluates unsold inventory age ($30, 60, 90\text{ days}$) and applies basis-point price reductions.

```mermaid
sequenceDiagram
    autonumber
    participant Cron as pg_cron (00:00 UTC)
    participant Edge as Edge Function (evaluate-markdowns)
    participant DB as PostgreSQL Core
    participant Sync as Edge Function (multichannel-sync)
    actor Consignor as Consignor App

    Cron->>Edge: Trigger Daily Markdown Evaluation
    Edge->>DB: Query `items` JOIN `markdown_schedules` WHERE status IN ('listed','marked_down') AND is_paused = false
    DB-->>Edge: Return Candidate Items (age >= 30, 60, or 90 days)

    loop For Each Eligible Aging Item
        Edge->>Edge: Calculate P_current = floor((P_base * (10000 - D_bps) + 5000) / 10000)
        Edge->>DB: Transaction: UPDATE `items.current_price_cents` & `status = 'marked_down'`
        Edge->>DB: UPDATE `markdown_schedules.applied_tier` & `last_markdown_applied_at`
        Edge->>DB: INSERT `provenance_events` (event_type = 'AUTO_MARKDOWN')
        Edge->>Sync: Dispatch Price Update Webhook to External Storefront
        DB-->>Consignor: Realtime Notification: "Item marked down per schedule"
    end
```

---

## 3. Checkout, Pessimistic Locking & Double-Entry Split Ledger Sequence

This sequence shows how concurrent purchases are serialized via `FOR UPDATE NOWAIT` and how revenue is split into unsettled escrow ledger entries.

```mermaid
sequenceDiagram
    autonumber
    actor Shopper1 as Shopper A
    actor Shopper2 as Shopper B (Concurrent)
    participant App as Flutter Storefront
    participant DB as PostgreSQL (`process_order_and_split`)

    par Concurrent Purchase Attempt on Unique Secondhand Item
        Shopper1->>App: Tap "Buy Now" (Item SKU-901)
        App->>DB: RPC `process_order_and_split(item_id, idempotency_key_A)`
        DB->>DB: SELECT * FROM items WHERE id = item_id FOR UPDATE NOWAIT (Lock Acquired)
    and
        Shopper2->>App: Tap "Buy Now" (Item SKU-901)
        App->>DB: RPC `process_order_and_split(item_id, idempotency_key_B)`
        DB-->>App: Lock Contention / Status Check Fails ('ITEM_ALREADY_SOLD_OR_UNAVAILABLE')
        App-->>Shopper2: Display Snackbar: "Item Just Sold to Another Shopper"
    end

    DB->>DB: Compute ConsignorCredit_cents & BoutiqueFee_cents
    DB->>DB: UPDATE `items` SET status = 'sold_escrow', sold_at = now()
    DB->>DB: INSERT `orders` (return_window_expires_at = now() + 7 days)
    DB->>DB: INSERT `consignor_ledger` (tx_type = 'sale_credit', is_settled = false)
    DB->>DB: INSERT `consignor_ledger` (tx_type = 'boutique_fee', is_settled = false)
    DB->>DB: INSERT `provenance_events` (event_type = 'SOLD_ESCROW', Hash H_k)
    DB-->>App: Commit Transaction & Return `order_id`
    App-->>Shopper1: Navigate to Order Confirmation & Provenance Certificate
```

---

## 4. Return Dispute & Escrow Freeze Sequence

This sequence covers what happens when a shopper files a return dispute within the 7-day escrow window and how the boutique owner resolves it.

```mermaid
sequenceDiagram
    autonumber
    actor Shopper as Resale Shopper
    participant App as Flutter App
    participant DB as PostgreSQL Core
    actor Owner as Boutique Owner
    actor Consignor as Consignor

    Shopper->>App: Submit Return Dispute (Reason + Macro Evidence Photos)
    App->>DB: Verify `now() <= orders.return_window_expires_at`
    App->>DB: Transaction: INSERT `disputes` (status = 'open')
    DB->>DB: UPDATE `items` SET status = 'disputed'
    DB->>DB: INSERT `consignor_ledger` (tx_type = 'dispute_hold', amount_cents = -ConsignorCredit)
    DB-->>Consignor: Realtime Alert: "Escrow frozen due to buyer return claim"

    Owner->>App: Review Dispute Evidence in `DisputeResolutionScreen`
    
    alt Dispute Denied (Item Matched Grading Description)
        Owner->>App: Tap "Deny Claim & Release Escrow"
        App->>DB: RPC `resolve_dispute(dispute_id, 'denied_closed')`
        DB->>DB: INSERT `consignor_ledger` (tx_type = 'dispute_release', amount_cents = +ConsignorCredit)
        DB->>DB: UPDATE `consignor_ledger` SET is_settled = true WHERE order_id = X
        DB->>DB: UPDATE `items` SET status = 'settled'
        DB-->>Consignor: Funds Moved to Available Payout Balance
    else Dispute Approved (Undisclosed Defect Confirmed)
        Owner->>App: Tap "Approve Refund & Relist Item"
        App->>DB: RPC `resolve_dispute(dispute_id, 'approved_refund')`
        DB->>DB: UPDATE `items` SET status = 'refunded_relisted', listed_at = now()
        DB->>DB: Append `provenance_events` ('RETURN_ACCEPTED_RELISTED')
        DB-->>Shopper: Issue Full Order Refund
    end
```

---

## 5. Consignor Payout Settlement Sequence

```mermaid
sequenceDiagram
    autonumber
    actor Consignor as Consignor
    participant App as Flutter Consignor Portal
    participant Edge as Edge Function (`process-payout`)
    participant DB as PostgreSQL Core
    participant Gateway as Payout Gateway (Stripe Connect)

    Consignor->>App: Tap "Withdraw Available Balance" (>= $20.00)
    App->>Edge: POST `/process-payout` (JWT + idempotency_key)
    Edge->>DB: Calculate SUM(amount_cents) WHERE consignor_id = uid AND is_settled = true
    DB-->>Edge: Return Available Balance Cents
    Edge->>Gateway: Initiate Transfer (amount_cents, idempotency_key)
    Gateway-->>Edge: Return Transfer Confirmation ID
    Edge->>DB: INSERT `consignor_ledger` (tx_type = 'payout_debit', amount_cents = -AvailableBalance, is_settled = true)
    DB-->>App: Return Updated Ledger Balance ($0.00 Available)
    App-->>Consignor: Render Payout Receipt & Settlement Confirmation
```