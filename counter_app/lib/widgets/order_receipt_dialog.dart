import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/billing_provider.dart';
import '../services/printer_service.dart';
import '../theme/app_theme.dart';

class OrderReceiptDialog extends StatelessWidget {
  final OrderModel order;
  final bool isViewingHistory;

  const OrderReceiptDialog({
    super.key,
    required this.order,
    this.isViewingHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    String paymentLabel = order.paymentMethod.toUpperCase();
    Color badgeBg = AppTheme.cashGreenLight;
    Color badgeFg = AppTheme.cashGreen;

    if (order.paymentMethod == 'gpay') {
      paymentLabel = 'GPAY';
      badgeBg = AppTheme.gpayBlueLight;
      badgeFg = AppTheme.gpayBlue;
    } else if (order.paymentMethod == 'split') {
      paymentLabel = 'SPLIT';
      badgeBg = AppTheme.primarySubtle;
      badgeFg = AppTheme.primaryBurgundy;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppTheme.surfaceWhite,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Badge
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isViewingHistory ? AppTheme.gpayBlueLight : AppTheme.cashGreenLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isViewingHistory ? Icons.receipt_long : Icons.check_circle_rounded,
                color: isViewingHistory ? AppTheme.gpayBlue : AppTheme.cashGreen,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isViewingHistory ? 'Bill Details' : 'Order Completed!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bill #${order.displayInvoiceNumber}',
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Receipt Container Card
            Container(
              padding: const EdgeInsets.all(16),
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
                      Text(dateFormat.format(order.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
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
                  const Divider(color: AppTheme.cardBorder, height: 20),
                  // Items list
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.qty}x ${item.name}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.qty).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                        ),
                      ],
                    ),
                  )),
                  const Divider(color: AppTheme.cardBorder, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                      Text(
                        '₹${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      if (isViewingHistory) {
                        await PrinterService().printReceipt(order);
                      } else {
                        await billing.reprintLastBill();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Printing receipt...')),
                        );
                      }
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: Text(isViewingHistory ? 'Print Bill' : 'Re-Print'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppTheme.textDark,
                      side: const BorderSide(color: AppTheme.cardBorderHover),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isViewingHistory) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBurgundy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isViewingHistory ? 'Close' : 'Next Bill',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
}
