import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/sales_summary.dart';
import '../config/supabase_config.dart';
import 'offline_storage_service.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  final OfflineStorageService _offlineService = OfflineStorageService();
  SupabaseClient? _client;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized && _client != null;
  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase is not initialized. Please configure credentials in Settings.');
    }
    return _client!;
  }

  Future<bool> initialize() async {
    try {
      final url = await SupabaseConfig.getUrl();
      final anonKey = await SupabaseConfig.getAnonKey();

      if (url.contains('YOUR_PROJECT_ID') || anonKey.contains('YOUR_SUPABASE_ANON_KEY') || anonKey.trim().isEmpty) {
        _isInitialized = false;
        return false;
      }

      _client = SupabaseClient(url, anonKey);
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing Supabase: $e');
      _isInitialized = false;
      return false;
    }
  }

  // Re-initialize with new URL/Key
  Future<bool> reinitialize(String url, String anonKey) async {
    try {
      await SupabaseConfig.saveConfig(url: url, anonKey: anonKey);
      _client = SupabaseClient(url, anonKey);
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Reinit error: $e');
      return false;
    }
  }

  // Fetch all active menu items with offline local cache fallback
  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      if (!_isInitialized || _client == null) {
        await initialize();
      }
      if (isInitialized) {
        final response = await client
            .from('menu_items')
            .select()
            .order('category', ascending: true)
            .order('name', ascending: true)
            .timeout(const Duration(seconds: 6));

        final data = response as List<dynamic>;
        final items = data.map((item) => MenuItem.fromJson(item as Map<String, dynamic>)).toList();
        if (items.isNotEmpty) {
          await _offlineService.saveCachedMenuItems(items);
          return items;
        }
      }
    } catch (e) {
      print('Notice fetching menu items online: $e. Falling back to local cache.');
    }

    // Fallback: local cached menu
    final cached = await _offlineService.getCachedMenuItems();
    if (cached.isNotEmpty) {
      return cached;
    }

    return getMockMenuItems();
  }

  // Place a completed order with order items (Safe for offline & online)
  Future<OrderModel?> createOrder({
    required List<CartItem> cartItems,
    required String paymentMethod, // 'cash', 'gpay', or 'split'
    required double total,
    double? cashAmount,
    double? gpayAmount,
    String? notes,
  }) async {
    final orderId = const Uuid().v4();
    final now = DateTime.now();

    final double effectiveCash = paymentMethod == 'cash'
        ? total
        : (paymentMethod == 'gpay' ? 0.0 : (cashAmount ?? 0.0));
    final double effectiveGpay = paymentMethod == 'gpay'
        ? total
        : (paymentMethod == 'cash' ? 0.0 : (gpayAmount ?? 0.0));

    final order = OrderModel(
      id: orderId,
      createdAt: now,
      total: total,
      paymentMethod: paymentMethod,
      cashAmount: effectiveCash,
      gpayAmount: effectiveGpay,
      status: 'completed',
      notes: notes,
      items: cartItems.map((cartItem) {
        return OrderItemModel(
          orderId: orderId,
          menuItemId: cartItem.menuItem.id,
          name: cartItem.menuItem.name,
          price: cartItem.menuItem.price,
          qty: cartItem.quantity,
        );
      }).toList(),
    );

    // 1. Always save to local order history first
    await _offlineService.saveLocalOrder(order);

    if (!isInitialized) {
      await _offlineService.saveOfflineOrder(order);
      return order;
    }

    try {
      // 2. Try inserting to Supabase with timeout
      await client.from('orders').insert(order.toInsertJson()).timeout(const Duration(seconds: 4));

      try {
        final itemsJson = order.items.map((item) => item.toInsertJson()).toList();
        if (itemsJson.isNotEmpty) {
          await client.from('order_items').insert(itemsJson).timeout(const Duration(seconds: 4));
        }
      } catch (itemErr) {
        print('Order items insert notice (e.g. non-UUID or schema constraint): $itemErr');
        // Fallback: Try inserting items without menuItemId
        try {
          final strippedItems = order.items.map((item) => {
            'order_id': item.orderId,
            'name': item.name,
            'price': item.price,
            'qty': item.qty,
          }).toList();
          await client.from('order_items').insert(strippedItems).timeout(const Duration(seconds: 3));
        } catch (_) {}
      }

      return order;
    } catch (e) {
      print('Supabase error during checkout: $e. Saved to offline sync queue.');
      // 3. Queue offline order for later auto-sync
      await _offlineService.saveOfflineOrder(order);
      // Return the order normally so UI checkout and Bluetooth printing continue seamlessly!
      return order;
    }
  }

  // Sync queued offline orders when connection is available
  Future<int> syncOfflineOrders() async {
    try {
      if (!_isInitialized || _client == null) {
        final ok = await initialize();
        if (!ok) return 0;
      }

      final queuedOrders = await _offlineService.getQueuedOfflineOrders();
      if (queuedOrders.isEmpty) return 0;

      int syncedCount = 0;
      for (final order in queuedOrders) {
        try {
          await client.from('orders').upsert(order.toInsertJson()).timeout(const Duration(seconds: 5));
          try {
            final itemsJson = order.items.map((item) => item.toInsertJson()).toList();
            if (itemsJson.isNotEmpty) {
              await client.from('order_items').upsert(itemsJson).timeout(const Duration(seconds: 5));
            }
          } catch (itemErr) {
            final strippedItems = order.items.map((item) => {
              'order_id': item.orderId,
              'name': item.name,
              'price': item.price,
              'qty': item.qty,
            }).toList();
            try {
              await client.from('order_items').upsert(strippedItems).timeout(const Duration(seconds: 3));
            } catch (_) {}
          }
          await _offlineService.removeOfflineOrder(order.id);
          syncedCount++;
        } catch (e) {
          print('Failed syncing offline order ${order.id}: $e');
          break; // Stop loop if network is still down
        }
      }
      return syncedCount;
    } catch (e) {
      print('Error in syncOfflineOrders: $e');
      return 0;
    }
  }

  // Fetch all orders and calculate metrics for a specific calendar date (Merging online + offline)
  Future<Map<String, dynamic>> fetchDailyData(DateTime targetDate) async {
    List<OrderModel> onlineOrders = [];
    bool onlineSuccess = false;

    if (isInitialized) {
      try {
        final res = await client
            .from('orders')
            .select('*, order_items(*)')
            .eq('status', 'completed')
            .order('created_at', ascending: false)
            .limit(400)
            .timeout(const Duration(seconds: 5));

        final list = (res as List<dynamic>?) ?? [];
        for (final orderJson in list) {
          final rawCreatedAt = orderJson['created_at']?.toString();
          if (rawCreatedAt == null) continue;

          final orderLocalTime = DateTime.parse(rawCreatedAt).toLocal();
          if (orderLocalTime.year == targetDate.year &&
              orderLocalTime.month == targetDate.month &&
              orderLocalTime.day == targetDate.day) {
            final itemsRaw = (orderJson['order_items'] as List<dynamic>?) ?? [];
            final items = itemsRaw.map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>)).toList();
            onlineOrders.add(OrderModel.fromJson(orderJson as Map<String, dynamic>, items));
          }
        }
        onlineSuccess = true;
      } catch (e) {
        print('Supabase orders fetch notice: $e');
      }
    }

    // Fetch local orders saved on this device
    final localOrders = await _offlineService.getLocalOrdersForDate(targetDate);

    // Merge orders (deduplicate by id)
    final Map<String, OrderModel> mergedMap = {};
    for (final o in onlineOrders) {
      mergedMap[o.id] = o;
    }
    for (final o in localOrders) {
      // Local orders ensure offline orders placed today are immediately visible
      mergedMap[o.id] = o;
    }

    final List<OrderModel> finalOrders = mergedMap.values.toList();
    // Sort descending by created_at
    finalOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // If no online connection and no local orders, show mock preview only if uninitialized
    if (!onlineSuccess && finalOrders.isEmpty && !isInitialized) {
      return _getMockDailyData(targetDate);
    }

    // Compute aggregate summary
    int totalOrders = finalOrders.length;
    double totalSales = 0.0;
    double cashTotal = 0.0;
    double gpayTotal = 0.0;
    int cashOrders = 0;
    int gpayOrders = 0;
    int splitOrders = 0;

    for (final o in finalOrders) {
      totalSales += o.total;
      cashTotal += o.cashAmount;
      gpayTotal += o.gpayAmount;
      if (o.paymentMethod == 'cash') cashOrders++;
      if (o.paymentMethod == 'gpay') gpayOrders++;
      if (o.paymentMethod == 'split') splitOrders++;
    }

    final summary = DailySalesSummary(
      date: targetDate,
      totalOrders: totalOrders,
      totalSales: totalSales,
      cashTotal: cashTotal,
      gpayTotal: gpayTotal,
      cashOrders: cashOrders,
      gpayOrders: gpayOrders,
      splitOrders: splitOrders,
    );

    return {
      'summary': summary,
      'orders': finalOrders,
    };
  }


  // Mock data for offline / preview testing with distinct dates
  Map<String, dynamic> _getMockDailyData(DateTime targetDate) {
    final now = DateTime.now();
    final isToday = targetDate.year == now.year && targetDate.month == now.month && targetDate.day == now.day;
    final isYesterday = targetDate.year == now.year && targetDate.month == now.month && targetDate.day == (now.day - 1);

    if (isToday) {
      final todayOrders = [
        OrderModel(
          id: '22220005',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          total: 520.0,
          paymentMethod: 'gpay',
          cashAmount: 0.0,
          gpayAmount: 520.0,
          items: [
            OrderItemModel(orderId: '22220005', name: 'Chicken Tikka (6 pcs)', price: 220.0, qty: 1),
            OrderItemModel(orderId: '22220005', name: 'Farmhouse Veg Pizza 8"', price: 210.0, qty: 1),
            OrderItemModel(orderId: '22220005', name: 'Cold Coffee with Ice Cream', price: 90.0, qty: 1),
          ],
        ),
        OrderModel(
          id: '22220004',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          total: 370.0,
          paymentMethod: 'cash',
          cashAmount: 370.0,
          gpayAmount: 0.0,
          items: [
            OrderItemModel(orderId: '22220004', name: 'Chicken Biryani Special', price: 240.0, qty: 1),
            OrderItemModel(orderId: '22220004', name: 'Sizzling Chocolate Brownie', price: 130.0, qty: 1),
          ],
        ),
        OrderModel(
          id: '22220006',
          createdAt: DateTime.now().subtract(const Duration(hours: 4)),
          total: 450.0,
          paymentMethod: 'split',
          cashAmount: 200.0,
          gpayAmount: 250.0,
          items: [
            OrderItemModel(orderId: '22220006', name: 'Paneer Butter Masala Combo', price: 200.0, qty: 2),
            OrderItemModel(orderId: '22220006', name: 'Fresh Lime Soda', price: 50.0, qty: 1),
          ],
        ),
      ];

      return {
        'summary': DailySalesSummary(
          date: targetDate,
          totalOrders: 3,
          totalSales: 1340.0,
          cashTotal: 570.0,
          gpayTotal: 770.0,
          cashOrders: 1,
          gpayOrders: 1,
          splitOrders: 1,
        ),
        'orders': todayOrders,
      };
    } else if (isYesterday) {
      final yesterdayOrders = [
        OrderModel(
          id: '22220002',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          total: 500.0,
          paymentMethod: 'gpay',
          cashAmount: 0.0,
          gpayAmount: 500.0,
          items: [
            OrderItemModel(orderId: '22220002', name: 'Chicken Biryani Special', price: 240.0, qty: 2),
            OrderItemModel(orderId: '22220002', name: 'Masala Chai', price: 20.0, qty: 1),
          ],
        ),
        OrderModel(
          id: '22220001',
          createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
          total: 290.0,
          paymentMethod: 'cash',
          cashAmount: 290.0,
          gpayAmount: 0.0,
          items: [
            OrderItemModel(orderId: '22220001', name: 'Classic Veg Burger', price: 90.0, qty: 1),
            OrderItemModel(orderId: '22220001', name: 'Peri Peri Fries', price: 100.0, qty: 1),
            OrderItemModel(orderId: '22220001', name: 'Fresh Lime Soda', price: 50.0, qty: 2),
          ],
        ),
      ];

      return {
        'summary': DailySalesSummary(
          date: targetDate,
          totalOrders: 2,
          totalSales: 790.0,
          cashTotal: 290.0,
          gpayTotal: 500.0,
          cashOrders: 1,
          gpayOrders: 1,
          splitOrders: 0,
        ),
        'orders': yesterdayOrders,
      };
    }

    return {
      'summary': DailySalesSummary.empty(targetDate),
      'orders': <OrderModel>[],
    };
  }

  // Listen to realtime menu changes
  RealtimeChannel? subscribeToMenuChanges(Function(List<MenuItem>) onUpdate) {
    if (!isInitialized) return null;

    final channel = client.channel('public:menu_items')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'menu_items',
          callback: (payload) async {
            final updatedMenu = await fetchMenuItems();
            onUpdate(updatedMenu);
          },
        )
        .subscribe();

    return channel;
  }

  // Mock Menu for instant UI display & offline mode
  List<MenuItem> getMockMenuItems() {
    return [
      MenuItem(id: '1', name: 'Masala Chai', price: 20.0, category: 'Beverages', isAvailable: true),
      MenuItem(id: '2', name: 'Filter Coffee', price: 30.0, category: 'Beverages', isAvailable: true),
      MenuItem(id: '3', name: 'Cold Coffee with Ice Cream', price: 90.0, category: 'Beverages', isAvailable: true),
      MenuItem(id: '4', name: 'Fresh Lime Soda', price: 50.0, category: 'Beverages', isAvailable: true),
      MenuItem(id: '5', name: 'Crispy French Fries', price: 80.0, category: 'Starters', isAvailable: true),
      MenuItem(id: '6', name: 'Peri Peri Fries', price: 100.0, category: 'Starters', isAvailable: true),
      MenuItem(id: '7', name: 'Paneer Tikka (6 pcs)', price: 180.0, category: 'Starters', isAvailable: true),
      MenuItem(id: '8', name: 'Chicken Tikka (6 pcs)', price: 220.0, category: 'Starters', isAvailable: true),
      MenuItem(id: '9', name: 'Classic Veg Burger', price: 90.0, category: 'Burgers', isAvailable: true),
      MenuItem(id: '10', name: 'Crispy Chicken Burger', price: 140.0, category: 'Burgers', isAvailable: true),
      MenuItem(id: '11', name: 'Paneer Cheese Grilled Sandwich', price: 110.0, category: 'Burgers', isAvailable: true),
      MenuItem(id: '12', name: 'Margherita Pizza 8"', price: 160.0, category: 'Pizzas', isAvailable: true),
      MenuItem(id: '13', name: 'Farmhouse Veg Pizza 8"', price: 210.0, category: 'Pizzas', isAvailable: true),
      MenuItem(id: '14', name: 'BBQ Chicken Pizza 8"', price: 260.0, category: 'Pizzas', isAvailable: true),
      MenuItem(id: '15', name: 'Veg Fried Rice', price: 130.0, category: 'Mains', isAvailable: true),
      MenuItem(id: '16', name: 'Chicken Biryani Special', price: 240.0, category: 'Mains', isAvailable: true),
      MenuItem(id: '17', name: 'Paneer Butter Masala Combo', price: 200.0, category: 'Mains', isAvailable: true),
      MenuItem(id: '18', name: 'Hot Gulab Jamun (2 pcs)', price: 60.0, category: 'Desserts', isAvailable: true),
      MenuItem(id: '19', name: 'Sizzling Chocolate Brownie', price: 130.0, category: 'Desserts', isAvailable: true),
    ];
  }
}
