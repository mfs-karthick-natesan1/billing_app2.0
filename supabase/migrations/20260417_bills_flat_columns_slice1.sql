-- Migration: #42 JSONB→relational slice 1 — bills flat columns
--
-- Adds nullable flat columns to the bills table that mirror the most
-- query-relevant fields from the data JSONB blob.  A BEFORE INSERT OR UPDATE
-- trigger extracts these automatically, so no changes to db_service.dart or
-- the complete_bill() RPC are needed in this slice.
--
-- Once all rows are backfilled and the trigger is proven in production,
-- slice 2 will add NOT NULL constraints, create covering indexes, and begin
-- routing GSTR / date-range queries to the flat columns instead of
-- deserialising JSONB on the client.
--
-- Flat columns added
-- ─────────────────
--   bill_number     TEXT      – bills.data->>'billNumber'
--   bill_timestamp  TIMESTAMPTZ – bills.data->>'timestamp' (ISO-8601 from Dart)
--   payment_mode    TEXT      – bills.data->>'paymentMode'
--   grand_total     NUMERIC   – bills.data->>'grandTotal'
--   customer_id     TEXT      – bills.data->'customer'->>'id'  (nullable)
--   cgst            NUMERIC   – bills.data->>'cgst'
--   sgst            NUMERIC   – bills.data->>'sgst'
--   igst            NUMERIC   – bills.data->>'igst'
--
-- All columns are nullable so existing rows and the current RPC path are
-- unaffected during the transition.

-- ── 1. Add flat columns ──────────────────────────────────────────────────────

alter table bills
  add column if not exists bill_number    text,
  add column if not exists bill_timestamp timestamptz,
  add column if not exists payment_mode   text,
  add column if not exists grand_total    numeric,
  add column if not exists customer_id    text,
  add column if not exists cgst           numeric,
  add column if not exists sgst           numeric,
  add column if not exists igst           numeric;

-- ── 2. Trigger function — extract flat fields from data JSONB ────────────────

create or replace function bills_extract_flat_columns()
returns trigger
language plpgsql
as $$
begin
  new.bill_number    := new.data->>'billNumber';
  new.bill_timestamp := (new.data->>'timestamp')::timestamptz;
  new.payment_mode   := new.data->>'paymentMode';
  new.grand_total    := (new.data->>'grandTotal')::numeric;
  new.customer_id    := new.data->'customer'->>'id';
  new.cgst           := coalesce((new.data->>'cgst')::numeric, 0);
  new.sgst           := coalesce((new.data->>'sgst')::numeric, 0);
  new.igst           := coalesce((new.data->>'igst')::numeric, 0);
  return new;
end;
$$;

-- Drop before recreating so the migration is idempotent (re-runnable).
drop trigger if exists bills_extract_flat_columns_trigger on bills;

create trigger bills_extract_flat_columns_trigger
before insert or update on bills
for each row execute function bills_extract_flat_columns();

-- ── 3. Backfill existing rows ────────────────────────────────────────────────
-- Touching data fires the trigger which populates the new columns.

update bills set data = data;

-- ── 4. Indexes for the query patterns unlocked by flat columns ───────────────
-- Partial index on credit bills — most useful for the receivables / aging view.
-- Concurrent creation not supported inside transactions; run separately if
-- table is large in production (pg_stat_user_tables to check row count first).

create index if not exists bills_timestamp_idx
  on bills (business_id, bill_timestamp desc);

create index if not exists bills_customer_idx
  on bills (business_id, customer_id)
  where customer_id is not null;

create index if not exists bills_payment_mode_idx
  on bills (business_id, payment_mode);

-- ── 5. Lightweight GSTR helper view ─────────────────────────────────────────
-- Returns per-business GST totals per calendar month directly from flat
-- columns — no JSONB deserialisation.  Used by slice 2 to validate that the
-- flat columns match what the client currently computes.

create or replace view gstr_monthly_summary as
select
  business_id,
  date_trunc('month', bill_timestamp) as month,
  payment_mode,
  count(*)                            as bill_count,
  sum(grand_total)                    as total_revenue,
  sum(cgst)                           as total_cgst,
  sum(sgst)                           as total_sgst,
  sum(igst)                           as total_igst
from bills
where bill_timestamp is not null
group by business_id, date_trunc('month', bill_timestamp), payment_mode;
