-- Migration: #42 JSONB→relational slice 2 — products flat columns
--
-- Same trigger-based approach as slice 1 (bills).  Adds nullable flat
-- columns to the products table that mirror the most query-relevant
-- fields from data JSONB.  A BEFORE INSERT OR UPDATE trigger extracts
-- them automatically — no Dart or RPC changes in this slice.
--
-- product_batches is deferred to slice 3 because the complete_bill()
-- RPC mutates data->'batches' via jsonb_set, requiring an RPC rewrite
-- to write to a relational table instead.
--
-- Flat columns added
-- ─────────────────
--   product_name          TEXT      – data->>'name'
--   selling_price         NUMERIC   – data->>'sellingPrice'
--   cost_price            NUMERIC   – data->>'costPrice'
--   stock_quantity        INT       – data->>'stockQuantity'
--   category              TEXT      – data->>'category'
--   hsn_code              TEXT      – data->>'hsnCode'
--   gst_rate              NUMERIC   – data->>'gstRate'
--   is_service            BOOLEAN   – data->>'isService'
--   low_stock_threshold   INT       – data->>'lowStockThreshold'
--   reorder_level         INT       – data->>'reorderLevel'
--   preferred_supplier_id TEXT      – data->>'preferredSupplierId'

-- ── 1. Add flat columns ──────────────────────────────────────────────────────

alter table products
  add column if not exists product_name          text,
  add column if not exists selling_price         numeric,
  add column if not exists cost_price            numeric,
  add column if not exists stock_quantity        int,
  add column if not exists category              text,
  add column if not exists hsn_code              text,
  add column if not exists gst_rate              numeric,
  add column if not exists is_service            boolean,
  add column if not exists low_stock_threshold   int,
  add column if not exists reorder_level         int,
  add column if not exists preferred_supplier_id text;

-- ── 2. Trigger function ──────────────────────────────────────────────────────

create or replace function products_extract_flat_columns()
returns trigger
language plpgsql
as $$
begin
  new.product_name          := new.data->>'name';
  new.selling_price         := (new.data->>'sellingPrice')::numeric;
  new.cost_price            := (new.data->>'costPrice')::numeric;
  new.stock_quantity        := (new.data->>'stockQuantity')::int;
  new.category              := new.data->>'category';
  new.hsn_code              := new.data->>'hsnCode';
  new.gst_rate              := coalesce((new.data->>'gstRate')::numeric, 0);
  new.is_service            := coalesce((new.data->>'isService')::boolean, false);
  new.low_stock_threshold   := (new.data->>'lowStockThreshold')::int;
  new.reorder_level         := (new.data->>'reorderLevel')::int;
  new.preferred_supplier_id := new.data->>'preferredSupplierId';
  return new;
end;
$$;

drop trigger if exists products_extract_flat_columns_trigger on products;

create trigger products_extract_flat_columns_trigger
before insert or update on products
for each row execute function products_extract_flat_columns();

-- ── 3. Backfill existing rows ────────────────────────────────────────────────

update products set data = data;

-- ── 4. Indexes ───────────────────────────────────────────────────────────────

create index if not exists products_name_idx
  on products (business_id, product_name);

create index if not exists products_category_idx
  on products (business_id, category)
  where category is not null;

create index if not exists products_low_stock_idx
  on products (business_id, stock_quantity, low_stock_threshold)
  where is_service = false;

create index if not exists products_supplier_idx
  on products (business_id, preferred_supplier_id)
  where preferred_supplier_id is not null;

-- ── 5. Inventory helper views ────────────────────────────────────────────────

create or replace view low_stock_products as
select
  business_id,
  id,
  product_name,
  stock_quantity,
  low_stock_threshold,
  reorder_level,
  preferred_supplier_id,
  category
from products
where is_service = false
  and low_stock_threshold is not null
  and stock_quantity <= low_stock_threshold;

create or replace view inventory_value_summary as
select
  business_id,
  category,
  count(*)                                        as product_count,
  sum(stock_quantity)                              as total_units,
  sum(stock_quantity * coalesce(cost_price, 0))    as total_cost_value,
  sum(stock_quantity * coalesce(selling_price, 0)) as total_selling_value
from products
where is_service = false
group by business_id, category;
