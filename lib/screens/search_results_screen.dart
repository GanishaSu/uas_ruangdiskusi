import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk mengakses data lokal
import 'dart:convert'; // Untuk JSON encode/decode
import 'package:intl/intl.dart'; // Untuk formatting tanggal
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi locale tanggal
import '../models/discussion_model.dart'; // Import model Diskusi
import 'discussion_detail_screen.dart'; // Navigasi ke Detail Diskusi

// Widget tampilan hasil pencarian
class SearchResultsScreen extends StatefulWidget {
  final String query; // Kata kunci pencarian yang dilewatkan
  final String name; // Nama user yang sedang login (untuk voting)
  final String role; // Role user yang sedang login (untuk detail diskusi)

  const SearchResultsScreen({
    Key? key,
    required this.query,
    required this.name,
    required this.role,
  }) : super(key: key);

  @override
  _SearchResultsScreenState createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  List<Discussion> _searchResults = []; // Daftar hasil diskusi yang cocok

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _performSearch(); // Lakukan pencarian saat screen pertama kali dibuat
  }

  // Fungsi utilitas untuk memformat tanggal
  String _formatDate(DateTime date) {
    return DateFormat('d MMM y, HH:mm', 'id_ID').format(date);
  }

  // Melakukan operasi pencarian dan memfilter hasil
  Future<void> _performSearch() async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString == null || discussionsString.isEmpty) return;

    // Deserialisasi semua diskusi
    final List<dynamic> discussionList = jsonDecode(discussionsString);
    final allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();

    final query = widget.query.toLowerCase(); // Ambil query dalam huruf kecil

    // Filtering: mencari kecocokan pada Judul ATAU Deskripsi
    final results = allDiscussions.where((discussion) {
      final titleMatch = discussion.title.toLowerCase().contains(query);
      final descriptionMatch = discussion.description.toLowerCase().contains(query);
      return titleMatch || descriptionMatch;
    }).toList();

    // Urutkan hasil pencarian berdasarkan tanggal (terbaru di atas)
    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (mounted) {
      setState(() {
        _searchResults = results; // Update state hasil pencarian
      });
    }
  }

  // Menyimpan seluruh daftar diskusi (dipanggil setelah voting)
  Future<void> _updateAndSaveDiscussions(List<Discussion> allDiscussions) async {
    final prefs = await SharedPreferences.getInstance();
    final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
    await prefs.setString('discussions', updatedDiscussionsString);
    _performSearch(); // Muat ulang pencarian untuk merefresh tampilan voting
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
    final currentUser = widget.name;
    final hasUpvoted = discussion.upvotedBy.contains(currentUser);
    final hasDownvoted = discussion.downvotedBy.contains(currentUser);

    // Logika voting (toggle dan saling meniadakan)
    if (isUpvote) {
      hasUpvoted ? discussion.upvotedBy.remove(currentUser) : discussion.upvotedBy.add(currentUser);
      if (!hasUpvoted) discussion.downvotedBy.remove(currentUser);
    } else {
      hasDownvoted ? discussion.downvotedBy.remove(currentUser) : discussion.downvotedBy.add(currentUser);
      if (!hasDownvoted) discussion.upvotedBy.remove(currentUser);
    }

    // Update jumlah total vote
    discussion.upvotes = discussion.upvotedBy.length;
    discussion.downvotes = discussion.downvotedBy.length;

    _updateAndSaveDiscussions(allDiscussions); // Simpan dan muat ulang
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hasil Pencarian: "${widget.query}"', style: const TextStyle(color: Colors.black, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      // Tampilkan pesan jika hasil kosong, atau tampilkan daftar hasil
      body: _searchResults.isEmpty
          ? const Center(child: Text('Tidak ada hasil yang ditemukan.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final discussion = _searchResults[index];
          return _buildDiscussionCard(discussion); // Membangun card hasil
        },
      ),
    );
  }

  // Widget Card untuk setiap Hasil Diskusi
  Widget _buildDiscussionCard(Discussion discussion) {
    final currentUser = widget.name;
    final hasUpvoted = discussion.upvotedBy.contains(currentUser);
    final hasDownvoted = discussion.downvotedBy.contains(currentUser);
    final int answerCount = discussion.answers.length;

    return GestureDetector(
      onTap: () {
        // Navigasi ke Detail Diskusi
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionDetailScreen(
              discussion: discussion,
              currentUser: widget.name,
              currentUserRole: widget.role,
            ),
          ),
        ).then((_) => _performSearch()); // Refresh hasil pencarian setelah kembali
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
            // Tanggal dan status diedit
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                    '${_formatDate(discussion.createdAt)}${discussion.isEdited ? ' (diedit)' : ''}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(discussion.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(discussion.description, style: TextStyle(color: Colors.black, height: 1.4)),
            const SizedBox(height: 12),
            // Penulis dan Role serta Tombol Vote
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Info Penulis
                Row(
                  children: [
                    Text('Oleh : ${discussion.authorName} - ${discussion.authorRole}',
                        style: const TextStyle(color: Colors.grey,fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(width: 8),
                    Icon(
                      discussion.authorRole == 'Guru' ? Icons.school : Icons.face,
                      color: Colors.blueAccent,
                      size: 16,
                    ),
                  ],
                ),
                // Tombol Vote
                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.thumb_up, color: hasUpvoted ? Colors.blueAccent : Colors.green, size: 18),
                      onPressed: () => _handleVote(discussion.id, true),
                    ),
                    const SizedBox(width: 4),
                    Text(discussion.upvotes.toString()),
                    const SizedBox(width: 12),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.thumb_down, color: hasDownvoted ? Colors.orangeAccent : Colors.red, size: 18),
                      onPressed: () => _handleVote(discussion.id, false),
                    ),
                    const SizedBox(width: 4),
                    Text(discussion.downvotes.toString()),
                  ],
                )
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
}