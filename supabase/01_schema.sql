-- ==============================================================================
-- 01_SCHEMA.SQL: Restaurant Billing System Core Schema
-- ==============================================================================

-- Enable UUID extension if not already enabled
create extension if not exists "pgcrypto";

-- 1. MENU ITEMS TABLE
-- Stores restaurant food & drink items, categories, pricing, and active status.
create table if not exists public.menu_items (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now() not null,
    name text not null,
    price numeric(10, 2) not null check (price >= 0),
    category text not null default 'General',
    is_available boolean not null default true,
    image_url text
);

-- 2. ORDERS TABLE
-- Stores finalized counter bills with totals, payment methods, and timestamps.
create table if not exists public.orders (
    id uuid primary key default gen_random_uuid(),
    created_at timestamptz default now() not null,
    total numeric(10, 2) not null check (total >= 0),
    payment_method text not null default 'cash' check (payment_method in ('cash', 'gpay')),
    status text not null default 'completed' check (status in ('completed', 'cancelled', 'refunded')),
    notes text
);

-- 3. ORDER ITEMS TABLE
-- Line items for each order. Stores immutable snapshots of product name & price at sale time.
create table if not exists public.order_items (
    id uuid primary key default gen_random_uuid(),
    order_id uuid not null references public.orders(id) on delete cascade,
    menu_item_id uuid references public.menu_items(id) on delete set null,
    name text not null,       -- snapshot at time of sale
    price numeric(10, 2) not null check (price >= 0),   -- snapshot at time of sale
    qty int not null check (qty > 0)
);

-- ==============================================================================
-- INDEXES FOR HIGH-PERFORMANCE QUERYING & REPORTING
-- ==============================================================================
create index if not exists idx_menu_items_available on public.menu_items(is_available);
create index if not exists idx_menu_items_category on public.menu_items(category);

create index if not exists idx_orders_created_at on public.orders(created_at desc);
create index if not exists idx_orders_status on public.orders(status);
create index if not exists idx_orders_payment_method on public.orders(payment_method);

create index if not exists idx_order_items_order_id on public.order_items(order_id);
create index if not exists idx_order_items_menu_item_id on public.order_items(menu_item_id);

-- Enable Supabase Realtime for orders and menu_items (if realtime publication exists)
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    alter publication supabase_realtime add table public.orders;
    alter publication supabase_realtime add table public.menu_items;
  end if;
exception
  when duplicate_object then null;
end $$;
