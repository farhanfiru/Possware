import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../models/sales_summary.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

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

  // Fetch all active menu items
  Future<List<MenuItem>> fetchMenuItems() async {
    try {
      if (!isInitialized) return getMockMenuItems();

      final response = await client
          .from('menu_items')
          .select()
          .order('category', ascending: true)
          .order('name', ascending: true)
          .timeout(const Duration(seconds: 15));

      final data = response as List<dynamic>;
      return data.map((item) => MenuItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error fetching menu items: $e');
      return getMockMenuItems();
    }
  }

  // Place a completed order with order items
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

    if (!isInitialized) {
      return order;
    }

    try {
      // 1. Insert order record
      await client.from('orders').insert(order.toInsertJson());

      // 2. Insert line items
      final itemsJson = order.items.map((item) => item.toInsertJson()).toList();
      await client.from('order_items').insert(itemsJson);

      return order;
    } catch (e) {
      print('Error creating order in Supabase: $e');
      rethrow;
    }
  }

  // Fetch all orders and calculate metrics for a specific calendar date
  Future<Map<String, dynamic>> fetchDailyData(DateTime targetDate) async {
    if (!isInitialized) {
      return _getMockDailyData(targetDate);
    }

    final String dateStr = "${targetDate.year.toString().padLeft(4, '0')}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}";

    try {
      Map<String, dynamic>? viewRes;
      List<dynamic> list = [];

      try {
        final res = await client
            .from('daily_sales')
            .select()
            .eq('sale_date', dateStr)
            .maybeSingle()
            .timeout(const Duration(seconds: 4));
        if (res != null) {
          viewRes = Map<String, dynamic>.from(res as Map);
        }
      } catch (e) {
        print('daily_sales view notice: $e');
      }

      try {
        final res = await client
            .from('orders')
            .select('*, order_items(*)')
            .eq('status', 'completed')
            .order('created_at', ascending: false)
            .limit(300)
            .timeout(const Duration(seconds: 4));
        list = (res as List<dynamic>?) ?? [];
      } catch (e) {
        print('orders table notice: $e');
      }

      DailySalesSummary? summary;
      if (viewRes != null) {
        summary = DailySalesSummary(
          date: targetDate,
          totalOrders: (viewRes['num_orders'] as num?)?.toInt() ?? 0,
          totalSales: (viewRes['total_sales'] as num?)?.toDouble() ?? 0.0,
          cashTotal: (viewRes['cash_total'] as num?)?.toDouble() ?? 0.0,
          gpayTotal: (viewRes['gpay_total'] as num?)?.toDouble() ?? 0.0,
          cashOrders: (viewRes['cash_orders'] as num?)?.toInt() ?? 0,
          gpayOrders: (viewRes['gpay_orders'] as num?)?.toInt() ?? 0,
          splitOrders: (viewRes['split_orders'] as num?)?.toInt() ?? 0,
        );
      }

      int totalOrders = 0;
      double totalSales = 0.0;
      double cashTotal = 0.0;
      double gpayTotal = 0.0;
      int cashOrders = 0;
      int gpayOrders = 0;
      int splitOrders = 0;

      final List<OrderModel> orders = [];

      for (final orderJson in list) {
        final rawCreatedAt = orderJson['created_at']?.toString();
        if (rawCreatedAt == null) continue;

        final orderLocalTime = DateTime.parse(rawCreatedAt).toLocal();

        if (orderLocalTime.year == targetDate.year &&
            orderLocalTime.month == targetDate.month &&
            orderLocalTime.day == targetDate.day) {
          
          final total = (orderJson['total'] as num?)?.toDouble() ?? 0.0;
          final method = orderJson['payment_method'] as String? ?? 'cash';
          final cash = (orderJson['cash_amount'] as num?)?.toDouble() ?? (method == 'cash' ? total : 0.0);
          final gpay = (orderJson['gpay_amount'] as num?)?.toDouble() ?? (method == 'gpay' ? total : 0.0);

          totalOrders++;
          totalSales += total;
          cashTotal += cash;
          gpayTotal += gpay;

          if (method == 'cash') cashOrders++;
          if (method == 'gpay') gpayOrders++;
          if (method == 'split') splitOrders++;

          final itemsRaw = (orderJson['order_items'] as List<dynamic>?) ?? [];
          final items = itemsRaw.map((i) => OrderItemModel.fromJson(i as Map<String, dynamic>)).toList();
          orders.add(OrderModel.fromJson(orderJson as Map<String, dynamic>, items));
        }
      }

      summary ??= DailySalesSummary(
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
        'orders': orders,
      };
    } catch (e) {
      print('Error in fetchDailyData: $e');
      return {
        'summary': DailySalesSummary.empty(targetDate),
        'orders': <OrderModel>[],
      };
    }
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
