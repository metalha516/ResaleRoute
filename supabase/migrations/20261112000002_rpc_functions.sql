-- ResaleRoute Atomic SECURITY DEFINER RPCs & Privilege Hardening
-- Migration: 20261112000002_rpc_functions.sql
-- Sources: docs/08_TDD.md, docs/09_Sequence_Diagrams.md, docs/02_AppFlow.md

-- ============================================================================
-- 1. COMPLETE ITEM INTAKE
-- Atomically creates an item, its markdown schedule, genesis provenance event,
-- and routes high-value garments (>= boutique threshold) to pending_auth.
-- ============================================================================
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
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_caller_role TEXT := auth.jwt() -> 'app_metadata' ->> 'role';
  v_caller_boutique_id UUID := NULLIF(auth.jwt() -> 'app_metadata' ->> 'boutique_id', '')::uuid;
  v_item_id UUID;
  v_now TIMESTAMPTZ;
  v_threshold_cents INTEGER;
  v_initial_status item_status;
  v_listed_at TIMESTAMPTZ;
  v_genesis_hash TEXT;
BEGIN
  IF v_caller_id IS NULL
     OR COALESCE(v_caller_role, '') NOT IN ('boutique_owner', 'boutique_staff')
     OR p_boutique_id IS NULL
     OR v_caller_boutique_id IS DISTINCT FROM p_boutique_id THEN
    RAISE EXCEPTION 'UNAUTHORIZED_INTAKE';
  END IF;

  IF p_base_price_cents IS NULL OR p_base_price_cents <= 0 THEN
    RAISE EXCEPTION 'INVALID_BASE_PRICE_CENTS';
  END IF;

  IF p_consignor_split_bps IS NULL OR p_consignor_split_bps NOT BETWEEN 1000 AND 9500 THEN
    RAISE EXCEPTION 'INVALID_CONSIGNOR_SPLIT_BPS';
  END IF;

  IF p_photo_urls IS NULL OR COALESCE(array_length(p_photo_urls, 1), 0) < 4 THEN
    RAISE EXCEPTION 'INSUFFICIENT_PHOTOS';
  END IF;

  SELECT high_value_auth_threshold_cents
  INTO v_threshold_cents
  FROM public.boutiques
  WHERE id = p_boutique_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'BOUTIQUE_NOT_FOUND';
  END IF;

  v_item_id := gen_random_uuid();
  v_now := now();

  IF p_base_price_cents >= COALESCE(v_threshold_cents, 25000) THEN
    v_initial_status := 'pending_auth';
    v_listed_at := NULL;
  ELSE
    v_initial_status := 'listed';
    v_listed_at := v_now;
  END IF;

  v_genesis_hash := encode(
    digest(
      'GENESIS_RESALEROUTE_V1|' ||
      v_item_id::text ||
      '|INTAKE_GRADED|' ||
      v_caller_id::text ||
      '|' ||
      to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
      'sha256'
    ),
    'hex'
  );

  INSERT INTO public.items (
    id,
    boutique_id,
    consignor_id,
    intake_staff_id,
    sku,
    title,
    brand,
    category,
    condition,
    condition_notes,
    photo_urls,
    base_price_cents,
    current_price_cents,
    consignor_split_bps,
    status,
    qr_provenance_hash,
    co2_saved_kg,
    water_saved_liters,
    listed_at,
    created_at
  ) VALUES (
    v_item_id,
    p_boutique_id,
    p_consignor_id,
    v_caller_id,
    p_sku,
    p_title,
    p_brand,
    p_category,
    p_condition,
    COALESCE(p_condition_notes, '{}'::jsonb),
    p_photo_urls,
    p_base_price_cents,
    p_base_price_cents,
    p_consignor_split_bps,
    v_initial_status,
    v_genesis_hash,
    COALESCE(p_co2_saved_kg, 6.50),
    COALESCE(p_water_saved_liters, 1800),
    v_listed_at,
    v_now
  );

  INSERT INTO public.markdown_schedules (item_id)
  VALUES (v_item_id);

  INSERT INTO public.provenance_events (
    item_id,
    actor_id,
    event_type,
    event_title,
    metadata,
    previous_hash,
    event_hash,
    occurred_at
  ) VALUES (
    v_item_id,
    v_caller_id,
    'INTAKE_GRADED',
    'Item received and graded (' || p_condition::text || ')',
    jsonb_build_object(
      'sku', p_sku,
      'base_price_cents', p_base_price_cents,
      'initial_status', v_initial_status::text
    ),
    'GENESIS_RESALEROUTE_V1',
    v_genesis_hash,
    v_now
  );

  IF v_initial_status = 'pending_auth' THEN
    INSERT INTO public.item_authentications (item_id, verdict)
    VALUES (v_item_id, 'pending');
  END IF;

  RETURN v_item_id;
