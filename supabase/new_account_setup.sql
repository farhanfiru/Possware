-- ==============================================================================
-- NEYCO POS: COMPLETE SUPABASE NEW PROJECT SCHEMA SETUP SCRIPT
-- Run this entire script ONCE in your NEW Supabase Project's SQL Editor:
-- https://supabase.com/dashboard/project/_/sql/new
--
-- This creates all tables, columns, indexes, RLS policies, views, functions,
-- and realtime settings with ZERO data modifications to your old project.
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS & TABLES
-- ------------------------------------------------------------------------------
create extension if not exists "pgcrypto";

-- Menu Items Table
create table if not exists public.menu_items (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now() not null,
    name text not null,
    price numeric(10, 2) not null check (price >= 0),
    category text not null default 'General',
    is_available boolean not null default true,
    image_url text
);

-- Orders Table (with full split payment and invoice number support)
create table if not exists public.orders (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now() not null,
    total numeric(10, 2) not null check (total >= 0),
    payment_method text not null default 'cash' check (payment_method in ('cash', 'gpay', 'split')),
    cash_amount numeric(10, 2) default 0.00,
    gpay_amount numeric(10, 2) default 0.00,
    status text not null default 'completed' check (status in ('completed', 'cancelled', 'refunded')),
    notes text,
    invoice_number text
);

-- Order Items Table
create table if not exists public.order_items (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references public.orders(id) on delete cascade,
    menu_item_id uuid references public.menu_items(id) on delete set null,
    name text not null,
    price numeric(10, 2) not null check (price >= 0),
    qty int not null check (qty > 0)
);

-- Order Edits Audit History Table (Exact schema from old project)
create table if not exists public.order_edits (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references public.orders(id) on delete cascade,
    edited_by text default 'owner',
    edited_at timestamptz default now() not null,
    edit_type text not null,
    old_total numeric(10, 2),
    new_total numeric(10, 2),
    note text
);

-- Expenses Table
create table if not exists public.expenses (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now() not null,
    expense_date date not null default (((now() at time zone 'Asia/Kolkata') - interval '3 hours')::date),
    expense_name text not null,
    price numeric(10, 2) not null check (price >= 0),
    category text not null default 'General',
    notes text,
    has_edits boolean not null default false,
    edit_history jsonb not null default '[]'::jsonb,
    updated_at timestamptz not null default now(),
    deleted_at timestamptz
);

-- ------------------------------------------------------------------------------
-- 2. INDEXES
-- ------------------------------------------------------------------------------
create index if not exists idx_menu_items_available on public.menu_items(is_available);
create index if not exists idx_menu_items_category on public.menu_items(category);

create index if not exists idx_orders_created_at on public.orders(created_at desc);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_orders_payment_method on public.orders(payment_method);
create index if not exists idx_orders_invoice_number on public.orders(invoice_number);

create index if not exists idx_order_items_order_id on public.order_items(order_id);
create index if not exists idx_order_items_menu_item_id on public.order_items(menu_item_id);

create index if not exists idx_order_edits_order_id on public.order_edits(order_id);
create index if not exists idx_order_edits_edited_at on public.order_edits(edited_at desc);

create index if not exists idx_expenses_date on public.expenses(expense_date desc) where deleted_at is null;
create index if not exists idx_expenses_category on public.expenses(category) where deleted_at is null;

-- ------------------------------------------------------------------------------
-- 3. REPORTING VIEWS (With Asia/Kolkata 3:00 AM Shift Cutoff)
-- ------------------------------------------------------------------------------

-- Daily Sales View (Calculates Cash, GPay, and Split portions accurately)
create or replace view public.daily_sales as
select
    ((created_at at time zone 'Asia/Kolkata') - interval '3 hours')::date as sale_date,
    count(*)::int as num_orders,
    coalesce(sum(total), 0)::numeric(10,2) as total_sales,
    coalesce(sum(
        case 
            when payment_method = 'cash' then total
            when payment_method = 'split' then coalesce(cash_amount, 0)
            else 0 
        end
    ), 0)::numeric(10,2) as cash_total,
    coalesce(sum(
        case 
            when payment_method = 'gpay' then total
            when payment_method = 'split' then coalesce(gpay_amount, 0)
            else 0 
        end
    ), 0)::numeric(10,2) as gpay_total,
    count(*) filter (where payment_method = 'cash')::int as cash_orders,
    count(*) filter (where payment_method = 'gpay')::int as gpay_orders,
    count(*) filter (where payment_method = 'split')::int as split_orders
