import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../models/sales_summary.dart';
import '../config/supabase_config.dart';

enum PaperSizeOption { mm58, mm80 }

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;
  BluetoothDevice? _selectedDevice;
  bool _isConnected = false;
  PaperSizeOption _paperSize = PaperSizeOption.mm58;

  BluetoothDevice? get selectedDevice => _selectedDevice;
  bool get isConnected => _isConnected;
  PaperSizeOption get paperSize => _paperSize;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('printer_address');
    final is80mm = prefs.getBool('printer_is_80mm') ?? false;
    _paperSize = is80mm ? PaperSizeOption.mm80 : PaperSizeOption.mm58;

    _bluetooth.onStateChanged().listen((state) {
      if (state == BlueThermalPrinter.CONNECTED) {
        _isConnected = true;
      } else {
        _isConnected = false;
      }
    });

    if (savedAddress != null) {
      final devices = await getBondedDevices();
      for (final dev in devices) {
        if (dev.address == savedAddress) {
          _selectedDevice = dev;
          await connect(dev);
          break;
        }
      }
    }
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final List<BluetoothDevice> devices = await _bluetooth.getBondedDevices();
      return devices;
    } catch (e) {
      print('Error getting bluetooth devices: $e');
      return [];
    }
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      if (_isConnected) {
        await _bluetooth.disconnect();
      }
      await _bluetooth.connect(device);
      _selectedDevice = device;
      _isConnected = true;

      final prefs = await SharedPreferences.getInstance();
      if (device.address != null) {
        await prefs.setString('printer_address', device.address!);
      }
      return true;
    } catch (e) {
      print('Failed to connect to printer: $e');
      _isConnected = false;
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
      _isConnected = false;
    } catch (e) {
      print('Disconnect error: $e');
    }
  }

  Future<void> setPaperSize(PaperSizeOption size) async {
    _paperSize = size;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('printer_is_80mm', size == PaperSizeOption.mm80);
  }

  /// Print a complete formatted receipt for an Order
  Future<bool> printReceipt(OrderModel order) async {
    if (!_isConnected) {
      print('Printer not connected');
      return false;
    }

    try {
      final restaurantName = await SupabaseConfig.getRestaurantName();
      final restaurantAddress = await SupabaseConfig.getRestaurantAddress();
      final restaurantPhone = await SupabaseConfig.getRestaurantPhone();
      final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
      final formattedDate = dateFormat.format(order.createdAt);
      final maxChars = _paperSize == PaperSizeOption.mm58 ? 32 : 48;

      // 1. Restaurant Header
      _bluetooth.printCustom(restaurantName, 3, 1); // Size 3 (Large), Center
      _bluetooth.printCustom(restaurantAddress, 0, 1); // Size 0 (Small), Center
      _bluetooth.printCustom('Ph: $restaurantPhone', 0, 1);
      _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);

      // 2. Order Metadata
      String paymentBadge = order.paymentMethod.toUpperCase();
      if (order.paymentMethod == 'split') {
        paymentBadge = 'SPLIT';
      } else if (order.paymentMethod == 'gpay') {
        paymentBadge = 'GPAY';
      } else {
        paymentBadge = 'CASH';
      }

      _bluetooth.printLeftRight(
        'Invoice: #${order.id.substring(0, 8).toUpperCase()}',
        paymentBadge,
        1,
      );
      _bluetooth.printCustom('Date: $formattedDate', 0, 0); // Left align
      _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

      // 3. Table Column Headers
      if (_paperSize == PaperSizeOption.mm58) {
        _bluetooth.printCustom('ITEM            QTY     TOTAL', 1, 0);
      } else {
        _bluetooth.printCustom('ITEM                          QTY    PRICE    TOTAL', 1, 0);
      }
      _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

      // 4. Item Rows
      for (final item in order.items) {
        final lineTotal = (item.price * item.qty).toStringAsFixed(2);
        final unitPrice = item.price.toStringAsFixed(2);

        if (_paperSize == PaperSizeOption.mm58) {
          String itemName = item.name;
          if (itemName.length > 30) {
            itemName = '${itemName.substring(0, 27)}...';
          }
          _bluetooth.printCustom(itemName, 0, 0);
          _bluetooth.printLeftRight('  ${item.qty} x Rs.$unitPrice', 'Rs.$lineTotal', 0);
        } else {
          String itemName = item.name;
          if (itemName.length > 26) {
            itemName = '${itemName.substring(0, 23)}...';
          }
          _bluetooth.printLeftRight(
            itemName.padRight(26) + '  ${item.qty}'.padRight(6) + ' Rs.$unitPrice'.padRight(10),
            'Rs.$lineTotal',
            0,
          );
        }
      }

      // 5. Totals & Payment Summary
      _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);
      _bluetooth.printLeftRight(
        'TOTAL AMOUNT:',
        'Rs. ${order.total.toStringAsFixed(2)}',
        2, // Bold / Medium
      );
      _bluetooth.printLeftRight(
        'Payment Mode:',
        paymentBadge,
        1,
      );
      _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);

      // 6. Footer & Cut Feed
      _bluetooth.printCustom('Thank you for dining with us!', 1, 1);
      _bluetooth.printCustom('Please visit again', 0, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();

      return true;
    } catch (e) {
      print('Error during receipt printing: $e');
      return false;
    }
  }

  /// Print a Day-End Summary / Z-Report for daily sales
  Future<bool> printDailySalesSummary(DailySalesSummary summary) async {
    if (!_isConnected) return false;

    try {
      final restaurantName = await SupabaseConfig.getRestaurantName();
      final dateFormat = DateFormat('dd MMMM yyyy');
      final timeFormat = DateFormat('hh:mm a');
      final maxChars = _paperSize == PaperSizeOption.mm58 ? 32 : 48;

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

      _bluetooth.printLeftRight('GRAND TOTAL SALES:', 'Rs. ${summary.totalSales.toStringAsFixed(2)}', 2);
      _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);

      _bluetooth.printCustom('Thank you, visit again!', 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();

      return true;
    } catch (e) {
      print('Print sales summary error: $e');
      return false;
    }
  }

  /// Print a quick test receipt
  Future<bool> printTestReceipt() async {
    if (!_isConnected) return false;

    final maxChars = _paperSize == PaperSizeOption.mm58 ? 32 : 48;
    try {
      _bluetooth.printCustom('TEST PRINT SUCCESSFUL', 2, 1);
      _bluetooth.printCustom(_getDivider(maxChars, '='), 0, 1);
      _bluetooth.printLeftRight('Printer Status:', 'ONLINE', 1);
      _bluetooth.printLeftRight('Paper Mode:', _paperSize == PaperSizeOption.mm58 ? '58mm (32 Col)' : '80mm (48 Col)', 0);
      _bluetooth.printCustom(_getDivider(maxChars, '-'), 0, 1);
      _bluetooth.printCustom('Neyco POS System Ready!', 1, 1);
      _bluetooth.printNewLine();
      _bluetooth.printNewLine();
      _bluetooth.paperCut();
      return true;
    } catch (e) {
      print('Test print error: $e');
      return false;
    }
  }

  String _getDivider(int length, String char) {
    return List.filled(length, char).join('');
  }
}
