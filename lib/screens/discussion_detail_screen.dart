import 'dart:io'; // Untuk File (menampilkan gambar)
import 'dart:typed_data'; // Untuk Uint8List (data byte gambar)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar jawaban
import 'package:shared_preferences/shared_preferences.dart'; // Untuk penyimpanan data lokal
import 'dart:convert'; // Untuk JSON encode/decode
import 'package:intl/intl.dart'; // Untuk formatting tanggal
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi locale tanggal
import '../models/discussion_model.dart'; // Import model Diskusi
import '../models/answer_model.dart'; // Import model Jawaban
import 'edit_discussion_screen.dart'; // Navigasi ke Edit Diskusi
import 'edit_answer_screen.dart'; // Navigasi ke Edit Jawaban
import 'image_editor_screen.dart'; // Navigasi ke Editor Gambar

// Widget detail diskusi, menerima objek Discussion dan info user yang login
class DiscussionDetailScreen extends StatefulWidget {
  final Discussion discussion; // Objek diskusi yang ditampilkan
  final String currentUser; // Nama user yang sedang login
  final String currentUserRole; // Role user yang sedang login

  const DiscussionDetailScreen({
    Key? key,
    required this.discussion,
    required this.currentUser,
    required this.currentUserRole,
  }) : super(key: key);

  @override
  _DiscussionDetailScreenState createState() => _DiscussionDetailScreenState();
}

class _DiscussionDetailScreenState extends State<DiscussionDetailScreen> {
  late Discussion _currentDiscussion; // State diskusi yang akan di-update
  final TextEditingController _answerController = TextEditingController(); // Controller input jawaban
  File? _answerImage; // File gambar yang dilampirkan pada jawaban
  final ImagePicker _picker = ImagePicker(); // Instance ImagePicker

  @override
  void initState() {
    super.initState();
    _currentDiscussion = widget.discussion; // Inisialisasi state dengan data awal
    initializeDateFormatting('id_ID', null); // Inisialisasi format tanggal bahasa Indonesia
  }

