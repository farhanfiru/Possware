import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/printer_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class OrderReceiptDialog extends StatefulWidget {
  final OrderModel order;
  final bool isViewingHistory;
  final ValueChanged<OrderModel>? onOrderUpdated;

  const OrderReceiptDialog({
    super.key,
    required this.order,
    this.isViewingHistory = false,
    this.onOrderUpdated,
  });

  @override
  State<OrderReceiptDialog> createState() => _OrderReceiptDialogState();
}

class _OrderReceiptDialogState extends State<OrderReceiptDialog> {
  late OrderModel _currentOrder;
  bool _isPrinting = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    String paymentLabel = _currentOrder.paymentMethod.toUpperCase();
    Color badgeBg = AppTheme.cashGreenLight;
    Color badgeFg = AppTheme.cashGreen;

    if (_currentOrder.paymentMethod == 'gpay') {
      paymentLabel = 'GPAY';
      badgeBg = AppTheme.gpayBlueLight;
      badgeFg = AppTheme.gpayBlue;
    } else if (_currentOrder.paymentMethod == 'split') {
      paymentLabel = 'SPLIT';
      badgeBg = AppTheme.primarySubtle;
      badgeFg = AppTheme.primaryBurgundy;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surfaceWhite,
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Bar with Close X
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(width: 32), // Placeholder to center badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: widget.isViewingHistory ? AppTheme.gpayBlueLight : AppTheme.cashGreenLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.isViewingHistory ? Icons.receipt_long : Icons.check_circle_rounded,
                    color: widget.isViewingHistory ? AppTheme.gpayBlue : AppTheme.cashGreen,
                    size: 28,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(_currentOrder),
                  tooltip: 'Close',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              widget.isViewingHistory ? 'Bill Details' : 'Order Saved & Completed!',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Bill #${_currentOrder.displayInvoiceNumber}',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),

            // Receipt Container Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date & Time:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      Text(
                        dateFormat.format(_currentOrder.createdAt.toLocal()),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Mode:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              paymentLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: badgeFg,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Edit Payment Button
                          InkWell(
                            onTap: _showEditPaymentModal,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceWhite,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.primaryBurgundy.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.edit_outlined, size: 12, color: AppTheme.primaryBurgundy),
                                  SizedBox(width: 3),
                                  Text(
                                    'Edit',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.primaryBurgundy,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_currentOrder.paymentMethod == 'split') ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.money, size: 14, color: AppTheme.cashGreen),
                              const SizedBox(width: 4),
                              Text(
                                'Cash: ₹${_currentOrder.cashAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 12, color: AppTheme.cardBorder),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_2, size: 14, color: AppTheme.gpayBlue),
                              const SizedBox(width: 4),
                              Text(
                                'GPay: ₹${_currentOrder.gpayAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(color: AppTheme.cardBorder, height: 18),
                  // Items list
                  ..._currentOrder.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.qty}x ${item.name}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.qty).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  )),
                  const Divider(color: AppTheme.cardBorder, height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                      Text(
                        '₹${_currentOrder.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Action Buttons (Print Bill vs Close)
            Row(
              children: [
                // 1. Optional Print Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isPrinting ? null : _handlePrint,
                    icon: _isPrinting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.print, size: 17),
                    label: Text(
                      _isPrinting ? 'Printing...' : 'Print Bill',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBurgundy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // 2. Close / Next Bill Button (No Print)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(_currentOrder),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.cardBorderHover, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPaymentModal() {
    String selectedMethod = _currentOrder.paymentMethod;
    final total = _currentOrder.total;

    final cashController = TextEditingController(
      text: selectedMethod == 'cash'
          ? total.toStringAsFixed(2)
          : (selectedMethod == 'split' ? _currentOrder.cashAmount.toStringAsFixed(2) : '0.00'),
    );

    final gpayController = TextEditingController(
      text: selectedMethod == 'gpay'
          ? total.toStringAsFixed(2)
          : (selectedMethod == 'split' ? _currentOrder.gpayAmount.toStringAsFixed(2) : '0.00'),
    );

    bool isUpdating = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          double parsedCash = double.tryParse(cashController.text.trim()) ?? 0.0;
          double parsedGpay = double.tryParse(gpayController.text.trim()) ?? 0.0;
          double currentSum = parsedCash + parsedGpay;
          double diff = total - currentSum;
          bool isValidSplit = diff.abs() < 0.01;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: AppTheme.surfaceWhite,
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.payment, color: AppTheme.primaryBurgundy, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Payment Method',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                      ),
                      Text(
                        'Bill Total: ₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Select Payment Mode:',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 10),

                  // Option 1: Cash
                  _buildPaymentOptionTile(
                    title: 'Cash',
                    subtitle: 'Full ₹${total.toStringAsFixed(2)} in Cash',
                    icon: Icons.money,
                    color: AppTheme.cashGreen,
                    isSelected: selectedMethod == 'cash',
                    onTap: () {
                      setModalState(() {
                        selectedMethod = 'cash';
                        cashController.text = total.toStringAsFixed(2);
                        gpayController.text = '0.00';
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option 2: GPay / UPI
                  _buildPaymentOptionTile(
                    title: 'GPay / UPI',
                    subtitle: 'Full ₹${total.toStringAsFixed(2)} via UPI / QR',
                    icon: Icons.qr_code_2,
                    color: AppTheme.gpayBlue,
                    isSelected: selectedMethod == 'gpay',
                    onTap: () {
                      setModalState(() {
                        selectedMethod = 'gpay';
                        cashController.text = '0.00';
                        gpayController.text = total.toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  // Option 3: Split
                  _buildPaymentOptionTile(
                    title: 'Split Payment',
                    subtitle: 'Custom split between Cash and GPay',
                    icon: Icons.call_split,
                    color: AppTheme.primaryBurgundy,
                    isSelected: selectedMethod == 'split',
                    onTap: () {
                      setModalState(() {
                        selectedMethod = 'split';
                        if (cashController.text == '0.00' && gpayController.text == '0.00') {
                          final half = (total / 2).roundToDouble();
                          cashController.text = half.toStringAsFixed(2);
                          gpayController.text = (total - half).toStringAsFixed(2);
                        }
                      });
                    },
                  ),

                  // Split Inputs section
                  if (selectedMethod == 'split') ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.scaffoldBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Cash Input
                          Row(
                            children: [
                              const Icon(Icons.money, size: 16, color: AppTheme.cashGreen),
                              const SizedBox(width: 8),
                              const Text('Cash Amount (₹):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: cashController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    filled: true,
                                    fillColor: AppTheme.surfaceWhite,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    final entered = double.tryParse(val.trim()) ?? 0.0;
                                    if (entered <= total) {
                                      gpayController.text = (total - entered).toStringAsFixed(2);
                                    }
                                    setModalState(() {});
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // GPay Input
                          Row(
                            children: [
                              const Icon(Icons.qr_code_2, size: 16, color: AppTheme.gpayBlue),
                              const SizedBox(width: 8),
                              const Text('GPay Amount (₹):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: gpayController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    filled: true,
                                    fillColor: AppTheme.surfaceWhite,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  onChanged: (_) => setModalState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!isValidSplit)
                            Text(
                              diff > 0
                                  ? 'Remaining: ₹${diff.toStringAsFixed(2)} to allocate'
                                  : 'Over by: ₹${(-diff).toStringAsFixed(2)}',
                              style: const TextStyle(color: AppTheme.errorRed, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                onPressed: (isUpdating || (selectedMethod == 'split' && !isValidSplit))
                    ? null
                    : () async {
                        setModalState(() => isUpdating = true);

                        double finalCash = selectedMethod == 'cash' ? total : 0.0;
                        double finalGpay = selectedMethod == 'gpay' ? total : 0.0;
                        if (selectedMethod == 'split') {
                          finalCash = double.tryParse(cashController.text.trim()) ?? 0.0;
                          finalGpay = double.tryParse(gpayController.text.trim()) ?? 0.0;
                        }

                        final supabaseService = SupabaseService();
                        final success = await supabaseService.updateOrderPaymentMethod(
                          order: _currentOrder,
                          newPaymentMethod: selectedMethod,
                          newCashAmount: finalCash,
                          newGpayAmount: finalGpay,
                        );

                        final updatedOrder = _currentOrder.copyWith(
                          paymentMethod: selectedMethod,
                          cashAmount: finalCash,
                          gpayAmount: finalGpay,
                        );

                        if (mounted) {
                          setState(() {
                            _currentOrder = updatedOrder;
                          });
                          widget.onOrderUpdated?.call(updatedOrder);
                          Navigator.of(dialogCtx).pop();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? 'Payment method updated to ${selectedMethod.toUpperCase()} in Supabase!'
                                  : 'Payment updated locally (queued for cloud sync).'),
                              backgroundColor: AppTheme.cashGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBurgundy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Update Payment', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.cardBorder,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : AppTheme.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 20)
            else
              const Icon(Icons.circle_outlined, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePrint() async {
    setState(() => _isPrinting = true);
    final printerService = PrinterService();
    
    if (!printerService.isConnected) {
      setState(() => _isPrinting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Printer not connected. Please connect in Settings.'),
            backgroundColor: AppTheme.errorRed,
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    try {
      final success = await printerService.printReceipt(_currentOrder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Receipt printed successfully!' : 'Printing failed. Check printer.'),
            backgroundColor: success ? AppTheme.cashGreen : AppTheme.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Print error: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }
}
