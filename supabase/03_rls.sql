-- ==============================================================================
-- 03_RLS.SQL: Row Level Security (RLS) Access Policies
-- ==============================================================================

-- Enable Row Level Security on all core tables
alter table public.menu_items enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;

-- ==============================================================================
-- 1. MENU_ITEMS POLICIES
-- Counter App / Anonymous: Can read menu items to display on counter screen
-- Owner (Authenticated): Full CRUD (Create, Read, Update, Delete)
-- ==============================================================================

-- Counter App / Anon: Read menu items
create policy "Counter & Public can view menu items"
on public.menu_items
for select
to anon, authenticated
using (true);

-- Owner (Authenticated): Insert new menu items
create policy "Owner can insert menu items"
on public.menu_items
for insert
to authenticated
with check (true);

-- Owner (Authenticated): Update menu items (prices, availability, names)
create policy "Owner can update menu items"
on public.menu_items
for update
to authenticated
using (true)
with check (true);

-- Owner (Authenticated): Delete menu items
create policy "Owner can delete menu items"
on public.menu_items
for delete
to authenticated
using (true);


-- ==============================================================================
-- 2. ORDERS POLICIES
-- Counter App / Anonymous: Can insert new completed bills
-- Counter App / Anonymous: Can read orders created in current session / read for bill verification
-- Owner (Authenticated): Full access to read, filter, manage all orders
-- ==============================================================================

-- Counter App / Anon: Insert orders
create policy "Counter can create orders"
on public.orders
for insert
to anon, authenticated
with check (true);

-- Counter & Owner: View orders
create policy "Anyone can read orders"
on public.orders
for select
to anon, authenticated
using (true);

-- Owner (Authenticated): Update / Cancel orders
create policy "Owner can update orders"
on public.orders
for update
to authenticated
using (true)
with check (true);

-- Owner (Authenticated): Delete orders if needed
create policy "Owner can delete orders"
on public.orders
for delete
to authenticated
using (true);


-- ==============================================================================
-- 3. ORDER_ITEMS POLICIES
-- Counter App / Anonymous: Can insert line items matching created order
-- Owner (Authenticated): Full access
-- ==============================================================================

-- Counter App / Anon: Insert order items
create policy "Counter can insert order items"
on public.order_items
for insert
to anon, authenticated
with check (true);

-- Counter & Owner: Read order items for receipts and reports
create policy "Anyone can read order items"
on public.order_items
for select
to anon, authenticated
using (true);

-- Owner (Authenticated): Update / Delete order items
create policy "Owner can manage order items"
on public.order_items
for all
to authenticated
using (true)
with check (true);

-- ==============================================================================
-- 4. GRANTS FOR VIEWS & FUNCTIONS
-- ==============================================================================
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;
grant execute on function public.get_dashboard_summary() to anon, authenticated;