END;
$$;

-- ============================================================================
-- 2. SUBMIT AUTHENTICATION VERDICT
-- Allows an authenticated third-party authenticator to approve or reject a
-- pending_auth item and append the chained provenance event.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.submit_auth_verdict(
  p_item_id UUID,
  p_verdict auth_verdict,
  p_serial_number_verified TEXT,
  p_inspection_report JSONB,
  p_rejection_reason TEXT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_caller_role TEXT := auth.jwt() -> 'app_metadata' ->> 'role';
  v_item RECORD;
  v_now TIMESTAMPTZ;
  v_prev_hash TEXT;
  v_event_type TEXT;
  v_new_hash TEXT;
  v_cert_hash TEXT;
BEGIN
  IF v_caller_id IS NULL OR COALESCE(v_caller_role, '') <> 'authenticator' THEN
    RAISE EXCEPTION 'UNAUTHORIZED_AUTHENTICATOR';
  END IF;

  IF p_verdict IS NULL OR p_verdict NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'INVALID_AUTH_VERDICT';
  END IF;

  SELECT *
  INTO v_item
  FROM public.items
  WHERE id = p_item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ITEM_NOT_FOUND';
  END IF;

  IF v_item.status <> 'pending_auth' THEN
    RAISE EXCEPTION 'ITEM_NOT_PENDING_AUTH';
  END IF;

  v_now := now();

  SELECT event_hash
  INTO v_prev_hash
  FROM public.provenance_events
  WHERE item_id = p_item_id
  ORDER BY occurred_at DESC
  LIMIT 1;

  v_prev_hash := COALESCE(v_prev_hash, v_item.qr_provenance_hash);

  IF p_verdict = 'approved' THEN
    v_event_type := 'AUTHENTICATED_LISTED';
    v_new_hash := encode(
      digest(
        v_prev_hash || '|' ||
        p_item_id::text || '|' ||
        v_event_type || '|' ||
        v_caller_id::text || '|' ||
        to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'sha256'
      ),
      'hex'
    );
    v_cert_hash := v_new_hash;

    UPDATE public.item_authentications
    SET verdict = 'approved',
        authenticator_id = v_caller_id,
        serial_number_verified = p_serial_number_verified,
        inspection_report = COALESCE(p_inspection_report, '{}'::jsonb),
        certificate_hash = v_cert_hash,
        reviewed_at = v_now
    WHERE item_id = p_item_id
      AND verdict = 'pending';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'PENDING_AUTHENTICATION_NOT_FOUND';
    END IF;

    UPDATE public.items
    SET status = 'listed',
        listed_at = v_now
    WHERE id = p_item_id;

    INSERT INTO public.provenance_events (
      item_id,
      actor_id,
      event_type,
      event_title,
      metadata,
      previous_hash,
      event_hash,
      occurred_at
    ) VALUES (
      p_item_id,
      v_caller_id,
      v_event_type,
      'Luxury authenticity verified and listed',
      jsonb_build_object(
        'certificate_hash', v_cert_hash,
        'serial_number_verified', p_serial_number_verified
      ),
      v_prev_hash,
      v_new_hash,
      v_now
    );
  ELSE
    IF NULLIF(trim(p_rejection_reason), '') IS NULL THEN
      RAISE EXCEPTION 'REJECTION_REASON_REQUIRED';
    END IF;

    v_event_type := 'AUTH_REJECTED';
    v_new_hash := encode(
      digest(
        v_prev_hash || '|' ||
        p_item_id::text || '|' ||
        v_event_type || '|' ||
        v_caller_id::text || '|' ||
        to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'sha256'
      ),
      'hex'
    );

    UPDATE public.item_authentications
    SET verdict = 'rejected',
        authenticator_id = v_caller_id,
        serial_number_verified = p_serial_number_verified,
        inspection_report = COALESCE(p_inspection_report, '{}'::jsonb) ||
          jsonb_build_object('rejection_reason', trim(p_rejection_reason)),
        reviewed_at = v_now
    WHERE item_id = p_item_id
      AND verdict = 'pending';

    IF NOT FOUND THEN
      RAISE EXCEPTION 'PENDING_AUTHENTICATION_NOT_FOUND';
    END IF;

    UPDATE public.items
    SET status = 'auth_rejected'
    WHERE id = p_item_id;

    INSERT INTO public.provenance_events (
      item_id,
      actor_id,
      event_type,
      event_title,
      metadata,
      previous_hash,
      event_hash,
      occurred_at
    ) VALUES (
      p_item_id,
      v_caller_id,
      v_event_type,
      'Authentication rejected: ' || trim(p_rejection_reason),
      jsonb_build_object('rejection_reason', trim(p_rejection_reason)),
      v_prev_hash,
      v_new_hash,
      v_now
    );
  END IF;
END;
$$;

-- ============================================================================
-- 3. PROCESS ORDER AND SPLIT
-- Pessimistically locks the item row (FOR UPDATE NOWAIT) to prevent concurrent
-- double-selling, creates an order with a 7-day escrow window, and inserts
-- double-entry consignor_ledger records with integer-cent half-up rounding.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_order_and_split(
  p_item_id UUID,
  p_idempotency_key TEXT
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_existing_order_id UUID;
  v_item RECORD;
  v_now TIMESTAMPTZ;
  v_order_id UUID;
  v_consignor_credit INTEGER;
  v_boutique_fee INTEGER;
  v_prev_hash TEXT;
  v_new_hash TEXT;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHENTICATED_CHECKOUT';
  END IF;

  IF NULLIF(trim(p_idempotency_key), '') IS NULL THEN
    RAISE EXCEPTION 'INVALID_IDEMPOTENCY_KEY';
  END IF;

  SELECT order_id
  INTO v_existing_order_id
  FROM public.consignor_ledger
  WHERE idempotency_key = p_idempotency_key || ':consignor_credit';

  IF FOUND THEN
    RETURN v_existing_order_id;
  END IF;

  -- Lock item row exclusively without waiting to prevent concurrent double-sells
  SELECT *
  INTO v_item
  FROM public.items
  WHERE id = p_item_id
  FOR UPDATE NOWAIT;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ITEM_NOT_FOUND';
  END IF;

  IF v_item.status NOT IN ('listed', 'marked_down') THEN
    RAISE EXCEPTION 'ITEM_ALREADY_SOLD_OR_UNAVAILABLE';
  END IF;

  v_now := now();

  -- Deterministic integer-cent half-up split
  v_consignor_credit := ((v_item.current_price_cents * v_item.consignor_split_bps) + 5000) / 10000;
  v_boutique_fee := v_item.current_price_cents - v_consignor_credit;

  UPDATE public.items
  SET status = 'sold_escrow',
      sold_at = v_now
  WHERE id = p_item_id;

  INSERT INTO public.orders (
    item_id,
    shopper_id,
    boutique_id,
    final_price_cents,
    return_window_expires_at,
    created_at
  ) VALUES (
    p_item_id,
    v_caller_id,
    v_item.boutique_id,
    v_item.current_price_cents,
    v_now + interval '7 days',
    v_now
  ) RETURNING id INTO v_order_id;

  INSERT INTO public.consignor_ledger (
    boutique_id,
    consignor_id,
    item_id,
    order_id,
    tx_type,
    amount_cents,
    is_settled,
    idempotency_key,
    created_at
  ) VALUES
  (
    v_item.boutique_id,
    v_item.consignor_id,
    p_item_id,
    v_order_id,
    'sale_credit',
    v_consignor_credit,
    false,
    p_idempotency_key || ':consignor_credit',
    v_now
  ),
  (
    v_item.boutique_id,
    v_item.consignor_id,
    p_item_id,
    v_order_id,
    'boutique_fee',
    v_boutique_fee,
    false,
    p_idempotency_key || ':boutique_fee',
    v_now
  );

  SELECT event_hash
  INTO v_prev_hash
  FROM public.provenance_events
  WHERE item_id = p_item_id
  ORDER BY occurred_at DESC
  LIMIT 1;

  v_prev_hash := COALESCE(v_prev_hash, v_item.qr_provenance_hash);

  v_new_hash := encode(
    digest(
      v_prev_hash || '|' ||
      p_item_id::text ||
      '|SOLD_ESCROW|' ||
      v_caller_id::text || '|' ||
      to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
      'sha256'
    ),
    'hex'
  );

  INSERT INTO public.provenance_events (
    item_id,
    actor_id,
    event_type,
    event_title,
    metadata,
    previous_hash,
    event_hash,
    occurred_at
  ) VALUES (
    p_item_id,
    v_caller_id,
    'SOLD_ESCROW',
    'Purchased by verified shopper (7-day escrow initiated)',
    jsonb_build_object(
      'order_id', v_order_id,
      'final_price_cents', v_item.current_price_cents
    ),
    v_prev_hash,
    v_new_hash,
    v_now
  );

  RETURN v_order_id;
END;
$$;

-- ============================================================================
-- 4. OPEN RETURN DISPUTE
-- Allows the order's shopper to open a dispute within the 7-day escrow window,
-- freezes consignor escrow via an append-only dispute_hold ledger entry, and
-- appends a DISPUTE_OPENED provenance event.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.open_return_dispute(
  p_order_id UUID,
  p_reason TEXT,
  p_evidence_urls TEXT[]
) RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_order RECORD;
  v_item RECORD;
  v_now TIMESTAMPTZ;
  v_dispute_id UUID;
  v_sale_credit INTEGER;
  v_prev_hash TEXT;
  v_new_hash TEXT;
BEGIN
  IF v_caller_id IS NULL THEN
    RAISE EXCEPTION 'UNAUTHENTICATED_DISPUTE';
  END IF;

  IF NULLIF(trim(p_reason), '') IS NULL THEN
    RAISE EXCEPTION 'DISPUTE_REASON_REQUIRED';
  END IF;

  v_now := now();

  SELECT *
  INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ORDER_NOT_FOUND';
  END IF;

  IF v_order.shopper_id <> v_caller_id THEN
    RAISE EXCEPTION 'UNAUTHORIZED_DISPUTE';
  END IF;

  IF v_now > v_order.return_window_expires_at THEN
    RAISE EXCEPTION 'RETURN_WINDOW_EXPIRED';
  END IF;

  SELECT *
  INTO v_item
  FROM public.items
  WHERE id = v_order.item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ITEM_NOT_FOUND';
  END IF;

  IF v_item.status <> 'sold_escrow' THEN
    RAISE EXCEPTION 'ITEM_NOT_IN_ESCROW';
  END IF;

  INSERT INTO public.disputes (
    order_id,
    shopper_id,
    reason,
    evidence_urls,
    status,
    created_at
  ) VALUES (
    p_order_id,
    v_caller_id,
    trim(p_reason),
    COALESCE(p_evidence_urls, '{}'),
    'open',
    v_now
  ) RETURNING id INTO v_dispute_id;

  UPDATE public.items
  SET status = 'disputed'
  WHERE id = v_order.item_id;

  SELECT amount_cents
  INTO v_sale_credit
  FROM public.consignor_ledger
  WHERE order_id = p_order_id
    AND tx_type = 'sale_credit'
  ORDER BY created_at ASC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ORIGINAL_SALE_CREDIT_NOT_FOUND';
  END IF;

  INSERT INTO public.consignor_ledger (
    boutique_id,
    consignor_id,
    item_id,
    order_id,
    tx_type,
    amount_cents,
    is_settled,
    idempotency_key,
    created_at
  ) VALUES (
    v_order.boutique_id,
    v_item.consignor_id,
    v_order.item_id,
    p_order_id,
    'dispute_hold',
    -v_sale_credit,
    false,
    p_order_id::text || ':dispute_hold:' || v_dispute_id::text,
    v_now
  );

  SELECT event_hash
  INTO v_prev_hash
  FROM public.provenance_events
  WHERE item_id = v_order.item_id
  ORDER BY occurred_at DESC
  LIMIT 1;

  v_prev_hash := COALESCE(v_prev_hash, v_item.qr_provenance_hash);

  v_new_hash := encode(
    digest(
      v_prev_hash || '|' ||
      v_order.item_id::text ||
      '|DISPUTE_OPENED|' ||
      v_caller_id::text || '|' ||
      to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
      'sha256'
    ),
    'hex'
  );

  INSERT INTO public.provenance_events (
    item_id,
    actor_id,
    event_type,
    event_title,
    metadata,
    previous_hash,
    event_hash,
    occurred_at
  ) VALUES (
    v_order.item_id,
    v_caller_id,
    'DISPUTE_OPENED',
    'Return dispute opened within 7-day escrow window',
    jsonb_build_object(
      'dispute_id', v_dispute_id,
      'order_id', p_order_id
    ),
    v_prev_hash,
    v_new_hash,
    v_now
  );

  RETURN v_dispute_id;
END;
$$;

-- ============================================================================
-- 5. RESOLVE DISPUTE
-- Allows the owning boutique_owner to deny a claim (append-only dispute_release
-- settled credit + item settled) or approve a refund (item refunded_relisted).
-- ============================================================================
CREATE OR REPLACE FUNCTION public.resolve_dispute(
  p_dispute_id UUID,
  p_resolution dispute_status,
  p_resolution_notes TEXT
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_caller_id UUID := auth.uid();
  v_caller_role TEXT := auth.jwt() -> 'app_metadata' ->> 'role';
  v_caller_boutique_id UUID := NULLIF(auth.jwt() -> 'app_metadata' ->> 'boutique_id', '')::uuid;
  v_dispute RECORD;
  v_order RECORD;
  v_item RECORD;
  v_now TIMESTAMPTZ;
  v_sale_credit INTEGER;
  v_prev_hash TEXT;
  v_new_hash TEXT;
BEGIN
  IF v_caller_id IS NULL OR COALESCE(v_caller_role, '') <> 'boutique_owner' THEN
    RAISE EXCEPTION 'UNAUTHORIZED_DISPUTE_RESOLUTION';
  END IF;

  IF p_resolution IS NULL OR p_resolution NOT IN ('denied_closed', 'approved_refund') THEN
    RAISE EXCEPTION 'INVALID_DISPUTE_RESOLUTION';
  END IF;

  SELECT *
  INTO v_dispute
  FROM public.disputes
  WHERE id = p_dispute_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'DISPUTE_NOT_FOUND';
  END IF;

  IF v_dispute.status NOT IN ('open', 'under_review') THEN
    RAISE EXCEPTION 'DISPUTE_ALREADY_RESOLVED';
  END IF;

  SELECT *
  INTO v_order
  FROM public.orders
  WHERE id = v_dispute.order_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ORDER_NOT_FOUND';
  END IF;

  IF v_caller_boutique_id IS DISTINCT FROM v_order.boutique_id THEN
    RAISE EXCEPTION 'UNAUTHORIZED_BOUTIQUE_DISPUTE';
  END IF;

  SELECT *
  INTO v_item
  FROM public.items
  WHERE id = v_order.item_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ITEM_NOT_FOUND';
  END IF;

  v_now := now();

  UPDATE public.disputes
  SET status = p_resolution,
      resolution_notes = p_resolution_notes,
      resolved_at = v_now
  WHERE id = p_dispute_id;

  SELECT event_hash
  INTO v_prev_hash
  FROM public.provenance_events
  WHERE item_id = v_order.item_id
  ORDER BY occurred_at DESC
  LIMIT 1;

  v_prev_hash := COALESCE(v_prev_hash, v_item.qr_provenance_hash);

  IF p_resolution = 'denied_closed' THEN
    SELECT amount_cents
    INTO v_sale_credit
    FROM public.consignor_ledger
    WHERE order_id = v_order.id
      AND tx_type = 'sale_credit'
    ORDER BY created_at ASC
    LIMIT 1;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'ORIGINAL_SALE_CREDIT_NOT_FOUND';
    END IF;

    INSERT INTO public.consignor_ledger (
      boutique_id,
      consignor_id,
      item_id,
      order_id,
      tx_type,
      amount_cents,
      is_settled,
      idempotency_key,
      created_at
    ) VALUES (
      v_order.boutique_id,
      v_item.consignor_id,
      v_order.item_id,
      v_order.id,
      'dispute_release',
      v_sale_credit,
      true,
      v_order.id::text || ':dispute_release:' || p_dispute_id::text,
      v_now
    );

    UPDATE public.items
    SET status = 'settled'
    WHERE id = v_order.item_id;

    v_new_hash := encode(
      digest(
        v_prev_hash || '|' ||
        v_order.item_id::text ||
        '|DISPUTE_DENIED_SETTLED|' ||
        v_caller_id::text || '|' ||
        to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'sha256'
      ),
      'hex'
    );

    INSERT INTO public.provenance_events (
      item_id,
      actor_id,
      event_type,
      event_title,
      metadata,
      previous_hash,
      event_hash,
      occurred_at
    ) VALUES (
      v_order.item_id,
      v_caller_id,
      'DISPUTE_DENIED_SETTLED',
      'Return claim denied; escrow released to consignor',
      jsonb_build_object(
        'dispute_id', p_dispute_id,
        'order_id', v_order.id
      ),
      v_prev_hash,
      v_new_hash,
      v_now
    );
  ELSE
    UPDATE public.items
    SET status = 'refunded_relisted',
        listed_at = v_now,
        sold_at = NULL
    WHERE id = v_order.item_id;

    v_new_hash := encode(
      digest(
        v_prev_hash || '|' ||
        v_order.item_id::text ||
        '|RETURN_ACCEPTED_RELISTED|' ||
        v_caller_id::text || '|' ||
        to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'sha256'
      ),
      'hex'
    );

    INSERT INTO public.provenance_events (
      item_id,
      actor_id,
      event_type,
      event_title,
      metadata,
      previous_hash,
      event_hash,
      occurred_at
    ) VALUES (
      v_order.item_id,
      v_caller_id,
      'RETURN_ACCEPTED_RELISTED',
      'Return approved and item relisted to storefront',
      jsonb_build_object(
        'dispute_id', p_dispute_id,
        'order_id', v_order.id
      ),
      v_prev_hash,
      v_new_hash,
      v_now
    );
  END IF;
END;
$$;

-- ============================================================================
-- 6. SETTLE EXPIRED ESCROWS
-- Restricted to service_role / pg_cron. Releases undisputed orders past the
-- 7-day return window using append-only compensating consignor_ledger rows
-- and NULL-safe SYSTEM_ESCROW_CRON SHA-256 provenance chaining.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.settle_expired_escrows()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_now TIMESTAMPTZ := now();
  v_settled_count INTEGER := 0;
  v_rec RECORD;
  v_sale_credit INTEGER;
  v_prev_hash TEXT;
  v_new_hash TEXT;
BEGIN
  FOR v_rec IN
    SELECT
      o.id AS order_id,
      o.item_id,
      o.boutique_id,
      i.consignor_id,
      i.qr_provenance_hash
    FROM public.orders o
    JOIN public.items i ON i.id = o.item_id
    WHERE i.status = 'sold_escrow'
      AND o.return_window_expires_at < v_now
      AND NOT EXISTS (
        SELECT 1
        FROM public.disputes d
        WHERE d.order_id = o.id
      )
    FOR UPDATE OF o, i SKIP LOCKED
  LOOP
    SELECT amount_cents
    INTO v_sale_credit
    FROM public.consignor_ledger
    WHERE order_id = v_rec.order_id
      AND tx_type = 'sale_credit'
    ORDER BY created_at ASC
    LIMIT 1;

    IF NOT FOUND THEN
      CONTINUE;
    END IF;

    -- Append-only compensating debit/credit pair (never mutate existing rows)
    INSERT INTO public.consignor_ledger (
      boutique_id,
      consignor_id,
      item_id,
      order_id,
      tx_type,
      amount_cents,
      is_settled,
      idempotency_key,
      created_at
    ) VALUES
    (
      v_rec.boutique_id,
      v_rec.consignor_id,
      v_rec.item_id,
      v_rec.order_id,
      'sale_credit',
      -v_sale_credit,
      false,
      v_rec.order_id::text || ':escrow_release_debit',
      v_now
    ),
    (
      v_rec.boutique_id,
      v_rec.consignor_id,
      v_rec.item_id,
      v_rec.order_id,
      'sale_credit',
      v_sale_credit,
      true,
      v_rec.order_id::text || ':escrow_release_credit',
      v_now
    );

    UPDATE public.items
    SET status = 'settled'
    WHERE id = v_rec.item_id;

    SELECT event_hash
    INTO v_prev_hash
    FROM public.provenance_events
    WHERE item_id = v_rec.item_id
    ORDER BY occurred_at DESC
    LIMIT 1;

    v_prev_hash := COALESCE(v_prev_hash, v_rec.qr_provenance_hash);

    v_new_hash := encode(
      digest(
        v_prev_hash || '|' ||
        v_rec.item_id::text ||
        '|ESCROW_SETTLED|' ||
        COALESCE(auth.uid()::text, 'SYSTEM_ESCROW_CRON') || '|' ||
        to_char(v_now AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
        'sha256'
      ),
      'hex'
    );

    INSERT INTO public.provenance_events (
      item_id,
      actor_id,
      event_type,
      event_title,
      metadata,
      previous_hash,
      event_hash,
      occurred_at
    ) VALUES (
      v_rec.item_id,
      auth.uid(),
      'ESCROW_SETTLED',
      '7-day return window expired; escrow settled to consignor',
      jsonb_build_object(
        'order_id', v_rec.order_id,
        'settled_by', COALESCE(auth.uid()::text, 'SYSTEM_ESCROW_CRON')
      ),
      v_prev_hash,
      v_new_hash,
      v_now
    );

    v_settled_count := v_settled_count + 1;
  END LOOP;

  RETURN v_settled_count;
END;
$$;

-- ============================================================================
-- 7. EXPLICIT FUNCTION PRIVILEGE HARDENING & PG_CRON SCHEDULE
-- ============================================================================
REVOKE ALL ON FUNCTION public.complete_item_intake(UUID, UUID, TEXT, TEXT, TEXT, TEXT, condition_grade, JSONB, TEXT[], INTEGER, INTEGER, NUMERIC, INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.complete_item_intake(UUID, UUID, TEXT, TEXT, TEXT, TEXT, condition_grade, JSONB, TEXT[], INTEGER, INTEGER, NUMERIC, INTEGER) TO authenticated;

REVOKE ALL ON FUNCTION public.submit_auth_verdict(UUID, auth_verdict, TEXT, JSONB, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_auth_verdict(UUID, auth_verdict, TEXT, JSONB, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.process_order_and_split(UUID, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.process_order_and_split(UUID, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.open_return_dispute(UUID, TEXT, TEXT[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.open_return_dispute(UUID, TEXT, TEXT[]) TO authenticated;

REVOKE ALL ON FUNCTION public.resolve_dispute(UUID, dispute_status, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_dispute(UUID, dispute_status, TEXT) TO authenticated;

REVOKE ALL ON FUNCTION public.settle_expired_escrows() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.settle_expired_escrows() TO service_role;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'settle-expired-escrows',
      '5 0 * * *',
      'SELECT public.settle_expired_escrows();'
    );
  END IF;
END;
$$;
