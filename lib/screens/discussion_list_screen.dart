import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk penyimpanan data lokal
import 'dart:convert'; // Untuk JSON encode/decode
import 'package:intl/intl.dart'; // Untuk formatting tanggal
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi locale tanggal
import '../models/discussion_model.dart'; // Import model Diskusi
import 'add_discussion_screen.dart'; // Navigasi ke Tambah Diskusi
import 'discussion_detail_screen.dart'; // Navigasi ke Detail Diskusi
import 'profile_screen.dart'; // Navigasi ke Profil
import 'edit_discussion_screen.dart'; // Navigasi ke Edit Diskusi

// Widget tampilan daftar diskusi berdasarkan kategori yang dipilih
class DiscussionListScreen extends StatefulWidget {
  final String categoryName; // Nama kategori yang dilewatkan
  final IconData categoryIcon; // Ikon kategori
  final String name; // Nama user yang sedang login
  final String role; // Role user yang sedang login

  const DiscussionListScreen({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.name,
    required this.role,
  }) : super(key: key);

  @override
  State<DiscussionListScreen> createState() => _DiscussionListScreenState();
}

class _DiscussionListScreenState extends State<DiscussionListScreen> {
  int _selectedIndex = 0; // Indeks Bottom Nav Bar (Home)
  List<Discussion> _categoryDiscussions = []; // Daftar diskusi yang sesuai dengan kategori

  @override
  void initState() {
    super.initState();
    // Inisialisasi format tanggal Indonesia
    initializeDateFormatting('id_ID', null);
    _loadCategoryDiscussions(); // Muat data diskusi saat initState
  }

  // Fungsi utilitas untuk memformat tanggal
  String _formatDate(DateTime date) {
    return DateFormat('d MMM y, HH:mm', 'id_ID').format(date);
  }

