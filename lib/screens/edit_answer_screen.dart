import 'dart:io'; // Untuk File (mengelola file gambar)
import 'dart:typed_data'; // Untuk Uint8List (data byte gambar)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar
import 'package:shared_preferences/shared_preferences.dart'; // Untuk penyimpanan data lokal
import 'dart:convert'; // Untuk JSON encode/decode
import '../models/discussion_model.dart'; // Import model Diskusi
import '../models/answer_model.dart'; // Import model Jawaban
import 'image_editor_screen.dart'; // Import screen editor gambar

// Widget untuk mengedit Jawaban (Answer) spesifik
class EditAnswerScreen extends StatefulWidget {
  final Discussion discussion; // Diskusi induk dari jawaban yang diedit
  final Answer answer; // Objek jawaban yang akan diedit

  const EditAnswerScreen({Key? key, required this.discussion, required this.answer}) : super(key: key);

  @override
  _EditAnswerScreenState createState() => _EditAnswerScreenState();
}

class _EditAnswerScreenState extends State<EditAnswerScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form
  late TextEditingController _contentController; // Controller untuk konten jawaban

  //State untuk gambar
  File? _image; // File gambar yang dilampirkan
  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi controller dengan konten jawaban yang sudah ada
    _contentController = TextEditingController(text: widget.answer.content);

    // 2. Muat gambar yang sudah ada (jika imagePath tidak null)
    if (widget.answer.imagePath != null && widget.answer.imagePath!.isNotEmpty) {
      _image = File(widget.answer.imagePath!);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  //Fungsi untuk memilih gambar (Gallery/Camera)
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  //Fungsi untuk mengedit gambar yang dipilih
  Future<void> _editImage() async {
    if (_image == null) return;

    // 1. Baca gambar sebagai byte
    final imageBytes = await _image!.readAsBytes();

    // 2. Navigasi ke ImageEditorScreen
    final editedImageBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(imageBytes: imageBytes),
      ),
    );

    // 3. Jika bytes dikembalikan (perubahan disimpan)
    if (editedImageBytes != null && editedImageBytes is Uint8List) {
      // Tulis byte yang sudah diedit kembali ke file asal
      final editedFile = await _image!.writeAsBytes(editedImageBytes);
      setState(() {
        _image = editedFile; // Perbarui pratinjau
      });
    }
  }

  // Menampilkan bottom sheet untuk memilih sumber gambar
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

  // Logika utama untuk menyimpan perubahan jawaban
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final String? discussionsString = prefs.getString('discussions');
      if (discussionsString == null) return;

      // 1. Deserialisasi seluruh data diskusi
      List<dynamic> discussionList = jsonDecode(discussionsString);
      var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();

      // 2. Cari diskusi induk berdasarkan ID
      final discussionIndex = allDiscussions.indexWhere((d) => d.id == widget.discussion.id);

      if (discussionIndex != -1) {
        // 3. Cari jawaban spesifik di dalam diskusi induk
        final answerIndex = allDiscussions[discussionIndex].answers.indexWhere((a) => a.id == widget.answer.id);

        if (answerIndex != -1) {
          // 4. Perbarui data jawaban yang lama dengan data baru

          // Perbarui konten teks
          allDiscussions[discussionIndex].answers[answerIndex].content = _contentController.text;

          // Set flag isEdited menjadi true
          allDiscussions[discussionIndex].answers[answerIndex].isEdited = true;

          // Perbarui path gambar:
          // Jika _image ada, gunakan path baru. Jika _image null (dihapus), set imagePath menjadi null.
          allDiscussions[discussionIndex].answers[answerIndex].imagePath = _image?.path;

          // 5. Serialisasi dan simpan kembali seluruh daftar diskusi
          final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
          await prefs.setString('discussions', updatedDiscussionsString);

          if (mounted) {
            // Tampilkan notifikasi dan tutup halaman
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Jawaban berhasil diubah'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          }
        }
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Edit Jawaban', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Input Konten Jawaban ---
              const Text('Jawaban Anda', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Masukkan jawaban Anda',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Jawaban tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),

              // --- UI UNTUK MENGELOLA GAMBAR ---
              const Text('Lampiran Gambar (Opsional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
                            image: FileImage(_image!),
                            fit: BoxFit.cover,
                          )
                      ),
                    ),
                    Row(
                      children: [
                        // Tombol Ganti Gambar
                        OutlinedButton.icon(
                          icon: const Icon(Icons.image_search, size: 18),
                          label: const Text('Ganti'),
                          onPressed: () => _showPicker(context),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Tombol Edit Foto
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
                        const SizedBox(width: 10),
                        // Tombol Hapus Gambar
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _image = null; // Hapus gambar
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                )
              else
              // Tombol Pilih Gambar (jika _image null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pilih Gambar'),
                  onPressed: () => _showPicker(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),

              const SizedBox(height: 40),
              // Tombol Simpan Perubahan
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveChanges, // Panggil fungsi penyimpanan
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF364CA7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}