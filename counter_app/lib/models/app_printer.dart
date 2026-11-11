import 'package:uuid/uuid.dart';

enum PrinterConnectionType { bluetooth, usb, lan }
enum PaperSizeOption { mm58, mm80 }
enum PrinterRole { receipt, kitchen, all }

class AppPrinter {
  final String id;
  String name;
  PrinterConnectionType type;
  PaperSizeOption paperSize;
  PrinterRole role;
  bool isEnabled;

  // LAN connection settings
  String? ipAddress;
  int port;

  // Bluetooth connection settings
  String? btAddress;
  String? btDeviceName;

  // USB connection settings
  String? usbVendorId;
  String? usbProductId;
  String? usbDeviceName;

  AppPrinter({
    String? id,
    required this.name,
    required this.type,
    this.paperSize = PaperSizeOption.mm58,
    this.role = PrinterRole.receipt,
    this.isEnabled = true,
    this.ipAddress,
    this.port = 9100,
    this.btAddress,
    this.btDeviceName,
    this.usbVendorId,
    this.usbProductId,
    this.usbDeviceName,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'paperSize': paperSize.name,
      'role': role.name,
      'isEnabled': isEnabled,
      'ipAddress': ipAddress,
      'port': port,
      'btAddress': btAddress,
      'btDeviceName': btDeviceName,
      'usbVendorId': usbVendorId,
      'usbProductId': usbProductId,
      'usbDeviceName': usbDeviceName,
    };
  }

  factory AppPrinter.fromJson(Map<String, dynamic> json) {
    return AppPrinter(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Thermal Printer',
      type: PrinterConnectionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PrinterConnectionType.bluetooth,
      ),
      paperSize: PaperSizeOption.values.firstWhere(
        (e) => e.name == json['paperSize'],
        orElse: () => PaperSizeOption.mm58,
      ),
      role: PrinterRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => PrinterRole.receipt,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      ipAddress: json['ipAddress'] as String?,
      port: (json['port'] as num?)?.toInt() ?? 9100,
      btAddress: json['btAddress'] as String?,
      btDeviceName: json['btDeviceName'] as String?,
      usbVendorId: json['usbVendorId'] as String?,
      usbProductId: json['usbProductId'] as String?,
      usbDeviceName: json['usbDeviceName'] as String?,
    );
  }

  String get connectionSummary {
    switch (type) {
      case PrinterConnectionType.bluetooth:
        return btDeviceName?.isNotEmpty == true ? btDeviceName! : (btAddress ?? 'Bluetooth Printer');
      case PrinterConnectionType.usb:
        return usbDeviceName?.isNotEmpty == true ? usbDeviceName! : 'USB OTG Printer';
      case PrinterConnectionType.lan:
        return ipAddress?.isNotEmpty == true ? '$ipAddress:$port' : 'LAN Printer';
    }
  }

  AppPrinter copyWith({
    String? name,
    PrinterConnectionType? type,
    PaperSizeOption? paperSize,
    PrinterRole? role,
    bool? isEnabled,
    String? ipAddress,
    int? port,
    String? btAddress,
    String? btDeviceName,
    String? usbVendorId,
    String? usbProductId,
    String? usbDeviceName,
  }) {
    return AppPrinter(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      paperSize: paperSize ?? this.paperSize,
      role: role ?? this.role,
      isEnabled: isEnabled ?? this.isEnabled,
      ipAddress: ipAddress ?? this.ipAddress,
      port: port ?? this.port,
      btAddress: btAddress ?? this.btAddress,
      btDeviceName: btDeviceName ?? this.btDeviceName,
      usbVendorId: usbVendorId ?? this.usbVendorId,
      usbProductId: usbProductId ?? this.usbProductId,
      usbDeviceName: usbDeviceName ?? this.usbDeviceName,
    );
  }
}

