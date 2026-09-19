import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/printer_service.dart';
import '../theme/app_theme.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  final PrinterService _printerService = PrinterService();
  List<BluetoothDevice> _btDevices = [];
  List<PrinterDevice> _usbDevices = [];
  bool _isLoading = false;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _printerService.addListener(_onPrinterServiceUpdated);
    _refreshDevices();
  }

  @override
  void dispose() {
    _printerService.removeListener(_onPrinterServiceUpdated);
    super.dispose();
  }

  void _onPrinterServiceUpdated() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshDevices() async {
    setState(() => _isLoading = true);

    if (_printerService.connectionType == PrinterConnectionType.bluetooth) {
      // Request Android Bluetooth permissions
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final bonded = await _printerService.getBondedDevices();
      if (mounted) {
        setState(() {
          _btDevices = bonded;
          _isLoading = false;
        });
      }
    } else {
      // Discover USB devices
      final usb = await _printerService.getUsbDevices();
      if (mounted) {
        setState(() {
          _usbDevices = usb;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _printerService.isConnected;
    final isUsb = _printerService.connectionType == PrinterConnectionType.usb;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text('Thermal Printer Settings', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textDark)),
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
            tooltip: 'Scan Devices',
            onPressed: _refreshDevices,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Connection Mode Selector (Bluetooth vs USB Cable)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await _printerService.setConnectionType(PrinterConnectionType.bluetooth);
                        _refreshDevices();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !isUsb ? AppTheme.primaryBurgundy : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bluetooth, size: 18, color: !isUsb ? Colors.white : AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'Bluetooth Mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: !isUsb ? Colors.white : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        await _printerService.setConnectionType(PrinterConnectionType.usb);
                        _refreshDevices();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isUsb ? AppTheme.primaryBurgundy : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.usb, size: 18, color: isUsb ? Colors.white : AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              'USB Cable (OTG)',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: isUsb ? Colors.white : AppTheme.textSecondary,
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
            const SizedBox(height: 16),

            // 2. Status Card
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
                      isConnected ? (isUsb ? Icons.usb : Icons.print) : Icons.print_disabled,
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
                          isConnected ? 'Printer Connected (${!isUsb ? "Bluetooth" : "USB OTG"})' : 'No Printer Connected',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: isConnected ? AppTheme.cashGreen : AppTheme.errorRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isConnected
                              ? (!isUsb
                                  ? (_printerService.selectedBtDevice?.name ?? 'Bluetooth Thermal Printer')
                                  : (_printerService.selectedUsbDevice?.name ?? 'USB Thermal Printer'))
                              : (isUsb
                                  ? 'Plug in USB OTG cable and tap Connect below'
                                  : 'Select a paired Bluetooth printer below'),
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
                        if (isUsb) {
                          await _printerService.disconnectUsb();
                        } else {
                          await _printerService.disconnectBluetooth();
                        }
                        setState(() {});
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorRed,
                        side: const BorderSide(color: AppTheme.errorRed),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      child: const Text('Disconnect', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Paper Width Setting
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
                    title: const Text('80mm Thermal Paper (3 Inch / 42 Columns)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Standard desktop restaurant counter POS printers (Recommended)', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    value: PaperSizeOption.mm80,
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
                    title: const Text('58mm Thermal Paper (2 Inch / 32 Columns)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    subtitle: const Text('Small portable / handheld thermal printers', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    value: PaperSizeOption.mm58,
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

            // 4. Test Print Action
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
                      : Text('Print Test Receipt (${isUsb ? "USB" : "Bluetooth"})', style: const TextStyle(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBurgundy,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 5. Devices Section
            if (isUsb) ...[
              // USB Devices List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Connected USB Printers (OTG)',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  if (_isLoading)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBurgundy)),
                ],
              ),
              const SizedBox(height: 8),

              // USB OTG Info Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primarySubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFFC2410C), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Plug the printer into your phone with a USB-OTG adapter. When Android prompts for USB permission, tap Allow.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF9A3412), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              if (_usbDevices.isEmpty && !_isLoading)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.usb_off, size: 36, color: AppTheme.textMuted),
                      const SizedBox(height: 8),
                      const Text('No USB Printer Detected', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                      const SizedBox(height: 4),
                      const Text(
                        'Ensure your printer is turned ON and connected via USB-OTG cable, then tap Scan above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: _refreshDevices,
                        icon: const Icon(Icons.search, size: 16),
                        label: const Text('Scan USB Devices'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBurgundy,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _usbDevices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final dev = _usbDevices[index];
                    final isThisConnected = isConnected &&
                        _printerService.selectedUsbDevice?.vendorId == dev.vendorId &&
                        _printerService.selectedUsbDevice?.productId == dev.productId;

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
                          Icons.usb,
                          color: isThisConnected ? AppTheme.cashGreen : AppTheme.textSecondary,
                        ),
                        title: Text(
                          dev.name.isNotEmpty ? dev.name : 'USB Thermal Printer',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark),
                        ),
                        subtitle: Text(
                          'Vendor ID: ${dev.vendorId ?? "N/A"} | Product ID: ${dev.productId ?? "N/A"}',
                          style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                        ),
                        trailing: ElevatedButton(
                          onPressed: isThisConnected
                              ? null
                              : () async {
                                  final success = await _printerService.connectUsb(dev);
                                  setState(() {});
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Connected to ${dev.name.isNotEmpty ? dev.name : "USB Printer"}!')),
                                    );
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to connect to USB printer. Check permissions.')),
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
            ] else ...[
              // Bluetooth Devices List
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

              if (_btDevices.isEmpty && !_isLoading)
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
                        'Pair your ESC/POS thermal printer in Android Bluetooth Settings first, then tap Refresh.',
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
                  itemCount: _btDevices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final dev = _btDevices[index];
                    final isThisConnected = isConnected && _printerService.selectedBtDevice?.address == dev.address;

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
                                  final success = await _printerService.connectBluetooth(dev);
                                  setState(() {});
                                  if (success && context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Connected to ${dev.name}')),
                                    );
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Failed to connect to Bluetooth printer')),
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
          ],
        ),
      ),
    );
  }

  Future<void> _handleTestPrint() async {
    setState(() => _isTesting = true);
    final success = await _printerService.printTestReceipt();
    setState(() => _isTesting = false);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test receipt printed successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to print test receipt. Check cable/power and paper.')),
        );
      }
    }
  }
}

