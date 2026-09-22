import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/sales_summary.dart';
import '../models/order_model.dart';
import '../services/supabase_service.dart';
import '../services/printer_service.dart';
import '../widgets/order_receipt_dialog.dart';
import '../theme/app_theme.dart';

class DailySalesScreen extends StatefulWidget {
  const DailySalesScreen({super.key});

  @override
  State<DailySalesScreen> createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final PrinterService _printerService = PrinterService();

  static DateTime _getBusinessToday() {
    final shifted = DateTime.now().subtract(const Duration(hours: 3));
    return DateTime(shifted.year, shifted.month, shifted.day);
  }

  late DateTime _selectedDate;
  DailySalesSummary? _summary;
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = _getBusinessToday();
    _loadSalesData();
  }

  Future<void> _loadSalesData() async {
    setState(() => _isLoading = true);
    try {
      // Attempt background sync of any pending offline orders
      try {
        await _supabaseService.syncOfflineOrders();
      } catch (_) {}

      final data = await _supabaseService.fetchDailyData(_selectedDate);
      if (!mounted) return;
      setState(() {
        _summary = data['summary'] as DailySalesSummary?;
        _orders = (data['orders'] as List<OrderModel>?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
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
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day + offsetDays);
    });
    _loadSalesData();
  }

  Future<void> _pickDate() async {
    final businessToday = _getBusinessToday();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: businessToday.add(const Duration(days: 1)),
    );
    if (picked != null && (picked.year != _selectedDate.year || picked.month != _selectedDate.month || picked.day != _selectedDate.day)) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
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
          backgroundColor: success ? AppTheme.cashGreen : AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    final businessToday = DateTime.now().subtract(const Duration(hours: 3));
    final isToday = DateFormat('yyyy-MM-dd').format(_selectedDate) == DateFormat('yyyy-MM-dd').format(businessToday);

    final totalSales = _summary?.totalSales ?? 0.0;
    final cashTotal = _summary?.cashTotal ?? 0.0;
    final gpayTotal = _summary?.gpayTotal ?? 0.0;
    final totalOrders = _summary?.totalOrders ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Daily Sales & Revenue',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textDark, letterSpacing: -0.3),
        ),
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.cardBorder, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textDark),
            tooltip: 'Refresh',
            onPressed: _loadSalesData,
          ),
          IconButton(
            icon: _isPrinting
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBurgundy))
                : const Icon(Icons.print, color: AppTheme.textDark),
            tooltip: 'Print Day Summary',
            onPressed: _handlePrintSummary,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryBurgundy,
        onRefresh: _loadSalesData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Navigation Selector (Overflow-safe on all screens)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: AppTheme.textDark),
                      onPressed: () => _changeDate(-1),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today, size: 15, color: AppTheme.primaryBurgundy),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  isToday ? 'Today, ${DateFormat('d MMM yyyy').format(_selectedDate)}' : dateFormat.format(_selectedDate),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: AppTheme.textDark),
                      onPressed: isToday ? null : () => _changeDate(1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: AppTheme.primaryBurgundy),
                  ),
                )
              else ...[
                // 1. Burgundy Hero Card (Exact Match to Owner Dashboard)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBurgundy,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBurgundy.withOpacity(0.25),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isToday ? "TODAY'S COLLECTION" : "COLLECTION FOR ${DateFormat('d MMMM yyyy').format(_selectedDate).toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          fontSize: 11.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '₹${totalSales.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sub-stats: Bills, Cash, GPay
                      Row(
                        children: [
                          _buildCollectionSubStat('Bills', '$totalOrders'),
                          const SizedBox(width: 24),
                          _buildCollectionSubStat('Cash', '₹${cashTotal.toStringAsFixed(0)}'),
                          const SizedBox(width: 24),
                          _buildCollectionSubStat('GPay', '₹${gpayTotal.toStringAsFixed(0)}'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Breakdown Cards: Cash vs GPay
                Row(
                  children: [
                    // Cash Received Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cashGreenLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.payments_outlined, color: AppTheme.cashGreen, size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Cash Drawer',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.cashGreen),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '₹${cashTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_summary?.cashOrders ?? 0} direct cash bills',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // GPay (UPI) Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceWhite,
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
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.gpayBlueLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.qr_code_2_outlined, color: AppTheme.gpayBlue, size: 18),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'GPay (UPI)',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.gpayBlue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '₹${gpayTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.textDark,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_summary?.gpayOrders ?? 0} online bills',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Print Day Summary Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _handlePrintSummary,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print Day Summary on Thermal Printer', style: TextStyle(fontWeight: FontWeight.w700)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryBurgundy,
                      side: const BorderSide(color: AppTheme.primaryBurgundy, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Orders History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bills for Selected Date',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark, letterSpacing: -0.2),
                    ),
                    Text(
                      '${_orders.length} total',
                      style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                if (_orders.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.receipt_long_outlined, size: 36, color: AppTheme.textMuted),
                        const SizedBox(height: 8),
                        const Text(
                          'No bills recorded for this date',
                          style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13.5),
                        ),
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
                      Color badgeBg = AppTheme.cashGreenLight;
                      Color badgeFg = AppTheme.cashGreen;

                      if (order.paymentMethod == 'gpay') {
                        badgeText = 'GPAY';
                        badgeBg = AppTheme.gpayBlueLight;
                        badgeFg = AppTheme.gpayBlue;
                      } else if (order.paymentMethod == 'split') {
                        badgeText = 'SPLIT';
                        badgeBg = AppTheme.primarySubtle;
                        badgeFg = AppTheme.primaryBurgundy;
                      }

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            final updated = await showDialog<OrderModel>(
                              context: context,
                              builder: (_) => OrderReceiptDialog(
                                order: order,
                                isViewingHistory: true,
                                onOrderUpdated: (_) {
                                  _loadSalesData();
                                },
                              ),
                            );
                            if (updated != null) {
                              _loadSalesData();
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceWhite,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.cardBorder),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.015), blurRadius: 6, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bill #${order.displayInvoiceNumber}',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppTheme.textDark),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      timeFormat.format(order.createdAt.toLocal()),
                                      style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
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
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: badgeFg),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  '₹${order.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 15.5,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_right, size: 18, color: AppTheme.textMuted),
                              ],
                            ),
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

  Widget _buildCollectionSubStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
