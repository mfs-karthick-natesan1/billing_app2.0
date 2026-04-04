-- Migration: Atomic bill completion RPC (Issue #5)
--
-- Wraps bill save + stock decrement + credit update + bill count increment
-- in a single DB transaction. If any step fails, all changes roll back.
--
-- Parameters (JSONB):
--   p_business_id  : text
--   p_bill         : jsonb   – full bill object to upsert into bills table
--   p_stock_changes: jsonb[] – [{productId, batchId?, qty}]
--   p_credit       : jsonb   – {customerId, amount} or null
--   p_prefix       : text    – bill number prefix (default 'INV')
--   p_use_server_bill_number : bool – when true, generates bill number server-side

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
      -- Update specific batch stockQuantity
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

      -- Recompute top-level stockQuantity from batch sum
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