  // Fungsi untuk mengedit gambar yang dilampirkan pada jawaban
  Future<void> _editAnswerImage() async {
    if (_answerImage == null) return;

    final imageBytes = await _answerImage!.readAsBytes();
    // Navigasi ke ImageEditorScreen dan tunggu hasil editan
    final editedImageBytes = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageEditorScreen(imageBytes: imageBytes),
      ),
    );

    // Jika hasil editan dikembalikan sebagai Uint8List
    if (editedImageBytes != null && editedImageBytes is Uint8List) {
      // Simpan byte yang sudah diedit kembali ke file asal
      final editedFile = await _answerImage!.writeAsBytes(editedImageBytes);
      setState(() {
        _answerImage = editedFile; // Perbarui pratinjau gambar jawaban
      });
    }
  }

  // Fungsi utilitas untuk memformat tanggal
  String _formatDate(DateTime date) {
    return DateFormat('d MMM y, HH:mm', 'id_ID').format(date);
  }

  // FUNGSI BARU: Menampilkan gambar dalam popup yang bisa di-zoom
  void _showImageDialog(String imagePath) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero, // Membuat dialog memenuhi layar
        child: Stack(
          children: [
            // InteractiveViewer memungkinkan pengguna melakukan pan dan zoom pada gambar
            InteractiveViewer(
              panEnabled: true, // Memungkinkan geser
              boundaryMargin: const EdgeInsets.all(20),
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // Tombol Tutup
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Memuat ulang data diskusi dari SharedPreferences (digunakan setelah Edit/Delete)
  Future<void> _reloadDiscussion() async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString == null) return;

    List<dynamic> discussionList = jsonDecode(discussionsString);
    var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();
    // Cari diskusi yang sudah terupdate
    final updatedDiscussion = allDiscussions.firstWhere(
            (d) => d.id == widget.discussion.id,
        orElse: () => widget.discussion);

    if (mounted) {
      setState(() {
        _currentDiscussion = updatedDiscussion; // Update state diskusi
      });
    }
  }

  // Menyimpan diskusi yang telah diupdate ke SharedPreferences
  Future<void> _updateAndSaveDiscussion(Discussion updatedDiscussion) async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString == null || discussionsString.isEmpty) return;

    List<dynamic> discussionList = jsonDecode(discussionsString);
    var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();
    // Cari dan ganti objek diskusi yang lama dengan yang baru
    final discussionIndex = allDiscussions.indexWhere((d) => d.id == updatedDiscussion.id);
    if (discussionIndex != -1) {
      allDiscussions[discussionIndex] = updatedDiscussion;
    }

    if (mounted) {
      setState(() {
        _currentDiscussion = updatedDiscussion; // Update state diskusi
      });
    }

    // Encode dan simpan kembali seluruh daftar diskusi
    final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
    await prefs.setString('discussions', updatedDiscussionsString);
  }

  // Menghapus diskusi saat ini
  Future<void> _deleteDiscussion() async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString == null || discussionsString.isEmpty) return;

    List<dynamic> discussionList = jsonDecode(discussionsString);
    var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();
    // Hapus diskusi dari list
    allDiscussions.removeWhere((d) => d.id == _currentDiscussion.id);

    // Simpan list yang sudah dihapus
    final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
    await prefs.setString('discussions', updatedDiscussionsString);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diskusi berhasil dihapus'), backgroundColor: Colors.red),
      );
      Navigator.of(context).pop(); // Keluar dari halaman detail
    }
  }

  // Menghapus jawaban berdasarkan ID
  void _deleteAnswer(String answerId) {
    final discussion = _currentDiscussion;
    discussion.answers.removeWhere((answer) => answer.id == answerId); // Hapus jawaban dari list
    _updateAndSaveDiscussion(discussion); // Simpan perubahan
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jawaban berhasil dihapus'), backgroundColor: Colors.red),
      );
    }
  }

  // Menandai jawaban sebagai Jawaban Terbaik (Best Answer)
  void _setBestAnswer(String answerId) {
    final discussion = _currentDiscussion;

    // Logika toggle: Jika sudah terbaik, hapus status terbaiknya
    if (discussion.bestAnswerId == answerId) {
      discussion.bestAnswerId = null;
    } else {
      discussion.bestAnswerId = answerId; // Set ID jawaban terbaik baru
    }

    // Perbarui flag isBestAnswer pada setiap objek Answer
    for (var answer in discussion.answers) {
      answer.isBestAnswer = (answer.id == discussion.bestAnswerId);
    }

    _updateAndSaveDiscussion(discussion); // Simpan perubahan
  }

  // Menangani voting (upvote/downvote) untuk Diskusi
  void _handleDiscussionVote(bool isUpvote) {
    final discussion = _currentDiscussion;
    final currentUser = widget.currentUser;
    final hasUpvoted = discussion.upvotedBy.contains(currentUser);
    final hasDownvoted = discussion.downvotedBy.contains(currentUser);

    if (isUpvote) {
      // Logic Upvote: Toggle upvote. Jika upvote, hapus downvote.
      hasUpvoted ? discussion.upvotedBy.remove(currentUser) : discussion.upvotedBy.add(currentUser);
      if (!hasUpvoted) discussion.downvotedBy.remove(currentUser);
    } else {
      // Logic Downvote: Toggle downvote. Jika downvote, hapus upvote.
      hasDownvoted ? discussion.downvotedBy.remove(currentUser) : discussion.downvotedBy.add(currentUser);
      if (!hasDownvoted) discussion.upvotedBy.remove(currentUser);
    }

    // Hitung ulang total upvotes/downvotes
    discussion.upvotes = discussion.upvotedBy.length;
    discussion.downvotes = discussion.downvotedBy.length;
    _updateAndSaveDiscussion(discussion);
  }

  // Menangani voting (upvote/downvote) untuk Jawaban
  void _handleAnswerVote(String answerId, bool isUpvote) {
    final discussion = _currentDiscussion;
    final answerIndex = discussion.answers.indexWhere((a) => a.id == answerId);
    if (answerIndex == -1) return;

    final answer = discussion.answers[answerIndex];
    final currentUser = widget.currentUser;
    final hasUpvoted = answer.upvotedBy.contains(currentUser);
    final hasDownvoted = answer.downvotedBy.contains(currentUser);

    // Logic voting sama seperti diskusi
    if (isUpvote) {
      hasUpvoted ? answer.upvotedBy.remove(currentUser) : answer.upvotedBy.add(currentUser);
      if (!hasUpvoted) answer.downvotedBy.remove(currentUser);
    } else {
      hasDownvoted ? answer.downvotedBy.remove(currentUser) : answer.downvotedBy.add(currentUser);
      if (!hasDownvoted) answer.upvotedBy.remove(currentUser);
    }

    answer.upvotes = answer.upvotedBy.length;
    answer.downvotes = answer.downvotedBy.length;
    _updateAndSaveDiscussion(discussion);
  }

  // Memilih gambar untuk jawaban
  Future<void> _pickAnswerImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _answerImage = File(pickedFile.path);
      });
    }
  }

  // Menampilkan bottom sheet untuk memilih sumber gambar jawaban
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
                      _pickAnswerImage(ImageSource.gallery);
                      Navigator.of(context).pop();
                    }),
                ListTile(
                  leading: const Icon(Icons.photo_camera),
                  title: const Text('Kamera'),
                  onTap: () {
                    _pickAnswerImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  // Submit jawaban baru
  void _submitAnswer() {
    // Validasi: Harus ada konten teks atau gambar
    if (_answerController.text.isEmpty && _answerImage == null) return;

    // Buat objek Answer baru
    final newAnswer = Answer(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: widget.currentUser,
      authorRole: widget.currentUserRole,
      content: _answerController.text,
      imagePath: _answerImage?.path,
      createdAt: DateTime.now(),
    );

    // Tambahkan jawaban ke diskusi
    final discussion = _currentDiscussion;
    discussion.answers.add(newAnswer);
    _updateAndSaveDiscussion(discussion);

    // Reset input form
    _answerController.clear();
    setState(() {
      _answerImage = null;
    });
    FocusScope.of(context).unfocus(); // Tutup keyboard
  }

  @override
  Widget build(BuildContext context) {
    // Sort Jawaban: Jawaban Terbaik selalu di atas, diikuti urutan waktu terbaru
    _currentDiscussion.answers.sort((a, b) {
      if (a.isBestAnswer) return -1; // a datang sebelum b
      if (b.isBestAnswer) return 1; // b datang sebelum a
      return b.createdAt.compareTo(a.createdAt); // Urutkan berdasarkan waktu (terbaru dulu)
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuestionCard(_currentDiscussion), // Tampilkan detail pertanyaan
              const SizedBox(height: 24),
              const Text('Jawaban :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildAnswersList(), // Tampilkan daftar jawaban
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildAnswerSubmissionArea(), // Area untuk input jawaban
    );
  }

  // Widget untuk Area Input Jawaban di Bottom Navigation Bar
  Widget _buildAnswerSubmissionArea() {
    return SingleChildScrollView(
      child: Container(
        // Padding bottom disesuaikan dengan keyboard (viewInsets.bottom)
        padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + MediaQuery.of(context).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0,-4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Kirim Jawaban :', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                // Tombol lampirkan gambar (memanggil _showPicker)
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Gambar'),
                  onPressed: () => _showPicker(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Pratinjau Gambar Jawaban (jika ada)
            if (_answerImage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(image: FileImage(_answerImage!), fit: BoxFit.cover)
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
                        onPressed: _editAnswerImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF364CA7),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            // Text Field Input Jawaban
            TextField(
              controller: _answerController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Masukkan Jawaban Anda',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.grey.shade300)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.blue.shade300)),
              ),
            ),
            const SizedBox(height: 16),
            // Tombol Kirim Jawaban
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitAnswer, // Memanggil fungsi submit
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF364CA7),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Kirim', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan detail pertanyaan (Diskusi)
  Widget _buildQuestionCard(Discussion discussion) {
    // Logika format lokasi penulis pertanyaan
    String locationText = "";
    if (discussion.authorCity != null && discussion.authorProvince != null) {
      locationText = "${discussion.authorCity}, ${discussion.authorProvince}";
    } else if (discussion.authorCity != null) {
      locationText = discussion.authorCity!;
    } else if (discussion.authorProvince != null) {
      locationText = discussion.authorProvince!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Text(_formatDate(discussion.createdAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (discussion.isEdited) // Tanda diedit
                        const Text(' (diedit)',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              // Menu Edit/Hapus (hanya muncul jika user adalah penulis diskusi)
              if (widget.currentUser == discussion.authorName)
                SizedBox(
                  width: 48,
                  height: 30,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        // Navigasi ke EditScreen dan panggil _reloadDiscussion setelah kembali
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    EditDiscussionScreen(discussion: discussion)))
                            .then((_) => _reloadDiscussion());
                      } else if (value == 'delete') {
                        _deleteDiscussion();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem<String>(
                          value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
            ],
          ),
          Text(discussion.title, // Judul pertanyaan
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          // Gambar Pertanyaan (jika ada, bisa di-tap untuk zoom)
          if (discussion.imagePath != null && discussion.imagePath!.isNotEmpty)
            GestureDetector(
              onTap: () => _showImageDialog(discussion.imagePath!),
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Image.file(File(discussion.imagePath!)),
              ),
            ),
          const SizedBox(height: 8),
          Text(discussion.description, // Deskripsi pertanyaan
              style: TextStyle(
                  color: Colors.grey.shade700, height: 1.4, fontSize: 15)),
          const SizedBox(height: 12),
          // Bagian Penulis dan Role
          Row(
            children: [
              Text('Oleh: ${discussion.authorName} - ${discussion.authorRole}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 8),
              // Ikon berdasarkan Role
              if (discussion.authorRole == 'Guru')
                const Icon(Icons.school, color: Colors.blueAccent, size: 16)
              else if (discussion.authorRole == 'Siswa')
                const Icon(Icons.face, color: Colors.blueAccent, size: 16)
              else
                const Icon(Icons.person, color: Colors.blueAccent, size: 16),
            ],
          ),
          const SizedBox(height: 4),

          // Baris Lokasi dan Tombol Vote Diskusi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Lokasi
              Expanded(
                child: Text(
                  locationText,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Tombol Vote Diskusi
              Row(
                children: [
                  // Upvote Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.thumb_up,
                        // Warna ikon disesuaikan dengan status vote user saat ini
                        color: discussion.upvotedBy.contains(widget.currentUser)
                            ? Colors.blueAccent
                            : Colors.green,
                        size: 18),
                    onPressed: () => _handleDiscussionVote(true),
                  ),
                  const SizedBox(width: 4),
                  Text(discussion.upvotes.toString()),
                  const SizedBox(width: 12),
                  // Downvote Button
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.thumb_down,
                        color:
                        discussion.downvotedBy.contains(widget.currentUser)
                            ? Colors.orangeAccent
                            : Colors.red,
                        size: 18),
                    onPressed: () => _handleDiscussionVote(false),
                  ),
                  const SizedBox(width: 4),
                  Text(discussion.downvotes.toString()),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  // Widget untuk menampilkan daftar Jawaban
  Widget _buildAnswersList() {
    if (_currentDiscussion.answers.isEmpty) {
      return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text('Belum ada jawaban.', style: TextStyle(color: Colors.grey)),
          ));
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Memastikan scrolling dikontrol oleh SingleChildScrollView induk
      itemCount: _currentDiscussion.answers.length,
      itemBuilder: (context, index) {
        final answer = _currentDiscussion.answers[index];
        return _buildAnswerCard(answer); // Membangun card untuk setiap jawaban
      },
    );
  }

  // Widget untuk menampilkan setiap Jawaban dalam bentuk card
  Widget _buildAnswerCard(Answer answer) {
    // Logika format lokasi penulis jawaban (saat ini lokasi diambil dari model Answer, padahal harusnya dari data User)
    String locationText = "";
    if (answer.authorCity != null && answer.authorProvince != null) {
      locationText = "${answer.authorCity}, ${answer.authorProvince}";
    } else if (answer.authorCity != null) {
      locationText = answer.authorCity!;
    } else if (answer.authorProvince != null) {
      locationText = answer.authorProvince!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Highlight jika ini adalah Jawaban Terbaik
        color: answer.isBestAnswer ? Colors.amber.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: answer.isBestAnswer ? Colors.amber : Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Text(_formatDate(answer.createdAt),
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (answer.isEdited) // Tanda diedit
                        const Text(' (diedit)',
                            style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              // Menu Edit/Hapus Jawaban (hanya untuk penulis jawaban)
              if (widget.currentUser == answer.author)
                SizedBox(
                  width: 48,
                  height: 30,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    onSelected: (value) {
                      if (value == 'edit') {
                        // Navigasi ke EditAnswerScreen dan reload setelah kembali
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => EditAnswerScreen(
                                    discussion: _currentDiscussion,
                                    answer: answer)))
                            .then((_) => _reloadDiscussion());
                      } else if (value == 'delete') {
                        _deleteAnswer(answer.id);
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                          value: 'edit', child: Text('Edit')),
                      const PopupMenuItem<String>(
                          value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ),
            ],
          ),
          Row(
            children: [
              Text('Dari : ${answer.author} - ${answer.authorRole}',
                  style:
                  const TextStyle(fontWeight: FontWeight.bold)),

              const SizedBox(width: 8),
              // Ikon Role Penulis Jawaban
              Icon(
                  answer.authorRole == 'Guru'
                      ? Icons.school
                      : Icons.face,
                  color: Colors.blueAccent,
                  size: 16),
              const SizedBox(width: 8),
              // Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     // Lokasi Jawaban
              //     if (locationText.isNotEmpty)
              //       Padding(
              //         padding: const EdgeInsets.only(top: 2.0),
              //         child: Text(locationText, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              //       ),
              //   ],
              // ),
            ],
          ),
          // Badge Jawaban Terbaik
          if (answer.isBestAnswer)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Jawaban Terbaik',
                    style: TextStyle(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          // Gambar Jawaban (jika ada, bisa di-tap untuk zoom)
          if (answer.imagePath != null && answer.imagePath!.isNotEmpty)
            GestureDetector(
              onTap: () => _showImageDialog(answer.imagePath!),
              child: Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Image.file(File(answer.imagePath!)),
              ),
            ),
          const SizedBox(height: 8),
          Text(answer.content), // Konten Jawaban
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tombol Vote Jawaban
              Row(
                children: _buildVoteButtons(answer),
              ),
              // Tombol Pilih Terbaik (hanya muncul untuk penulis pertanyaan)
              if (widget.currentUser == _currentDiscussion.authorName)
                TextButton.icon(
                  onPressed: () => _setBestAnswer(answer.id),
                  icon: Icon(answer.isBestAnswer ? Icons.star : Icons.star_border, color: Colors.amber),
                  label: Text(answer.isBestAnswer ? 'Terpilih' : 'Pilih Terbaik',
                      style: const TextStyle(color: Colors.black54)),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30)),
                )
            ],
          )
        ],
      ),
    );
  }

  // Helper function untuk membuat Tombol Vote Jawaban
  List<Widget> _buildVoteButtons(Answer answer) {
    return [
      // Upvote Button Jawaban
      IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(Icons.thumb_up,
            color:
            answer.upvotedBy.contains(widget.currentUser)
                ? Colors.blueAccent
                : Colors.green,
            size: 18),
        onPressed: () => _handleAnswerVote(answer.id, true),
      ),
      const SizedBox(width: 4),
      Text(answer.upvotes.toString()),
      const SizedBox(width: 12),
      // Downvote Button Jawaban
      IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(Icons.thumb_down,
            color:
            answer.downvotedBy.contains(widget.currentUser)
                ? Colors.orangeAccent
                : Colors.red,
            size: 18),
        onPressed: () => _handleAnswerVote(answer.id, false),
      ),
      const SizedBox(width: 4),
      Text(answer.downvotes.toString()),
    ];
  }
}