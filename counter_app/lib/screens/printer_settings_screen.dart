import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import '../services/printer_service.dart';
import '../theme/app_theme.dart';

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
    final isConnected = _printerService.isConnected;
    final currentDevice = _printerService.selectedDevice;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Bluetooth Thermal Printer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textDark)),
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.cardBorder, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textDark),
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
                color: isConnected ? AppTheme.cashGreenLight : AppTheme.errorRedLight,
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
                      color: isConnected ? AppTheme.cashGreen : AppTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isConnected ? Icons.print : Icons.print_disabled,
                      color: Colors.white,
                      size: 22,
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
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isConnected ? AppTheme.cashGreen : AppTheme.errorRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected && currentDevice != null
                              ? '${currentDevice.name} (${currentDevice.address})'
                              : 'Select a paired ESC/POS thermal printer below',
                          style: TextStyle(
                            fontSize: 12,
                            color: isConnected ? AppTheme.cashGreen : AppTheme.errorRed,
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
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
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
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Column(
                children: [
                  RadioListTile<PaperSizeOption>(
                    activeColor: AppTheme.primaryBurgundy,
                    title: const Text('58mm Thermal Paper (2 Inch / 32 Columns)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Standard portable / handheld Bluetooth printers', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    value: PaperSizeOption.mm58,
                    groupValue: _printerService.paperSize,
                    onChanged: (val) async {
                      if (val != null) {
                        await _printerService.setPaperSize(val);
                        setState(() {});
                      }
                    },
                  ),
                  const Divider(height: 1, color: AppTheme.cardBorder),
                  RadioListTile<PaperSizeOption>(
                    activeColor: AppTheme.primaryBurgundy,
                    title: const Text('80mm Thermal Paper (3 Inch / 48 Columns)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Standard desktop restaurant counter POS printers', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
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
                  icon: const Icon(Icons.receipt, size: 18),
                  label: _isTesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                        )
                      : const Text('Print Test Receipt', style: TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBurgundy,
                    foregroundColor: Colors.white,
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
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                if (_isLoading)
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBurgundy)),
              ],
            ),
            const SizedBox(height: 8),

            if (_devices.isEmpty && !_isLoading)
              Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.bluetooth_searching, size: 36, color: AppTheme.textMuted),
                    SizedBox(height: 8),
                    Text('No paired Bluetooth printers found', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                    SizedBox(height: 4),
                    Text(
                      'Please pair your ESC/POS thermal printer in Android Bluetooth Settings first, then tap Refresh.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isThisConnected ? AppTheme.cashGreen : AppTheme.cardBorder,
                        width: isThisConnected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.print,
                        color: isThisConnected ? AppTheme.cashGreen : AppTheme.textSecondary,
                      ),
                      title: Text(
                        dev.name ?? 'Unknown Bluetooth Device',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark),
                      ),
                      subtitle: Text(
                        dev.address ?? 'No MAC Address',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                          backgroundColor: isThisConnected ? AppTheme.scaffoldBg : AppTheme.primaryBurgundy,
                          foregroundColor: isThisConnected ? AppTheme.textMuted : Colors.white,
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
