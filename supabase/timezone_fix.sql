-- ==============================================================================
-- TIMEZONE_FIX.SQL: Set Database Timezone & Local Date Grouping in Views
-- ==============================================================================

-- 1. Set database default timezone to Asia/Kolkata (IST, UTC+5:30)
-- (You can change 'Asia/Kolkata' to your desired local timezone, e.g. 'America/New_York', 'UTC', etc.)
alter database postgres set timezone to 'Asia/Kolkata';

-- 2. Update daily_sales view to group by local timezone date
create or replace view public.daily_sales as
select
    (created_at at time zone 'Asia/Kolkata')::date as sale_date,
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
group by (created_at at time zone 'Asia/Kolkata')::date
order by sale_date desc;

-- 3. Update daily_product_sales view to group by local timezone date
create or replace view public.daily_product_sales as
select
    (o.created_at at time zone 'Asia/Kolkata')::date as sale_date,
    oi.name as product_name,
    coalesce(sum(oi.qty), 0)::int as qty_sold,
    coalesce(sum(oi.qty * oi.price), 0)::numeric(10,2) as revenue
from public.orders o
join public.order_items oi on oi.order_id = o.id
where o.status = 'completed'
group by (o.created_at at time zone 'Asia/Kolkata')::date, oi.name
order by sale_date desc, qty_sold desc;

-- 4. Update monthly_sales view to group by local month
create or replace view public.monthly_sales as
select
    date_trunc('month', created_at at time zone 'Asia/Kolkata')::date as sale_month,
    to_char(created_at at time zone 'Asia/Kolkata', 'Month YYYY') as month_label,
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
group by date_trunc('month', created_at at time zone 'Asia/Kolkata'), to_char(created_at at time zone 'Asia/Kolkata', 'Month YYYY')
order by sale_month desc;
