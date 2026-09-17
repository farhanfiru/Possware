-- ==============================================================================
-- RESTAURANT BILLING SYSTEM - COMPLETE SUPABASE SETUP SCRIPT (ALL-IN-ONE)
-- Run this entire script in Supabase SQL Editor (https://supabase.com/dashboard)
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS & TABLES
-- ------------------------------------------------------------------------------
create extension if not exists "pgcrypto";

create table if not exists public.menu_items (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now() not null,
    name text not null,
    price numeric(10, 2) not null check (price >= 0),
    category text not null default 'General',
    is_available boolean not null default true,
    image_url text
);

create table if not exists public.orders (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now() not null,
    total numeric(10, 2) not null check (total >= 0),
    payment_method text not null default 'cash' check (payment_method in ('cash', 'gpay', 'split')),
    cash_amount numeric(10, 2) default 0.00,
    gpay_amount numeric(10, 2) default 0.00,
    status text not null default 'completed' check (status in ('completed', 'cancelled', 'refunded')),
    notes text
);

create table if not exists public.order_items (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references public.orders(id) on delete cascade,
    menu_item_id uuid references public.menu_items(id) on delete set null,
    name text not null,       -- snapshot at time of sale
    price numeric(10, 2) not null check (price >= 0),   -- snapshot at time of sale
    qty int not null check (qty > 0)
);

-- ------------------------------------------------------------------------------
-- 2. INDEXES
-- ------------------------------------------------------------------------------
create index if not exists idx_menu_items_available on public.menu_items(is_available);
create index if not exists idx_menu_items_category on public.menu_items(category);

create index if not exists idx_orders_created_at on public.orders(created_at desc);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_orders_payment_method on public.orders(payment_method);

create index if not exists idx_order_items_order_id on public.order_items(order_id);
create index if not exists idx_order_items_menu_item_id on public.order_items(menu_item_id);

-- ------------------------------------------------------------------------------
-- 3. REPORTING VIEWS & RPC FUNCTION
-- ------------------------------------------------------------------------------

-- Daily Sales View (Calculates Pure Cash, Pure GPay, and Split Mixed portions)
create or replace view public.daily_sales as
select
    date(created_at) as sale_date,
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
group by date(created_at)
order by sale_date desc;

-- Daily Product Sales View
create or replace view public.daily_product_sales as
select
    date(o.created_at) as sale_date,
    oi.name as product_name,
    coalesce(sum(oi.qty), 0)::int as qty_sold,
    coalesce(sum(oi.qty * oi.price), 0)::numeric(10,2) as revenue
from public.orders o
join public.order_items oi on oi.order_id = o.id
where o.status = 'completed'
group by date(o.created_at), oi.name
order by sale_date desc, qty_sold desc;

-- Monthly Sales View
create or replace view public.monthly_sales as
select
    date_trunc('month', created_at)::date as sale_month,
    to_char(created_at, 'Month YYYY') as month_label,
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
group by date_trunc('month', created_at), to_char(created_at, 'Month YYYY')
order by sale_month desc;

-- Dashboard Summary RPC Function
create or replace function public.get_dashboard_summary()
returns json
language plpgsql
security definer
as $$
declare
    result json;
    v_today date := current_date;
    v_month_start date := date_trunc('month', current_date)::date;
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
            where status = 'completed' and date(created_at) = v_today
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
            where status = 'completed' and created_at >= v_month_start
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
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- Drop existing policies if re-running
drop policy if exists "Counter & Public can view menu items" on public.menu_items;
drop policy if exists "Owner can insert menu items" on public.menu_items;
drop policy if exists "Owner can update menu items" on public.menu_items;
drop policy if exists "Owner can delete menu items" on public.menu_items;

drop policy if exists "Counter can create orders" on public.orders;
drop policy if exists "Anyone can read orders" on public.orders;
drop policy if exists "Owner can update orders" on public.orders;
drop policy if exists "Owner can delete orders" on public.orders;

drop policy if exists "Counter can insert order items" on public.order_items;
drop policy if exists "Anyone can read order items" on public.order_items;
drop policy if exists "Owner can manage order items" on public.order_items;

-- Menu Items Policies
create policy "Counter & Public can view menu items"
on public.menu_items for select to anon, authenticated using (true);

create policy "Owner can insert menu items"
on public.menu_items for insert to authenticated with check (true);

create policy "Owner can update menu items"
on public.menu_items for update to authenticated using (true) with check (true);

create policy "Owner can delete menu items"
on public.menu_items for delete to authenticated using (true);

-- Orders Policies
create policy "Counter can create orders"
on public.orders for insert to anon, authenticated with check (true);

create policy "Anyone can read orders"
on public.orders for select to anon, authenticated using (true);

create policy "Owner can update orders"
on public.orders for update to authenticated using (true) with check (true);

create policy "Owner can delete orders"
on public.orders for delete to authenticated using (true);

-- Order Items Policies
create policy "Counter can insert order items"
on public.order_items for insert to anon, authenticated with check (true);

create policy "Anyone can read order items"
on public.order_items for select to anon, authenticated using (true);

create policy "Owner can manage order items"
on public.order_items for all to authenticated using (true) with check (true);

-- Permissions
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;
grant execute on function public.get_dashboard_summary() to anon, authenticated;

-- Enable Realtime
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.orders;
    alter publication supabase_realtime add table public.menu_items;
  end if;
exception
  when duplicate_object then null;
end $$;

-- ------------------------------------------------------------------------------
-- 5. SEED DATA (MENU ITEMS & SAMPLE ORDERS)
-- ------------------------------------------------------------------------------
insert into public.menu_items (id, name, price, category, is_available) values
('11111111-1111-1111-1111-111111110001', 'Masala Chai', 20.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110002', 'Filter Coffee', 30.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110003', 'Cold Coffee with Ice Cream', 90.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110004', 'Fresh Lime Soda', 50.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110005', 'Mango Lassi', 70.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110006', 'Crispy French Fries', 80.00, 'Starters', true),
('11111111-1111-1111-1111-111111110007', 'Peri Peri Fries', 100.00, 'Starters', true),
('11111111-1111-1111-1111-111111110008', 'Paneer Tikka (6 pcs)', 180.00, 'Starters', true),
('11111111-1111-1111-1111-111111110009', 'Chicken Tikka (6 pcs)', 220.00, 'Starters', true),
('11111111-1111-1111-1111-111111110010', 'Veg Spring Rolls', 120.00, 'Starters', true),
('11111111-1111-1111-1111-111111110011', 'Classic Veg Burger', 90.00, 'Burgers', true),
('11111111-1111-1111-1111-111111110012', 'Crispy Chicken Burger', 140.00, 'Burgers', true),
('11111111-1111-1111-1111-111111110013', 'Paneer Cheese Grilled Sandwich', 110.00, 'Burgers', true),
('11111111-1111-1111-1111-111111110014', 'Chicken Club Sandwich', 150.00, 'Burgers', true),
('11111111-1111-1111-1111-111111110015', 'Margherita Pizza 8"', 160.00, 'Pizzas', true),
('11111111-1111-1111-1111-111111110016', 'Farmhouse Veg Pizza 8"', 210.00, 'Pizzas', true),
('11111111-1111-1111-1111-111111110017', 'BBQ Chicken Pizza 8"', 260.00, 'Pizzas', true),
('11111111-1111-1111-1111-111111110018', 'Veg Fried Rice', 130.00, 'Mains', true),
('11111111-1111-1111-1111-111111110019', 'Chicken Biryani Special', 240.00, 'Mains', true),
('11111111-1111-1111-1111-111111110020', 'Paneer Butter Masala Combo', 200.00, 'Mains', true),
('11111111-1111-1111-1111-111111110021', 'Butter Naan', 35.00, 'Mains', true),
('11111111-1111-1111-1111-111111110022', 'Hot Gulab Jamun (2 pcs)', 60.00, 'Desserts', true),
('11111111-1111-1111-1111-111111110023', 'Sizzling Chocolate Brownie', 130.00, 'Desserts', true)
on conflict (id) do update set
    name = excluded.name,
    price = excluded.price,
    category = excluded.category,
    is_available = excluded.is_available;

-- Sample Orders with Cash, GPay, and Split
insert into public.orders (id, created_at, total, payment_method, cash_amount, gpay_amount, status) values
('22222222-2222-2222-2222-222222220001', now() - interval '1 day' + interval '2 hours', 290.00, 'cash', 290.00, 0.00, 'completed'),
('22222222-2222-2222-2222-222222220002', now() - interval '1 day' + interval '4 hours', 500.00, 'gpay', 0.00, 500.00, 'completed'),
('22222222-2222-2222-2222-222222220003', now() - interval '2 days' + interval '1 hour', 420.00, 'split', 200.00, 220.00, 'completed'),
('22222222-2222-2222-2222-222222220004', now() - interval '2 hours', 370.00, 'cash', 370.00, 0.00, 'completed'),
('22222222-2222-2222-2222-222222220005', now() - interval '30 minutes', 520.00, 'gpay', 0.00, 520.00, 'completed')
on conflict (id) do nothing;

-- Sample Order Items
insert into public.order_items (order_id, menu_item_id, name, price, qty) values
('22222222-2222-2222-2222-222222220001', '11111111-1111-1111-1111-111111110011', 'Classic Veg Burger', 90.00, 1),
('22222222-2222-2222-2222-222222220001', '11111111-1111-1111-1111-111111110007', 'Peri Peri Fries', 100.00, 1),
('22222222-2222-2222-2222-222222220001', '11111111-1111-1111-1111-111111110004', 'Fresh Lime Soda', 50.00, 2),

('22222222-2222-2222-2222-222222220002', '11111111-1111-1111-1111-111111110019', 'Chicken Biryani Special', 240.00, 2),
('22222222-2222-2222-2222-222222220002', '11111111-1111-1111-1111-111111110001', 'Masala Chai', 20.00, 1),

('22222222-2222-2222-2222-222222220003', '11111111-1111-1111-1111-111111110017', 'BBQ Chicken Pizza 8"', 260.00, 1),
('22222222-2222-2222-2222-222222220003', '11111111-1111-1111-1111-111111110015', 'Margherita Pizza 8"', 160.00, 1),

('22222222-2222-2222-2222-222222220004', '11111111-1111-1111-1111-111111110019', 'Chicken Biryani Special', 240.00, 1),
('22222222-2222-2222-2222-222222220004', '11111111-1111-1111-1111-111111110023', 'Sizzling Chocolate Brownie', 130.00, 1),

('22222222-2222-2222-2222-222222220005', '11111111-1111-1111-1111-111111110009', 'Chicken Tikka (6 pcs)', 220.00, 1),
('22222222-2222-2222-2222-222222220005', '11111111-1111-1111-1111-111111110016', 'Farmhouse Veg Pizza 8"', 210.00, 1),
('22222222-2222-2222-2222-222222220005', '11111111-1111-1111-1111-111111110003', 'Cold Coffee with Ice Cream', 90.00, 1)
on conflict do nothing;
