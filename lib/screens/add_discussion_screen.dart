import 'dart:io'; // Digunakan untuk tipe data File (mengelola file gambar yang dipilih)
import 'dart:typed_data'; // Digunakan untuk tipe data Uint8List (data mentah byte dari gambar)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Library untuk memilih gambar
import 'package:shared_preferences/shared_preferences.dart'; // Library untuk penyimpanan data lokal sederhana
import 'dart:convert'; // Untuk jsonEncode dan jsonDecode
import '../models/discussion_model.dart'; // Import model data Discussion
import 'profile_screen.dart';
import 'discussion_detail_screen.dart';
import 'image_editor_screen.dart'; // Import screen editor gambar

// Widget utama untuk menambahkan diskusi baru (StatefulWidget)
class AddDiscussionScreen extends StatefulWidget {
  final String name; // Nama user yang sedang login (dibutuhkan untuk author)
  final String role; // Role user yang sedang login (dibutuhkan untuk author)

  const AddDiscussionScreen({Key? key, required this.name, required this.role}) : super(key: key);

  @override
  _AddDiscussionScreenState createState() => _AddDiscussionScreenState();
}

class _AddDiscussionScreenState extends State<AddDiscussionScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form input
  String? _selectedCategory; // State untuk kategori yang dipilih
  // Daftar kategori yang tersedia pada dropdown
  final List<String> _categories = [
    'Bahasa', 'Biologi', 'Matematika', 'Geografi', 'Fisika',
    'Kimia', 'Seni Budaya', 'Ekonomi', 'IT'
  ];
  final TextEditingController _questionController = TextEditingController(); // Controller untuk input pertanyaan
  final TextEditingController _descriptionController = TextEditingController(); // Controller untuk input keterangan
  int _selectedIndex = 1; // Indeks aktif Bottom Navigation Bar (1 = Add/Diskusi)

  File? _image; // Variabel untuk menyimpan file gambar yang dipilih
  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

  @override
  void dispose() {
    // Memastikan controller dibuang saat widget dihancurkan untuk menghindari memory leak
    _questionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar dari sumber (galeri atau kamera)
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Set _image ke File yang dipilih
      });
    }
  }

  // Fungsi untuk mengedit gambar yang sudah dipilih
  Future<void> _editImage() async {
    if (_image == null) return; // Keluar jika tidak ada gambar yang dipilih

    // 1. Baca gambar dari File sebagai array byte (Uint8List)
    final imageBytes = await _image!.readAsBytes();

    // 2. Panggil layar editor dengan membawa data byte gambar
    final editedImageBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(
          imageBytes: imageBytes,
        ),
      ),
    );

    // 3. Jika pengguna menyimpan perubahan (editedImageBytes adalah Uint8List yang berisi data gambar yang diedit)
    if (editedImageBytes != null && editedImageBytes is Uint8List) {
      // Uint8List adalah daftar panjang byte untuk menyimpan data mentah, jadi mengubah data mentah gambar lalu dikembalikan data yang sudah diedit

      // 4. Tulis data byte yang sudah diedit kembali ke file gambar yang sama
      final editedFile = await _image!.writeAsBytes(editedImageBytes);
      setState(() {
        _image = editedFile; // Perbarui state _image untuk menampilkan pratinjau yang baru
      });
    }
  }

  // Menampilkan bottom sheet untuk opsi pemilihan gambar (Kamera/Galeri)
  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Galeri'),
                  onTap: () {
                    _pickImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  }),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Logika utama untuk menyimpan diskusi ke SharedPreferences
  Future<void> _saveDiscussion() async {
    // 1. Validasi form
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();

      // Inisialisasi variabel untuk menyimpan data kota dan provinsi
      String? userCity;
      String? userProvince;

      // 2. Ambil data Kota dan Provinsi user yang sedang login dari 'users' data
      final String? usersString = prefs.getString('users');
      if (usersString != null) {
        final List<dynamic> userList = jsonDecode(usersString);
        // Mencari objek user yang sedang login berdasarkan 'name'
        final userJson = userList.firstWhere(
                (u) => u['name'] == widget.name,
            orElse: () => null // Jika tidak ditemukan, kembalikan null
        );

        if (userJson != null) {
          userCity = userJson['city'];
          userProvince = userJson['province'];
        }
      }

      // 3. Ambil dan deserialisasi semua diskusi yang sudah ada
      final String? discussionsString = prefs.getString('discussions');
      List<Discussion> allDiscussions = [];
      if (discussionsString != null && discussionsString.isNotEmpty) {
        final List<dynamic> discussionList = jsonDecode(discussionsString);
        // Mapping List JSON ke List<Discussion>
        allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();
      }

      // 4. Buat objek Discussion baru
      final newDiscussion = Discussion(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // ID unik berdasarkan waktu
        title: _questionController.text,
        description: _descriptionController.text,
        category: _selectedCategory!,
        authorName: widget.name,
        authorRole: widget.role,
        authorCity: userCity, // Tambahkan data wilayah
        authorProvince: userProvince, // Tambahkan data wilayah
        imagePath: _image?.path, // Simpan path lokal gambar jika ada
        createdAt: DateTime.now(),
      );

      // 5. Simpan diskusi baru ke SharedPreferences
      allDiscussions.add(newDiscussion);
      // Serialisasi List<Discussion> kembali ke JSON String
      final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
      await prefs.setString('discussions', updatedDiscussionsString);

      // 6. Tampilkan Snackbar notifikasi sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Diskusi berhasil dibuat!'),
          backgroundColor: Colors.green,
        ),
      );

      // 7. Navigasi ke halaman detail diskusi baru (menggunakan pushReplacement)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionDetailScreen(
              discussion: newDiscussion,
              currentUser: widget.name,
              currentUserRole: widget.role,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(), // Kembali ke halaman sebelumnya
        ),
        title: const Text(
          'Buat Diskusi Baru',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Form(
          key: _formKey, // Kunci untuk validasi form
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Input Pertanyaan
              const Text('Pertanyaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  hintText: 'Masukkan Pertanyaan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Pertanyaan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),

              // Bagian Dropdown Kategori
              const Text('Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                hint: const Text('Pilih Kategori'),
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(value: category, child: Text(category));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                validator: (value) => value == null ? 'Kategori harus dipilih' : null,
              ),
              const SizedBox(height: 24),

              // Bagian Lampirkan Gambar
              const Text('Lampirkan Gambar (Opsional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (_image != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pratinjau Gambar
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: DecorationImage(
                            image: FileImage(_image!), // Menampilkan gambar dari File
                            fit: BoxFit.cover,
                          )
                      ),
                    ),
                    Row(
                      children: [
                        // Tombol Ganti Gambar (memanggil _showPicker)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.image_search, size: 18),
                          label: const Text('Ganti'),
                          onPressed: () => _showPicker(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // TOMBOL EDIT FOTO BARU (memanggil _editImage)
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Foto'),
                          onPressed: _editImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF364CA7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              else
              // Tombol Pilih Gambar (jika belum ada gambar)
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pilih Gambar'),
                  onPressed: () => _showPicker(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              const SizedBox(height: 24),
              // Bagian Input Keterangan
              const Text('Keterangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Masukkan Keterangan dari Pertanyaan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Keterangan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 40),

              // Tombol Buat Diskusi (Submit)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveDiscussion, // Memanggil fungsi penyimpanan
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF364CA7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Buat Diskusi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(), // Menampilkan Bottom Nav Bar
    );
  }

  // Fungsi untuk membangun Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF364CA7),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.add_circle, 'Add', 1), // Indeks saat ini
          _buildNavItem(Icons.person, 'Profile', 2),
        ],
      ),
    );
  }

  // Fungsi untuk membangun setiap item navigasi
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        // Logika navigasi berdasarkan indeks
        if (index == 0) {
          // Navigasi ke Home: pop semua rute hingga rute pertama
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (index == 2) {
          // Navigasi ke Profile: menggunakan pushReplacement
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen(name: widget.name, role: widget.role)),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? Colors.white : Colors.white.withOpacity(0.6), size: 28),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.white.withOpacity(0.6), fontSize: 12)),
        ],
      ),
    );
  }
}