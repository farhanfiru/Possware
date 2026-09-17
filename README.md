# Neyco POS - Restaurant Counter Billing & Management System

A cross-platform Point-of-Sale (POS) counter billing terminal and real-time backend designed for restaurants and cafes.

---

## 📁 Repository Structure

```
naycko/
├── counter_app/           # Flutter Counter POS App (Android / Tablet / Desktop)
│   ├── lib/               # Dart source code (screens, providers, services, models, widgets)
│   ├── android/           # Native Android Gradle configuration & permissions
│   └── pubspec.yaml       # Flutter dependencies & assets
│
└── supabase/              # Supabase PostgreSQL Backend
    ├── setup_all.sql      # Full database schema (tables, views, RLS policies, seed data)
    ├── update_split_payment.sql # Split payment support migrations
    ├── timezone_fix.sql   # Timezone-aware date aggregation views
    └── README.md          # Backend documentation
```

---

## 🚀 Getting Started

### 1. Supabase Backend Setup
1. Create a new Supabase project at [supabase.com](https://supabase.com).
2. In Supabase Dashboard, go to **SQL Editor** $\rightarrow$ **New query**.
3. Paste and run [`supabase/setup_all.sql`](supabase/setup_all.sql).

### 2. Counter POS Flutter App
1. Navigate to `counter_app/`:
   ```bash
   cd counter_app
   flutter pub get
   ```
2. Run on connected Android device / emulator or Windows:
   ```bash
   flutter run
   ```
3. In the Counter App, open **Settings** (PIN: `9599`) and enter your Supabase Project URL & Anon Key.

---

## ✨ Features
- **Touch Counter Billing**: Responsive POS terminal with category tabs, search, item counters, and order cart.
- **Flexible Payment Modes**: Cash (with tender & change calculation), 1-tap GPay checkout, and Split (Cash + GPay) payments.
- **ESC/POS Thermal Printing**: Formatted customer receipts and Daily Sales Summary (Z-Report) via Bluetooth thermal printer (58mm / 80mm).
- **Daily Sales & Revenue Reports**: Real-time sales summary, cash drawer vs online breakdown, and historical bill inspection.
- **Protected Settings**: PIN-protected (`9599`) Supabase API configuration and customizable restaurant receipt headers.
