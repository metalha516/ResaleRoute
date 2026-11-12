-- ResaleRoute Initial PostgreSQL 15 Schema, Triggers, RLS & Immutability
-- Migration: 20261112000001_initial_schema.sql
-- Source: docs/05_Schema.md

-- ============================================================================
-- SECTION 1: EXTENSIONS, ENUMS, TABLES, AND PERFORMANCE INDEXES
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pg_cron";

-- 1. ENUMERATED TYPES
CREATE TYPE user_role AS ENUM (
  'boutique_owner',
  'boutique_staff',
  'consignor',
  'authenticator',
  'shopper'
);

CREATE TYPE condition_grade AS ENUM (
  'mint',
  'excellent',
  'very_good',
  'good',
  'fair'
);

CREATE TYPE item_status AS ENUM (
  'draft',
  'pending_auth',
  'authenticated',
  'auth_rejected',
  'listed',
  'marked_down',
  'sold_escrow',
  'settled',
  'disputed',
  'refunded_relisted',
  'returned_to_consignor'
);

CREATE TYPE auth_verdict AS ENUM ('pending', 'approved', 'rejected');

CREATE TYPE ledger_tx_type AS ENUM (
  'sale_credit',
  'boutique_fee',
  'dispute_hold',
  'dispute_release',
  'payout_debit'
);

CREATE TYPE dispute_status AS ENUM (
  'open',
  'under_review',
  'approved_refund',
  'denied_closed'
);

-- 2. CORE TABLES
CREATE TABLE boutiques (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  default_consignor_split_bps INTEGER NOT NULL DEFAULT 7000
    CHECK (default_consignor_split_bps BETWEEN 1000 AND 9500),
  high_value_auth_threshold_cents INTEGER NOT NULL DEFAULT 25000,
  webhook_url TEXT,
  webhook_secret TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  boutique_id UUID REFERENCES boutiques(id) ON DELETE SET NULL,
  role user_role NOT NULL DEFAULT 'shopper',
  full_name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT,
  payout_account_ref TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  boutique_id UUID NOT NULL REFERENCES boutiques(id) ON DELETE CASCADE,
  consignor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  intake_staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  sku TEXT UNIQUE NOT NULL,
  title TEXT NOT NULL,
  brand TEXT NOT NULL,
  category TEXT NOT NULL,
  condition condition_grade NOT NULL,
  condition_notes JSONB NOT NULL DEFAULT '{}'::jsonb,
  photo_urls TEXT[] NOT NULL CHECK (array_length(photo_urls, 1) >= 4),
  base_price_cents INTEGER NOT NULL CHECK (base_price_cents > 0),
  current_price_cents INTEGER NOT NULL CHECK (current_price_cents > 0),
  consignor_split_bps INTEGER NOT NULL
    CHECK (consignor_split_bps BETWEEN 1000 AND 9500),
  status item_status NOT NULL DEFAULT 'draft',
  qr_provenance_hash TEXT UNIQUE NOT NULL,
  co2_saved_kg NUMERIC(6,2) NOT NULL DEFAULT 6.50,
  water_saved_liters INTEGER NOT NULL DEFAULT 1800,
  listed_at TIMESTAMPTZ,
  sold_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE item_authentications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  authenticator_id UUID REFERENCES profiles(id) ON DELETE RESTRICT,
  verdict auth_verdict NOT NULL DEFAULT 'pending',
  serial_number_verified TEXT,
  inspection_report JSONB NOT NULL DEFAULT '{}'::jsonb,
  certificate_hash TEXT UNIQUE,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE markdown_schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID UNIQUE NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  day_30_discount_bps INTEGER NOT NULL DEFAULT 1500,
  day_60_discount_bps INTEGER NOT NULL DEFAULT 3000,
  day_90_discount_bps INTEGER NOT NULL DEFAULT 5000,
  applied_tier INTEGER NOT NULL DEFAULT 0 CHECK (applied_tier IN (0, 30, 60, 90)),
  last_markdown_applied_at TIMESTAMPTZ,
  is_paused BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE provenance_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID NOT NULL REFERENCES items(id) ON DELETE CASCADE,
  actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  event_type TEXT NOT NULL,
  event_title TEXT NOT NULL,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  previous_hash TEXT NOT NULL,
  event_hash TEXT UNIQUE NOT NULL,
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  item_id UUID UNIQUE NOT NULL REFERENCES items(id) ON DELETE RESTRICT,
  shopper_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  boutique_id UUID NOT NULL REFERENCES boutiques(id) ON DELETE RESTRICT,
  final_price_cents INTEGER NOT NULL CHECK (final_price_cents > 0),
  return_window_expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE consignor_ledger (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  boutique_id UUID NOT NULL REFERENCES boutiques(id) ON DELETE RESTRICT,
  consignor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  item_id UUID REFERENCES items(id) ON DELETE RESTRICT,
  order_id UUID REFERENCES orders(id) ON DELETE RESTRICT,
  tx_type ledger_tx_type NOT NULL,
  amount_cents INTEGER NOT NULL,
  is_settled BOOLEAN NOT NULL DEFAULT false,
  idempotency_key TEXT UNIQUE NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE disputes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID UNIQUE NOT NULL REFERENCES orders(id) ON DELETE RESTRICT,
  shopper_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  reason TEXT NOT NULL,
  evidence_urls TEXT[] NOT NULL DEFAULT '{}',
  status dispute_status NOT NULL DEFAULT 'open',
  resolution_notes TEXT,
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. PERFORMANCE INDEXES
CREATE INDEX idx_items_boutique_status ON items(boutique_id, status);
CREATE INDEX idx_items_consignor ON items(consignor_id);
CREATE INDEX idx_items_qr_hash ON items(qr_provenance_hash);
CREATE INDEX idx_items_aging ON items(status, listed_at)
  WHERE status IN ('listed', 'marked_down');
CREATE INDEX idx_auth_queue ON item_authentications(verdict, created_at);
CREATE INDEX idx_ledger_consignor_settled ON consignor_ledger(consignor_id, is_settled);
CREATE INDEX idx_provenance_item_time ON provenance_events(item_id, occurred_at DESC);

-- ============================================================================
-- SECTION 2: TRIGGERS, ROW-LEVEL SECURITY (RLS) & IMMUTABILITY ENFORCEMENT
-- ============================================================================

-- 4. AUTH TRIGGERS & PRIVILEGE ESCALATION GUARD
-- Sync profile role and boutique_id into auth.users app_metadata for zero-join RLS checks
CREATE OR REPLACE FUNCTION public.sync_profile_claims()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE auth.users
  SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb) ||
    jsonb_build_object('role', NEW.role, 'boutique_id', NEW.boutique_id)
  WHERE id = NEW.id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_profile_claims
AFTER INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.sync_profile_claims();

-- Auto-create default shopper profile on auth.users signup (ignores client role/boutique_id metadata)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.email, NEW.id::text || '@placeholder.local'),
    COALESCE(
      NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
      split_part(COALESCE(NEW.email, 'User'), '@', 1)
    ),
    'shopper'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Prevent non-privileged client sessions from mutating role or boutique_id on profiles
