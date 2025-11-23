import 'package:flutter/material.dart'; // Widget dasar Flutter
import 'package:shared_preferences/shared_preferences.dart'; // Untuk penyimpanan data lokal
import 'package:flutter/services.dart'; // Untuk Clipboard (menyalin teks)
import 'dart:convert'; // Butuh ini untuk JSON (encode/decode data ke SharedPreferences)
import 'dart:math'; // Untuk Random Generator (membuat kode acak)

// Widget utama Admin Dashboard (Stateful karena mengelola data dan UI)
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Struktur data: List of Maps. Setiap map mewakili satu kode guru.
  // Contoh struktur: [ {'code': 'ABC', 'isUsed': false, 'usedBy': ''}, ... ]
  List<Map<String, dynamic>> _teacherData = [];
  final TextEditingController _codeController = TextEditingController(); // Controller untuk input/display kode

  @override
  void initState() {
    super.initState();
    _loadData(); // Panggil fungsi pemuatan data saat widget pertama kali dibuat
  }

  // Memuat data dari SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    // Ambil string JSON yang tersimpan dengan kunci 'teacher_codes_db'
    final String? dataString = prefs.getString('teacher_codes_db');

    if (dataString != null) {
      setState(() {
        // Decode string JSON menjadi List<dynamic>, lalu di-cast menjadi List<Map<String, dynamic>>
        _teacherData = List<Map<String, dynamic>>.from(jsonDecode(dataString));
      });
    }
  }

  // Menyimpan data ke SharedPreferences
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    // Encode List of Maps menjadi string JSON sebelum disimpan
    await prefs.setString('teacher_codes_db', jsonEncode(_teacherData));
  }

  // FUNGSI UTILITY: GENERATE KODE ACAK
  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'; // Karakter yang diizinkan
    final random = Random(); // Generator bilangan acak

    // Tentukan panjang kode acak antara 5 sampai 7 karakter
    final length = 5 + random.nextInt(3); // nextInt(3) menghasilkan 0, 1, atau 2

    // Buat kode dengan mengambil karakter acak sebanyak 'length'
    return List.generate(length, (index) {
      return chars[random.nextInt(chars.length)];
    }).join(); // Gabungkan list karakter menjadi satu string
  }


  // Menambah kode baru yang sudah diisi di dialog
  Future<void> _addCode() async {
    final codeText = _codeController.text.trim();
    if (codeText.isNotEmpty) {
      // Cek duplikasi: pastikan kode belum ada di _teacherData
      bool exists = _teacherData.any((element) => element['code'] == codeText);

      if (exists) {
        // Tampilkan snackbar jika kode sudah ada
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kode ini sudah ada!'), backgroundColor: Colors.red),
        );
        return;
      }

      // Tambahkan kode baru ke list
      setState(() {
        _teacherData.add({
          'code': codeText,
          'isUsed': false, // Status awal: belum dipakai
          'usedBy': '-', // Nama pengguna yang memakai (default '-')
        });
      });

      await _saveData(); // Simpan perubahan ke SharedPreferences
      _codeController.clear(); // Bersihkan input
      Navigator.of(context).pop(); // Tutup dialog

      // Tampilkan notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kode berhasil ditambahkan'), backgroundColor: Colors.green),
      );
    }
  }

  // Menghapus kode berdasarkan indeks di list
  Future<void> _deleteCode(int index) async {
    setState(() {
      _teacherData.removeAt(index); // Hapus elemen dari list
    });
    await _saveData(); // Simpan perubahan

    if (mounted) {
      // Tampilkan notifikasi penghapusan
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Kode berhasil dihapus'),
            backgroundColor: Colors.red
        ),
      );
    }
  }

  // Menampilkan dialog untuk menambah atau mengacak kode baru
  void _showAddDialog() {
    // Pastikan controller direset dan diisi dengan kode acak saat dialog dibuka
    _codeController.text = _generateRandomCode();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kode Guru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Kode ini akan digunakan guru untuk mendaftar."),
              const SizedBox(height: 15),
              // UPDATE: TextField yang menampilkan kode acak dan tidak bisa diedit
              TextField(
                controller: _codeController,
                readOnly: true, // Kode tidak bisa diedit manual
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                  color: Color(0xFF364CA7),
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  // Tombol Acak Ulang (Refresh)
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: "Acak Ulang",
                    onPressed: () {
                      // Isi controller dengan kode acak baru
                      _codeController.text = _generateRandomCode();
                    },
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text("Tekan tombol refresh untuk mengganti kode", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Batal')),
            ElevatedButton(
              onPressed: _addCode, // Panggil fungsi _addCode saat disimpan
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF364CA7)),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // Tampilkan pesan jika data kosong, jika tidak, tampilkan ListView
      body: _teacherData.isEmpty
          ? Center(child: Text('Belum ada Kode Guru.', style: TextStyle(color: Colors.grey[600])))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _teacherData.length,
        itemBuilder: (context, index) {
          final item = _teacherData[index];
          // Gunakan null check pada item['isUsed']
          final bool isUsed = item['isUsed'] ?? false;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            // Warna Card berbeda berdasarkan status penggunaan
            color: isUsed ? Colors.grey.shade100 : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                // Ikon dan warna berdasarkan status penggunaan
                backgroundColor: isUsed ? Colors.grey : const Color(0xFF364CA7).withOpacity(0.1),
                child: Icon(
                    isUsed ? Icons.check_circle : Icons.vpn_key,
                    color: isUsed ? Colors.white : const Color(0xFF364CA7)
                ),
              ),
              title: Text(
                item['code'], // Tampilkan kode
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isUsed ? Colors.grey : Colors.black,
                ),
              ),
              // Subtitle menampilkan status penggunaan dan nama pengguna jika sudah dipakai
              subtitle: isUsed
                  ? Text("Dipakai oleh: ${item['usedBy']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                  : const Text("Status: Belum Dipakai", style: TextStyle(color: Colors.orange)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tampilkan tombol Copy hanya jika kode belum dipakai
                  if (!isUsed)
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.grey),
                      onPressed: () {
                        // Salin kode ke clipboard
                        Clipboard.setData(ClipboardData(text: item['code']));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode disalin')),
                        );
                      },
                    ),
                  // Tombol Hapus
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCode(index), // Panggil fungsi hapus
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // Floating Action Button untuk memicu dialog penambahan kode
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF364CA7),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Kode", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}