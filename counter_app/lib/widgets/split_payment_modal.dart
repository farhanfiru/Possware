import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import '../models/order_model.dart';
import '../theme/app_theme.dart';

class SplitPaymentModal extends StatefulWidget {
  final Function(OrderModel) onSuccess;

  const SplitPaymentModal({super.key, required this.onSuccess});

  @override
  State<SplitPaymentModal> createState() => _SplitPaymentModalState();
}

class _SplitPaymentModalState extends State<SplitPaymentModal> {
  final TextEditingController _cashPortionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  double _cashPortion = 0.0;
  double _gpayPortion = 0.0;
  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final billing = context.read<BillingProvider>();
    final total = billing.grandTotal;

    // Default split: half & half rounded
    _cashPortion = (total / 2).roundToDouble();
    _gpayPortion = total - _cashPortion;
    _cashPortionController.text = _cashPortion.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _cashPortionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCashPortionChanged(String val, double total) {
    final parsed = double.tryParse(val) ?? 0.0;
    setState(() {
      _cashPortion = parsed > total ? total : parsed;
      _gpayPortion = total - _cashPortion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final total = billing.grandTotal;

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
                      child: const Icon(Icons.call_split_outlined, color: AppTheme.primaryBurgundy, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Split Payment',
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
                    'TOTAL BILL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
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

            // Split Breakdown Boxes (Cash Portion & GPay Portion)
            Row(
              children: [
                // Cash Portion Input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cashGreenLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.payments_outlined, size: 15, color: AppTheme.cashGreen),
                            SizedBox(width: 4),
                            Text(
                              'Cash Paid (₹)',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.cashGreen),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _cashPortionController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            fillColor: Colors.white,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark),
                          onChanged: (val) => _onCashPortionChanged(val, total),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // GPay Portion (Auto Calculated Remaining)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.gpayBlueLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code_2_outlined, size: 15, color: AppTheme.gpayBlue),
                            SizedBox(width: 4),
                            Text(
                              'GPay Balance',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.gpayBlue),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Text('₹ ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.gpayBlue)),
                              Text(
                                _gpayPortion.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.gpayBlue),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Order Notes
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Order notes / Table number (Optional)',
                hintStyle: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12, fontWeight: FontWeight.w700)),
            ],

            const SizedBox(height: 18),

            // Charge Split Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _submitSplitOrder(billing),
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
                          const Icon(Icons.print, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Charge Split (₹${_cashPortion.toStringAsFixed(0)} Cash + ₹${_gpayPortion.toStringAsFixed(0)} GPay)',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
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

  Future<void> _submitSplitOrder(BillingProvider billing) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      billing.setPaymentMethod('split');
      final order = await billing.processCheckout(
        autoPrint: true,
        cashAmount: _cashPortion,
        gpayAmount: _gpayPortion,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (order != null) {
        widget.onSuccess(order);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to record split order: $e';
        _isProcessing = false;
      });
    }
  }
}
