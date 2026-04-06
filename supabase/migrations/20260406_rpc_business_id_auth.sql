-- Migration: RPC business_id authorization checks
--
-- Adds authorization checks to complete_bill, get_next_bill_number, and
-- check_bill_limit to ensure p_business_id belongs to the authenticated
-- user. Prior to this migration, any authenticated user could pass an
-- arbitrary p_business_id and operate on another tenant's data.
--
-- Uses current_business_id() helper defined in 20260404_rls_role_enforcement.sql

-- ── complete_bill ────────────────────────────────────────────────────────────

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
      select (b->>'stockQuantity')::int
      into v_stock_avail
      from products,
           jsonb_array_elements(data->'batches') as b
      where id = v_product_id
        and business_id = p_business_id
        and b->>'id' = v_batch_id;
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

  -- 5. Decrement stock
  for v_stock in select * from jsonb_array_elements(p_stock_changes) loop
    v_product_id := v_stock->>'productId';
    v_batch_id   := v_stock->>'batchId';
    v_qty        := (v_stock->>'qty')::int;

    if v_batch_id is not null then
      update products
      set data = jsonb_set(
        data,
        '{batches}',
        (
          select jsonb_agg(
            case when (b->>'id') = v_batch_id
              then jsonb_set(b, '{stockQuantity}',
                to_jsonb((b->>'stockQuantity')::int - v_qty))
              else b
            end
          )
          from jsonb_array_elements(data->'batches') b
        )
      )
      where id = v_product_id and business_id = p_business_id;

      update products
      set data = jsonb_set(
        data,
        '{stockQuantity}',
        to_jsonb((
          select coalesce(sum((b->>'stockQuantity')::int), 0)
          from jsonb_array_elements(data->'batches') b
        ))
      )
      where id = v_product_id and business_id = p_business_id;
    else
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

-- ── get_next_bill_number ─────────────────────────────────────────────────────

create or replace function get_next_bill_number(
  p_business_id text,
  p_prefix      text default 'INV'
)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_fy          text;
  v_start_year  int;
  v_next        int;
  v_padded      text;
begin
  if p_business_id is distinct from current_business_id() then
    raise exception 'UNAUTHORIZED'
      using detail = 'User is not authorized for business ' || coalesce(p_business_id, '<null>'),
            errcode = '42501';
  end if;

  select
    case when extract(month from now()) >= 4
      then extract(year from now())::int
      else extract(year from now())::int - 1
    end
  into v_start_year;

  v_fy := v_start_year::text || '-' ||
          lpad(((v_start_year + 1) % 100)::text, 2, '0');

  insert into bill_number_sequences (business_id, financial_year, prefix, last_number)
  values (p_business_id, v_fy, p_prefix, 1)
  on conflict (business_id, financial_year, prefix)
  do update set last_number = bill_number_sequences.last_number + 1
  returning last_number into v_next;

  v_padded := lpad(v_next::text, 3, '0');
  return v_fy || '/' || p_prefix || '-' || v_padded;
end;
$$;

-- ── check_bill_limit ─────────────────────────────────────────────────────────

create or replace function check_bill_limit(p_business_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max_bills        int;
  v_bills_this_month int;
  v_tier             text;
begin
  if p_business_id is distinct from current_business_id() then
    raise exception 'UNAUTHORIZED'
      using detail = 'User is not authorized for business ' || coalesce(p_business_id, '<null>'),
            errcode = '42501';
  end if;

  select
    coalesce(tier, 'trial'),
    coalesce(bills_this_month, 0),
    coalesce((limits->>'maxBillsPerMonth')::int, -1)
  into v_tier, v_bills_this_month, v_max_bills
  from subscriptions
  where business_id = p_business_id;

  if not found then
    return;
  end if;

  if v_max_bills = -1 then
    return;
  end if;

  if v_bills_this_month >= v_max_bills then
    raise exception 'SUBSCRIPTION_LIMIT_EXCEEDED'
      using detail = 'Monthly bill limit of ' || v_max_bills || ' reached. Upgrade your plan.',
            errcode = 'P0001';
  end if;
end;
$$;