from public.orders
where status = 'completed'
group by ((created_at at time zone 'Asia/Kolkata') - interval '3 hours')::date
order by sale_date desc;

-- Daily Product Sales View
create or replace view public.daily_product_sales as
select
    ((o.created_at at time zone 'Asia/Kolkata') - interval '3 hours')::date as sale_date,
    oi.name as product_name,
    coalesce(sum(oi.qty), 0)::int as qty_sold,
    coalesce(sum(oi.qty * oi.price), 0)::numeric(10,2) as revenue
from public.orders o
join public.order_items oi on oi.order_id = o.id
where o.status = 'completed'
group by ((o.created_at at time zone 'Asia/Kolkata') - interval '3 hours')::date, oi.name
order by sale_date desc, qty_sold desc;

-- Monthly Sales View
create or replace view public.monthly_sales as
select
    date_trunc('month', (created_at at time zone 'Asia/Kolkata') - interval '3 hours')::date as sale_month,
    to_char((created_at at time zone 'Asia/Kolkata') - interval '3 hours', 'Month YYYY') as month_label,
    count(*)::int as num_orders,
    coalesce(sum(total), 0)::numeric(10,2) as total_sales,
    coalesce(sum(
        case 
            when payment_method = 'cash' then total
            when payment_method = 'split' then coalesce(cash_amount, 0)
            else 0 
        end
    ), 0)::numeric(10,2) as cash_total,
    coalesce(sum(
        case 
            when payment_method = 'gpay' then total
            when payment_method = 'split' then coalesce(gpay_amount, 0)
            else 0 
        end
    ), 0)::numeric(10,2) as gpay_total,
    count(*) filter (where payment_method = 'cash')::int as cash_orders,
    count(*) filter (where payment_method = 'gpay')::int as gpay_orders,
    count(*) filter (where payment_method = 'split')::int as split_orders
from public.orders
where status = 'completed'
group by 
    date_trunc('month', (created_at at time zone 'Asia/Kolkata') - interval '3 hours'), 
    to_char((created_at at time zone 'Asia/Kolkata') - interval '3 hours', 'Month YYYY')
order by sale_month desc;

-- Daily Expenses View
create or replace view public.daily_expenses as
select
    expense_date,
    count(*)::int as num_expenses,
    coalesce(sum(price), 0)::numeric(10,2) as total_expenses
from public.expenses
where deleted_at is null
group by expense_date
order by expense_date desc;

-- Daily Category Expenses View
create or replace view public.daily_category_expenses as
select
    expense_date,
    category,
    count(*)::int as num_expenses,
    coalesce(sum(price), 0)::numeric(10,2) as total_expenses
from public.expenses
where deleted_at is null
group by expense_date, category
order by expense_date desc, total_expenses desc;

-- Monthly Expenses View
create or replace view public.monthly_expenses as
select
    date_trunc('month', expense_date)::date as expense_month,
    to_char(expense_date, 'Month YYYY') as month_label,
    count(*)::int as num_expenses,
    coalesce(sum(price), 0)::numeric(10,2) as total_expenses
from public.expenses
where deleted_at is null
group by 
    date_trunc('month', expense_date)::date,
    to_char(expense_date, 'Month YYYY')
order by expense_month desc;

-- Monthly Category Expenses View
create or replace view public.monthly_category_expenses as
select
    date_trunc('month', expense_date)::date as expense_month,
    to_char(expense_date, 'Month YYYY') as month_label,
    category,
    count(*)::int as num_expenses,
    coalesce(sum(price), 0)::numeric(10,2) as total_expenses
