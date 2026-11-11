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
  String? _testingPrinterId;

  @override
  void initState() {
    super.initState();
    _printerService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _printerService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _handleTestPrint(AppPrinter printer) async {
    setState(() => _testingPrinterId = printer.id);
    final success = await _printerService.testPrinter(printer);
    if (!mounted) return;
    setState(() => _testingPrinterId = null);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Test print sent successfully to "${printer.name}"!'
              : 'Failed to print on "${printer.name}". Check connection.',
        ),
        backgroundColor: success ? AppTheme.cashGreen : AppTheme.primaryBurgundy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openPrinterDialog({AppPrinter? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddEditPrinterSheet(
        printerService: _printerService,
        existingPrinter: existing,
      ),
    );
  }

  Future<void> _confirmDelete(AppPrinter printer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Printer', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBurgundy),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _printerService.removePrinter(printer.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final printers = _printerService.printers;
    final activeCount = _printerService.activePrinterCount;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: const Text(
          'Restaurant Printers',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppTheme.textDark),
        ),
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppTheme.cardBorder, height: 1),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryBurgundy, size: 26),
            tooltip: 'Add Printer',
            onPressed: () => _openPrinterDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: activeCount > 0 ? AppTheme.cashGreen.withValues(alpha: 0.12) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.print,
                      color: activeCount > 0 ? AppTheme.cashGreen : AppTheme.textSecondary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeCount > 0 ? '$activeCount Active Printer${activeCount > 1 ? 's' : ''}' : 'No Active Printers',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Configure Bluetooth, USB, or LAN Ethernet printers for Counter & Kitchen.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openPrinterDialog(),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBurgundy,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Printers List
            if (printers.isEmpty)
              _buildEmptyState()
            else ...[
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'CONFIGURED PRINTERS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ...printers.map((printer) => _buildPrinterCard(printer)),
            ],

            const SizedBox(height: 24),

            // Instructions Note Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'LAN / Ethernet Cable Setup Tip',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF166534)),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Connect your printer with an RJ45 Ethernet cable to your Wi-Fi router. Ensure your tablet/phone is connected to the same Wi-Fi network and enter the printer\'s IP address (Port 9100).',
                          style: TextStyle(fontSize: 12, color: Color(0xFF15803D), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.primaryBurgundy.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.print_disabled_outlined, size: 42, color: AppTheme.primaryBurgundy),
          ),
          const SizedBox(height: 14),
          const Text(
            'No Printers Configured Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            'Add your billing counter printer or kitchen order ticket printer via Bluetooth, USB, or LAN cable.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openPrinterDialog(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Your First Printer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBurgundy,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrinterCard(AppPrinter printer) {
    final isTestingThis = _testingPrinterId == printer.id;

    Color badgeColor;
    IconData typeIcon;
    switch (printer.type) {
      case PrinterConnectionType.lan:
        badgeColor = const Color(0xFF0284C7);
        typeIcon = Icons.lan;
        break;
      case PrinterConnectionType.bluetooth:
        badgeColor = const Color(0xFF4F46E5);
        typeIcon = Icons.bluetooth;
        break;
      case PrinterConnectionType.usb:
        badgeColor = const Color(0xFFD97706);
        typeIcon = Icons.usb;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: printer.isEnabled ? AppTheme.cardBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Type Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(typeIcon, color: badgeColor, size: 24),
                ),
                const SizedBox(width: 12),

                // Name & Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              printer.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: printer.isEnabled ? AppTheme.textDark : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        printer.connectionSummary,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Badges
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          // Interface Badge
                          _buildChip(
                            printer.type.name.toUpperCase(),
                            badgeColor.withValues(alpha: 0.1),
                            badgeColor,
                          ),
                          // Paper Size
                          _buildChip(
                            printer.paperSize == PaperSizeOption.mm80 ? '80mm (3")' : '58mm (2")',
                            Colors.grey.shade100,
                            Colors.grey.shade700,
                          ),
                          // Role Badge
                          _buildChip(
                            printer.role == PrinterRole.receipt
                                ? 'Receipts'
                                : (printer.role == PrinterRole.kitchen ? 'Kitchen KOT' : 'Receipt + KOT'),
                            const Color(0xFFFEF3C7),
                            const Color(0xFFB45309),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Active Switch
                Switch(
                  value: printer.isEnabled,
                  activeColor: AppTheme.primaryBurgundy,
                  onChanged: (val) => _printerService.togglePrinter(printer.id, val),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),

          // Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              children: [
                // Test Print
                TextButton.icon(
                  onPressed: isTestingThis ? null : () => _handleTestPrint(printer),
                  icon: isTestingThis
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryBurgundy),
                        )
                      : const Icon(Icons.print_outlined, size: 17, color: AppTheme.textDark),
                  label: Text(
                    isTestingThis ? 'Printing...' : 'Test Print',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                  ),
                ),
                const Spacer(),

                // Edit
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                  tooltip: 'Edit Printer',
                  onPressed: () => _openPrinterDialog(existing: printer),
                ),

                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFDC2626)),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(printer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color bg, Color text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }
}

