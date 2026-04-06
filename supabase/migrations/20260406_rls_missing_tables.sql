-- Migration: Enable RLS on previously unprotected tables
--
-- Per security audit, 13 tables lacked row-level security, meaning any
-- authenticated user could read/write rows across tenant boundaries.
-- This migration enables RLS on every such table that exists and installs
-- business_id-scoped policies using the existing current_business_id() and
-- current_user_role() helpers from 20260404_rls_role_enforcement.sql.
--
-- Each table is wrapped in a to_regclass guard so the migration is a no-op
-- on any table that does not exist in a given environment.
--
-- Not covered here:
--   * bill_number_sequences: already has RLS (20260404_server_side_bill_numbers.sql)
--   * app_users, businesses: managed by Supabase auth layer, not in migrations

do $mig$
declare
  t           text;
  mutate_roles text := $$('owner','manager','cashier')$$;
  write_roles  text := $$('owner','manager')$$;
  owner_only   text := $$('owner')$$;
begin
  -- Tables with cashier-level mutate (all CRUD for cash-handling staff)
  for t in select unnest(array[
    'cash_book',
    'customer_payment_entries',
    'sales_returns',
    'quotations',
    'job_cards',
    'table_orders'
  ]) loop
    if to_regclass('public.' || t) is null then
      raise notice 'Skipping %: table does not exist', t;
      continue;
    end if;

    execute format('alter table public.%I enable row level security', t);

    execute format($f$drop policy if exists "%1$s_select" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_select" on public.%1$I
          for select using (business_id = current_business_id())$f$, t);

    execute format($f$drop policy if exists "%1$s_insert" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_insert" on public.%1$I
          for insert with check (
            business_id = current_business_id()
            and current_user_role() in %2$s
          )$f$, t, mutate_roles);

    execute format($f$drop policy if exists "%1$s_update" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_update" on public.%1$I
          for update using (
            business_id = current_business_id()
            and current_user_role() in %2$s
          )$f$, t, mutate_roles);

    execute format($f$drop policy if exists "%1$s_delete" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_delete" on public.%1$I
          for delete using (
            business_id = current_business_id()
            and current_user_role() in %2$s
          )$f$, t, owner_only);
  end loop;

  -- Tables restricted to owner/manager for mutations (inventory-grade data)
  for t in select unnest(array[
    'purchases',
    'serial_numbers'
  ]) loop
    if to_regclass('public.' || t) is null then
      raise notice 'Skipping %: table does not exist', t;
      continue;
    end if;

    execute format('alter table public.%I enable row level security', t);

    execute format($f$drop policy if exists "%1$s_select" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_select" on public.%1$I
          for select using (business_id = current_business_id())$f$, t);

    execute format($f$drop policy if exists "%1$s_insert" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_insert" on public.%1$I
          for insert with check (
            business_id = current_business_id()
            and current_user_role() in %2$s
          )$f$, t, write_roles);

    execute format($f$drop policy if exists "%1$s_update" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_update" on public.%1$I
          for update using (
            business_id = current_business_id()
            and current_user_role() in %2$s
          )$f$, t, write_roles);

    execute format($f$drop policy if exists "%1$s_delete" on public.%1$I$f$, t);
    execute format(
      $f$create policy "%1$s_delete" on public.%1$I
          for delete using (
            business_id = current_business_id()
            and current_user_role() in %2$s
          )$f$, t, owner_only);
  end loop;

  -- Subscriptions: read by business, mutate by owner only, no delete
  if to_regclass('public.subscriptions') is not null then
    alter table public.subscriptions enable row level security;

    drop policy if exists "subscriptions_select" on public.subscriptions;
    create policy "subscriptions_select" on public.subscriptions
      for select using (business_id = current_business_id());

    drop policy if exists "subscriptions_update" on public.subscriptions;
    create policy "subscriptions_update" on public.subscriptions
      for update using (
        business_id = current_business_id()
        and current_user_role() = 'owner'
      );
  else
    raise notice 'Skipping subscriptions: table does not exist';
  end if;

  -- Support tickets: anyone in the business can read/create; only owner edits
  if to_regclass('public.support_tickets') is not null then
    alter table public.support_tickets enable row level security;

    drop policy if exists "support_tickets_select" on public.support_tickets;
    create policy "support_tickets_select" on public.support_tickets
      for select using (business_id = current_business_id());

    drop policy if exists "support_tickets_insert" on public.support_tickets;
    create policy "support_tickets_insert" on public.support_tickets
      for insert with check (business_id = current_business_id());

    drop policy if exists "support_tickets_update" on public.support_tickets;
    create policy "support_tickets_update" on public.support_tickets
      for update using (
        business_id = current_business_id()
        and current_user_role() = 'owner'
      );
  else
    raise notice 'Skipping support_tickets: table does not exist';
  end if;
end
$mig$;
