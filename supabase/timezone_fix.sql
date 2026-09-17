-- ==============================================================================
-- TIMEZONE & MIDNIGHT CUTOFF FIX (3:00 AM SHIFTED BOUNDARY)
-- NEYCO operates 11:00 AM to 2:00 AM (past midnight).
-- By subtracting 3 hours, sales made between 12:00 AM and 2:59 AM land in the
-- previous calendar day's business shift rather than splitting across dates.
-- ==============================================================================

-- 1. Set database default timezone to Asia/Kolkata (IST, UTC+5:30)
alter database postgres set timezone to 'Asia/Kolkata';

-- 2. DAILY SALES VIEW (Shifted 3-hour boundary)
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

-- 3. DAILY PRODUCT SALES VIEW (Shifted 3-hour boundary)
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

-- 4. MONTHLY SALES VIEW (Shifted 3-hour boundary)
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
