class OrderModel {
  final String id;
  final DateTime createdAt;
  final double total;
  final String paymentMethod; // 'cash', 'gpay', or 'split'
  final double cashAmount;
  final double gpayAmount;
  final String status;
  final String? notes;
  final List<OrderItemModel> items;
  final String? invoiceNumber;

  OrderModel({
    required this.id,
    required this.createdAt,
    required this.total,
    required this.paymentMethod,
    this.cashAmount = 0.0,
    this.gpayAmount = 0.0,
    this.status = 'completed',
    this.notes,
    this.items = const [],
    this.invoiceNumber,
  });

  String get displayInvoiceNumber {
    if (invoiceNumber != null && invoiceNumber!.trim().isNotEmpty) {
      return invoiceNumber!;
    }
    final bizDate = createdAt.toLocal().subtract(const Duration(hours: 3));
    final dd = bizDate.day.toString().padLeft(2, '0');
    final mm = bizDate.month.toString().padLeft(2, '0');
    final datePrefix = '$dd$mm';

    final numericOnly = id.replaceAll(RegExp(r'[^0-9]'), '');
    final suffix = numericOnly.length >= 3
        ? numericOnly.substring(numericOnly.length - 3)
        : (id.length >= 3 ? id.substring(0, 3).toUpperCase() : '001');
    return '$datePrefix-$suffix';
  }

  factory OrderModel.fromJson(Map<String, dynamic> json, [List<OrderItemModel> items = const []]) {
    final method = json['payment_method'] as String? ?? 'cash';
    final total = (json['total'] as num?)?.toDouble() ?? 0.0;
    final cash = (json['cash_amount'] as num?)?.toDouble() ?? (method == 'cash' ? total : 0.0);
    final gpay = (json['gpay_amount'] as num?)?.toDouble() ?? (method == 'gpay' ? total : 0.0);

    List<OrderItemModel> resolvedItems = items;
    if (resolvedItems.isEmpty && json['items'] is List) {
      resolvedItems = (json['items'] as List)
          .map((i) => OrderItemModel.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList();
    }

    return OrderModel(
      id: json['id'] as String,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      total: total,
      paymentMethod: method,
      cashAmount: cash,
      gpayAmount: gpay,
      status: json['status'] as String? ?? 'completed',
      notes: json['notes'] as String?,
      items: resolvedItems,
      invoiceNumber: json['invoice_number'] as String?,
    );
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'total': total,
      'payment_method': paymentMethod,
      'cash_amount': cashAmount,
      'gpay_amount': gpayAmount,
      'status': status,
      if (notes != null) 'notes': notes,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      'items': items.map((i) => i.toMap()).toList(),
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'total': total,
      'payment_method': paymentMethod,
      'cash_amount': cashAmount,
      'gpay_amount': gpayAmount,
      'status': status,
      if (notes != null) 'notes': notes,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
    };
  }
}

class OrderItemModel {
  final String? id;
  final String orderId;
  final String? menuItemId;
  final String name;
  final double price;
  final int qty;

  OrderItemModel({
    this.id,
    required this.orderId,
    this.menuItemId,
    required this.name,
    required this.price,
    required this.qty,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      id: json['id'] as String?,
      orderId: json['order_id'] as String? ?? '',
      menuItemId: json['menu_item_id'] as String?,
      name: json['name'] as String? ?? 'Item',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel.fromJson(map);
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'order_id': orderId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
      'name': name,
      'price': price,
      'qty': qty,
    };
  }

  Map<String, dynamic> toInsertJson() {
    final bool isValidUuid = menuItemId != null &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(menuItemId!);

    return {
      'order_id': orderId,
      if (isValidUuid) 'menu_item_id': menuItemId,
      'name': name,
      'price': price,
      'qty': qty,
    };
  }
}

