import 'package:flutter/material.dart';
import 'screens/login_page.dart';
import 'screens/qr_scanner_page.dart';
import 'screens/combined_form_page.dart'; // Tambahkan import ini
import 'screens/profile_page.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Absensi',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        cardTheme: CardTheme(
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/home': (context) => QRScannerPage(),
        '/form': (context) => CombinedFormPage(), // Tambahkan route untuk form gabungan
        '/profile': (context) => ProfilePage(),
        // Biarkan route lama untuk kompatibilitas
        '/izin': (context) => CombinedFormPage(),
        '/cuti': (context) => CombinedFormPage(),
        '/lembur': (context) => CombinedFormPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}