-- Migration: #42 JSONB→relational slice 3 — product_batches table
--
-- Extracts data->'batches' from the products JSONB blob into a proper
-- relational table.  The complete_bill() RPC is rewritten to validate
-- and decrement stock directly on the product_batches table instead of
-- the deeply nested jsonb_set approach.
--
-- Dart continues to read/write batches via data->'batches' as before.
-- An AFTER INSERT OR UPDATE trigger on products syncs the JSONB array
-- into the product_batches table.  When complete_bill() mutates
-- product_batches directly, it sets a session flag to skip the sync
-- trigger and rebuilds the JSONB array from the table to keep both
-- representations consistent.

-- ── 1. Create product_batches table ──────────────────────────────────────────

create table if not exists product_batches (
  id            text        not null primary key,
  product_id    text        not null references products(id) on delete cascade,
  business_id   text        not null,
  batch_number  text        not null,
  expiry_date   timestamptz not null,
  stock_quantity int        not null default 0,
  created_at    timestamptz not null default now()
);

-- ── 2. RLS ───────────────────────────────────────────────────────────────────

alter table product_batches enable row level security;

create policy "product_batches_select"
  on product_batches for select
  using (business_id = current_business_id());

create policy "product_batches_insert"
  on product_batches for insert
  with check (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );

create policy "product_batches_update"
  on product_batches for update
  using (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );

create policy "product_batches_delete"
  on product_batches for delete
  using (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );

-- ── 3. Indexes ───────────────────────────────────────────────────────────────

create index if not exists product_batches_product_idx
  on product_batches (product_id);

create index if not exists product_batches_business_idx
  on product_batches (business_id);

create index if not exists product_batches_expiry_idx
  on product_batches (product_id, expiry_date)
  where stock_quantity > 0;

-- ── 4. Backfill from existing JSONB ──────────────────────────────────────────

insert into product_batches (id, product_id, business_id, batch_number, expiry_date, stock_quantity, created_at)
select
  b->>'id',
  p.id,
  p.business_id,
  b->>'batchNumber',
  (b->>'expiryDate')::timestamptz,
  coalesce((b->>'stockQuantity')::int, 0),
  coalesce((b->>'createdAt')::timestamptz, now())
from products p,
     jsonb_array_elements(p.data->'batches') b
where p.data->'batches' is not null
  and jsonb_array_length(p.data->'batches') > 0
on conflict (id) do nothing;

-- ── 5. Sync trigger: products.data->'batches' → product_batches ─────────────
-- Fires on every Dart-side product upsert.  Skipped when complete_bill()
-- sets the session flag (it manages the table directly).

create or replace function sync_product_batches_from_jsonb()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Skip when called from within complete_bill to avoid redundant sync
  if current_setting('app.skip_batch_sync', true) = 'true' then
    return new;
  end if;

  -- Remove old batch rows for this product
  delete from product_batches where product_id = new.id;

  -- Re-insert from JSONB array
  if new.data->'batches' is not null
     and jsonb_typeof(new.data->'batches') = 'array'
     and jsonb_array_length(new.data->'batches') > 0
  then
    insert into product_batches (id, product_id, business_id, batch_number, expiry_date, stock_quantity, created_at)
    select
      b->>'id',
      new.id,
      new.business_id,
      b->>'batchNumber',
      (b->>'expiryDate')::timestamptz,
      coalesce((b->>'stockQuantity')::int, 0),
      coalesce((b->>'createdAt')::timestamptz, now())
    from jsonb_array_elements(new.data->'batches') b;
  end if;

  return new;
end;
$$;

drop trigger if exists sync_product_batches_trigger on products;

create trigger sync_product_batches_trigger
after insert or update on products
for each row execute function sync_product_batches_from_jsonb();

-- ── 6. Rewrite complete_bill() ──────────────────────────────────────────────
-- Key change: batch stock validation and decrement now operate on the
-- product_batches table.  After decrementing, the RPC rebuilds
-- data->'batches' from the table so the JSONB stays consistent for
-- Dart reads.

