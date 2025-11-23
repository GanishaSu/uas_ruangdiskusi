import 'package:flutter/material.dart';
import '/screens/animated_welcome_screen.dart'; // Mengimpor halaman baru

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RuangDiskusiPelajarApp());
}

class RuangDiskusiPelajarApp extends StatelessWidget {
  const RuangDiskusiPelajarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruang Diskusi',
      theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          fontFamily: 'Poppins',
          textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF364CA7),
              )
          )
      ),
      debugShowCheckedModeBanner: false,
      // Halaman awal aplikasi sekarang adalah AnimatedWelcomeScreen
      home: const AnimatedWelcomeScreen(),
    );
  }
}

