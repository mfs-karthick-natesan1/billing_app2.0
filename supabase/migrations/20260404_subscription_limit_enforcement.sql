-- Migration: Server-side subscription limit enforcement (Issue #3)
--
-- Adds a Postgres function that validates the bill limit before insertion.
-- Called by the complete_bill RPC (Issue #5) so limit checks happen server-side.

create or replace function check_bill_limit(p_business_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max_bills    int;
  v_bills_this_month int;
  v_tier         text;
begin
  select
    coalesce(tier, 'trial'),
    coalesce(bills_this_month, 0),
    coalesce(
      (limits->>'maxBillsPerMonth')::int,
      -1   -- -1 = unlimited
    )
  into v_tier, v_bills_this_month, v_max_bills
  from subscriptions
  where business_id = p_business_id;

  -- No subscription row → treat as unlimited trial
  if not found then
    return;
  end if;

  -- -1 means unlimited
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
