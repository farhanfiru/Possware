import 'dart:io';

void main() {
  final path = r'C:\Users\farha\AppData\Local\Pub\Cache\hosted\pub.dev\blue_thermal_printer-1.2.3\android\src\main\AndroidManifest.xml';
  final file = File(path);
  if (file.existsSync()) {
    String content = file.readAsStringSync();
    content = content.replaceAll('package="id.kakzaki.blue_thermal_printer"', '');
    file.writeAsStringSync(content);
    print('Successfully removed package attribute from blue_thermal_printer AndroidManifest.xml');
  } else {
    print('File not found: $path');
  }
}
