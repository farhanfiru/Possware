class DailySalesSummary {
  final DateTime date;
  final int totalOrders;
  final double totalSales;
  final double cashTotal;
  final double gpayTotal;
  final int cashOrders;
  final int gpayOrders;
  final int splitOrders;

  DailySalesSummary({
    required this.date,
    required this.totalOrders,
    required this.totalSales,
    required this.cashTotal,
    required this.gpayTotal,
    this.cashOrders = 0,
    this.gpayOrders = 0,
    this.splitOrders = 0,
  });

  factory DailySalesSummary.fromViewJson(Map<String, dynamic> json) {
    return DailySalesSummary(
      date: json['sale_date'] != null ? DateTime.parse(json['sale_date'].toString()) : DateTime.now(),
      totalOrders: (json['num_orders'] as num?)?.toInt() ?? 0,
      totalSales: (json['total_sales'] as num?)?.toDouble() ?? 0.0,
      cashTotal: (json['cash_total'] as num?)?.toDouble() ?? 0.0,
      gpayTotal: (json['gpay_total'] as num?)?.toDouble() ?? 0.0,
      cashOrders: (json['cash_orders'] as num?)?.toInt() ?? 0,
      gpayOrders: (json['gpay_orders'] as num?)?.toInt() ?? 0,
      splitOrders: (json['split_orders'] as num?)?.toInt() ?? 0,
    );
  }

  factory DailySalesSummary.empty([DateTime? date]) {
    return DailySalesSummary(
      date: date ?? DateTime.now(),
      totalOrders: 0,
      totalSales: 0.0,
      cashTotal: 0.0,
      gpayTotal: 0.0,
    );
  }
}
