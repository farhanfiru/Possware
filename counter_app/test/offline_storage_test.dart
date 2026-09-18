import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:counter_app/models/menu_item.dart';
import 'package:counter_app/models/order_model.dart';
import 'package:counter_app/services/offline_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Offline Storage & Serialization Tests', () {
    test('OrderModel serialization and deserialization retains all fields and items', () {
      final order = OrderModel(
        id: 'ord_123',
        createdAt: DateTime(2026, 9, 18, 12, 30),
        total: 350.0,
        paymentMethod: 'split',
        cashAmount: 200.0,
        gpayAmount: 150.0,
        notes: 'Less spicy',
        invoiceNumber: '1809-001',
        items: [
          OrderItemModel(
            id: 'item_1',
            orderId: 'ord_123',
            menuItemId: 'menu_9',
            name: 'Classic Veg Burger',
            price: 90.0,
            qty: 2,
          ),
          OrderItemModel(
            id: 'item_2',
            orderId: 'ord_123',
            menuItemId: 'menu_8',
            name: 'Chicken Tikka',
            price: 170.0,
            qty: 1,
          ),
        ],
      );

      final map = order.toMap();
      final reconstructed = OrderModel.fromMap(map);

      expect(reconstructed.id, equals('ord_123'));
      expect(reconstructed.invoiceNumber, equals('1809-001'));
      expect(reconstructed.displayInvoiceNumber, equals('1809-001'));
      expect(reconstructed.total, equals(350.0));
      expect(reconstructed.paymentMethod, equals('split'));
      expect(reconstructed.cashAmount, equals(200.0));
      expect(reconstructed.gpayAmount, equals(150.0));
      expect(reconstructed.notes, equals('Less spicy'));
      expect(reconstructed.items.length, equals(2));
      expect(reconstructed.items[0].name, equals('Classic Veg Burger'));
      expect(reconstructed.items[0].qty, equals(2));
      expect(reconstructed.items[1].name, equals('Chicken Tikka'));
    });

    test('OrderModel fallback displayInvoiceNumber generates clean date-based format', () {
      final orderPastMidnight = OrderModel(
        id: 'ord-a1b2-c3d4-9876',
        createdAt: DateTime(2026, 9, 19, 1, 30), // Belongs to 18 Sep trading day (3 AM boundary)
        total: 100.0,
        paymentMethod: 'cash',
      );

      expect(orderPastMidnight.displayInvoiceNumber.startsWith('1809-'), isTrue);
    });

    test('OfflineStorageService saves and retrieves cached menu items', () async {
      final service = OfflineStorageService();
      final menu = [
        MenuItem(id: '1', name: 'Masala Chai', price: 20.0, category: 'Beverages', isAvailable: true),
        MenuItem(id: '2', name: 'Filter Coffee', price: 30.0, category: 'Beverages', isAvailable: true),
      ];

      await service.saveCachedMenuItems(menu);
      final retrieved = await service.getCachedMenuItems();

      expect(retrieved.length, equals(2));
      expect(retrieved[0].name, equals('Masala Chai'));
      expect(retrieved[1].price, equals(30.0));
    });

    test('OfflineStorageService queues offline orders and updates count', () async {
      final service = OfflineStorageService();
      final order1 = OrderModel(
        id: 'ord_offline_1',
        createdAt: DateTime.now(),
        total: 100.0,
        paymentMethod: 'cash',
        cashAmount: 100.0,
        items: [
          OrderItemModel(orderId: 'ord_offline_1', name: 'Peri Peri Fries', price: 100.0, qty: 1),
        ],
      );

      await service.saveOfflineOrder(order1);
      expect(await service.getPendingOfflineOrdersCount(), equals(1));

      final queue = await service.getQueuedOfflineOrders();
      expect(queue.length, equals(1));
      expect(queue.first.id, equals('ord_offline_1'));

      await service.removeOfflineOrder('ord_offline_1');
      expect(await service.getPendingOfflineOrdersCount(), equals(0));
    });

    test('OfflineStorageService saves local order history and filters by date', () async {
      final service = OfflineStorageService();
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      final orderToday = OrderModel(
        id: 'ord_today',
        createdAt: today,
        total: 250.0,
        paymentMethod: 'gpay',
        gpayAmount: 250.0,
      );

      final orderYesterday = OrderModel(
        id: 'ord_yesterday',
        createdAt: yesterday,
        total: 180.0,
        paymentMethod: 'cash',
        cashAmount: 180.0,
      );

      await service.saveLocalOrder(orderToday);
      await service.saveLocalOrder(orderYesterday);

      final todayOrders = await service.getLocalOrdersForDate(today);
      expect(todayOrders.length, equals(1));
      expect(todayOrders.first.id, equals('ord_today'));

      final yesterdayOrders = await service.getLocalOrdersForDate(yesterday);
      expect(yesterdayOrders.length, equals(1));
    });

    test('OfflineStorageService groups orders placed past midnight (before 3 AM) into previous trading day', () async {
      final service = OfflineStorageService();

      // Sep 18, 11:30 PM (Regular night order)
      final nightOrder = OrderModel(
        id: 'ord_night_18',
        createdAt: DateTime(2026, 9, 18, 23, 30),
        total: 200.0,
        paymentMethod: 'cash',
        cashAmount: 200.0,
      );

      // Sep 19, 1:30 AM (Post-midnight order belonging to Sep 18 shift)
      final postMidnightOrder = OrderModel(
        id: 'ord_post_midnight_19',
        createdAt: DateTime(2026, 9, 19, 1, 30),
        total: 150.0,
        paymentMethod: 'gpay',
        gpayAmount: 150.0,
      );

      // Sep 19, 11:30 AM (Next day's morning order)
      final nextDayOrder = OrderModel(
        id: 'ord_next_day_19',
        createdAt: DateTime(2026, 9, 19, 11, 30),
        total: 300.0,
        paymentMethod: 'cash',
        cashAmount: 300.0,
      );

      await service.saveLocalOrder(nightOrder);
      await service.saveLocalOrder(postMidnightOrder);
      await service.saveLocalOrder(nextDayOrder);

      // Querying for Sep 18 trading day (e.g. at 2:00 PM on Sep 18)
      final sep18Orders = await service.getLocalOrdersForDate(DateTime(2026, 9, 18, 14, 0));
      expect(sep18Orders.length, equals(2));
      expect(sep18Orders.map((o) => o.id).toSet(), equals({'ord_night_18', 'ord_post_midnight_19'}));

      // Querying for Sep 19 trading day
      final sep19Orders = await service.getLocalOrdersForDate(DateTime(2026, 9, 19, 14, 0));
      expect(sep19Orders.length, equals(1));
      expect(sep19Orders.first.id, equals('ord_next_day_19'));
    });
  });
}
