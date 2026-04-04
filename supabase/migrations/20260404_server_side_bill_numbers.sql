-- Migration: Server-side bill number generation (Issue #2)
--
-- Adds a per-business, per-financial-year atomic sequence for bill numbers.
-- Replaces the client-side in-memory counter in BillNumberService.
--
-- Financial year: April → March (Indian FY). E.g. FY 2025-26 = "2025-26".

-- Table to store the last used counter per (business, financial_year, prefix).
create table if not exists bill_number_sequences (
  business_id  text    not null,
  financial_year text  not null,  -- e.g. "2025-26"
  prefix       text    not null default 'INV',
  last_number  integer not null default 0,
  primary key (business_id, financial_year, prefix)
);

-- RLS: only authenticated users belonging to the business can read/write.
alter table bill_number_sequences enable row level security;

create policy "business members can manage sequences"
  on bill_number_sequences
  for all
  using (
    business_id = (
      select business_id from app_users
      where id = auth.uid()
    )
  );

-- RPC: atomically increment and return next bill number.
create or replace function get_next_bill_number(
  p_business_id text,
  p_prefix text default 'INV'
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
  -- Compute Indian financial year (Apr–Mar)
  select
    case when extract(month from now()) >= 4
      then extract(year from now())::int
      else extract(year from now())::int - 1
    end
  into v_start_year;

  v_fy := v_start_year::text || '-' ||
          lpad(((v_start_year + 1) % 100)::text, 2, '0');

  -- Atomically increment counter (upsert)
  insert into bill_number_sequences (business_id, financial_year, prefix, last_number)
  values (p_business_id, v_fy, p_prefix, 1)
  on conflict (business_id, financial_year, prefix)
  do update set last_number = bill_number_sequences.last_number + 1
  returning last_number into v_next;

  v_padded := lpad(v_next::text, 3, '0');
  return v_fy || '/' || p_prefix || '-' || v_padded;
end;
$$;
