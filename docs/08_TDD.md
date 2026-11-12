# 08 — Technical Design Documentation (TDD): ResaleRoute

## 1. Mathematical Specifications & Domain Formulas

All financial and environmental calculations are strictly deterministic. Floating-point arithmetic is prohibited for currency.

### 1.1 Dynamic Markdown Calculation
Given an item's base price in cents $P_{\text{base}} \in \mathbb{Z}^+$ and a scheduled discount tier in basis points $D_{\text{bps}} \in [0, 9000]$ (where $10000\text{ bps} = 100\%$):

$$P_{\text{current}} = \left\lfloor \frac{P_{\text{base}} \times (10000 - D_{\text{bps}}) + 5000}{10000} \right\rfloor$$

Adding $5000$ in the numerator before integer floor division performs exact half-up rounding in integer arithmetic.

### 1.2 Consignor vs. Boutique Revenue Split
Given a final checkout price $P_{\text{final}} \in \mathbb{Z}^+$ and consignor split ratio $S_{\text{bps}} \in [1000, 9500]$:

$$\text{ConsignorCredit}_{\text{cents}} = \left\lfloor \frac{P_{\text{final}} \times S_{\text{bps}} + 5000}{10000} \right\rfloor$$

$$\text{BoutiqueFee}_{\text{cents}} = P_{\text{final}} - \text{ConsignorCredit}_{\text{cents}}$$

This guarantees the invariant:
$$\text{ConsignorCredit}_{\text{cents}} + \text{BoutiqueFee}_{\text{cents}} \equiv P_{\text{final}}$$

### 1.3 Cryptographic Provenance Hash Chain
Each provenance event $k$ computes its SHA-256 digest $H_k$ over the canonical pipe-delimited string:

$$H_k = \text{SHA256}\left( H_{k-1} \parallel \text{"|"} \parallel \text{item\_id} \parallel \text{"|"} \parallel \text{event\_type} \parallel \text{"|"} \parallel \text{actor\_id} \parallel \text{"|"} \parallel \text{occurred\_at\_iso8601} \right)$$

For the genesis intake event ($k = 0$), $H_{-1} = \text{"GENESIS\_RESALEROUTE\_V1"}$.

---

## 2. Pure Dart Domain Calculators (`lib/core/utils/`)

### 2.1 `split_calculator.dart`
```dart
class SplitResult {
  final int finalPriceCents;
  final int consignorCreditCents;
  final int boutiqueFeeCents;
  final int splitBps;

  const SplitResult({
    required this.finalPriceCents,
    required this.consignorCreditCents,
    required this.boutiqueFeeCents,
    required this.splitBps,
  });
}

class SplitCalculator {
  const SplitCalculator._();

  static SplitResult compute({
    required int finalPriceCents,
    required int consignorSplitBps,
  }) {
    if (finalPriceCents <= 0) {
      throw ArgumentError.value(finalPriceCents, 'finalPriceCents', 'Must be > 0');
    }
    if (consignorSplitBps < 1000 || consignorSplitBps > 9500) {
      throw ArgumentError.value(
        consignorSplitBps,
        'consignorSplitBps',
        'Must be between 1000 (10%) and 9500 (95%)',
      );
    }

    final int consignorCredit =
        ((finalPriceCents * consignorSplitBps) + 5000) ~/ 10000;
    final int boutiqueFee = finalPriceCents - consignorCredit;

    return SplitResult(
      finalPriceCents: finalPriceCents,
      consignorCreditCents: consignorCredit,
      boutiqueFeeCents: boutiqueFee,
      splitBps: consignorSplitBps,
    );
  }
}
```