from public.expenses
where deleted_at is null
group by 
    date_trunc('month', expense_date)::date,
    to_char(expense_date, 'Month YYYY'),
    category
order by expense_month desc, total_expenses desc;

-- ------------------------------------------------------------------------------
-- 4. DASHBOARD SUMMARY RPC FUNCTION
-- ------------------------------------------------------------------------------
create or replace function public.get_dashboard_summary()
returns json
language plpgsql
security definer
as $$
declare
    result json;
    v_today date := (((now() at time zone 'Asia/Kolkata') - interval '3 hours')::date);
    v_month_start date := (date_trunc('month', (now() at time zone 'Asia/Kolkata') - interval '3 hours')::date);
begin
    select json_build_object(
        'today', (
            select json_build_object(
                'date', v_today,
                'total_sales', coalesce(sum(total), 0),
                'cash_total', coalesce(sum(case when payment_method = 'cash' then total when payment_method = 'split' then coalesce(cash_amount, 0) else 0 end), 0),
                'gpay_total', coalesce(sum(case when payment_method = 'gpay' then total when payment_method = 'split' then coalesce(gpay_amount, 0) else 0 end), 0),
                'num_orders', count(*),
                'cash_orders', count(*) filter (where payment_method = 'cash'),
                'gpay_orders', count(*) filter (where payment_method = 'gpay'),
                'split_orders', count(*) filter (where payment_method = 'split')
            )
            from public.orders
            where status = 'completed' and (((created_at at time zone 'Asia/Kolkata') - interval '3 hours')::date) = v_today
        ),
        'this_month', (
            select json_build_object(
                'month_start', v_month_start,
                'total_sales', coalesce(sum(total), 0),
                'cash_total', coalesce(sum(case when payment_method = 'cash' then total when payment_method = 'split' then coalesce(cash_amount, 0) else 0 end), 0),
                'gpay_total', coalesce(sum(case when payment_method = 'gpay' then total when payment_method = 'split' then coalesce(gpay_amount, 0) else 0 end), 0),
                'num_orders', count(*)
            )
            from public.orders
            where status = 'completed' and (((created_at at time zone 'Asia/Kolkata') - interval '3 hours')::date) >= v_month_start
        ),
        'all_time', (
            select json_build_object(
                'total_sales', coalesce(sum(total), 0),
                'num_orders', count(*),
                'active_menu_items', (select count(*) from public.menu_items where is_available = true)
            )
            from public.orders
            where status = 'completed'
        )
    ) into result;

    return result;
end;
$$;

-- ------------------------------------------------------------------------------
-- 5. ORDER EDITS AUDIT TRIGGER
-- ------------------------------------------------------------------------------
create or replace function public.log_order_edit()
returns trigger
language plpgsql
security definer
as $$
begin
    if (old.total is distinct from new.total) or
       (old.payment_method is distinct from new.payment_method) or
       (old.cash_amount is distinct from new.cash_amount) or
       (old.gpay_amount is distinct from new.gpay_amount) or
       (old.status is distinct from new.status) then
        insert into public.order_edits (
            order_id,
            edited_by,
            edited_at,
            edit_type,
            old_total,
            new_total,
            note
        ) values (
            new.id,
            'owner',
            now(),
            case 
                when old.payment_method is distinct from new.payment_method then 'payment_changed'
                when old.total is distinct from new.total then 'total_changed'
                else 'qty_changed'
            end,
            old.total,
            new.total,
            'Edited by owner'
        );
    end if;
    return new;
end;
$$;

drop trigger if exists trigger_log_order_edit on public.orders;
create trigger trigger_log_order_edit
after update on public.orders
for each row
execute function public.log_order_edit();

-- Expenses Audit Trigger
create or replace function public.trg_expenses_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists trg_expenses_set_updated_at on public.expenses;
create trigger trg_expenses_set_updated_at
before update on public.expenses
for each row
execute function public.trg_expenses_updated_at();

-- ------------------------------------------------------------------------------
-- 6. ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.order_edits enable row level security;
alter table public.expenses enable row level security;

