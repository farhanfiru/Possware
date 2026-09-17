# Supabase Database Setup for Restaurant Billing System

This directory contains the database schema, analytics views, security policies (RLS), and sample seed data for the Restaurant Billing System.

---

## 🚀 Quick Setup (1-Click)

1. Go to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Create a new project (or select an existing one).
3. Navigate to **SQL Editor** from the left sidebar.
4. Click **New Query**, copy the contents of [`setup_all.sql`](file:///c:/Users/farha/Desktop/naycko/supabase/setup_all.sql), and click **Run**.

---

## 📁 Individual Script Files

If you prefer running individual migration scripts in order:

| File | Purpose |
|------|---------|
| [`01_schema.sql`](file:///c:/Users/farha/Desktop/naycko/supabase/01_schema.sql) | Core tables (`menu_items`, `orders`, `order_items`), constraints, performance indexes, and Realtime replication |
| [`02_views.sql`](file:///c:/Users/farha/Desktop/naycko/supabase/02_views.sql) | Reporting views (`daily_sales`, `daily_product_sales`, `monthly_sales`) and `get_dashboard_summary()` RPC function |
| [`03_rls.sql`](file:///c:/Users/farha/Desktop/naycko/supabase/03_rls.sql) | Row Level Security (RLS) policies for Owner CRUD & Counter POS insert/view access |
| [`04_seed.sql`](file:///c:/Users/farha/Desktop/naycko/supabase/04_seed.sql) | Realistic initial menu items (Beverages, Starters, Burgers, Pizzas, Mains, Desserts) & sample orders |

---

## 👤 Creating the Owner Login Account

To log into the **Owner Web Dashboard**:
1. In the Supabase Dashboard, go to **Authentication** > **Users**.
2. Click **Add User** > **Create User**.
3. Enter the owner's email and password (e.g. `owner@restaurant.com` / `YourPassword123!`).
4. Set **Auto Confirm User?** to **Yes**.

---

## 🔑 Supabase Credentials

Copy the following from **Project Settings** > **API**:
- **Project URL** (e.g., `https://xyzproject.supabase.co`)
- **anon / public key** (e.g., `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)

These credentials will be configured in:
- **Owner Web App**: in `config.js` or via the web settings modal.
- **Flutter Counter App**: in `lib/config/supabase_config.dart`.
