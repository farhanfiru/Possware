import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import '../models/order_model.dart';

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
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
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
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'Split Payment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.call_split, color: Color(0xFF7C3AED), size: 22),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount summary banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Bill:', style: TextStyle(color: Colors.white70, fontSize: 15)),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Split Breakdown Boxes
            Row(
              children: [
                // Cash Portion Input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.money, size: 16, color: Color(0xFF059669)),
                            SizedBox(width: 4),
                            Text('Cash Given (₹)', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF065F46))),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.qr_code, size: 16, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text('Remaining on GPay', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Text('₹ ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text(
                                _gpayPortion.toStringAsFixed(2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1D4ED8)),
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
            const SizedBox(height: 16),

            // Order Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Order notes / Table number (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _submitSplitOrder(billing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED), // Purple for Split
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Charge Split (₹${_cashPortion.toStringAsFixed(0)} Cash + ₹${_gpayPortion.toStringAsFixed(0)} GPay)',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
