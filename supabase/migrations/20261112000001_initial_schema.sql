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
