-- Migration: #42 JSONB→relational slice 4 — bill_line_items table
--
-- Extracts data->'lineItems' from the bills JSONB blob into a proper
-- relational table.  Enables server-side product sales analytics,
-- HSN-wise tax reporting (GSTR-1), and per-product revenue queries
-- without deserialising the full JSONB on the client.
--
-- Dart continues to read/write line items via data->'lineItems'.
-- An AFTER INSERT OR UPDATE trigger on bills syncs the JSONB array
-- into the bill_line_items table automatically.
--
-- No RPC changes — complete_bill() inserts into bills (which fires
-- the trigger), so line items are extracted on every bill creation.

-- ── 1. Create bill_line_items table ──────────────────────────────────────────

create table if not exists bill_line_items (
  id              text        not null default gen_random_uuid()::text primary key,
  bill_id         text        not null references bills(id) on delete cascade,
  business_id     text        not null,
  product_id      text,
  product_name    text,
  batch_id        text,
  quantity        numeric     not null default 1,
  selling_price   numeric     not null default 0,
  cost_price      numeric     not null default 0,
  gst_rate        numeric     not null default 0,
  gst_inclusive    boolean     not null default false,
  discount_pct    numeric     not null default 0,
  hsn_code        text,
  line_total      numeric     generated always as (selling_price * quantity) stored,
  discount_amount numeric     generated always as (selling_price * quantity * discount_pct / 100) stored
);

-- ── 2. RLS ───────────────────────────────────────────────────────────────────

alter table bill_line_items enable row level security;

create policy "bill_line_items_select"
  on bill_line_items for select
  using (business_id = current_business_id());

create policy "bill_line_items_insert"
  on bill_line_items for insert
  with check (business_id = current_business_id());

create policy "bill_line_items_update"
  on bill_line_items for update
  using (business_id = current_business_id());

create policy "bill_line_items_delete"
  on bill_line_items for delete
  using (business_id = current_business_id());

-- ── 3. Indexes ───────────────────────────────────────────────────────────────

create index if not exists bill_line_items_bill_idx
  on bill_line_items (bill_id);

create index if not exists bill_line_items_business_idx
  on bill_line_items (business_id);

create index if not exists bill_line_items_product_idx
  on bill_line_items (business_id, product_id)
  where product_id is not null;

create index if not exists bill_line_items_hsn_idx
  on bill_line_items (business_id, hsn_code)
  where hsn_code is not null;

-- ── 4. Sync trigger: bills.data->'lineItems' → bill_line_items ──────────────

create or replace function sync_bill_line_items_from_jsonb()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item jsonb;
  v_product jsonb;
begin
  -- Remove old line item rows for this bill
  delete from bill_line_items where bill_id = new.id;

  -- Extract line items from JSONB
  if new.data->'lineItems' is not null
     and jsonb_typeof(new.data->'lineItems') = 'array'
     and jsonb_array_length(new.data->'lineItems') > 0
  then
    for v_item in select * from jsonb_array_elements(new.data->'lineItems') loop
      v_product := v_item->'product';

      insert into bill_line_items (
        bill_id, business_id, product_id, product_name, batch_id,
        quantity, selling_price, cost_price, gst_rate, gst_inclusive,
        discount_pct, hsn_code
      ) values (
        new.id,
        new.business_id,
        v_product->>'id',
        v_product->>'name',
        v_item->'batch'->>'id',
        coalesce((v_item->>'quantity')::numeric, 1),
        coalesce((v_product->>'sellingPrice')::numeric, 0),
        coalesce((v_product->>'costPrice')::numeric, 0),
        coalesce((v_item->>'gstRate')::numeric, 0),
        coalesce((v_item->>'gstInclusivePrice')::boolean, false),
        coalesce((v_item->>'discountPercent')::numeric, 0),
        v_product->>'hsnCode'
      );
    end loop;
  end if;

  return new;
end;
$$;

drop trigger if exists sync_bill_line_items_trigger on bills;

create trigger sync_bill_line_items_trigger
after insert or update on bills
for each row execute function sync_bill_line_items_from_jsonb();

-- ── 5. Backfill existing bills ───────────────────────────────────────────────
-- Touch every bill to fire the trigger and populate bill_line_items.

update bills set data = data;

-- ── 6. Analytics views ──────────────────────────────────────────────────────

-- Product sales summary — revenue, quantity, profit per product
create or replace view product_sales_summary as
select
  li.business_id,
  li.product_id,
  li.product_name,
  count(distinct li.bill_id)                          as bill_count,
  sum(li.quantity)                                     as total_qty_sold,
  sum(li.line_total)                                   as total_revenue,
  sum(li.line_total - li.discount_amount)              as net_revenue,
  sum((li.selling_price - li.cost_price) * li.quantity) as total_profit
from bill_line_items li
group by li.business_id, li.product_id, li.product_name;

-- HSN-wise tax summary — for GSTR-1 HSN table
create or replace view hsn_tax_summary as
select
  li.business_id,
  b.bill_timestamp,
  li.hsn_code,
  li.gst_rate,
  count(*)                                as line_count,
  sum(li.quantity)                         as total_quantity,
  sum(li.line_total - li.discount_amount)  as total_value,
  sum(
    case when li.gst_inclusive then
      (li.line_total - li.discount_amount) / (1 + li.gst_rate / 100)
    else
      li.line_total - li.discount_amount
    end
  )                                        as taxable_value,
  sum(
    case when li.gst_inclusive then
      (li.line_total - li.discount_amount) - (li.line_total - li.discount_amount) / (1 + li.gst_rate / 100)
    else
      (li.line_total - li.discount_amount) * li.gst_rate / 100
    end
  )                                        as total_tax
from bill_line_items li
join bills b on b.id = li.bill_id
where li.hsn_code is not null
group by li.business_id, b.bill_timestamp, li.hsn_code, li.gst_rate;