create or replace function complete_bill(
  p_business_id            text,
  p_bill                   jsonb,
  p_stock_changes          jsonb default '[]'::jsonb,
  p_credit                 jsonb default null,
  p_prefix                 text  default 'INV',
  p_use_server_bill_number bool  default true
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_bill_number  text;
  v_stock        jsonb;
  v_product_id   text;
  v_batch_id     text;
  v_qty          int;
  v_stock_avail  int;
  v_result       jsonb;
begin
  -- Authorization: p_business_id must match the authenticated user's business
  if p_business_id is distinct from current_business_id() then
    raise exception 'UNAUTHORIZED'
      using detail = 'User is not authorized for business ' || coalesce(p_business_id, '<null>'),
            errcode = '42501';
  end if;

  -- 1. Enforce subscription limit (raises exception if exceeded)
  perform check_bill_limit(p_business_id);

  -- 2. Generate server-side bill number if requested
  if p_use_server_bill_number then
    v_bill_number := get_next_bill_number(p_business_id, p_prefix);
  else
    v_bill_number := p_bill->>'billNumber';
  end if;

  -- 3. Validate stock availability
  for v_stock in select * from jsonb_array_elements(p_stock_changes) loop
    v_product_id := v_stock->>'productId';
    v_batch_id   := v_stock->>'batchId';
    v_qty        := (v_stock->>'qty')::int;

    if v_batch_id is not null then
      -- Read from product_batches table
      select stock_quantity
      into v_stock_avail
      from product_batches
      where id = v_batch_id
        and product_id = v_product_id;
    else
      select (data->>'stockQuantity')::int
      into v_stock_avail
      from products
      where id = v_product_id
        and business_id = p_business_id;
    end if;

    if not found then
      raise exception 'PRODUCT_NOT_FOUND'
        using detail = 'Product ' || v_product_id || ' not found',
              errcode = 'P0002';
    end if;

    if v_stock_avail < v_qty then
      raise exception 'INSUFFICIENT_STOCK'
        using detail = 'Insufficient stock for product ' || v_product_id ||
                       ': available=' || v_stock_avail || ', requested=' || v_qty,
              errcode = 'P0003';
    end if;
  end loop;

  -- 4. Save bill
  insert into bills (id, business_id, data)
  values (
    coalesce(p_bill->>'id', gen_random_uuid()::text),
    p_business_id,
    jsonb_set(p_bill, '{billNumber}', to_jsonb(v_bill_number))
  )
  on conflict (id) do update
    set data = jsonb_set(excluded.data, '{billNumber}', to_jsonb(v_bill_number)),
        updated_at = now();

  -- Prevent the batch sync trigger from firing during stock decrements
  -- (we manage the product_batches table directly below).
  perform set_config('app.skip_batch_sync', 'true', true);

  -- 5. Decrement stock
  for v_stock in select * from jsonb_array_elements(p_stock_changes) loop
    v_product_id := v_stock->>'productId';
    v_batch_id   := v_stock->>'batchId';
    v_qty        := (v_stock->>'qty')::int;

    if v_batch_id is not null then
      -- Decrement batch stock in the relational table
      update product_batches
      set stock_quantity = stock_quantity - v_qty
      where id = v_batch_id
        and product_id = v_product_id;

      -- Rebuild data->'batches' and data->'stockQuantity' from table
      update products
      set data = jsonb_set(
        jsonb_set(
          data,
          '{batches}',
          coalesce(
            (select jsonb_agg(
              jsonb_build_object(
                'id', pb.id,
                'productId', pb.product_id,
                'batchNumber', pb.batch_number,
                'expiryDate', to_char(pb.expiry_date, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
                'stockQuantity', pb.stock_quantity,
                'createdAt', to_char(pb.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"')
              )
            from product_batches pb
            where pb.product_id = v_product_id),
            '[]'::jsonb
          )
        ),
        '{stockQuantity}',
        to_jsonb(coalesce(
          (select sum(pb2.stock_quantity)::int
           from product_batches pb2
           where pb2.product_id = v_product_id),
          0
        ))
      )
      where id = v_product_id and business_id = p_business_id;
    else
      -- Non-batch product: decrement directly in JSONB (unchanged)
      update products
      set data = jsonb_set(
        data,
        '{stockQuantity}',
        to_jsonb((data->>'stockQuantity')::int - v_qty)
      )
      where id = v_product_id and business_id = p_business_id;
    end if;
  end loop;

  -- 6. Update customer credit balance
  if p_credit is not null then
    update customers
    set data = jsonb_set(
      data,
      '{outstandingBalance}',
      to_jsonb(
        coalesce((data->>'outstandingBalance')::float, 0)
        + (p_credit->>'amount')::float
      )
    )
    where id = (p_credit->>'customerId')
      and business_id = p_business_id;
  end if;

  -- 7. Increment monthly bill count
  update subscriptions
  set bills_this_month = coalesce(bills_this_month, 0) + 1
  where business_id = p_business_id;

  v_result := jsonb_build_object(
    'billNumber', v_bill_number,
    'success', true
  );
  return v_result;
end;
$$;

-- ── 7. Expiring batches view ─────────────────────────────────────────────────

create or replace view expiring_batches as
select
  pb.business_id,
  pb.product_id,
  p.product_name,
  pb.id as batch_id,
  pb.batch_number,
  pb.expiry_date,
  pb.stock_quantity,
  case
    when pb.expiry_date < now() then 'expired'
    when pb.expiry_date < now() + interval '90 days' then 'expiring_soon'
    else 'ok'
  end as status
from product_batches pb
join products p on p.id = pb.product_id
where pb.stock_quantity > 0
  and pb.expiry_date < now() + interval '90 days';
