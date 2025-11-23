import 'dart:io'; // Untuk File (mengelola file gambar)
import 'dart:typed_data'; // Untuk Uint8List (data byte gambar)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar
import 'package:shared_preferences/shared_preferences.dart'; // Untuk penyimpanan data lokal
import 'dart:convert'; // Untuk JSON encode/decode
import 'package:path_provider/path_provider.dart'; // Untuk mendapatkan direktori sementara (tempDir)
import '../models/discussion_model.dart'; // Import model Diskusi
import 'image_editor_screen.dart'; // Import screen editor gambar

// Widget untuk mengedit Diskusi (pertanyaan) spesifik
class EditDiscussionScreen extends StatefulWidget {
  final Discussion discussion; // Objek diskusi yang akan diedit

  const EditDiscussionScreen({Key? key, required this.discussion}) : super(key: key);

  @override
  _EditDiscussionScreenState createState() => _EditDiscussionScreenState();
}

class _EditDiscussionScreenState extends State<EditDiscussionScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form
  late TextEditingController _titleController; // Controller untuk judul
  late TextEditingController _descriptionController; // Controller untuk deskripsi

  File? _image; // File gambar yang dilampirkan
  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

  @override
  void initState() {
    super.initState();
    // 1. Inisialisasi controller dengan data diskusi yang sudah ada
    _titleController = TextEditingController(text: widget.discussion.title);
    _descriptionController = TextEditingController(text: widget.discussion.description);

    // 2. Muat gambar yang sudah ada (jika imagePath tidak null)
    if (widget.discussion.imagePath != null && widget.discussion.imagePath!.isNotEmpty) {
      _image = File(widget.discussion.imagePath!);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih gambar
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // --- FUNGSI PERBAIKAN UNTUK EDIT FOTO ---
  Future<void> _editImage() async {
    if (_image == null) return;

    final imageBytes = await _image!.readAsBytes();
    final editedImageBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(imageBytes: imageBytes),
      ),
    );

    // Jika bytes dikembalikan (perubahan disimpan)
    if (editedImageBytes != null && editedImageBytes is Uint8List) {
      // PENTING: Simpan hasil edit ke file sementara baru.
      // Ini menghindari masalah hak akses atau caching jika menulis ke path file lama,
      // dan memastikan pratinjau segera diperbarui.
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.png');
      await tempFile.writeAsBytes(editedImageBytes);

      setState(() {
        _image = tempFile; // Update state _image dengan file baru
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

  // Logika utama untuk menyimpan perubahan diskusi
  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final String? discussionsString = prefs.getString('discussions');
      if (discussionsString == null) return;

      // 1. Deserialisasi seluruh data diskusi
      List<dynamic> discussionList = jsonDecode(discussionsString);
      var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();

      // 2. Cari diskusi yang sedang diedit berdasarkan ID
      final discussionIndex = allDiscussions.indexWhere((d) => d.id == widget.discussion.id);

      if (discussionIndex != -1) {
        // 3. Perbarui properti diskusi yang sesuai
        allDiscussions[discussionIndex].title = _titleController.text;
        allDiscussions[discussionIndex].description = _descriptionController.text;
        allDiscussions[discussionIndex].isEdited = true; // Set flag bahwa telah diedit

        // Perbarui path gambar: gunakan path baru (_image?.path), atau null jika gambar dihapus
        allDiscussions[discussionIndex].imagePath = _image?.path;

        // 4. Serialisasi dan simpan kembali seluruh daftar diskusi
        final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
        await prefs.setString('discussions', updatedDiscussionsString);

        if(mounted) {
          // Tampilkan notifikasi sukses dan kembali ke halaman sebelumnya
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perubahan berhasil disimpan'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
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
        title: const Text('Edit Diskusi', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Input Judul Pertanyaan
              const Text('Judul Pertanyaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Masukkan Judul Pertanyaan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 24),

              //UI UNTUK MENGELOLA GAMBAR
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
              //Tombol Pilih Gambar (jika _image null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Pilih Gambar'),
                  onPressed: () => _showPicker(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              const SizedBox(height: 24),

              //Input Keterangan/Deskripsi
              const Text('Keterangan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Masukkan Keterangan dari Pertanyaan',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Keterangan tidak boleh kosong' : null,
              ),
              const SizedBox(height: 40),

              //Tombol Simpan Perubahan
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