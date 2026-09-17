import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/billing_provider.dart';
import '../services/printer_service.dart';

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
    Color badgeBg = const Color(0xFFDCFCE7);
    Color badgeFg = const Color(0xFF16A34A);

    if (order.paymentMethod == 'gpay') {
      paymentLabel = 'GPAY';
      badgeBg = const Color(0xFFDBEAFE);
      badgeFg = const Color(0xFF1D4ED8);
    } else if (order.paymentMethod == 'split') {
      paymentLabel = 'SPLIT';
      badgeBg = const Color(0xFFF3E8FF);
      badgeFg = const Color(0xFF7C3AED);
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isViewingHistory ? const Color(0xFFEFF6FF) : const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isViewingHistory ? Icons.receipt_long : Icons.check_circle,
                color: isViewingHistory ? const Color(0xFF2563EB) : const Color(0xFF16A34A),
                size: 36,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isViewingHistory ? 'Bill Details' : 'Order Completed!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            Text(
              'Bill #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),

            // Receipt Container Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date & Time:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(dateFormat.format(order.createdAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Payment Mode:', style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                            fontWeight: FontWeight.bold,
                            color: badgeFg,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  // Items list
                  ...order.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.qty}x ${item.name}',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        Text(
                          '₹${(item.price * item.qty).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        '₹${order.total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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
                    icon: const Icon(Icons.print, size: 18),
                    label: Text(isViewingHistory ? 'Print Bill' : 'Re-Print'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      isViewingHistory ? 'Close' : 'Next Bill',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