### 2.2 `markdown_calculator.dart`
```dart
class MarkdownCalculator {
  const MarkdownCalculator._();

  static int computeDiscountedPriceCents({
    required int basePriceCents,
    required int discountBps,
  }) {
    if (basePriceCents <= 0) {
      throw ArgumentError.value(basePriceCents, 'basePriceCents', 'Must be > 0');
    }
    if (discountBps < 0 || discountBps > 9000) {
      throw ArgumentError.value(discountBps, 'discountBps', 'Must be 0..9000');
    }
    return ((basePriceCents * (10000 - discountBps)) + 5000) ~/ 10000;
  }

  static int resolveActiveDiscountBps({
    required DateTime listedAt,
    required DateTime now,
    required int day30Bps,
    required int day60Bps,
    required int day90Bps,
  }) {
    final int ageDays = now.difference(listedAt).inDays;
    if (ageDays >= 90) return day90Bps;
    if (ageDays >= 60) return day60Bps;
    if (ageDays >= 30) return day30Bps;
    return 0;
  }
}
```

---

## 3. PostgreSQL Atomic RPC Procedures (`supabase/migrations/20261112000002_rpc_functions.sql`)

### 3.1 `complete_item_intake`
Atomically inserts the item, configures its markdown schedule, records the genesis provenance hash, and routes high-value items to the authentication queue.

```sql
CREATE OR REPLACE FUNCTION public.complete_item_intake(
  p_boutique_id UUID,
  p_consignor_id UUID,
  p_sku TEXT,
  p_title TEXT,
  p_brand TEXT,
  p_category TEXT,
  p_condition condition_grade,
  p_condition_notes JSONB,
  p_photo_urls TEXT[],
  p_base_price_cents INTEGER,
  p_consignor_split_bps INTEGER,
  p_co2_saved_kg NUMERIC,
  p_water_saved_liters INTEGER
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_item_id UUID;
  v_threshold_cents INTEGER;
  v_initial_status item_status;
  v_listed_at TIMESTAMPTZ;
  v_genesis_hash TEXT;
BEGIN
  SELECT high_value_auth_threshold_cents INTO v_threshold_cents
  FROM public.boutiques WHERE id = p_boutique_id;

  IF p_base_price_cents >= COALESCE(v_threshold_cents, 25000) THEN
    v_initial_status := 'pending_auth';
    v_listed_at := NULL;
  ELSE
    v_initial_status := 'listed';
    v_listed_at := now();
  END IF;

  v_genesis_hash := encode(
    digest('GENESIS_RESALEROUTE_V1|' || p_sku || '|' || auth.uid()::text || '|' || now()::text, 'sha256'),
    'hex'
  );

  INSERT INTO public.items (
    boutique_id, consignor_id, intake_staff_id, sku, title, brand, category,
    condition, condition_notes, photo_urls, base_price_cents, current_price_cents,
    consignor_split_bps, status, qr_provenance_hash, co2_saved_kg, water_saved_liters, listed_at
  ) VALUES (
    p_boutique_id, p_consignor_id, auth.uid(), p_sku, p_title, p_brand, p_category,
    p_condition, p_condition_notes, p_photo_urls, p_base_price_cents, p_base_price_cents,
    p_consignor_split_bps, v_initial_status, v_genesis_hash, p_co2_saved_kg, p_water_saved_liters, v_listed_at
  ) RETURNING id INTO v_item_id;

  INSERT INTO public.markdown_schedules (item_id) VALUES (v_item_id);

  INSERT INTO public.provenance_events (
    item_id, actor_id, event_type, event_title, metadata, previous_hash, event_hash
  ) VALUES (
    v_item_id, auth.uid(), 'INTAKE_GRADED',
    'Item received and graded (' || p_condition::text || ')',
    jsonb_build_object('sku', p_sku, 'base_price_cents', p_base_price_cents),
    'GENESIS_RESALEROUTE_V1',
    v_genesis_hash
  );

  IF v_initial_status = 'pending_auth' THEN
    INSERT INTO public.item_authentications (item_id, verdict)
    VALUES (v_item_id, 'pending');
  END IF;

  RETURN v_item_id;
END;
$$;
```

