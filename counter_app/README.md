# Naycko Counter App (Flutter POS & Bluetooth Thermal Billing)

A cross-platform Flutter Point-of-Sale (POS) counter billing terminal designed for restaurants and cafes. It syncs with Supabase in real-time and prints formatted customer receipts on Bluetooth Classic SPP thermal printers.

---

## ✨ Features

- 📱 **POS Billing Interface**: Fast menu item lookup, category filters, and touch-to-add items.
- 🛒 **Interactive Bill Cart**: Real-time quantity adjustments, price calculations, and item removals.
- 💵 **Payment Modes**:
  - **Cash**: Quick tender notes (`₹100`, `₹200`, `₹500`, `₹2000`, `Exact`) with instant Change-Due calculator.
  - **GPay (UPI)**: Instant UPI QR code & transaction confirmation.
- 🖨️ **Bluetooth Thermal Printing (ESC/POS)**:
  - Supports standard **58mm** (2-inch / 32 columns) & **80mm** (3-inch / 48 columns) Bluetooth Classic SPP receipt printers (UUID `00001101-0000-1000-8000-00805F9B34FB`).
  - Formatted receipts: Restaurant Header, Invoice ID, Date & Time, Itemized Table (`Qty x Unit Price = Total`), Grand Total, Payment Mode badge (`CASH` / `GPAY`), and footer note.
  - Device scanner, paired device manager, and 1-tap Test Print.
- ⚡ **Direct Supabase Integration**:
  - Automatically fetches live available menu items from `menu_items`.
  - Atomically writes finalized bills to `orders` and line items snapshot to `order_items`.
  - Subscribes to real-time menu updates (menu changes on the Owner website reflect immediately on the counter screen).

---

## 📂 Project Structure

```
counter_app/
├── lib/
│   ├── config/
│   │   └── supabase_config.dart     # Credentials & SharedPreferences storage
│   ├── models/
│   │   ├── menu_item.dart           # Food & Beverage item model
│   │   ├── cart_item.dart           # Active cart line item model
│   │   └── order_model.dart         # Order & OrderItems serialization
│   ├── providers/
│   │   └── billing_provider.dart    # Cart state, payments, checkout orchestration
│   ├── screens/
│   │   ├── pos_screen.dart          # Main adaptive billing screen (Tablet & Mobile)
│   │   ├── printer_settings_screen.dart # Bluetooth device pair & test print
│   │   └── settings_screen.dart     # Supabase URL/Key & receipt header setup
│   ├── services/
│   │   ├── printer_service.dart     # ESC/POS Bluetooth SPP thermal printing
│   │   └── supabase_service.dart    # Supabase CRUD & Realtime subscription
│   ├── widgets/
│   │   ├── cart_panel.dart          # Bill summary panel with charge button
│   │   ├── category_selector.dart   # Category filter chips
│   │   ├── menu_item_card.dart      # Touch-friendly menu item card
│   │   ├── order_receipt_dialog.dart# Post-checkout receipt popup with reprint
│   │   └── payment_modal.dart       # Cash tender / GPay payment sheet
│   └── main.dart                    # App root & Provider setup
└── pubspec.yaml
```

---

## 🚀 Running the Counter App

### Prerequisites
1. [Flutter SDK (3.0+)](https://docs.flutter.dev/get-started/install) installed.
2. Android phone, tablet, or emulator with Bluetooth enabled.

### Steps
1. Navigate to the `counter_app` directory:
   ```bash
   cd counter_app
   ```
2. Install Flutter dependencies:
   ```bash
   flutter pub get
   ```
3. Run on your connected Android device or emulator:
   ```bash
   flutter run
   ```

### ⚙️ First-Time Configuration
1. Tap the **Settings** icon (top right) in the Counter App.
2. Enter your **Supabase Project URL** and **Anon Public Key** (from Supabase Dashboard > Project Settings > API).
3. Enter your **Restaurant Name, Address, and Phone** for receipt headers.
4. Tap **Save & Reconnect Backend**.
5. Pair your Bluetooth ESC/POS printer in Android Settings, then open **Printer Settings** in the app to connect.
