import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import '../theme/app_theme.dart';
import 'payment_modal.dart';
import 'split_payment_modal.dart';
import 'order_receipt_dialog.dart';

class CartPanel extends StatelessWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header: Deep Burgundy matching Owner Dashboard
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryBurgundy,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Current Bill',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${billing.totalItemCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                if (billing.cart.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _confirmClearCart(context, billing),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.white, size: 15),
                            SizedBox(width: 4),
                            Text(
                              'Clear',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: AppTheme.scaffoldBg,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 36,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Bill is empty',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap menu items to add to bill',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: billing.cart.length,
                    separatorBuilder: (_, __) => const Divider(color: AppTheme.cardBorder, height: 16),
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
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13.5,
                                    color: AppTheme.textDark,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${item.menuItem.price.toStringAsFixed(2)} each',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Stepper
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  color: AppTheme.errorRed,
                                  onPressed: () => billing.decrementQuantity(item.menuItem.id),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '${item.quantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      color: AppTheme.textDark,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                                  color: AppTheme.primaryBurgundy,
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
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),

          // Total & Checkout Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.scaffoldBg,
              border: Border(top: BorderSide(color: AppTheme.cardBorder)),
            ),
            child: Column(
              children: [
                // 3-Way Payment Method Selector (Cash / GPay / Split)
                Row(
                  children: [
                    Expanded(
                      child: _buildPaymentOption(
                        label: 'Cash',
                        icon: Icons.payments_outlined,
                        isSelected: billing.paymentMethod == 'cash',
                        activeColor: AppTheme.primaryBurgundy,
                        activeBg: AppTheme.primarySubtle,
                        onTap: () => billing.setPaymentMethod('cash'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPaymentOption(
                        label: 'GPay',
                        icon: Icons.qr_code_2_outlined,
                        isSelected: billing.paymentMethod == 'gpay',
                        activeColor: AppTheme.gpayBlue,
                        activeBg: AppTheme.gpayBlueLight,
                        onTap: () => billing.setPaymentMethod('gpay'),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildPaymentOption(
                        label: 'Split',
                        icon: Icons.call_split_outlined,
                        isSelected: billing.paymentMethod == 'split',
                        activeColor: AppTheme.primaryBurgundy,
                        activeBg: AppTheme.primarySubtle,
                        onTap: () => billing.setPaymentMethod('split'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Grand Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      '₹${billing.grandTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Primary Charge Action Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: billing.cart.isEmpty || billing.isProcessingOrder
                        ? null
                        : () => _handleChargeAction(context, billing),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: billing.paymentMethod == 'gpay'
                          ? AppTheme.gpayBlue
                          : AppTheme.primaryBurgundy,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: billing.isProcessingOrder
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                billing.paymentMethod == 'split'
                                    ? 'Charge Split (₹${billing.grandTotal.toStringAsFixed(2)})'
                                    : (billing.paymentMethod == 'gpay'
                                        ? 'Charge GPay ₹${billing.grandTotal.toStringAsFixed(2)}'
                                        : 'Charge Cash ₹${billing.grandTotal.toStringAsFixed(2)}'),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
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
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color activeBg,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? activeBg : AppTheme.surfaceWhite,
            border: Border.all(
              color: isSelected ? activeColor : AppTheme.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? activeColor : AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : AppTheme.textDark,
                ),
              ),
            ],
          ),
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
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
      try {
        final order = await billing.processCheckout(autoPrint: false);
        if (order != null && context.mounted) {
          showDialog(
            context: context,
            builder: (_) => OrderReceiptDialog(order: order),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error creating order: $e'), backgroundColor: AppTheme.errorRed),
          );
        }
      }
    } else if (billing.paymentMethod == 'split') {
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
