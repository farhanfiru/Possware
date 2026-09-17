import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/menu_item.dart';
import '../models/order_model.dart';

class OfflineStorageService {
  static final OfflineStorageService _instance = OfflineStorageService._internal();
  factory OfflineStorageService() => _instance;
  OfflineStorageService._internal();

  static const String _keyCachedMenu = 'cached_menu_items_v1';
  static const String _keyOfflineQueue = 'offline_orders_queue_v1';
  static const String _keyLocalOrderHistory = 'local_order_history_v1';

  // --- MENU ITEMS CACHING ---

  Future<void> saveCachedMenuItems(List<MenuItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = items.map((item) => item.toJson()).toList();
      await prefs.setString(_keyCachedMenu, jsonEncode(jsonList));
    } catch (e) {
      print('OfflineStorageService error saving menu: $e');
    }
  }

  Future<List<MenuItem>> getCachedMenuItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyCachedMenu);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => MenuItem.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('OfflineStorageService error reading cached menu: $e');
      return [];
    }
  }

  // --- OFFLINE QUEUE (Orders waiting to sync to Supabase) ---

  Future<void> saveOfflineOrder(OrderModel order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await getQueuedOfflineOrders();

      // Check if already queued
      final index = queue.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        queue[index] = order;
      } else {
        queue.add(order);
      }

      final jsonList = queue.map((o) => o.toMap()).toList();
      await prefs.setString(_keyOfflineQueue, jsonEncode(jsonList));
    } catch (e) {
      print('OfflineStorageService error queuing offline order: $e');
    }
  }

  Future<List<OrderModel>> getQueuedOfflineOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyOfflineQueue);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('OfflineStorageService error reading offline queue: $e');
      return [];
    }
  }

  Future<void> removeOfflineOrder(String orderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queue = await getQueuedOfflineOrders();
      queue.removeWhere((o) => o.id == orderId);

      final jsonList = queue.map((o) => o.toMap()).toList();
      await prefs.setString(_keyOfflineQueue, jsonEncode(jsonList));
    } catch (e) {
      print('OfflineStorageService error removing offline order: $e');
    }
  }

  Future<void> clearOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyOfflineQueue);
    } catch (e) {
      print('OfflineStorageService error clearing queue: $e');
    }
  }

  Future<int> getPendingOfflineOrdersCount() async {
    final queue = await getQueuedOfflineOrders();
    return queue.length;
  }

  // --- LOCAL ORDER HISTORY (All orders created locally on this tablet) ---

  Future<void> saveLocalOrder(OrderModel order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await getAllLocalOrders();

      final index = orders.indexWhere((o) => o.id == order.id);
      if (index >= 0) {
        orders[index] = order;
      } else {
        orders.insert(0, order); // Most recent first
      }

      // Keep last 1000 orders to avoid unbounded storage growth
      if (orders.length > 1000) {
        orders.removeRange(1000, orders.length);
      }

      final jsonList = orders.map((o) => o.toMap()).toList();
      await prefs.setString(_keyLocalOrderHistory, jsonEncode(jsonList));
    } catch (e) {
      print('OfflineStorageService error saving local order: $e');
    }
  }

  Future<List<OrderModel>> getAllLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyLocalOrderHistory);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => OrderModel.fromMap(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      print('OfflineStorageService error reading local order history: $e');
      return [];
    }
  }

  Future<List<OrderModel>> getLocalOrdersForDate(DateTime targetDate) async {
    final allOrders = await getAllLocalOrders();
    // NEYCO trading shift boundary is 3:00 AM (subtract 3 hours for business date)
    final targetBiz = targetDate.toLocal().subtract(const Duration(hours: 3));

    return allOrders.where((o) {
      final orderBiz = o.createdAt.toLocal().subtract(const Duration(hours: 3));
      return orderBiz.year == targetBiz.year &&
          orderBiz.month == targetBiz.month &&
          orderBiz.day == targetBiz.day;
    }).toList();
  }
}
