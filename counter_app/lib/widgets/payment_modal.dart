import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';

class PaymentModal extends StatefulWidget {
  final Function(OrderModel) onSuccess;

  const PaymentModal({super.key, required this.onSuccess});

  @override
  State<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends State<PaymentModal> {
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final billing = context.read<BillingProvider>();
    _cashController.text = billing.grandTotal.toStringAsFixed(0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BillingProvider>().setCashTendered(billing.grandTotal);
      }
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySubtle,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.payments_outlined, color: AppTheme.primaryBurgundy, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Cash Payment',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount summary banner (Burgundy hero card matching dashboard)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.primaryBurgundy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'BILL AMOUNT',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '₹${billing.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cash Tender Input
            const Text(
              'Cash Received (₹)',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.textDark),
                filled: true,
                fillColor: AppTheme.scaffoldBg,
              ),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                billing.setCashTendered(parsed);
              },
            ),
            const SizedBox(height: 10),

            // Quick Cash Denomination Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildQuickNoteChip('Exact', billing.grandTotal, billing),
                _buildQuickNoteChip('₹100', 100, billing),
                _buildQuickNoteChip('₹200', 200, billing),
                _buildQuickNoteChip('₹500', 500, billing),
                _buildQuickNoteChip('₹2000', 2000, billing),
              ],
            ),
            const SizedBox(height: 14),

            // Change Due Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: billing.changeDue > 0 ? AppTheme.primarySubtle : AppTheme.scaffoldBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: billing.changeDue > 0 ? const Color(0xFFF0CCD0) : AppTheme.cardBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change to Return:',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: billing.changeDue > 0 ? AppTheme.primaryBurgundy : AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '₹${billing.changeDue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: billing.changeDue > 0 ? AppTheme.primaryBurgundy : AppTheme.textDark,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Order notes / Table number (Optional)',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: AppTheme.errorRed, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ],

            const SizedBox(height: 18),

            // Complete & Print Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _submitOrder(billing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBurgundy,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Save & Complete Bill (₹${billing.grandTotal.toStringAsFixed(2)})',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickNoteChip(String label, double amount, BillingProvider billing) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _cashController.text = amount.toStringAsFixed(0);
          billing.setCashTendered(amount);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.scaffoldBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder(BillingProvider billing) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final order = await billing.processCheckout(
        autoPrint: false,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (order != null) {
        widget.onSuccess(order);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to record order: $e';
        _isProcessing = false;
      });
    }
  }
}
