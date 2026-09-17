-- ==============================================================================
-- UPDATE_SPLIT_PAYMENT.SQL: Support for Split / Mixed Payments (Cash + GPay)
-- Run this in Supabase SQL Editor to enable Split Payments
-- ==============================================================================

-- 1. Update orders table to allow 'split' payment method and record cash/gpay amounts
alter table public.orders drop constraint if exists orders_payment_method_check;
alter table public.orders add constraint orders_payment_method_check check (payment_method in ('cash', 'gpay', 'split'));

alter table public.orders add column if not exists cash_amount numeric(10, 2) default 0.00;
alter table public.orders add column if not exists gpay_amount numeric(10, 2) default 0.00;

-- Backfill existing orders
update public.orders 
set cash_amount = total, gpay_amount = 0.00 
where payment_method = 'cash' and (cash_amount is null or cash_amount = 0);

update public.orders 
set gpay_amount = total, cash_amount = 0.00 
where payment_method = 'gpay' and (gpay_amount is null or gpay_amount = 0);

-- 2. Update daily_sales view to calculate accurate split cash and gpay totals
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

-- 3. Update monthly_sales view
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

-- 4. Update get_dashboard_summary RPC function
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