// -------------------------------------------------------------
// ADD / EDIT PRINTER MODAL SHEET
// -------------------------------------------------------------

class _AddEditPrinterSheet extends StatefulWidget {
  final PrinterService printerService;
  final AppPrinter? existingPrinter;

  const _AddEditPrinterSheet({
    required this.printerService,
    this.existingPrinter,
  });

  @override
  State<_AddEditPrinterSheet> createState() => _AddEditPrinterSheetState();
}

class _AddEditPrinterSheetState extends State<_AddEditPrinterSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipController;
  late TextEditingController _portController;

  late PrinterConnectionType _selectedType;
  late PaperSizeOption _selectedPaperSize;
  late PrinterRole _selectedRole;

  // Bluetooth & USB Discovery State
  List<BluetoothDevice> _btDevices = [];
  List<PrinterDevice> _usbDevices = [];
  BluetoothDevice? _selectedBtDevice;
  PrinterDevice? _selectedUsbDevice;

  bool _isScanning = false;
  bool _isTestingLan = false;
  bool? _lanTestSuccess;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPrinter;
    _nameController = TextEditingController(text: p?.name ?? 'Counter Printer');
    _ipController = TextEditingController(text: p?.ipAddress ?? '192.168.1.100');
    _portController = TextEditingController(text: (p?.port ?? 9100).toString());

    _selectedType = p?.type ?? PrinterConnectionType.bluetooth;
    _selectedPaperSize = p?.paperSize ?? PaperSizeOption.mm58;
    _selectedRole = p?.role ?? PrinterRole.receipt;

    _scanDevicesForType(_selectedType);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _scanDevicesForType(PrinterConnectionType type) async {
    setState(() => _isScanning = true);
    if (type == PrinterConnectionType.bluetooth) {
      await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();
      final bonded = await widget.printerService.getBondedDevices();
      if (mounted) {
        setState(() {
          _btDevices = bonded;
          if (widget.existingPrinter?.btAddress != null) {
            _selectedBtDevice = _btDevices.firstWhere(
              (d) => d.address == widget.existingPrinter!.btAddress,
              orElse: () => BluetoothDevice(widget.existingPrinter!.btDeviceName, widget.existingPrinter!.btAddress),
            );
          } else if (_btDevices.isNotEmpty) {
            _selectedBtDevice = _btDevices.first;
          }
          _isScanning = false;
        });
      }
    } else if (type == PrinterConnectionType.usb) {
      final usb = await widget.printerService.getUsbDevices();
      if (mounted) {
        setState(() {
          _usbDevices = usb;
          if (widget.existingPrinter?.usbVendorId != null) {
            _selectedUsbDevice = _usbDevices.firstWhere(
              (d) => d.vendorId == widget.existingPrinter!.usbVendorId,
              orElse: () => _usbDevices.isNotEmpty ? _usbDevices.first : PrinterDevice(name: 'USB Printer'),
            );
          } else if (_usbDevices.isNotEmpty) {
            _selectedUsbDevice = _usbDevices.first;
          }
          _isScanning = false;
        });
      }
    } else {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _testLanConnection() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;
    if (ip.isEmpty) return;

    setState(() {
      _isTestingLan = true;
      _lanTestSuccess = null;
    });

    final ok = await widget.printerService.testLanConnection(ip, port);
    if (!mounted) return;
    setState(() {
      _isTestingLan = false;
      _lanTestSuccess = ok;
    });
  }

  void _savePrinter() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final isEdit = widget.existingPrinter != null;

    final printer = AppPrinter(
      id: widget.existingPrinter?.id,
      name: name,
      type: _selectedType,
      paperSize: _selectedPaperSize,
      role: _selectedRole,
      isEnabled: widget.existingPrinter?.isEnabled ?? true,
      ipAddress: _selectedType == PrinterConnectionType.lan ? _ipController.text.trim() : null,
      port: _selectedType == PrinterConnectionType.lan ? (int.tryParse(_portController.text.trim()) ?? 9100) : 9100,
      btAddress: _selectedType == PrinterConnectionType.bluetooth ? _selectedBtDevice?.address : null,
      btDeviceName: _selectedType == PrinterConnectionType.bluetooth ? _selectedBtDevice?.name : null,
      usbVendorId: _selectedType == PrinterConnectionType.usb ? _selectedUsbDevice?.vendorId : null,
      usbProductId: _selectedType == PrinterConnectionType.usb ? _selectedUsbDevice?.productId : null,
      usbDeviceName: _selectedType == PrinterConnectionType.usb ? _selectedUsbDevice?.name : null,
    );

    if (isEdit) {
      await widget.printerService.updatePrinter(printer);
    } else {
      await widget.printerService.addPrinter(printer);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Header
              Row(
                children: [
                  Text(
                    widget.existingPrinter != null ? 'Edit Printer' : 'Add New Printer',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 1, thickness: 1),
              const SizedBox(height: 16),

              // 1. Printer Name
              const Text('PRINTER NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.6)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'e.g. Counter Cashier, Kitchen KOT, Bar',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppTheme.cardBorder)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a printer name' : null,
              ),

              // Name Suggestions
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Cash Counter', 'Kitchen KOT', 'Bar Printer', 'Order Token'].map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                    backgroundColor: Colors.grey.shade100,
                    padding: EdgeInsets.zero,
                    onPressed: () => setState(() => _nameController.text = suggestion),
                  );
                }).toList(),
              ),

              const SizedBox(height: 18),

              // 2. Connection Type Selector
              const Text('CONNECTION TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.6)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeTab(PrinterConnectionType.bluetooth, Icons.bluetooth, 'Bluetooth'),
                  const SizedBox(width: 8),
                  _buildTypeTab(PrinterConnectionType.usb, Icons.usb, 'USB Cable'),
                  const SizedBox(width: 8),
                  _buildTypeTab(PrinterConnectionType.lan, Icons.lan, 'LAN Cable'),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Dynamic Connection Configuration
              if (_selectedType == PrinterConnectionType.lan)
                _buildLanConfigSection()
              else if (_selectedType == PrinterConnectionType.bluetooth)
                _buildBluetoothConfigSection()
              else
                _buildUsbConfigSection(),

              const SizedBox(height: 18),

              // 4. Paper Size Selector
              const Text('PAPER SIZE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.6)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      title: '58 mm',
                      subtitle: '2-inch Compact roll',
                      isSelected: _selectedPaperSize == PaperSizeOption.mm58,
                      onTap: () => setState(() => _selectedPaperSize = PaperSizeOption.mm58),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildChoiceCard(
                      title: '80 mm',
                      subtitle: '3-inch Wide roll',
                      isSelected: _selectedPaperSize == PaperSizeOption.mm80,
                      onTap: () => setState(() => _selectedPaperSize = PaperSizeOption.mm80),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 5. Printer Role
              const Text('PRINT ROLE / TARGET', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.6)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Receipts',
                      subtitle: 'Customer bills',
                      isSelected: _selectedRole == PrinterRole.receipt,
                      onTap: () => setState(() => _selectedRole = PrinterRole.receipt),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Kitchen KOT',
                      subtitle: 'Chef order tokens',
                      isSelected: _selectedRole == PrinterRole.kitchen,
                      onTap: () => setState(() => _selectedRole = PrinterRole.kitchen),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildChoiceCard(
                      title: 'Both',
                      subtitle: 'Receipt & KOT',
                      isSelected: _selectedRole == PrinterRole.all,
                      onTap: () => setState(() => _selectedRole = PrinterRole.all),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _savePrinter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBurgundy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    widget.existingPrinter != null ? 'Update Printer' : 'Save Printer',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(PrinterConnectionType type, IconData icon, String label) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() => _selectedType = type);
          _scanDevicesForType(type);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryBurgundy : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBurgundy : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppTheme.textDark, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanConfigSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRINTER IP ADDRESS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _ipController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '192.168.1.100',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.cardBorder)),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Enter IP address' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PORT', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 5),
                    TextFormField(
                      controller: _portController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: '9100',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.cardBorder)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _isTestingLan ? null : _testLanConnection,
                icon: _isTestingLan
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.wifi_tethering, size: 16),
                label: Text(_isTestingLan ? 'Pinging...' : 'Test LAN Connection'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              if (_lanTestSuccess != null)
                Row(
                  children: [
                    Icon(
                      _lanTestSuccess! ? Icons.check_circle : Icons.error_outline,
                      color: _lanTestSuccess! ? AppTheme.cashGreen : AppTheme.primaryBurgundy,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _lanTestSuccess! ? 'Reachable' : 'Unreachable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _lanTestSuccess! ? AppTheme.cashGreen : AppTheme.primaryBurgundy,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBluetoothConfigSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('SELECT PAIRED BLUETOOTH PRINTER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const Spacer(),
              InkWell(
                onTap: _isScanning ? null : () => _scanDevicesForType(PrinterConnectionType.bluetooth),
                child: const Row(
                  children: [
                    Icon(Icons.refresh, size: 14, color: AppTheme.primaryBurgundy),
                    SizedBox(width: 3),
                    Text('Rescan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBurgundy)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isScanning)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_btDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No paired Bluetooth printers found. Please pair the thermal printer in Android Bluetooth Settings first.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            )
          else
            DropdownButtonFormField<BluetoothDevice>(
              value: _selectedBtDevice,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.cardBorder)),
              ),
              items: _btDevices.map((dev) {
                return DropdownMenuItem(
                  value: dev,
                  child: Text(
                    '${dev.name ?? "Thermal Printer"} (${dev.address ?? ""})',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (dev) => setState(() => _selectedBtDevice = dev),
            ),
        ],
      ),
    );
  }

  Widget _buildUsbConfigSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('SELECT CONNECTED USB PRINTER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
              const Spacer(),
              InkWell(
                onTap: _isScanning ? null : () => _scanDevicesForType(PrinterConnectionType.usb),
                child: const Row(
                  children: [
                    Icon(Icons.refresh, size: 14, color: AppTheme.primaryBurgundy),
                    SizedBox(width: 3),
                    Text('Rescan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBurgundy)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isScanning)
            const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
          else if (_usbDevices.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No USB thermal printer detected. Please connect your printer via USB OTG cable and turn it ON.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            )
          else
            DropdownButtonFormField<PrinterDevice>(
              value: _selectedUsbDevice,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.cardBorder)),
              ),
              items: _usbDevices.map((dev) {
                return DropdownMenuItem(
                  value: dev,
                  child: Text(
                    '${dev.name.isNotEmpty ? dev.name : "USB Printer"} (VID: ${dev.vendorId}, PID: ${dev.productId})',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (dev) => setState(() => _selectedUsbDevice = dev),
            ),
        ],
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBurgundy.withValues(alpha: 0.08) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBurgundy : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppTheme.primaryBurgundy : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.5,
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
