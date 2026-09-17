import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/billing_provider.dart';
import 'screens/pos_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);

  runApp(const NayckoBillingApp());
}

class NayckoBillingApp extends StatelessWidget {
  const NayckoBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BillingProvider()..init()),
      ],
      child: MaterialApp(
        title: 'Neyco POS',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F172A), // Slate 900
            primary: const Color(0xFF0F172A),
            secondary: const Color(0xFF059669), // Emerald 600
            surface: Colors.white,
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF0F172A),
            elevation: 0,
          ),
        ),
        home: const PosScreen(),
      ),
    );
  }
}
