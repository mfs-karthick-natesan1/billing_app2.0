-- Migration: Server-side RLS for role enforcement (Issue #14)
--
-- Creates row-level security policies that enforce permissions stored in the
-- app_users table. Client-side PermissionService checks remain as a UX layer
-- but are no longer the authoritative gate.

-- Helper function: returns the role of the current authenticated user
-- within their business.
create or replace function current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(role, 'viewer')
  from app_users
  where id = auth.uid()
  limit 1;
$$;

-- Helper: returns the business_id of the current authenticated user.
create or replace function current_business_id()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select business_id
  from app_users
  where id = auth.uid()
  limit 1;
$$;

-- ── Bills ─────────────────────────────────────────────────────────────────────
-- All roles can read bills for their business.
-- Only owner/manager/cashier can insert.
-- Only owner can delete.

alter table bills enable row level security;

drop policy if exists "bills_select" on bills;
create policy "bills_select"
  on bills for select
  using (business_id = current_business_id());

drop policy if exists "bills_insert" on bills;
create policy "bills_insert"
  on bills for insert
  with check (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager', 'cashier')
  );

drop policy if exists "bills_update" on bills;
create policy "bills_update"
  on bills for update
  using (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );

drop policy if exists "bills_delete" on bills;
create policy "bills_delete"
  on bills for delete
  using (
    business_id = current_business_id()
    and current_user_role() = 'owner'
  );

-- ── Products ─────────────────────────────────────────────────────────────────
alter table products enable row level security;

drop policy if exists "products_select" on products;
create policy "products_select"
  on products for select
  using (business_id = current_business_id());

drop policy if exists "products_insert" on products;
create policy "products_insert"
  on products for insert
  with check (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );

drop policy if exists "products_update" on products;
create policy "products_update"
  on products for update
  using (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager', 'cashier')
  );

drop policy if exists "products_delete" on products;
create policy "products_delete"
  on products for delete
  using (
    business_id = current_business_id()
    and current_user_role() = 'owner'
  );

-- ── Customers ─────────────────────────────────────────────────────────────────
alter table customers enable row level security;

drop policy if exists "customers_all" on customers;
create policy "customers_all"
  on customers for all
  using (business_id = current_business_id())
  with check (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager', 'cashier')
  );

-- ── Expenses ─────────────────────────────────────────────────────────────────
alter table expenses enable row level security;

drop policy if exists "expenses_select" on expenses;
create policy "expenses_select"
  on expenses for select
  using (business_id = current_business_id());

drop policy if exists "expenses_write" on expenses;
create policy "expenses_write"
  on expenses for all
  using (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  )
  with check (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );

-- ── Suppliers ─────────────────────────────────────────────────────────────────
alter table suppliers enable row level security;

drop policy if exists "suppliers_all" on suppliers;
create policy "suppliers_all"
  on suppliers for all
  using (business_id = current_business_id())
  with check (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );

-- ── Stock Adjustments ─────────────────────────────────────────────────────────
alter table stock_adjustments enable row level security;

drop policy if exists "stock_adjustments_all" on stock_adjustments;
create policy "stock_adjustments_all"
  on stock_adjustments for all
  using (business_id = current_business_id())
  with check (
    business_id = current_business_id()
    and current_user_role() in ('owner', 'manager')
  );
