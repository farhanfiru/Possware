import 'package:flutter/foundation.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter_pos_printer_platform_image_3/flutter_pos_printer_platform_image_3.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../models/sales_summary.dart';
import '../config/supabase_config.dart';

enum PrinterConnectionType { bluetooth, usb }
enum PaperSizeOption { mm58, mm80 }

class PrinterService extends ChangeNotifier {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  final PrinterManager _printerManager = PrinterManager.instance;

  PrinterConnectionType _connectionType = PrinterConnectionType.bluetooth;
  BluetoothDevice? _selectedBtDevice;
  PrinterDevice? _selectedUsbDevice;

  bool _isBtConnected = false;
  bool _isUsbConnected = false;
  PaperSizeOption _paperSize = PaperSizeOption.mm58;

  PrinterConnectionType get connectionType => _connectionType;
  BluetoothDevice? get selectedBtDevice => _selectedBtDevice;
  PrinterDevice? get selectedUsbDevice => _selectedUsbDevice;

  bool get isConnected => _connectionType == PrinterConnectionType.usb ? _isUsbConnected : _isBtConnected;
  bool get isBtConnected => _isBtConnected;
  bool get isUsbConnected => _isUsbConnected;
  PaperSizeOption get paperSize => _paperSize;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedType = prefs.getString('printer_connection_type') ?? 'bluetooth';
    _connectionType = savedType == 'usb' ? PrinterConnectionType.usb : PrinterConnectionType.bluetooth;

    final savedBtAddress = prefs.getString('printer_address');
    final savedUsbVendor = prefs.getString('printer_usb_vendor');
    final savedUsbProduct = prefs.getString('printer_usb_product');
    final is80mm = prefs.getBool('printer_is_80mm') ?? false;
    _paperSize = is80mm ? PaperSizeOption.mm80 : PaperSizeOption.mm58;

    // Listen to Bluetooth state changes
    _bluetooth.onStateChanged().listen((state) {
      final oldState = _isBtConnected;
      _isBtConnected = (state == BlueThermalPrinter.CONNECTED);
      if (oldState != _isBtConnected) {
        notifyListeners();
      }
    });

    // Listen to USB state changes
    _printerManager.stateUSB.listen((state) {
      final oldState = _isUsbConnected;
      _isUsbConnected = (state == USBStatus.connected);
      if (oldState != _isUsbConnected) {
        notifyListeners();
      }
    });

    await checkConnection();

