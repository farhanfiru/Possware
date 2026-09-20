import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import '../services/printer_service.dart';
import '../theme/app_theme.dart';

class OrderReceiptDialog extends StatefulWidget {
  final OrderModel order;
  final bool isViewingHistory;

  const OrderReceiptDialog({
    super.key,
    required this.order,
    this.isViewingHistory = false,
  });

  @override
  State<OrderReceiptDialog> createState() => _OrderReceiptDialogState();
}

class _OrderReceiptDialogState extends State<OrderReceiptDialog> {
  bool _isPrinting = false;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    String paymentLabel = widget.order.paymentMethod.toUpperCase();
    Color badgeBg = AppTheme.cashGreenLight;
    Color badgeFg = AppTheme.cashGreen;

    if (widget.order.paymentMethod == 'gpay') {
      paymentLabel = 'GPAY';
      badgeBg = AppTheme.gpayBlueLight;
      badgeFg = AppTheme.gpayBlue;
    } else if (widget.order.paymentMethod == 'split') {
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
                  onPressed: () => Navigator.of(context).pop(),
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
              'Bill #${widget.order.displayInvoiceNumber}',
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
                      Text(dateFormat.format(widget.order.createdAt.toLocal()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Mode:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                    ],
                  ),
                  const Divider(color: AppTheme.cardBorder, height: 18),
                  // Items list
                  ...widget.order.items.map((item) => Padding(
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
                        '₹${widget.order.total.toStringAsFixed(2)}',
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
                    onPressed: () => Navigator.of(context).pop(),
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
      final success = await printerService.printReceipt(widget.order);
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