  // Memuat dan memfilter diskusi berdasarkan kategori
  Future<void> _loadCategoryDiscussions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString != null && discussionsString.isNotEmpty) {
      final List<dynamic> discussionList = jsonDecode(discussionsString);
      final allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();

      if (mounted) {
        setState(() {
          // 1. Mengurutkan semua diskusi berdasarkan waktu (terbaru di atas)
          allDiscussions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          // 2. Memfilter diskusi hanya untuk kategori saat ini
          _categoryDiscussions = allDiscussions.where((d) => d.category == widget.categoryName).toList();
        });
      }
    }
  }

  // Menyimpan seluruh daftar diskusi (biasanya dipanggil setelah vote/edit)
  Future<void> _updateAndSaveDiscussions(List<Discussion> allDiscussions) async {
    final prefs = await SharedPreferences.getInstance();
    final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
    await prefs.setString('discussions', updatedDiscussionsString);
    _loadCategoryDiscussions(); // Muat ulang data kategori setelah penyimpanan
  }

  //Menghapus Diskusi
  Future<void> _deleteDiscussion(String discussionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString == null || discussionsString.isEmpty) return;

    List<dynamic> discussionList = jsonDecode(discussionsString);
    var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();

    // Hapus diskusi berdasarkan ID
    allDiscussions.removeWhere((d) => d.id == discussionId);

    // Simpan kembali daftar diskusi yang sudah diperbarui
    final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
    await prefs.setString('discussions', updatedDiscussionsString);

    // Muat ulang daftar setelah menghapus
    _loadCategoryDiscussions();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diskusi berhasil dihapus'), backgroundColor: Colors.red),
      );
    }
  }

  //Menampilkan Bottom Sheet Menu Opsi (Edit/Hapus)
  void _showOptions(Discussion discussion) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context); // Tutup bottom sheet
                  // Navigasi ke EditDiscussionScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDiscussionScreen(discussion: discussion),
                    ),
                  ).then((_) => _loadCategoryDiscussions()); // Refresh daftar setelah kembali dari Edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context); // Tutup bottom sheet
                  _deleteDiscussion(discussion.id); // Panggil fungsi hapus
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Menangani Voting (Upvote/Downvote)
  void _handleVote(String discussionId, bool isUpvote) async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString == null || discussionsString.isEmpty) return;

    List<dynamic> discussionList = jsonDecode(discussionsString);
    var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();

    final discussionIndex = allDiscussions.indexWhere((d) => d.id == discussionId);
    if (discussionIndex == -1) return;

    final discussion = allDiscussions[discussionIndex];
    final currentUser = widget.name; // Nama user yang vote

    // Logika voting (toggle dan saling meniadakan)
    final hasUpvoted = discussion.upvotedBy.contains(currentUser);
    final hasDownvoted = discussion.downvotedBy.contains(currentUser);

    if (isUpvote) {
      hasUpvoted ? discussion.upvotedBy.remove(currentUser) : discussion.upvotedBy.add(currentUser);
      if (!hasUpvoted) discussion.downvotedBy.remove(currentUser); // Hapus downvote jika upvote baru
    } else {
      hasDownvoted ? discussion.downvotedBy.remove(currentUser) : discussion.downvotedBy.add(currentUser);
      if (!hasDownvoted) discussion.upvotedBy.remove(currentUser); // Hapus upvote jika downvote baru
    }

    // Hitung ulang total vote
    discussion.upvotes = discussion.upvotedBy.length;
    discussion.downvotes = discussion.downvotedBy.length;

    _updateAndSaveDiscussions(allDiscussions); // Simpan dan muat ulang daftar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
        child: Column(
          children: [
            _buildHeader(), // Header menampilkan kategori
            const SizedBox(height: 24),
            Expanded(
              child: _categoryDiscussions.isEmpty
                  ? const Center(
                child: Text(
                  'Belum ada diskusi di kategori ini.',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              )
                  : ListView.builder(
                itemCount: _categoryDiscussions.length,
                itemBuilder: (context, index) {
                  final discussion = _categoryDiscussions[index];
                  return _buildDiscussionCard(discussion); // Membangun card diskusi
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(), // Bottom Navigation Bar
    );
  }

  // Widget Header Kategori
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF364CA7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(widget.categoryIcon, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Text(
            widget.categoryName, // Nama kategori
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Widget Card untuk setiap Diskusi
  Widget _buildDiscussionCard(Discussion discussion) {
    final currentUser = widget.name;
    final hasUpvoted = discussion.upvotedBy.contains(currentUser);
    final hasDownvoted = discussion.downvotedBy.contains(currentUser);
    final int answerCount = discussion.answers.length; // Hitung jumlah jawaban

    // Logika format lokasi penulis
    String locationText = "";
    if (discussion.authorCity != null && discussion.authorProvince != null) {
      locationText = "${discussion.authorCity}, ${discussion.authorProvince}";
    } else if (discussion.authorCity != null) {
      locationText = discussion.authorCity!;
    } else if (discussion.authorProvince != null) {
      locationText = discussion.authorProvince!;
    }

    return GestureDetector(
      // Tap: Navigasi ke detail diskusi
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionDetailScreen(
              discussion: discussion,
              currentUser: widget.name,
              currentUserRole: widget.role,
            ),
          ),
        ).then((_) => _loadCategoryDiscussions()); // Refresh daftar setelah kembali
      },
      // LongPress: Munculkan menu opsi (Edit/Hapus) jika user adalah penulis
      onLongPress: () {
        if (widget.name == discussion.authorName) {
          _showOptions(discussion);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tanggal dan status diedit
                Text(
                  '${_formatDate(discussion.createdAt)}${discussion.isEdited ? ' (diedit)' : ''}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(discussion.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(discussion.description, style: TextStyle(color: Colors.black, height: 1.4)),
            const SizedBox(height: 12),
            // Penulis dan Role
            Row(
              children: [
                Text('Oleh : ${discussion.authorName} - ${discussion.authorRole}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                // Ikon berdasarkan peran
                if (discussion.authorRole == 'Guru')
                  const Icon(Icons.school, color: Colors.blueAccent, size: 16)
                else if (discussion.authorRole == 'Siswa')
                  const Icon(Icons.face, color: Colors.blueAccent, size: 16)
                else
                  const Icon(Icons.person, color: Colors.blueAccent, size: 16),
              ],
            ),
            const SizedBox(height: 4),

            // BARIS LOKASI DAN LIKE/DISLIKE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Lokasi
                Expanded(
                  child: Text(
                    locationText,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                // Tombol Like/Dislike
                Row(
                  children: [
                    // Upvote Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.thumb_up,
                          color: hasUpvoted ? Colors.blueAccent : Colors.green, size: 18),
                      onPressed: () => _handleVote(discussion.id, true),
                    ),
                    const SizedBox(width: 4),
                    Text(discussion.upvotes.toString()),
                    const SizedBox(width: 12),
                    // Downvote Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.thumb_down,
                          color: hasDownvoted ? Colors.orangeAccent : Colors.red, size: 18),
                      onPressed: () => _handleVote(discussion.id, false),
                    ),
                    const SizedBox(width: 4),
                    Text(discussion.downvotes.toString()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Indikator Jumlah Jawaban
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.remove_red_eye, size: 18, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    '$answerCount - Lihat Jawaban',
                    style: const TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Bottom Navigation Bar
  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF364CA7),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.add_circle, 'Add', 1),
          _buildNavItem(Icons.person, 'Profile', 2),
        ],
      ),
    );
  }

  // Widget Item Navigasi
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        // Logika navigasi antar halaman utama
        if (index == 0) {
          // Home: Pop semua rute hingga rute pertama
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (index == 1) {
          // Add: Navigasi ke AddDiscussionScreen dan refresh setelah kembali
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddDiscussionScreen(name: widget.name, role: widget.role)),
          ).then((_) => _loadCategoryDiscussions());
        } else if (index == 2) {
          // Profile: Navigasi ke ProfileScreen
          Navigator.push(
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