-- Menu Items Policies
drop policy if exists "Allow public read on menu_items" on public.menu_items;
drop policy if exists "Allow public insert on menu_items" on public.menu_items;
drop policy if exists "Allow public update on menu_items" on public.menu_items;
drop policy if exists "Allow public delete on menu_items" on public.menu_items;

create policy "Allow public read on menu_items"
on public.menu_items for select using (true);

create policy "Allow public insert on menu_items"
on public.menu_items for insert with check (true);

create policy "Allow public update on menu_items"
on public.menu_items for update using (true) with check (true);

create policy "Allow public delete on menu_items"
on public.menu_items for delete using (true);

-- Orders Policies (includes payment editing update support)
drop policy if exists "Allow public select on orders" on public.orders;
drop policy if exists "Allow public insert on orders" on public.orders;
drop policy if exists "Allow public update on orders" on public.orders;
drop policy if exists "Allow public delete on orders" on public.orders;

create policy "Allow public select on orders"
on public.orders for select using (true);

create policy "Allow public insert on orders"
on public.orders for insert with check (true);

create policy "Allow public update on orders"
on public.orders for update using (true) with check (true);

create policy "Allow public delete on orders"
on public.orders for delete using (true);

-- Order Items Policies
drop policy if exists "Allow public select on order_items" on public.order_items;
drop policy if exists "Allow public insert on order_items" on public.order_items;
drop policy if exists "Allow public update on order_items" on public.order_items;
drop policy if exists "Allow public delete on order_items" on public.order_items;

create policy "Allow public select on order_items"
on public.order_items for select using (true);

create policy "Allow public insert on order_items"
on public.order_items for insert with check (true);

create policy "Allow public update on order_items"
on public.order_items for update using (true) with check (true);

create policy "Allow public delete on order_items"
on public.order_items for delete using (true);

-- Order Edits Policies
drop policy if exists "Allow public select on order_edits" on public.order_edits;
drop policy if exists "Allow public insert on order_edits" on public.order_edits;

create policy "Allow public select on order_edits"
on public.order_edits for select using (true);

create policy "Allow public insert on order_edits"
on public.order_edits for insert with check (true);

-- Expenses Policies
drop policy if exists "Allow public select on expenses" on public.expenses;
drop policy if exists "Allow public insert on expenses" on public.expenses;
drop policy if exists "Allow public update on expenses" on public.expenses;
drop policy if exists "Allow public delete on expenses" on public.expenses;

create policy "Allow public select on expenses"
on public.expenses for select using (true);

create policy "Allow public insert on expenses"
on public.expenses for insert with check (true);

create policy "Allow public update on expenses"
on public.expenses for update using (true) with check (true);

create policy "Allow public delete on expenses"
on public.expenses for delete using (true);

-- ------------------------------------------------------------------------------
-- 7. PERMISSIONS & REALTIME
-- ------------------------------------------------------------------------------
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;
grant execute on function public.get_dashboard_summary() to anon, authenticated;
grant execute on function public.log_order_edit() to anon, authenticated;

-- Enable Realtime for orders, menu_items, and expenses
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.orders;
    alter publication supabase_realtime add table public.menu_items;
    alter publication supabase_realtime add table public.order_edits;
    alter publication supabase_realtime add table public.expenses;
  end if;
end $$;

-- ------------------------------------------------------------------------------
-- 7. INITIAL MENU ITEMS (OPTIONAL: UNCOMMENT IF YOU WANT DEFAULT MENU PRELOADED)
-- ------------------------------------------------------------------------------
/*
insert into public.menu_items (name, price, category, is_available) values
('BIRIYANI Rice H', 50.00, 'Mains', true),
('Biriyani rice F', 70.00, 'Mains', true),
('CHICKEN BIRIYANI', 140.00, 'Mains', true),
('Chicken biriyani H', 100.00, 'Mains', true),
('Alfahm H', 180.00, 'Mains', true),
('Alfahm F', 340.00, 'Mains', true),
('Lime Juice', 25.00, 'Beverages', true),
('Tea', 12.00, 'Beverages', true)
on conflict do nothing;
*/