    // Auto-reconnect saved device
    if (_connectionType == PrinterConnectionType.bluetooth && savedBtAddress != null && !_isBtConnected) {
      final devices = await getBondedDevices();
      for (final dev in devices) {
        if (dev.address == savedBtAddress) {
          _selectedBtDevice = dev;
          await connectBluetooth(dev);
          break;
        }
      }
    } else if (_connectionType == PrinterConnectionType.usb && savedUsbVendor != null && !_isUsbConnected) {
      final usbDevices = await getUsbDevices();
      for (final dev in usbDevices) {
        if (dev.vendorId == savedUsbVendor && dev.productId == savedUsbProduct) {
          _selectedUsbDevice = dev;
          await connectUsb(dev);
          break;
        }
      }
    }
  }

  Future<bool> checkConnection() async {
    try {
      if (_connectionType == PrinterConnectionType.usb) {
        return _isUsbConnected;
      } else {
        final connected = await _bluetooth.isConnected ?? false;
        if (_isBtConnected != connected) {
          _isBtConnected = connected;
          notifyListeners();
        }
        return _isBtConnected;
      }
    } catch (_) {
      return isConnected;
    }
  }

  Future<void> setConnectionType(PrinterConnectionType type) async {
    _connectionType = type;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_connection_type', type == PrinterConnectionType.usb ? 'usb' : 'bluetooth');
  }

  Future<void> setPaperSize(PaperSizeOption size) async {
    _paperSize = size;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('printer_is_80mm', size == PaperSizeOption.mm80);
  }

  // --- BLUETOOTH METHODS ---

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      print('Error getting bluetooth devices: $e');
      return [];
    }
  }

  Future<bool> connectBluetooth(BluetoothDevice device) async {
    try {
      if (_isBtConnected) {
        await _bluetooth.disconnect();
      }
      await _bluetooth.connect(device);
      _selectedBtDevice = device;
      _isBtConnected = true;
      _connectionType = PrinterConnectionType.bluetooth;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_connection_type', 'bluetooth');
      if (device.address != null) {
        await prefs.setString('printer_address', device.address!);
      }
      return true;
    } catch (e) {
      print('Failed to connect bluetooth printer: $e');
      _isBtConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnectBluetooth() async {
    try {
      await _bluetooth.disconnect();
      _isBtConnected = false;
      notifyListeners();
    } catch (e) {
      print('Bluetooth disconnect error: $e');
    }
  }

  // --- USB OTG METHODS ---

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

  Future<bool> connectUsb(PrinterDevice device) async {
    try {
      if (_isUsbConnected) {
        await _printerManager.disconnect(type: PrinterType.usb);
      }

      final result = await _printerManager.connect(
        type: PrinterType.usb,
        model: UsbPrinterInput(
          name: device.name,
          vendorId: device.vendorId,
          productId: device.productId,
        ),
      );

      _selectedUsbDevice = device;
      _isUsbConnected = result;
      _connectionType = PrinterConnectionType.usb;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('printer_connection_type', 'usb');
      if (device.vendorId != null) await prefs.setString('printer_usb_vendor', device.vendorId!);
      if (device.productId != null) await prefs.setString('printer_usb_product', device.productId!);

      return result;
    } catch (e) {
      print('USB connect error: $e');
      _isUsbConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnectUsb() async {
    try {
      await _printerManager.disconnect(type: PrinterType.usb);
      _isUsbConnected = false;
      notifyListeners();
    } catch (e) {
      print('USB disconnect error: $e');
    }
  }

  // --- PRINTING ACTIONS (UNIFIED USB & BLUETOOTH) ---

  /// Print a formatted receipt for an Order
  Future<bool> printReceipt(OrderModel order) async {
    if (!isConnected) {
      print('Printer not connected');
      return false;
    }

    try {
      if (_connectionType == PrinterConnectionType.usb) {
        final bytes = await generateReceiptBytes(order);
        return await _printerManager.send(type: PrinterType.usb, bytes: bytes);
      } else {
        return await _printReceiptBluetooth(order);
      }
    } catch (e) {
      print('Error during receipt printing: $e');
      return false;
    }
  }

  /// Print Day-End Z-Report / Daily Sales Summary
  Future<bool> printDailySalesSummary(DailySalesSummary summary) async {
    if (!isConnected) return false;

    try {
      if (_connectionType == PrinterConnectionType.usb) {
        final bytes = await generateDailySummaryBytes(summary);
        return await _printerManager.send(type: PrinterType.usb, bytes: bytes);
      } else {
        return await _printDailySummaryBluetooth(summary);
      }
    } catch (e) {
      print('Print sales summary error: $e');
      return false;
    }
  }

  /// Print a quick test receipt
  Future<bool> printTestReceipt() async {
    if (!isConnected) return false;

    try {
      if (_connectionType == PrinterConnectionType.usb) {
        final bytes = await generateTestReceiptBytes();
        return await _printerManager.send(type: PrinterType.usb, bytes: bytes);
      } else {
        return await _printTestReceiptBluetooth();
      }
    } catch (e) {
      print('Test print error: $e');
      return false;
    }
  }

  // --- ESC/POS BYTE GENERATORS (FOR USB & DIRECT RAW STREAMING) ---

  Future<List<int>> generateReceiptBytes(OrderModel order) async {
    final profile = await CapabilityProfile.load();
    final is80mm = _paperSize == PaperSizeOption.mm80;
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    final restaurantName = await SupabaseConfig.getRestaurantName();
    final restaurantAddress = await SupabaseConfig.getRestaurantAddress();
    final restaurantPhone = await SupabaseConfig.getRestaurantPhone();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt.toLocal());

    // 1. Restaurant Header
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
      bytes += generator.text(restaurantAddress, styles: const PosStyles(align: PosAlign.center));
    }
    if (restaurantPhone.trim().isNotEmpty) {
      bytes += generator.text('Ph: $restaurantPhone', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr(ch: '=');

    // 2. Order Metadata
    String paymentBadge = order.paymentMethod.toUpperCase();
    if (order.paymentMethod == 'split') {
      paymentBadge = 'SPLIT';
    } else if (order.paymentMethod == 'gpay') {
      paymentBadge = 'GPAY';
    } else {
      paymentBadge = 'CASH';
    }

    bytes += generator.row([
      PosColumn(text: 'Invoice: #${order.displayInvoiceNumber}', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: paymentBadge, width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.text('Date: $formattedDate');
    bytes += generator.hr(ch: '-');

    // 3. Items Table
    if (is80mm) {
      bytes += generator.row([
        PosColumn(text: 'ITEM', width: 5, styles: const PosStyles(bold: true)),
        PosColumn(text: 'QTY', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'PRICE', width: 2, styles: const PosStyles(align: PosAlign.right, bold: true)),
        PosColumn(text: 'TOTAL', width: 3, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.hr(ch: '-');

      for (final item in order.items) {
        final lineTotal = (item.price * item.qty).toStringAsFixed(2);
        final unitPrice = item.price.toStringAsFixed(2);
        String name = item.name;
        if (name.length > 18) name = '${name.substring(0, 15)}...';

        bytes += generator.row([
          PosColumn(text: name, width: 5),
          PosColumn(text: '${item.qty}', width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: unitPrice, width: 2, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: lineTotal, width: 3, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    } else {
      bytes += generator.row([
        PosColumn(text: 'ITEM', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'QTY', width: 2, styles: const PosStyles(align: PosAlign.center, bold: true)),
        PosColumn(text: 'TOTAL', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]);
      bytes += generator.hr(ch: '-');

      for (final item in order.items) {
        final lineTotal = (item.price * item.qty).toStringAsFixed(2);
        final unitPrice = item.price.toStringAsFixed(2);
        String name = item.name;
        if (name.length > 20) name = '${name.substring(0, 17)}...';

        bytes += generator.text(name);
        bytes += generator.row([
          PosColumn(text: '  ${item.qty} x Rs.$unitPrice', width: 7),
          PosColumn(text: 'Rs.$lineTotal', width: 5, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    // 4. Totals
    bytes += generator.hr(ch: '=');
    bytes += generator.row([
      PosColumn(text: 'TOTAL AMOUNT:', width: 7, styles: const PosStyles(height: PosTextSize.size1, width: PosTextSize.size1, bold: true)),
      PosColumn(text: 'Rs. ${order.total.toStringAsFixed(2)}', width: 5, styles: const PosStyles(align: PosAlign.right, height: PosTextSize.size1, width: PosTextSize.size1, bold: true)),
    ]);

    if (order.paymentMethod == 'split') {
      bytes += generator.row([
        PosColumn(text: '  Cash Portion:', width: 6),
        PosColumn(text: 'Rs. ${order.cashAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
      bytes += generator.row([
        PosColumn(text: '  GPay Portion:', width: 6),
        PosColumn(text: 'Rs. ${order.gpayAmount.toStringAsFixed(2)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    } else {
      bytes += generator.row([
        PosColumn(text: 'Payment Mode:', width: 6),
        PosColumn(text: paymentBadge, width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.hr(ch: '-');

    // 5. Footer & Margin
    bytes += generator.text('Thank you for dining with us!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Please visit again', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(7);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> generateDailySummaryBytes(DailySalesSummary summary) async {
    final profile = await CapabilityProfile.load();
    final is80mm = _paperSize == PaperSizeOption.mm80;
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    final restaurantName = await SupabaseConfig.getRestaurantName();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('hh:mm a');

    bytes += generator.text(restaurantName, styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));
    bytes += generator.text('DAILY SALES SUMMARY REPORT', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Date: ${dateFormat.format(summary.date)}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Generated: ${timeFormat.format(DateTime.now())}', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '=');

    bytes += generator.row([
      PosColumn(text: 'Total Customers Today:', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(text: '${summary.totalOrders}', width: 4, styles: const PosStyles(align: PosAlign.right, bold: true)),
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

    bytes += generator.text('Thank you, visit again!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(7);
    bytes += generator.cut();

    return bytes;
  }

  Future<List<int>> generateTestReceiptBytes() async {
    final profile = await CapabilityProfile.load();
    final is80mm = _paperSize == PaperSizeOption.mm80;
    final generator = Generator(is80mm ? PaperSize.mm80 : PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text('TEST PRINT SUCCESSFUL', styles: const PosStyles(align: PosAlign.center, height: PosTextSize.size2, width: PosTextSize.size2, bold: true));
    bytes += generator.hr(ch: '=');
    bytes += generator.row([
      PosColumn(text: 'Printer Status:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'ONLINE (USB)', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Paper Mode:', width: 6),
      PosColumn(text: is80mm ? '80mm (3 Inch)' : '58mm (2 Inch)', width: 6, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');
    bytes += generator.text('Neyco POS System Ready!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(7);
    bytes += generator.cut();

    return bytes;
  }

  // --- BLUETOOTH PRINT IMPLEMENTATIONS ---

  Future<bool> _printReceiptBluetooth(OrderModel order) async {
    final restaurantName = await SupabaseConfig.getRestaurantName();
    final restaurantAddress = await SupabaseConfig.getRestaurantAddress();
    final restaurantPhone = await SupabaseConfig.getRestaurantPhone();
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(order.createdAt.toLocal());
    final is80mm = _paperSize == PaperSizeOption.mm80;
    final maxChars = is80mm ? 42 : 32;

    _bluetooth.printCustom(restaurantName, 2, 1);
    if (restaurantAddress.trim().isNotEmpty) {
      _bluetooth.printCustom(restaurantAddress, 0, 1);
    }
    if (restaurantPhone.trim().isNotEmpty) {
      _bluetooth.printCustom('Ph: $restaurantPhone', 0, 1);
    }
    _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);

    String paymentBadge = order.paymentMethod.toUpperCase();
    if (order.paymentMethod == 'split') {
      paymentBadge = 'SPLIT';
    } else if (order.paymentMethod == 'gpay') {
      paymentBadge = 'GPAY';
    } else {
      paymentBadge = 'CASH';
    }

    _bluetooth.printLeftRight(
      'Invoice: #${order.displayInvoiceNumber}',
      paymentBadge,
      0,
    );
    _bluetooth.printCustom('Date: $formattedDate', 0, 0);
    _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

    if (is80mm) {
      final headerItem = 'ITEM'.padRight(18);
      final headerQty = 'QTY'.padLeft(4);
      final headerPrice = 'PRICE'.padLeft(8);
      final headerTotal = 'TOTAL'.padLeft(9);
      _bluetooth.printCustom('$headerItem $headerQty $headerPrice $headerTotal', 0, 0);
      _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

      for (final item in order.items) {
        final lineTotal = (item.price * item.qty).toStringAsFixed(2);
        final unitPrice = item.price.toStringAsFixed(2);

        String itemName = item.name.trim();
        if (itemName.length > 18) {
          itemName = '${itemName.substring(0, 15)}...';
        }

        final colItem = itemName.padRight(18);
        final colQty = '${item.qty}'.padLeft(4);
        final colPrice = unitPrice.padLeft(8);
        final colTotal = lineTotal.padLeft(9);

        _bluetooth.printCustom('$colItem $colQty $colPrice $colTotal', 0, 0);
      }
    } else {
      _bluetooth.printCustom('ITEM            QTY     TOTAL', 0, 0);
      _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

      for (final item in order.items) {
        final lineTotal = (item.price * item.qty).toStringAsFixed(2);
        final unitPrice = item.price.toStringAsFixed(2);

        String itemName = item.name.trim();
        if (itemName.length > 28) {
          itemName = '${itemName.substring(0, 25)}...';
        }
        _bluetooth.printCustom(itemName, 0, 0);
        _bluetooth.printLeftRight('  ${item.qty} x Rs.$unitPrice', 'Rs.$lineTotal', 0);
      }
    }

    _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);
    _bluetooth.printLeftRight(
      'TOTAL AMOUNT:',
      'Rs. ${order.total.toStringAsFixed(2)}',
      1,
    );

    if (order.paymentMethod == 'split') {
      _bluetooth.printLeftRight('  Cash Amount:', 'Rs. ${order.cashAmount.toStringAsFixed(2)}', 0);
      _bluetooth.printLeftRight('  GPay Amount:', 'Rs. ${order.gpayAmount.toStringAsFixed(2)}', 0);
    } else {
      _bluetooth.printLeftRight(
        'Payment Mode:',
        paymentBadge,
        0,
      );
    }
    _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

    _bluetooth.printCustom('Thank you for dining with us!', 1, 1);
    _bluetooth.printCustom('Please visit again', 0, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();

    return true;
  }

  Future<bool> _printDailySummaryBluetooth(DailySalesSummary summary) async {
    final restaurantName = await SupabaseConfig.getRestaurantName();
    final dateFormat = DateFormat('dd MMMM yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final is80mm = _paperSize == PaperSizeOption.mm80;
    final maxChars = is80mm ? 42 : 32;

    _bluetooth.printCustom(restaurantName, 2, 1);
    _bluetooth.printCustom('DAILY SALES SUMMARY REPORT', 1, 1);
    _bluetooth.printCustom('Date: ${dateFormat.format(summary.date)}', 0, 1);
    _bluetooth.printCustom('Generated: ${timeFormat.format(DateTime.now())}', 0, 1);
    _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);

    _bluetooth.printLeftRight('Total Customers Today:', '${summary.totalOrders}', 1);
    _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

    _bluetooth.printLeftRight('CASH RECEIVED:', 'Rs. ${summary.cashTotal.toStringAsFixed(2)}', 1);
    _bluetooth.printLeftRight('GPAY (UPI) TOTAL:', 'Rs. ${summary.gpayTotal.toStringAsFixed(2)}', 1);
    _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);

    _bluetooth.printLeftRight('GRAND TOTAL SALES:', 'Rs. ${summary.totalSales.toStringAsFixed(2)}', 1);
    _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);

    _bluetooth.printCustom('Thank you, visit again!', 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();

    return true;
  }

  Future<bool> _printTestReceiptBluetooth() async {
    final is80mm = _paperSize == PaperSizeOption.mm80;
    final maxChars = is80mm ? 42 : 32;
    _bluetooth.printCustom('TEST PRINT SUCCESSFUL', 2, 1);
    _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);
    _bluetooth.printLeftRight('Printer Status:', 'ONLINE (BT)', 1);
    _bluetooth.printLeftRight('Paper Mode:', is80mm ? '80mm (42 Col)' : '58mm (32 Col)', 0);
    _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);
    _bluetooth.printCustom('Neyco POS System Ready!', 1, 1);
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.printNewLine();
    _bluetooth.paperCut();
    return true;
  }

  String _getDivider(int length, String char) {
    return List.filled(length, char).join('');
  }
}

