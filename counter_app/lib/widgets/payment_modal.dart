import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/billing_provider.dart';
import '../models/order_model.dart';

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
                      'Cash Payment',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    SizedBox(width: 10),
                    Icon(Icons.payments, color: Color(0xFF059669), size: 22),
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
                  const Text(
                    'Bill Amount',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  Text(
                    '₹${billing.grandTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Cash Tender Input
            const Text(
              'Cash Received (₹)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _cashController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              onChanged: (val) {
                final parsed = double.tryParse(val) ?? 0.0;
                billing.setCashTendered(parsed);
              },
            ),
            const SizedBox(height: 10),

            // Quick Note Buttons
            Wrap(
              spacing: 8,
              children: [
                _buildQuickNoteBtn('Exact', billing.grandTotal, billing),
                _buildQuickNoteBtn('₹100', 100, billing),
                _buildQuickNoteBtn('₹200', 200, billing),
                _buildQuickNoteBtn('₹500', 500, billing),
                _buildQuickNoteBtn('₹2000', 2000, billing),
              ],
            ),
            const SizedBox(height: 16),

            // Change Due Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: billing.changeDue > 0 ? Colors.green.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: billing.changeDue > 0 ? Colors.green.shade200 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Change to Return:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: billing.changeDue > 0 ? Colors.green.shade900 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    '₹${billing.changeDue.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: billing.changeDue > 0 ? Colors.green.shade800 : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Order notes / Table number (Optional)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : () => _submitOrder(billing),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 3,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Complete & Print Receipt (₹${billing.grandTotal.toStringAsFixed(2)})',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildQuickNoteBtn(String label, double amount, BillingProvider billing) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.grey.shade100,
      onPressed: () {
        _cashController.text = amount.toStringAsFixed(0);
        billing.setCashTendered(amount);
      },
    );
  }

  Future<void> _submitOrder(BillingProvider billing) async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final order = await billing.processCheckout(
        autoPrint: true,
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
