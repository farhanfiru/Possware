-- ==============================================================================
-- 04_SEED.SQL: Initial Menu Items & Historical Sample Sales Data
-- ==============================================================================

-- 1. SEED MENU ITEMS
insert into public.menu_items (id, name, price, category, is_available) values
-- Hot & Cold Beverages
('11111111-1111-1111-1111-111111110001', 'Masala Chai', 20.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110002', 'Filter Coffee', 30.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110003', 'Cold Coffee with Ice Cream', 90.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110004', 'Fresh Lime Soda', 50.00, 'Beverages', true),
('11111111-1111-1111-1111-111111110005', 'Mango Lassi', 70.00, 'Beverages', true),

-- Starters & Snacks
('11111111-1111-1111-1111-111111110006', 'Crispy French Fries', 80.00, 'Starters', true),
('11111111-1111-1111-1111-111111110007', 'Peri Peri Fries', 100.00, 'Starters', true),
('11111111-1111-1111-1111-111111110008', 'Paneer Tikka (6 pcs)', 180.00, 'Starters', true),
('11111111-1111-1111-1111-111111110009', 'Chicken Tikka (6 pcs)', 220.00, 'Starters', true),
('11111111-1111-1111-1111-111111110010', 'Veg Spring Rolls', 120.00, 'Starters', true),

-- Burgers & Sandwiches
('11111111-1111-1111-1111-111111110011', 'Classic Veg Burger', 90.00, 'Burgers', true),
('11111111-1111-1111-1111-111111110012', 'Crispy Chicken Burger', 140.00, 'Burgers', true),
('11111111-1111-1111-1111-111111110013', 'Paneer Cheese Grilled Sandwich', 110.00, 'Burgers', true),
('11111111-1111-1111-1111-111111110014', 'Chicken Club Sandwich', 150.00, 'Burgers', true),

-- Pizzas
('11111111-1111-1111-1111-111111110015', 'Margherita Pizza 8"', 160.00, 'Pizzas', true),
('11111111-1111-1111-1111-111111110016', 'Farmhouse Veg Pizza 8"', 210.00, 'Pizzas', true),
('11111111-1111-1111-1111-111111110017', 'BBQ Chicken Pizza 8"', 260.00, 'Pizzas', true),

-- Main Course & Rice
('11111111-1111-1111-1111-111111110018', 'Veg Fried Rice', 130.00, 'Mains', true),
('11111111-1111-1111-1111-111111110019', 'Chicken Biryani Special', 240.00, 'Mains', true),
('11111111-1111-1111-1111-111111110020', 'Paneer Butter Masala Combo', 200.00, 'Mains', true),
('11111111-1111-1111-1111-111111110021', 'Butter Naan', 35.00, 'Mains', true),

-- Desserts
('11111111-1111-1111-1111-111111110022', 'Hot Gulab Jamun (2 pcs)', 60.00, 'Desserts', true),
('11111111-1111-1111-1111-111111110023', 'Sizzling Chocolate Brownie', 130.00, 'Desserts', true)
on conflict (id) do update set
    name = excluded.name,
    price = excluded.price,
    category = excluded.category,
    is_available = excluded.is_available;


-- 2. SEED SAMPLE ORDERS ACROSS DIFFERENT DATES & PAYMENT METHODS

-- Order 1: Yesterday Cash
insert into public.orders (id, created_at, total, payment_method, status) values
('22222222-2222-2222-2222-222222220001', now() - interval '1 day' + interval '2 hours', 290.00, 'cash', 'completed')
on conflict (id) do nothing;

insert into public.order_items (order_id, menu_item_id, name, price, qty) values
('22222222-2222-2222-2222-222222220001', '11111111-1111-1111-1111-111111110011', 'Classic Veg Burger', 90.00, 1),
('22222222-2222-2222-2222-222222220001', '11111111-1111-1111-1111-111111110007', 'Peri Peri Fries', 100.00, 1),
('22222222-2222-2222-2222-222222220001', '11111111-1111-1111-1111-111111110004', 'Fresh Lime Soda', 50.00, 2)
on conflict do nothing;

-- Order 2: Yesterday GPay
insert into public.orders (id, created_at, total, payment_method, status) values
('22222222-2222-2222-2222-222222220002', now() - interval '1 day' + interval '4 hours', 500.00, 'gpay', 'completed')
on conflict (id) do nothing;

insert into public.order_items (order_id, menu_item_id, name, price, qty) values
('22222222-2222-2222-2222-222222220002', '11111111-1111-1111-1111-111111110019', 'Chicken Biryani Special', 240.00, 2),
('22222222-2222-2222-2222-222222220002', '11111111-1111-1111-1111-111111110001', 'Masala Chai', 20.00, 1)
on conflict do nothing;

-- Order 3: 2 Days Ago GPay
insert into public.orders (id, created_at, total, payment_method, status) values
('22222222-2222-2222-2222-222222220003', now() - interval '2 days' + interval '1 hour', 420.00, 'gpay', 'completed')
on conflict (id) do nothing;

insert into public.order_items (order_id, menu_item_id, name, price, qty) values
('22222222-2222-2222-2222-222222220003', '11111111-1111-1111-1111-111111110017', 'BBQ Chicken Pizza 8"', 260.00, 1),
('22222222-2222-2222-2222-222222220003', '11111111-1111-1111-1111-111111110015', 'Margherita Pizza 8"', 160.00, 1)
on conflict do nothing;

-- Order 4: Today Cash
insert into public.orders (id, created_at, total, payment_method, status) values
('22222222-2222-2222-2222-222222220004', now() - interval '2 hours', 370.00, 'cash', 'completed')
on conflict (id) do nothing;

insert into public.order_items (order_id, menu_item_id, name, price, qty) values
('22222222-2222-2222-2222-222222220004', '11111111-1111-1111-1111-111111110019', 'Chicken Biryani Special', 240.00, 1),
('22222222-2222-2222-2222-222222220004', '11111111-1111-1111-1111-111111110023', 'Sizzling Chocolate Brownie', 130.00, 1)
on conflict do nothing;

-- Order 5: Today GPay
insert into public.orders (id, created_at, total, payment_method, status) values
('22222222-2222-2222-2222-222222220005', now() - interval '30 minutes', 520.00, 'gpay', 'completed')
on conflict (id) do nothing;

insert into public.order_items (order_id, menu_item_id, name, price, qty) values
('22222222-2222-2222-2222-222222220005', '11111111-1111-1111-1111-111111110009', 'Chicken Tikka (6 pcs)', 220.00, 1),
('22222222-2222-2222-2222-222222220005', '11111111-1111-1111-1111-111111110016', 'Farmhouse Veg Pizza 8"', 210.00, 1),
('22222222-2222-2222-2222-222222220005', '11111111-1111-1111-1111-111111110003', 'Cold Coffee with Ice Cream', 90.00, 1)
on conflict do nothing;