CREATE OR REPLACE FUNCTION public.prevent_profile_role_escalation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF COALESCE(auth.role(), '') IN ('anon', 'authenticated') THEN
    IF NEW.role IS DISTINCT FROM OLD.role OR NEW.boutique_id IS DISTINCT FROM OLD.boutique_id THEN
      RAISE EXCEPTION 'Permission denied: cannot modify role or boutique_id';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_prevent_profile_role_escalation
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.prevent_profile_role_escalation();

-- 5. ENABLE ROW-LEVEL SECURITY ON ALL 9 TABLES
ALTER TABLE boutiques ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE item_authentications ENABLE ROW LEVEL SECURITY;
ALTER TABLE markdown_schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE provenance_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE consignor_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;

-- 6. STRICT RLS POLICIES

-- Boutiques Policies (public non-secret storefront read; owner-only update)
CREATE POLICY "Public view boutique storefront metadata"
  ON boutiques FOR SELECT
  USING (true);

CREATE POLICY "Boutique owners update own boutique"
  ON boutiques FOR UPDATE
  USING (
    id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    AND (auth.jwt() -> 'app_metadata' ->> 'role') = 'boutique_owner'
  )
  WITH CHECK (
    id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    AND (auth.jwt() -> 'app_metadata' ->> 'role') = 'boutique_owner'
  );

-- Profiles Policies
CREATE POLICY "Users view own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Boutique staff view boutique and consignor profiles"
  ON profiles FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
    AND (
      boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
      OR role = 'consignor'
    )
  );

CREATE POLICY "Users update own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Items Policies
CREATE POLICY "Public shoppers view active and sold items"
  ON items FOR SELECT
  USING (status IN ('listed', 'marked_down', 'sold_escrow', 'settled'));

CREATE POLICY "Consignors view their own consigned items"
  ON items FOR SELECT
  USING (auth.uid() = consignor_id);