### 3.2 `process_order_and_split`
Uses `FOR UPDATE NOWAIT` to prevent concurrent checkout race conditions, creates the order with a 7-day escrow window, and writes double-entry rows to `consignor_ledger`.

```sql
CREATE OR REPLACE FUNCTION public.process_order_and_split(
  p_item_id UUID,
  p_idempotency_key TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_item RECORD;
  v_order_id UUID;
  v_consignor_credit INTEGER;
  v_boutique_fee INTEGER;
  v_prev_hash TEXT;
  v_new_hash TEXT;
BEGIN
  -- Lock item row exclusively without waiting to prevent double-selling
  SELECT * INTO v_item
  FROM public.items
  WHERE id = p_item_id
  FOR UPDATE NOWAIT;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ITEM_NOT_FOUND';
  END IF;

  IF v_item.status NOT IN ('listed', 'marked_down') THEN
    RAISE EXCEPTION 'ITEM_ALREADY_SOLD_OR_UNAVAILABLE';
  END IF;

  -- Compute integer-cent split
  v_consignor_credit := ((v_item.current_price_cents * v_item.consignor_split_bps) + 5000) / 10000;
  v_boutique_fee := v_item.current_price_cents - v_consignor_credit;

  -- Transition item to sold_escrow
  UPDATE public.items
  SET status = 'sold_escrow', sold_at = now()
  WHERE id = p_item_id;

  -- Insert Order with 7-day return window
  INSERT INTO public.orders (
    item_id, shopper_id, boutique_id, final_price_cents, return_window_expires_at
  ) VALUES (
    p_item_id, auth.uid(), v_item.boutique_id, v_item.current_price_cents, now() + interval '7 days'
  ) RETURNING id INTO v_order_id;

  -- Double-entry ledger records (unsettled escrow)
  INSERT INTO public.consignor_ledger (
    boutique_id, consignor_id, item_id, order_id, tx_type, amount_cents, is_settled, idempotency_key
  ) VALUES
  (
    v_item.boutique_id, v_item.consignor_id, p_item_id, v_order_id,
    'sale_credit', v_consignor_credit, false, p_idempotency_key || ':consignor_credit'
  ),
  (
    v_item.boutique_id, v_item.consignor_id, p_item_id, v_order_id,
    'boutique_fee', v_boutique_fee, false, p_idempotency_key || ':boutique_fee'
  );

  -- Append provenance event
  SELECT event_hash INTO v_prev_hash
  FROM public.provenance_events
  WHERE item_id = p_item_id
  ORDER BY occurred_at DESC LIMIT 1;

  v_new_hash := encode(
    digest(v_prev_hash || '|' || p_item_id::text || '|SOLD_ESCROW|' || auth.uid()::text || '|' || now()::text, 'sha256'),
    'hex'
  );

  INSERT INTO public.provenance_events (
    item_id, actor_id, event_type, event_title, metadata, previous_hash, event_hash
  ) VALUES (
    p_item_id, auth.uid(), 'SOLD_ESCROW', 'Purchased by verified shopper (7-day escrow initiated)',
    jsonb_build_object('order_id', v_order_id, 'final_price_cents', v_item.current_price_cents),
    v_prev_hash, v_new_hash
  );

  RETURN v_order_id;
END;
$$;
```

---

## 4. Offline Intake Queue Specification (`OfflineIntakeQueueService`)
* **Trigger:** When `ItemIntakeWizardScreen` submits while `ConnectivityResult == none` or RPC times out.
* **Storage Payload:** Serializes a `DraftIntakeJob` JSON containing a client-generated `clientJobId` (UUIDv4), form fields, and local file system paths of the 4+ compressed WebP images.
* **Sync Loop:** On connectivity restoration, uploads missing WebP images to `item-media/{boutique_id}/{sku}/{index}.webp` with `upsert: true`, then invokes `complete_item_intake`. If `sku` already exists, marks local job complete to ensure idempotency.