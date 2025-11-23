import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk mengakses data user yang tersimpan
import 'dart:convert'; // Untuk JSON encode/decode
import '../models/user_model.dart'; // Import model User
import 'home_screen.dart'; // Navigasi ke Home Screen setelah login
import 'register_screen.dart'; // Navigasi ke Register Screen
import 'admin_dashboard_screen.dart'; // Navigasi ke Admin Dashboard

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form
  final _emailController = TextEditingController(); // Controller input email
  final _passwordController = TextEditingController(); // Controller input password

  bool _obscurePassword = true; // State untuk toggle visibility password
  List<User> _users = []; // Daftar user yang dimuat dari penyimpanan lokal

  // --- AKUN ADMIN YANG DI-HARDCODE ---
  final String _adminEmail = 'admin@gmail.com';
  final String _adminPassword = 'admin123';

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Muat data user saat screen dimulai
  }

  @override
  void dispose() {
    // Pastikan controller dibuang untuk mencegah memory leak
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Memuat data user dari SharedPreferences
  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString('users');

    if (usersString != null && usersString.isNotEmpty) {
      final List<dynamic> userList = jsonDecode(usersString);
      if (mounted) {
        setState(() {
          // Deserialisasi dari List JSON ke List<User>
          _users = userList.map((user) => User.fromJson(user)).toList();
        });
      }
    }
  }

  // --- FUNGSI LOGIN TUNGGAL ---
  void _handleLogin() {
    // 1. Lakukan validasi form
    if (_formKey.currentState!.validate()) {

      // 2. CEK APAKAH YANG LOGIN ADALAH ADMIN
      if (_emailController.text == _adminEmail &&
          _passwordController.text == _adminPassword) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login sebagai Admin...'), backgroundColor: Colors.blue),
        );

        // Beri delay sebelum navigasi
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _emailController.clear();
            _passwordController.clear();

            // Navigasi ke Admin Dashboard
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
            );
          }
        });
        return; // Penting: Hentikan eksekusi setelah admin login
      }

      // 3. JIKA BUKAN ADMIN, CEK USER BIASA
      try {
        // Cari user yang email dan passwordnya cocok dalam daftar _users
        final user = _users.firstWhere(
              (user) => user.email == _emailController.text && user.password == _passwordController.text,
        );

        // Jika user ditemukan (tidak melempar error), tampilkan sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Selamat datang kembali, ${user.name}!'),
            backgroundColor: Colors.green,
          ),
        );

        // Beri delay sebelum navigasi
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            // Navigasi ke Home Screen, menghapus semua rute sebelumnya (pushAndRemoveUntil)
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => HomeScreen(name: user.name, role: user.role),
              ),
                  (Route<dynamic> route) => false, // Predikat ini memastikan semua rute di stack dihapus
            );
          }
        });

      } catch (e) {
        // Jika firstWhere melempar StateError (user tidak ditemukan)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email atau password salah.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Form(
            key: _formKey, // Kunci form
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/RuangDiskusi.png',
                    height: 150,
                  ),
                  const SizedBox(height: 70),
                  _buildEmailField(), // Widget input Email
                  const SizedBox(height: 20),
                  _buildPasswordField(), // Widget input Password
                  const SizedBox(height: 12),
                  // Tombol Lupa Password (saat ini tidak berfungsi)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Text(
                        'Lupa Password ?',
                        style: TextStyle(
                          color: Color(0xFF364CA7),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogin, // Memanggil fungsi login
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
                  const SizedBox(height: 20),
                  // Link Daftar Sekarang
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum daftar akun ? '),
                      GestureDetector(
                        onTap: () {
                          // Navigasi ke Register Screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          ).then((_) => _loadUsers()); // Muat ulang user setelah kembali dari daftar
                        },
                        child: const Text(
                          'Daftar sekarang',
                          style: TextStyle(
                            color: Color(0xFF364CA7),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget khusus untuk field Email
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      decoration: InputDecoration(
        hintText: 'Email',
        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email tidak boleh kosong';
        }

        // --- VALIDATOR FORMAT EMAIL ---
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
          return 'Format email tidak valid';
        }
        return null;
      },
    );
  }

  // Widget khusus untuk field Password
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword, // Dikontrol oleh state _obscurePassword
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
        // Tombol toggle visibility password
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey.shade600,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword; // Toggle state
            });
          },
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password tidak boleh kosong';
        }
        return null;
      },
    );
  }
}