CREATE POLICY "Authenticators view auth queue items"
  ON items FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'authenticator'
    AND status IN ('pending_auth', 'authenticated', 'auth_rejected')
  );

CREATE POLICY "Boutique staff manage own boutique items"
  ON items FOR ALL
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid = boutique_id
    AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
  )
  WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid = boutique_id
    AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
  );

-- Item Authentications Policies
CREATE POLICY "Authenticators inspect assigned queue"
  ON item_authentications FOR ALL
  USING ((auth.jwt() -> 'app_metadata' ->> 'role') = 'authenticator')
  WITH CHECK ((auth.jwt() -> 'app_metadata' ->> 'role') = 'authenticator');

CREATE POLICY "Boutique staff view own boutique item authentications"
  ON item_authentications FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
    AND EXISTS (
      SELECT 1 FROM items
      WHERE items.id = item_authentications.item_id
        AND items.boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    )
  );

-- Markdown Schedules Policies
CREATE POLICY "Boutique staff view own boutique markdown schedules"
  ON markdown_schedules FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
    AND EXISTS (
      SELECT 1 FROM items
      WHERE items.id = markdown_schedules.item_id
        AND items.boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    )
  );

CREATE POLICY "Boutique staff update own boutique markdown schedules"
  ON markdown_schedules FOR UPDATE
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
    AND EXISTS (
      SELECT 1 FROM items
      WHERE items.id = markdown_schedules.item_id
        AND items.boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    )
  )
  WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
    AND EXISTS (
      SELECT 1 FROM items
      WHERE items.id = markdown_schedules.item_id
        AND items.boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    )
  );

CREATE POLICY "Consignors view own item markdown schedules"
  ON markdown_schedules FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM items
      WHERE items.id = markdown_schedules.item_id
        AND items.consignor_id = auth.uid()
    )
  );

-- Provenance Events Policy (Public Read, Append-Only via Security Definer RPCs)
CREATE POLICY "Anyone can view provenance chain"
  ON provenance_events FOR SELECT
  USING (true);

-- Orders Policies
CREATE POLICY "Shoppers view own orders"
  ON orders FOR SELECT
  USING (auth.uid() = shopper_id);

CREATE POLICY "Boutique staff view own boutique orders"
  ON orders FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid = boutique_id
    AND (auth.jwt() -> 'app_metadata' ->> 'role') IN ('boutique_owner', 'boutique_staff')
  );

-- Consignor Ledger Policies (Append-Only, Read Isolated)
CREATE POLICY "Consignors read own ledger entries"
  ON consignor_ledger FOR SELECT
  USING (auth.uid() = consignor_id);

CREATE POLICY "Boutique owners read boutique ledger entries"
  ON consignor_ledger FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid = boutique_id
    AND (auth.jwt() -> 'app_metadata' ->> 'role') = 'boutique_owner'
  );

-- Disputes Policies
CREATE POLICY "Shoppers view own disputes"
  ON disputes FOR SELECT
  USING (auth.uid() = shopper_id);

CREATE POLICY "Boutique owners view own boutique disputes"
  ON disputes FOR SELECT
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'boutique_owner'
    AND EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = disputes.order_id
        AND orders.boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    )
  );

CREATE POLICY "Boutique owners update own boutique disputes"
  ON disputes FOR UPDATE
  USING (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'boutique_owner'
    AND EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = disputes.order_id
        AND orders.boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    )
  )
  WITH CHECK (
    (auth.jwt() -> 'app_metadata' ->> 'role') = 'boutique_owner'
    AND EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = disputes.order_id
        AND orders.boutique_id = (auth.jwt() -> 'app_metadata' ->> 'boutique_id')::uuid
    )
  );

-- 7. APPEND-ONLY IMMUTABILITY & COLUMN-LEVEL SECRET GRANTS
REVOKE UPDATE, DELETE ON public.consignor_ledger, public.provenance_events FROM anon, authenticated;
REVOKE INSERT ON public.consignor_ledger, public.provenance_events FROM anon, authenticated;

-- Protect boutiques.webhook_secret from client SELECT queries.
-- Note: client/PostgREST queries MUST project explicit non-secret columns rather than SELECT *.
REVOKE ALL ON public.boutiques FROM anon, authenticated;
GRANT SELECT (id, name, slug, default_consignor_split_bps, high_value_auth_threshold_cents, webhook_url, created_at) ON public.boutiques TO anon, authenticated;
GRANT UPDATE (name, default_consignor_split_bps, high_value_auth_threshold_cents, webhook_url, webhook_secret) ON public.boutiques TO authenticated;

