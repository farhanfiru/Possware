import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sales_summary.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import '../services/printer_service.dart';
import '../widgets/order_receipt_dialog.dart';

class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final PrinterService _printerService = PrinterService();

  DateTime _selectedDate = DateTime.now();
  DailySalesSummary? _summary;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.fetchDailyData(_selectedDate);
      if (!mounted) return;
      setState(() {
        _summary = data['summary'] as DailySalesSummary?;
        _orders = (data['orders'] as List<OrderModel>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      print('Load sales data error: $e');
      if (!mounted) return;
      setState(() {
        _summary = DailySalesSummary.empty(_selectedDate);
        _orders = [];
        _isLoading = false;
      });
    }
  }

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
    _loadSalesData();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null && (picked.year != _selectedDate.year || picked.month != _selectedDate.month || picked.day != _selectedDate.day)) {
      setState(() => _selectedDate = picked);
      _loadSalesData();
    }
  }

  Future<void> _handlePrintSummary() async {
    if (_summary == null) return;
    if (!_printerService.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer not connected. Please connect printer in settings.')),
      );
      return;
    }

    setState(() => _isPrinting = true);
    final success = await _printerService.printDailySalesSummary(_summary!);
    setState(() => _isPrinting = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Day summary printed successfully!' : 'Failed to print day summary.'),
          backgroundColor: success ? const Color(0xFF10B981) : Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, dd MMM yyyy');
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(DateTime.now());

    final totalSales = _summary?.totalSales ?? 0.0;
    final cashTotal = _summary?.cashTotal ?? 0.0;
    final gpayTotal = _summary?.gpayTotal ?? 0.0;
    final totalOrders = _summary?.totalOrders ?? 0;

    final cashPercent = totalSales > 0 ? (cashTotal / totalSales) : 0.5;
    final gpayPercent = totalSales > 0 ? (gpayTotal / totalSales) : 0.5;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Sales & Revenue Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadSalesData,
          ),
          IconButton(
            icon: _isPrinting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print),
            tooltip: 'Print Day Summary',
            onPressed: _handlePrintSummary,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadSalesData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_supabaseService.isInitialized) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Showing Offline Demo Data. To load live sales from Supabase, enter your Anon Key in Settings (PIN: 9599).',
                          style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Date Navigation Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _changeDate(-1),
                    ),
                    InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 18, color: Color(0xFF0F172A)),
                            const SizedBox(width: 8),
                            Text(
                              isToday ? 'Today (${dateFormat.format(_selectedDate)})' : dateFormat.format(_selectedDate),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: isToday ? null : () => _changeDate(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // 2. Primary KPI Banner: Grand Total Sales
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'TOTAL REVENUE',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 12),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF10B981)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.receipt_long, size: 14, color: Color(0xFF34D399)),
                                const SizedBox(width: 4),
                                Text(
                                  '$totalOrders Bills',
                                  style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${totalSales.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Visual ratio bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: SizedBox(
                          height: 8,
                          child: Row(
                            children: [
                              Expanded(
                                flex: (cashPercent * 100).toInt().clamp(1, 100),
                                child: Container(color: const Color(0xFF10B981)),
                              ),
                              Expanded(
                                flex: (gpayPercent * 100).toInt().clamp(1, 100),
                                child: Container(color: const Color(0xFF3B82F6)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Side-by-Side Breakdown Cards: Cash vs GPay
                Row(
                  children: [
                    // Cash Received Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFECFDF5),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.money, color: Color(0xFF059669), size: 20),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Cash Drawer',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF065F46)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₹${cashTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF065F46),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_summary?.cashOrders ?? 0} direct cash bills',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // GPay (UPI) Received Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.qr_code, color: Color(0xFF2563EB), size: 20),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'GPay (UPI)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1D4ED8)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₹${gpayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_summary?.gpayOrders ?? 0} online bills',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Print Day Summary Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _handlePrintSummary,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print Day Summary on Thermal Printer', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F172A),
                      side: const BorderSide(color: Color(0xFF0F172A), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 5. Orders History List for Selected Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bills for Selected Date',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      '${_orders.length} total',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_orders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 40, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        const Text('No bills recorded for this date.', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      final timeFormat = DateFormat('hh:mm a');

                      String badgeText = order.paymentMethod.toUpperCase();
                      Color badgeBg = const Color(0xFFECFDF5);
                      Color badgeFg = const Color(0xFF065F46);

                      if (order.paymentMethod == 'gpay') {
                        badgeText = 'GPAY';
                        badgeBg = const Color(0xFFEFF6FF);
                        badgeFg = const Color(0xFF1D4ED8);
                      } else if (order.paymentMethod == 'split') {
                        badgeText = 'SPLIT';
                        badgeBg = const Color(0xFFF5F3FF);
                        badgeFg = const Color(0xFF7C3AED);
                      }

                      return InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => OrderReceiptDialog(
                              order: order,
                              isViewingHistory: true,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bill #${order.id.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeFormat.format(order.createdAt),
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  badgeText,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeFg),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Text(
                                '₹${order.total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
