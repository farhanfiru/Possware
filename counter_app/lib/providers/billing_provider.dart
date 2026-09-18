import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import '../services/printer_service.dart';
import '../services/offline_storage_service.dart';

class BillingProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  final PrinterService _printerService = PrinterService();
  final OfflineStorageService _offlineService = OfflineStorageService();

  List<MenuItem> _menuItems = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isLoading = false;
  int _pendingOfflineCount = 0;
  bool _isSyncing = false;

  final List<CartItem> _cart = [];
  String _paymentMethod = 'cash'; // 'cash', 'gpay', or 'split'
  double _cashTendered = 0.0;
  double _splitCashAmount = 0.0;
  double _splitGpayAmount = 0.0;
  bool _isProcessingOrder = false;
  OrderModel? _lastCompletedOrder;

  // Getters
  List<MenuItem> get menuItems {
    return _menuItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty || item.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<String> get categories => _categories;
  String get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  int get pendingOfflineCount => _pendingOfflineCount;
  bool get isSyncing => _isSyncing;

  List<CartItem> get cart => List.unmodifiable(_cart);
  String get paymentMethod => _paymentMethod;
  double get cashTendered => _cashTendered;
  double get splitCashAmount => _splitCashAmount;
  double get splitGpayAmount => _splitGpayAmount;
  bool get isProcessingOrder => _isProcessingOrder;
  OrderModel? get lastCompletedOrder => _lastCompletedOrder;

  int get totalItemCount => _cart.fold(0, (sum, item) => sum + item.quantity);
  double get grandTotal => _cart.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get changeDue {
    final target = _paymentMethod == 'split' ? _splitCashAmount : grandTotal;
    return (_cashTendered - target) > 0 ? (_cashTendered - target) : 0.0;
  }

  BillingProvider() {
    _printerService.addListener(() {
      notifyListeners();
    });
  }

  bool get isPrinterConnected => _printerService.isConnected;

  Future<void> refreshPrinterStatus() async {
    await _printerService.checkConnection();
    notifyListeners();
  }

  // Initialize data
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _supabaseService.initialize().timeout(const Duration(seconds: 4), onTimeout: () => false);
      await fetchMenu();
      await refreshPendingOfflineCount();

      // Trigger background sync if there are pending offline orders
      if (_pendingOfflineCount > 0) {
        syncOfflineOrdersNow();
      }

      _supabaseService.subscribeToMenuChanges((updatedMenu) {
        if (updatedMenu.isNotEmpty) {
          _updateMenuItemsList(updatedMenu);
        }
      });
    } catch (e) {
      print('Init notice: $e');
      if (_menuItems.isEmpty) {
        _updateMenuItemsList(_supabaseService.getMockMenuItems());
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Initialize bluetooth printer non-blocking in background
    Future.microtask(() async {
      try {
        await _printerService.init().timeout(const Duration(seconds: 3), onTimeout: () {});
        notifyListeners();
      } catch (e) {
        print('Printer init notice: $e');
      }
    });
  }

  Future<void> refreshPendingOfflineCount() async {
    try {
      _pendingOfflineCount = await _offlineService.getPendingOfflineOrdersCount();
      notifyListeners();
    } catch (e) {
      print('Error checking pending offline count: $e');
    }
  }

  Future<int> syncOfflineOrdersNow() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    notifyListeners();

    try {
      final synced = await _supabaseService.syncOfflineOrders();
      await refreshPendingOfflineCount();
      return synced;
    } catch (e) {
      print('Sync error: $e');
      return 0;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }


  Future<void> fetchMenu() async {
    try {
      final items = await _supabaseService.fetchMenuItems().timeout(
        const Duration(seconds: 8),
        onTimeout: () => _menuItems.isNotEmpty ? _menuItems : _supabaseService.getMockMenuItems(),
      );
      if (items.isNotEmpty) {
        _updateMenuItemsList(items);
      }
    } catch (e) {
      print('Fetch menu notice: $e');
      if (_menuItems.isEmpty) {
        _updateMenuItemsList(_supabaseService.getMockMenuItems());
      }
    }
  }

  void _updateMenuItemsList(List<MenuItem> items) {
    _menuItems = items;
    final catSet = <String>{'All'};
    for (final item in items) {
      if (item.category.isNotEmpty) catSet.add(item.category);
    }
    _categories = catSet.toList();
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  // Cart Management
  void addToCart(MenuItem item) {
    final index = _cart.indexWhere((c) => c.menuItem.id == item.id);
    if (index >= 0) {
      _cart[index].quantity += 1;
    } else {
      _cart.add(CartItem(menuItem: item, quantity: 1));
    }
    _autoInitSplitAmounts();
    notifyListeners();
  }

  void incrementQuantity(String menuItemId) {
    final index = _cart.indexWhere((c) => c.menuItem.id == menuItemId);
    if (index >= 0) {
      _cart[index].quantity += 1;
      _autoInitSplitAmounts();
      notifyListeners();
    }
  }

  void decrementQuantity(String menuItemId) {
    final index = _cart.indexWhere((c) => c.menuItem.id == menuItemId);
    if (index >= 0) {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity -= 1;
      } else {
        _cart.removeAt(index);
      }
      _autoInitSplitAmounts();
      notifyListeners();
    }
  }

  void removeFromCart(String menuItemId) {
    _cart.removeWhere((c) => c.menuItem.id == menuItemId);
    _autoInitSplitAmounts();
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _cashTendered = 0.0;
    _splitCashAmount = 0.0;
    _splitGpayAmount = 0.0;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    _autoInitSplitAmounts();
    notifyListeners();
  }

  void setCashTendered(double amount) {
    _cashTendered = amount;
    notifyListeners();
  }

  void setSplitAmounts({required double cash, required double gpay}) {
    _splitCashAmount = cash;
    _splitGpayAmount = gpay;
    notifyListeners();
  }

  void _autoInitSplitAmounts() {
    if (_paymentMethod == 'split') {
      if (_splitCashAmount == 0 && _splitGpayAmount == 0) {
        _splitCashAmount = (grandTotal / 2).roundToDouble();
        _splitGpayAmount = grandTotal - _splitCashAmount;
      } else {
        _splitGpayAmount = grandTotal - _splitCashAmount;
        if (_splitGpayAmount < 0) _splitGpayAmount = 0;
      }
    }
  }

  // Checkout and optional printing
  Future<OrderModel?> processCheckout({
    bool autoPrint = true,
    double? cashAmount,
    double? gpayAmount,
    String? notes,
  }) async {
    if (_cart.isEmpty) return null;

    _isProcessingOrder = true;
    notifyListeners();

    try {
      final effectiveCash = _paymentMethod == 'split' ? (cashAmount ?? _splitCashAmount) : (_paymentMethod == 'cash' ? grandTotal : 0.0);
      final effectiveGpay = _paymentMethod == 'split' ? (gpayAmount ?? _splitGpayAmount) : (_paymentMethod == 'gpay' ? grandTotal : 0.0);

      final order = await _supabaseService.createOrder(
        cartItems: _cart,
        paymentMethod: _paymentMethod,
        total: grandTotal,
        cashAmount: effectiveCash,
        gpayAmount: effectiveGpay,
        notes: notes,
      );

      _lastCompletedOrder = order;

      // Auto-print receipt
      if (autoPrint && order != null && _printerService.isConnected) {
        try {
          await _printerService.printReceipt(order);
        } catch (printErr) {
          print('Printer receipt notice: $printErr');
        }
      }

      clearCart();
      await refreshPendingOfflineCount();

      // If there are queued orders, try background sync non-blocking
      if (_pendingOfflineCount > 0) {
        Future.microtask(() => syncOfflineOrdersNow());
      }

      _isProcessingOrder = false;
      notifyListeners();
      return order;
    } catch (e) {
      _isProcessingOrder = false;
      notifyListeners();
      rethrow;
    }
  }

  // Reprint last bill
  Future<bool> reprintLastBill() async {
    if (_lastCompletedOrder == null) return false;
    return await _printerService.printReceipt(_lastCompletedOrder!);
  }
}
