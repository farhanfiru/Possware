import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_printer.dart';
import '../models/order_model.dart';
import '../models/sales_summary.dart';
import '../config/supabase_config.dart';

export '../models/app_printer.dart';

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final PrinterManager _printerManager = PrinterManager.instance;

  List<AppPrinter> _printers = [];
  bool _isBtConnected = false;
  bool _isUsbConnected = false;
  String? _currentlyConnectedBtAddress;
  String? _currentlyConnectedUsbKey;

  List<AppPrinter> get printers => List.unmodifiable(_printers);
  List<AppPrinter> get enabledPrinters => _printers.where((p) => p.isEnabled).toList();

  bool get isConnected => _printers.any((p) => p.isEnabled);
  int get activePrinterCount => _printers.where((p) => p.isEnabled).length;

  bool get isBtConnected => _isBtConnected;
  bool get isUsbConnected => _isUsbConnected;

  // Legacy compatibility getters
  PrinterConnectionType get connectionType =>
      _printers.isNotEmpty ? _printers.first.type : PrinterConnectionType.bluetooth;
  PaperSizeOption get paperSize =>
      _printers.isNotEmpty ? _printers.first.paperSize : PaperSizeOption.mm58;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load multi-printer list
    final savedPrintersJson = prefs.getStringList('app_printers_list');
    if (savedPrintersJson != null && savedPrintersJson.isNotEmpty) {
      _printers = savedPrintersJson
          .map((item) {
            try {
              return AppPrinter.fromJson(jsonDecode(item) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<AppPrinter>()
          .toList();
    } else {
      // 2. Migration: Check if legacy single printer settings exist
      final savedType = prefs.getString('printer_connection_type');
      final savedBtAddress = prefs.getString('printer_address');
      final savedUsbVendor = prefs.getString('printer_usb_vendor');
      final savedUsbProduct = prefs.getString('printer_usb_product');
      final is80mm = prefs.getBool('printer_is_80mm') ?? false;

      if (savedType != null || savedBtAddress != null || savedUsbVendor != null) {
        final legacyPrinter = AppPrinter(
          name: 'Main Counter Printer',
          type: savedType == 'usb' ? PrinterConnectionType.usb : PrinterConnectionType.bluetooth,
          paperSize: is80mm ? PaperSizeOption.mm80 : PaperSizeOption.mm58,
          role: PrinterRole.all,
          btAddress: savedBtAddress,
          usbVendorId: savedUsbVendor,
          usbProductId: savedUsbProduct,
        );
        _printers = [legacyPrinter];
        await _savePrinters();
      }
    }

    // 3. Listen to Bluetooth hardware status changes
    _bluetooth.onStateChanged().listen((state) {
      final oldState = _isBtConnected;
      _isBtConnected = (state == BlueThermalPrinter.CONNECTED);
      if (oldState != _isBtConnected) {
        notifyListeners();
      }
    });

    // 4. Listen to USB hardware status changes
    _printerManager.stateUSB.listen((state) {
      final oldState = _isUsbConnected;
      _isUsbConnected = (state == USBStatus.connected);
      if (oldState != _isUsbConnected) {
        notifyListeners();
      }
    });

    await checkConnection();
  }

  Future<void> _savePrinters() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _printers.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('app_printers_list', jsonList);
    notifyListeners();
  }

  Future<void> addPrinter(AppPrinter printer) async {
    _printers.add(printer);
    await _savePrinters();
  }

  Future<void> updatePrinter(AppPrinter printer) async {
    final index = _printers.indexWhere((p) => p.id == printer.id);
    if (index != -1) {
      _printers[index] = printer;
      await _savePrinters();
    }
  }

  Future<void> removePrinter(String id) async {
    _printers.removeWhere((p) => p.id == id);
    await _savePrinters();
  }

  Future<void> togglePrinter(String id, bool isEnabled) async {
    final index = _printers.indexWhere((p) => p.id == id);
    if (index != -1) {
      _printers[index].isEnabled = isEnabled;
      await _savePrinters();
    }
  }

  Future<bool> checkConnection() async {
    try {
      final btConnected = await _bluetooth.isConnected ?? false;
      _isBtConnected = btConnected;
      notifyListeners();
      return isConnected;
    } catch (_) {
      return isConnected;
    }
  }

  // --- HARDWARE DISCOVERY METHODS ---

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      print('Error getting bluetooth devices: $e');
      return [];
    }
  }

  Future<List<PrinterDevice>> getUsbDevices() async {
    final List<PrinterDevice> devices = [];
    try {
      final stream = _printerManager.discovery(type: PrinterType.usb);
      await for (final dev in stream.timeout(const Duration(seconds: 2), onTimeout: (sink) => sink.close())) {
        if (!devices.any((d) => d.vendorId == dev.vendorId && d.productId == dev.productId)) {
          devices.add(dev);
        }
      }
    } catch (e) {
      print('Error discovering USB printers: $e');
    }
    return devices;
  }

  // --- LAN / ETHERNET PRINTING DRIVER ---

  /// Ping / Test connection to a LAN printer via raw TCP socket on port 9100
  Future<bool> testLanConnection(String ip, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip.trim(), port, timeout: const Duration(seconds: 3));
      await socket.close();
      return true;
    } catch (e) {
      print('LAN test connection failed ($ip:$port): $e');
      try {
        socket?.destroy();
      } catch (_) {}
      return false;
    }
  }

  /// Send ESC/POS raw bytes over raw TCP socket
  Future<bool> _printToLan(String ip, int port, List<int> bytes) async {
    Socket? socket;
    try {
      socket = await Socket.connect(ip.trim(), port, timeout: const Duration(seconds: 4));
      socket.add(bytes);
      await socket.flush();
      await Future.delayed(const Duration(milliseconds: 100));
      await socket.close();
      return true;
    } catch (e) {
      print('LAN print error ($ip:$port): $e');
      try {
        socket?.destroy();
      } catch (_) {}
      return false;
    }
  }

  // --- BLUETOOTH DRIVER HELPERS ---

  Future<bool> _ensureBluetoothConnected(String btAddress) async {
    try {
      final isNowConnected = await _bluetooth.isConnected ?? false;
      if (isNowConnected && _currentlyConnectedBtAddress == btAddress) {
        return true;
      }
      if (isNowConnected) {
        await _bluetooth.disconnect();
      }
      final devices = await getBondedDevices();
      final target = devices.firstWhere(
        (d) => d.address == btAddress,
        orElse: () => BluetoothDevice('', btAddress),
      );
      await _bluetooth.connect(target);
      _currentlyConnectedBtAddress = btAddress;
      _isBtConnected = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Failed connecting bluetooth printer ($btAddress): $e');
      return false;
    }
  }

  // --- USB DRIVER HELPERS ---

  Future<bool> _ensureUsbConnected(String vendorId, String productId) async {
    try {
      final currentKey = '$vendorId:$productId';
      if (_isUsbConnected && _currentlyConnectedUsbKey == currentKey) {
        return true;
      }
      if (_isUsbConnected) {
        await _printerManager.disconnect(type: PrinterType.usb);
      }
      final result = await _printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: 'USB Printer',
          vendorId: vendorId,
          productId: productId,
        ),
      );
      if (result) {
        _currentlyConnectedUsbKey = currentKey;
        _isUsbConnected = true;
        notifyListeners();
      }
      return result;
    } catch (e) {
      print('Failed connecting USB printer ($vendorId:$productId): $e');
      return false;
    }
  }

  // --- INDIVIDUAL PRINTER DISPATCH ---

  /// Send ESC/POS bytes to an individual printer based on its interface type
  Future<bool> printToPrinter(AppPrinter printer, List<int> bytes) async {
    if (!printer.isEnabled) return false;

    switch (printer.type) {
      case PrinterConnectionType.lan:
        if (printer.ipAddress == null || printer.ipAddress!.trim().isEmpty) {
          print('LAN printer has no IP configured: ${printer.name}');
          return false;
        }
        return await _printToLan(printer.ipAddress!, printer.port, bytes);

      case PrinterConnectionType.usb:
        if (printer.usbVendorId == null || printer.usbProductId == null) {
          print('USB printer missing vendor/product ID: ${printer.name}');
          return false;
        }
        final connected = await _ensureUsbConnected(printer.usbVendorId!, printer.usbProductId!);
        if (!connected) return false;
        return await _printerManager.send(type: PrinterType.usb, bytes: bytes);

      case PrinterConnectionType.bluetooth:
        if (printer.btAddress == null || printer.btAddress!.trim().isEmpty) {
          print('Bluetooth printer has no MAC address: ${printer.name}');
          return false;
        }
        final connected = await _ensureBluetoothConnected(printer.btAddress!);
        if (!connected) return false;
        try {
          await _bluetooth.writeBytes(Uint8List.fromList(bytes));
          return true;
        } catch (e) {
          print('Error sending raw bytes to BT printer: $e');
          return false;
        }
    }
  }

  // --- HIGH-LEVEL PRINTING WORKFLOWS ---

  /// Print customer receipt to all enabled printers assigned to `receipt` or `all`
  Future<bool> printReceipt(OrderModel order) async {
    final targets = _printers
        .where((p) => p.isEnabled && (p.role == PrinterRole.receipt || p.role == PrinterRole.all))
        .toList();

    if (targets.isEmpty) {
      print('No active receipt printers configured');
      return false;
    }

    bool anySuccess = false;
    for (final printer in targets) {
      final bytes = await generateReceiptBytes(order, printer.paperSize);
      final ok = await printToPrinter(printer, bytes);
      if (ok) anySuccess = true;
    }
    return anySuccess;
  }

  /// Print Kitchen Order Ticket (KOT) to all enabled printers assigned to `kitchen` or `all`
  Future<bool> printKitchenTicket(OrderModel order) async {
    final targets = _printers
        .where((p) => p.isEnabled && (p.role == PrinterRole.kitchen || p.role == PrinterRole.all))
        .toList();

    if (targets.isEmpty) {
      return false;
    }

    bool anySuccess = false;
    for (final printer in targets) {
      final bytes = await generateKitchenTicketBytes(order, printer.paperSize);
      final ok = await printToPrinter(printer, bytes);
      if (ok) anySuccess = true;
    }
    return anySuccess;
  }

  /// Print Day-End Z-Report / Daily Sales Summary to all enabled receipt printers
  Future<bool> printDailySalesSummary(DailySalesSummary summary) async {
    final targets = _printers
        .where((p) => p.isEnabled && (p.role == PrinterRole.receipt || p.role == PrinterRole.all))
        .toList();

    if (targets.isEmpty) return false;

    bool anySuccess = false;
    for (final printer in targets) {
      final bytes = await generateDailySummaryBytes(summary, printer.paperSize);
      final ok = await printToPrinter(printer, bytes);
      if (ok) anySuccess = true;
    }
    return anySuccess;
  }

  /// Print a single test receipt for a specific printer
  Future<bool> testPrinter(AppPrinter printer) async {
    final bytes = await generateTestReceiptBytes(printer);
    return await printToPrinter(printer, bytes);
  }

  /// Legacy test print (tests first enabled printer)
  Future<bool> printTestReceipt() async {
    if (_printers.isEmpty) return false;
    final printer = _printers.firstWhere((p) => p.isEnabled, orElse: () => _printers.first);
    return await testPrinter(printer);
  }

  // --- ESC/POS BYTE GENERATORS ---

  /// Generate customer receipt bytes matching printer paper size
  Future<List<int>> generateReceiptBytes(OrderModel order, PaperSizeOption sizeOption) async {
    final profile = await CapabilityProfile.load();
    final is80mm = sizeOption == PaperSizeOption.mm80;
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    final restaurantName = await SupabaseConfig.getRestaurantName();
    final restaurantAddress = await SupabaseConfig.getRestaurantAddress();
    final restaurantPhone = await SupabaseConfig.getRestaurantPhone();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt.toLocal());

    bytes += generator.text(
      restaurantName,
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    if (restaurantAddress.trim().isNotEmpty) {
      bytes += generator.text(
        restaurantAddress,
        styles: const PosStyles(align: PosAlign.center),
      );
    }
    if (restaurantPhone.trim().isNotEmpty) {
      bytes += generator.text(
        'Tel: $restaurantPhone',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.hr(ch: '=');
    bytes += generator.text(
      'TAX INVOICE / BILL',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr(ch: '-');

    if (order.invoiceNumber != null && order.invoiceNumber!.isNotEmpty) {
      bytes += generator.row([
        PosColumn(text: 'Invoice No:', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: order.invoiceNumber!, width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Date & Time:', width: 5),
      PosColumn(text: formattedDate, width: 7, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Payment Mode:', width: 6),
      PosColumn(text: order.paymentMethod.toUpperCase(), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.hr(ch: '-');

    // Header row
    if (is80mm) {
      bytes += generator.row([
        PosColumn(text: 'Item Name', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'Rate', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(text: 'Total', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    } else {
      bytes += generator.row([
        PosColumn(text: 'Item Name', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'Amt', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
    }

    bytes += generator.hr(ch: '-');

    // Items
    for (final item in order.items) {
      final itemTotal = (item.price * item.qty).toStringAsFixed(2);
      if (is80mm) {
        bytes += generator.row([
          PosColumn(text: item.name, width: 6),
          PosColumn(text: item.qty.toString(), width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: item.price.toStringAsFixed(2), width: 2, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: itemTotal, width: 2, styles: const PosStyles(align: PosAlign.right)),
        ]);
      } else {
        bytes += generator.row([
          PosColumn(text: item.name, width: 6),
          PosColumn(text: item.qty.toString(), width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: itemTotal, width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr(ch: '=');

    // Totals
    bytes += generator.row([
      PosColumn(text: 'TOTAL AMOUNT:', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size1)),
      PosColumn(
        text: 'Rs. ${order.total.toStringAsFixed(2)}',
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
      ),
    ]);

    if (order.paymentMethod == 'split') {
      bytes += generator.hr(ch: '-');
      bytes += generator.row([
        PosColumn(text: 'Cash Paid:', width: 6),
        PosColumn(text: 'Rs. ${order.cashAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: 'GPay/UPI Paid:', width: 6),
        PosColumn(text: 'Rs. ${order.gpayAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    if (order.notes != null && order.notes!.trim().isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('Notes: ${order.notes}', styles: const PosStyles(align: PosAlign.left));
    }

    bytes += generator.hr(ch: '=');
    bytes += generator.text('Thank you! Visit again.', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(4);
    bytes += generator.cut();

    return bytes;
  }

  /// Generate Kitchen Order Ticket (KOT) bytes focusing on items & notes
  Future<List<int>> generateKitchenTicketBytes(OrderModel order, PaperSizeOption sizeOption) async {
    final profile = await CapabilityProfile.load();
    final is80mm = sizeOption == PaperSizeOption.mm80;
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    final dateFormat = DateFormat('dd MMM, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt.toLocal());

    bytes += generator.text(
      '*** KITCHEN ORDER TICKET ***',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    bytes += generator.hr(ch: '=');

    if (order.invoiceNumber != null && order.invoiceNumber!.isNotEmpty) {
      bytes += generator.text(
        'TOKEN / BILL: ${order.invoiceNumber}',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ),
      );
    }

    bytes += generator.text('Time: $formattedDate', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '-');

    bytes += generator.row([
      PosColumn(text: 'ITEM', width: 8, styles: const PosStyles(bold: true, height: PosTextSize.size1)),
      PosColumn(text: 'QTY', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1)),
    ]);
    bytes += generator.hr(ch: '-');

    for (final item in order.items) {
      bytes += generator.row([
        PosColumn(
          text: item.name,
          width: 8,
          styles: const PosStyles(bold: true, height: PosTextSize.size1),
        ),
        PosColumn(
          text: 'x ${item.qty}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
        ),
      ]);
    }

    if (order.notes != null && order.notes!.trim().isNotEmpty) {
      bytes += generator.hr(ch: '-');
      bytes += generator.text('SPECIAL NOTES: ${order.notes}', styles: const PosStyles(bold: true));
    }

    bytes += generator.hr(ch: '=');
    bytes += generator.feed(4);
    bytes += generator.cut();

    return bytes;
  }

  /// Generate Day-End Z-Report / Daily Sales Summary bytes
  Future<List<int>> generateDailySummaryBytes(DailySalesSummary summary, PaperSizeOption sizeOption) async {
    final profile = await CapabilityProfile.load();
    final is80mm = sizeOption == PaperSizeOption.mm80;
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    final restaurantName = await SupabaseConfig.getRestaurantName();
    final dateFormat = DateFormat('dd MMM yyyy');
    final formattedDate = dateFormat.format(summary.date);

    bytes += generator.text(
      restaurantName,
      styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
    );
    bytes += generator.text('DAILY SALES SUMMARY (Z-REPORT)', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Date: $formattedDate', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '=');

    bytes += generator.row([
      PosColumn(text: 'Total Completed Orders:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: '${summary.totalOrders}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr(ch: '-');

    bytes += generator.row([
      PosColumn(text: 'CASH RECEIVED:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rs. ${summary.cashTotal.toStringAsFixed(2)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'GPAY (UPI) TOTAL:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rs. ${summary.gpayTotal.toStringAsFixed(2)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr(ch: '=');

    bytes += generator.row([
      PosColumn(text: 'GRAND TOTAL SALES:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rs. ${summary.totalSales.toStringAsFixed(2)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.hr(ch: '=');

    bytes += generator.feed(4);
    bytes += generator.cut();

    return bytes;
  }

  /// Generate Test Print bytes
  Future<List<int>> generateTestReceiptBytes(AppPrinter printer) async {
    final profile = await CapabilityProfile.load();
    final is80mm = printer.paperSize == PaperSizeOption.mm80;
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text(
      'TEST PRINT SUCCESSFUL',
      styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true),
    );
    bytes += generator.hr(ch: '=');
    bytes += generator.row([
      PosColumn(text: 'Printer Name:', width: 5, styles: const PosStyles(bold: true)),
      PosColumn(text: printer.name, width: 7, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Connection:', width: 5),
      PosColumn(text: printer.type.name.toUpperCase(), width: 7, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Target Details:', width: 5),
      PosColumn(text: printer.connectionSummary, width: 7, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Paper Size:', width: 6),
      PosColumn(text: is80mm ? '80mm (3 Inch)' : '58mm (2 Inch)', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Assigned Role:', width: 5),
      PosColumn(text: printer.role.name.toUpperCase(), width: 7, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');
    bytes += generator.text('POSWare Thermal Printing Ready!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(4);
    bytes += generator.cut();

    return bytes;
  }
}
