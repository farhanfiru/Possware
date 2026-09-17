-- ==============================================================================
-- 02_VIEWS.SQL: Sales & Analytics Reporting Views
-- ==============================================================================

-- 1. DAILY SALES VIEW
-- Aggregates orders, totals, cash/gpay sales, and order counts per calendar day.
create or replace view public.daily_sales as
select
    date(created_at) as sale_date,
    count(*)::int as num_orders,
    coalesce(sum(total), 0)::numeric(10,2) as total_sales,
    coalesce(sum(total) filter (where payment_method = 'cash'), 0)::numeric(10,2) as cash_total,
    coalesce(sum(total) filter (where payment_method = 'gpay'), 0)::numeric(10,2) as gpay_total,
    count(*) filter (where payment_method = 'cash')::int as cash_orders,
    count(*) filter (where payment_method = 'gpay')::int as gpay_orders
from public.orders
where status = 'completed'
group by date(created_at)
order by sale_date desc;

-- 2. DAILY PRODUCT SALES VIEW
-- Aggregates individual product sales, quantities sold, and revenue generated per day.
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

-- 3. MONTHLY SALES VIEW
-- Aggregates sales by month (YYYY-MM-01 format) for month-over-month performance tracking.
create or replace view public.monthly_sales as
select
    date_trunc('month', created_at)::date as sale_month,
    to_char(created_at, 'Month YYYY') as month_label,
    count(*)::int as num_orders,
    coalesce(sum(total), 0)::numeric(10,2) as total_sales,
    coalesce(sum(total) filter (where payment_method = 'cash'), 0)::numeric(10,2) as cash_total,
    coalesce(sum(total) filter (where payment_method = 'gpay'), 0)::numeric(10,2) as gpay_total,
    count(*) filter (where payment_method = 'cash')::int as cash_orders,
    count(*) filter (where payment_method = 'gpay')::int as gpay_orders
from public.orders
where status = 'completed'
group by date_trunc('month', created_at), to_char(created_at, 'Month YYYY')
order by sale_month desc;

-- 4. OVERALL STATS HELPER FUNCTION
-- Quick RPC function for the Owner Dashboard to fetch today, this month, and all-time KPIs in one call
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
                'cash_total', coalesce(sum(total) filter (where payment_method = 'cash'), 0),
                'gpay_total', coalesce(sum(total) filter (where payment_method = 'gpay'), 0),
                'num_orders', count(*),
                'cash_orders', count(*) filter (where payment_method = 'cash'),
                'gpay_orders', count(*) filter (where payment_method = 'gpay')
            )
            from public.orders
            where status = 'completed' and date(created_at) = v_today
        ),
        'this_month', (
            select json_build_object(
                'month_start', v_month_start,
                'total_sales', coalesce(sum(total), 0),
                'cash_total', coalesce(sum(total) filter (where payment_method = 'cash'), 0),
                'gpay_total', coalesce(sum(total) filter (where payment_method = 'gpay'), 0),
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
