import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../services/printer_service.dart';
import '../providers/billing_provider.dart';
import '../config/supabase_config.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothDevice> _devices = [];
  bool _isLoading = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    setState(() => _isLoading = true);

    // Request Android Bluetooth permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    final bonded = await _printerService.getBondedDevices();
    setState(() {
      _devices = bonded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final billing = context.watch<BillingProvider>();
    final isConnected = _printerService.isConnected;
    final currentDevice = _printerService.selectedDevice;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Bluetooth Thermal Printer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Devices',
            onPressed: _requestPermissionsAndScan,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isConnected ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected ? const Color(0xFFA7F3D0) : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isConnected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConnected ? Icons.print : Icons.print_disabled,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isConnected ? 'Printer Connected' : 'Printer Disconnected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isConnected ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected && currentDevice != null
                              ? '${currentDevice.name} (${currentDevice.address})'
                              : 'Select a paired ESC/POS thermal printer below',
                          style: TextStyle(
                            fontSize: 12,
                            color: isConnected ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isConnected)
                    OutlinedButton(
                      onPressed: () async {
                        await _printerService.disconnect();
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                      ),
                      child: const Text('Disconnect'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Paper Size Setting
            const Text(
              'Paper Width Settings',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  RadioListTile<PaperSizeOption>(
                    title: const Text('58mm Thermal Paper (2 Inch / 32 Columns)'),
                    subtitle: const Text('Standard portable / handheld Bluetooth printers'),
                    value: PaperSizeOption.mm58,
                    groupValue: _printerService.paperSize,
                    onChanged: (val) async {
                      if (val != null) {
                        await _printerService.setPaperSize(val);
                        setState(() {});
                      }
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<PaperSizeOption>(
                    title: const Text('80mm Thermal Paper (3 Inch / 48 Columns)'),
                    subtitle: const Text('Standard desktop restaurant counter POS printers'),
                    value: PaperSizeOption.mm80,
                    groupValue: _printerService.paperSize,
                    onChanged: (val) async {
                      if (val != null) {
                        await _printerService.setPaperSize(val);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Test Print Action
            if (isConnected) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isTesting ? null : _handleTestPrint,
                  icon: const Icon(Icons.receipt),
                  label: _isTesting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Print Test Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Paired Devices List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Paired Bluetooth Devices',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                if (_isLoading)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            const SizedBox(height: 8),

            if (_devices.isEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bluetooth_searching, size: 40, color: Colors.grey.shade400),
                    const SizedBox(height: 8),
                    const Text('No paired Bluetooth printers found.', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    const Text(
                      'Please pair your ESC/POS thermal printer in Android Bluetooth Settings first, then tap Refresh.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _devices.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final dev = _devices[index];
                  final isThisConnected = isConnected && currentDevice?.address == dev.address;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isThisConnected ? const Color(0xFF10B981) : Colors.grey.shade200,
                        width: isThisConnected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.print,
                        color: isThisConnected ? const Color(0xFF10B981) : Colors.grey.shade600,
                      ),
                      title: Text(
                        dev.name ?? 'Unknown Bluetooth Device',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        dev.address ?? 'No MAC Address',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      trailing: ElevatedButton(
                        onPressed: isThisConnected
                            ? null
                            : () async {
                                final success = await _printerService.connect(dev);
                                setState(() {});
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Connected to ${dev.name}')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Failed to connect to printer')),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isThisConnected ? Colors.grey.shade200 : const Color(0xFF0F172A),
                          foregroundColor: isThisConnected ? Colors.grey.shade600 : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text(isThisConnected ? 'Connected' : 'Connect'),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTestPrint() async {
    setState(() => _isTesting = true);
    final success = await _printerService.printTestReceipt();
    setState(() => _isTesting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test receipt printed successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to print test receipt. Check paper and connection.')),
      );
    }
  }
}
