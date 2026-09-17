import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import 'payment_modal.dart';
import 'split_payment_modal.dart';
import 'order_receipt_dialog.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 22),
                    const SizedBox(width: 8),
                    const Text(
                      'Current Bill',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${billing.totalItemCount} items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (billing.cart.isNotEmpty)
                  InkWell(
                    onTap: () => _confirmClearCart(context, billing),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: billing.cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'No items added yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap menu items on the left to build the bill',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: billing.cart.length,
                    separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 16),
                    itemBuilder: (context, index) {
                      final item = billing.cart[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.menuItem.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${item.menuItem.price.toStringAsFixed(2)} each',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () => billing.decrementQuantity(item.menuItem.id),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  onPressed: () => billing.incrementQuantity(item.menuItem.id),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 65,
                            child: Text(
                              '₹${item.lineTotal.toStringAsFixed(2)}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Total & Checkout
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                // 3-Way Payment Method Selector (Cash / GPay / Split)
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentOption(
                        context: context,
                        label: 'Cash',
                        icon: Icons.money,
                        isSelected: billing.paymentMethod == 'cash',
                        onTap: () => billing.setPaymentMethod('cash'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPaymentOption(
                        context: context,
                        label: 'GPay',
                        icon: Icons.payment,
                        isSelected: billing.paymentMethod == 'gpay',
                        onTap: () => billing.setPaymentMethod('gpay'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPaymentOption(
                        context: context,
                        label: 'Split',
                        icon: Icons.call_split,
                        isSelected: billing.paymentMethod == 'split',
                        onTap: () => billing.setPaymentMethod('split'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Grand Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    Text(
                      '₹${billing.grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Charge Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: billing.cart.isEmpty || billing.isProcessingOrder
                        ? null
                        : () => _handleChargeAction(context, billing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: billing.paymentMethod == 'gpay'
                          ? const Color(0xFF2563EB) // Blue for GPay
                          : (billing.paymentMethod == 'split'
                              ? const Color(0xFF7C3AED) // Purple for Split
                              : const Color(0xFF059669)), // Green for Cash
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: billing.isProcessingOrder
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.print, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                billing.paymentMethod == 'split'
                                    ? 'Split & Print (₹${billing.grandTotal.toStringAsFixed(2)})'
                                    : (billing.paymentMethod == 'gpay'
                                        ? 'Charge GPay ₹${billing.grandTotal.toStringAsFixed(2)} & Print'
                                        : 'Charge Cash ₹${billing.grandTotal.toStringAsFixed(2)} & Print'),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor.withOpacity(0.12) : Colors.white,
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? theme.primaryColor : Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? theme.primaryColor : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCart(BuildContext context, BillingProvider billing) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Current Bill?'),
        content: const Text('This will remove all items from the current cart.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              billing.clearCart();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleChargeAction(BuildContext context, BillingProvider billing) async {
    if (billing.paymentMethod == 'gpay') {
      // 1-Tap Direct Checkout for GPay
      try {
        final order = await billing.processCheckout(autoPrint: true);
        if (order != null && context.mounted) {
          showDialog(
            context: context,
            builder: (_) => OrderReceiptDialog(order: order),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating order: $e'), backgroundColor: Colors.redAccent),
          );
        }
      }
    } else if (billing.paymentMethod == 'split') {
      // Split payment -> Open Split sheet
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => SplitPaymentModal(
          onSuccess: (order) {
            Navigator.pop(ctx);
            showDialog(
              context: context,
              builder: (_) => OrderReceiptDialog(order: order),
            );
          },
        ),
      );
    } else {
      // Cash payment -> Open Cash tender modal
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => PaymentModal(
          onSuccess: (order) {
            Navigator.pop(ctx);
            showDialog(
              context: context,
              builder: (_) => OrderReceiptDialog(order: order),
            );
          },
        ),
      );
    }
  }
}
