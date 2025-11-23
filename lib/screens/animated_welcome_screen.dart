import 'dart:async'; // Digunakan untuk Timer (mengontrol urutan animasi)
import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import screen login
import 'register_screen.dart'; // Import screen register

// Widget utama untuk tampilan selamat datang dengan animasi (StatefulWidget)
class AnimatedWelcomeScreen extends StatefulWidget {
  const AnimatedWelcomeScreen({Key? key}) : super(key: key);

  @override
  _AnimatedWelcomeScreenState createState() => _AnimatedWelcomeScreenState();
}

class _AnimatedWelcomeScreenState extends State<AnimatedWelcomeScreen> {
  // State boolean untuk mengontrol animasi Opacity (fade in logo)
  bool _showLogo = false;
  // State boolean untuk mengontrol animasi Positioned (slide up tombol)
  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    // Timer 1: Untuk Animasi Logo (fade in)
    Timer(const Duration(milliseconds: 200), () {
      if (mounted) { // Pastikan widget masih aktif (mounted) sebelum memanggil setState
        setState(() {
          _showLogo = true; // Mulai animasi fade in logo
        });
      }
    });

    // Timer 2: Untuk Animasi Tombol (slide up). Dimulai lebih lambat (delay)
    Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _showButtons = true; // Mulai animasi slide up tombol
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ambil tinggi layar untuk penempatan elemen secara responsif
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack( // Stack digunakan untuk menumpuk elemen (logo di tengah, tombol di bawah)
          children: [
            // 1. Logo (Center, dianimasikan menggunakan Opacity)
            Center(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 3000), // Durasi fade in yang panjang
                opacity: _showLogo ? 1.0 : 0.0, // Opacity dikontrol oleh _showLogo
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/icons/RuangDiskusi.png', // Logo aplikasi
                      height: 150,
                    ),
                    // Memberikan jarak dari logo ke tengah layar untuk memberi ruang tombol di bawah
                    SizedBox(height: screenHeight * 0.25),
                  ],
                ),
              ),
            ),

            // 2. Tombol (AnimatedPositioned, dianimasikan slide up)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 2500), // Durasi animasi slide
              curve: Curves.easeInOut, // Kurva animasi
              // Posisi bottom: Jika _showButtons true, pindah ke 150. Jika false, posisikan di luar layar (-300).
              bottom: _showButtons ? 150 : -300,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  // Tombol Masuk
                  const Text('Sudah Punya Akun?'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigasi ke LoginScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF364CA7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tombol Daftar
                  const Text('Belum Punya Akun?'),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigasi ke RegisterScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF364CA7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Daftar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
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
}