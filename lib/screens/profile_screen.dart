import 'dart:io'; // Untuk File (mengelola/menampilkan foto profil)
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Untuk memilih gambar profil
import 'package:shared_preferences/shared_preferences.dart'; // Untuk penyimpanan data lokal
import 'dart:convert'; // Untuk JSON encode/decode
import 'package:intl/intl.dart'; // Untuk formatting tanggal
import 'package:intl/date_symbol_data_local.dart'; // Untuk inisialisasi locale
import '../models/discussion_model.dart'; // Import model Diskusi
import '../models/user_model.dart'; // Import model User
import 'add_discussion_screen.dart'; // Navigasi ke Tambah Diskusi
import 'animated_welcome_screen.dart'; // Navigasi ke Halaman Welcome (saat Logout)
import 'discussion_detail_screen.dart'; // Navigasi ke Detail Diskusi
import 'edit_discussion_screen.dart'; // Navigasi ke Edit Diskusi

// Widget tampilan Profil Pengguna (StatefulWidget)
class ProfileScreen extends StatefulWidget {
  final String name; // Nama user yang sedang login
  final String role; // Role user yang sedang login

  const ProfileScreen({Key? key, required this.name, required this.role}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _selectedIndex = 2; // Indeks Bottom Nav Bar (2 = Profile)
  List<Discussion> _myDiscussions = []; // Daftar diskusi yang dibuat oleh user ini

  // Data profil user
  String? _profileImagePath;
  String? _userCity;
  String? _userProvince;
  String? _userSchool; // Data sekolah/institusi

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadUserData(); // Muat data profil (gambar, lokasi, sekolah)
    _loadMyDiscussions(); // Muat diskusi yang dibuat oleh user ini
  }

  // Fungsi utilitas untuk memformat tanggal
  String _formatDate(DateTime date) {
    return DateFormat('d MMM y, HH:mm', 'id_ID').format(date);
  }

  // Memuat data profil spesifik dari SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString('users');
    if (usersString != null) {
      final List<dynamic> userList = jsonDecode(usersString);
      // Cari data user yang cocok dengan widget.name
      final userJson = userList.firstWhere(
              (u) => u['name'] == widget.name,
          orElse: () => null // Jika tidak ditemukan
      );

      if (userJson != null && mounted) {
        setState(() {
          // Set state data profil
          _profileImagePath = userJson['profileImagePath'];
          _userCity = userJson['city'];
          _userProvince = userJson['province'];
          _userSchool = userJson['school'];
        });
      }
    }
  }

  // Memuat diskusi yang dibuat oleh user ini
  Future<void> _loadMyDiscussions() async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString != null && discussionsString.isNotEmpty) {
      final List<dynamic> discussionList = jsonDecode(discussionsString);
      final allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();
      if (mounted) {
        setState(() {
          // Urutkan dan filter diskusi berdasarkan penulis
          allDiscussions.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Terbaru di atas
          _myDiscussions = allDiscussions.where((d) => d.authorName == widget.name).toList();
        });
      }
    }
  }

  // Menyimpan path gambar profil yang baru/diubah ke SharedPreferences
  Future<void> _updateProfilePicture(String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString('users');
    if (usersString == null) return;

    List<dynamic> userList = jsonDecode(usersString);
    var allUsers = userList.map((u) => User.fromJson(u)).toList();
    final userIndex = allUsers.indexWhere((user) => user.name == widget.name);

    if (userIndex != -1) {
      // Update path gambar
      allUsers[userIndex].profileImagePath = imagePath;
    }

    // Simpan kembali list user yang sudah diupdate
    final String updatedUsersString = jsonEncode(allUsers.map((u) => u.toJson()).toList());
    await prefs.setString('users', updatedUsersString);

    if (mounted) {
      setState(() {
        _profileImagePath = imagePath; // Update state untuk refresh UI
      });
    }
  }

  // Memilih gambar dari sumber (Galeri/Kamera)
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      _updateProfilePicture(pickedFile.path); // Panggil update dengan path file baru
    }
  }

  // Menampilkan bottom sheet untuk opsi penggantian/penghapusan foto profil
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Ganti Foto dari Galeri'),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
              // Opsi hapus hanya muncul jika sudah ada foto profil
              if (_profileImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Hapus Foto Profil', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    _updateProfilePicture(null); // Hapus path
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  // Menyimpan seluruh daftar diskusi (biasanya setelah vote/hapus)
  Future<void> _updateAndSaveDiscussions(List<Discussion> allDiscussions) async {
    final prefs = await SharedPreferences.getInstance();
    final String updatedDiscussionsString = jsonEncode(allDiscussions.map((d) => d.toJson()).toList());
    await prefs.setString('discussions', updatedDiscussionsString);
    _loadMyDiscussions(); // Muat ulang diskusi saya
  }

  // Menangani Voting (Upvote/Downvote) pada diskusi
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
    discussion.upvotes = discussion.upvotedBy.length;
    discussion.downvotes = discussion.downvotedBy.length;

    _updateAndSaveDiscussions(allDiscussions); // Simpan perubahan
  }

  // Menghapus diskusi
  void _deleteDiscussion(String discussionId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? discussionsString = prefs.getString('discussions');
    if (discussionsString == null || discussionsString.isEmpty) return;

    List<dynamic> discussionList = jsonDecode(discussionsString);
    var allDiscussions = discussionList.map((d) => Discussion.fromJson(d)).toList();
    allDiscussions.removeWhere((d) => d.id == discussionId);

    _updateAndSaveDiscussions(allDiscussions); // Simpan dan muat ulang list
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diskusi berhasil dihapus'), backgroundColor: Colors.red),
      );
    }
  }

  // Menangani proses Log Out
  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Log Out'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Keluar', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigasi ke AnimatedWelcomeScreen dan hapus semua rute di stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const AnimatedWelcomeScreen()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          children: [
            // Header Profile & Tombol Logout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Text(
                      'Profile',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black54),
                  tooltip: 'Log Out',
                  onPressed: _handleLogout, // Panggil fungsi logout
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildProfileCard(), // Card informasi profil
            const SizedBox(height: 30),
            // Label "Diskusi Saya"
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
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
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Text(
                    'Diskusi Saya',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildDiscussionList(), // Daftar diskusi yang dibuat user
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(), // Bottom Nav Bar
    );
  }

  // Widget untuk Card Informasi Profil
  Widget _buildProfileCard() {
    // Logika format lokasi
    String locationText = "";
    if (_userCity != null && _userProvince != null) {
      locationText = "$_userCity, $_userProvince";
    } else if (_userCity != null) {
      locationText = _userCity!;
    } else if (_userProvince != null) {
      locationText = _userProvince!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF364CA7),
        borderRadius: BorderRadius.circular(25),
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
        children: [
          // Foto Profil (bisa di-tap untuk ganti/hapus)
          GestureDetector(
            onTap: _showImagePickerOptions,
            child: CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              // Jika ada path, tampilkan gambar dari file
              backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
              child: _profileImagePath == null
                  ? const Icon(Icons.person, size: 50, color: Color(0xFF364CA7)) // Ikon default
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(widget.role, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          // Menampilkan Sekolah
          if (_userSchool != null && _userSchool!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _userSchool!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            "Asal",
            style: const TextStyle(color: Colors.white70, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          // Menampilkan Lokasi
          if (locationText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                locationText,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Widget untuk Daftar Diskusi Pengguna
  Widget _buildDiscussionList() {
    if (_myDiscussions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('Anda belum membuat diskusi apapun.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(), // Memastikan scrolling dikontrol oleh ListView induk
      itemCount: _myDiscussions.length,
      itemBuilder: (context, index) {
        final discussion = _myDiscussions[index];
        return _buildDiscussionCard(discussion); // Membangun card untuk setiap diskusi
      },
    );
  }

  // Widget Card untuk setiap Diskusi Pengguna
  Widget _buildDiscussionCard(Discussion discussion) {
    final currentUser = widget.name;
    final hasUpvoted = discussion.upvotedBy.contains(currentUser);
    final hasDownvoted = discussion.downvotedBy.contains(currentUser);
    final int answerCount = discussion.answers.length;

    // Format lokasi (sama seperti di Card Profil)
    String locationText = "";
    if (discussion.authorCity != null && discussion.authorProvince != null) {
      locationText = "${discussion.authorCity}, ${discussion.authorProvince}";
    } else if (discussion.authorCity != null) {
      locationText = discussion.authorCity!;
    } else if (discussion.authorProvince != null) {
      locationText = discussion.authorProvince!;
    }

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
        ).then((_) => _loadMyDiscussions()); // Refresh setelah kembali
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
            // BARIS 1: TANGGAL & MENU EDIT/HAPUS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tanggal dan status diedit
                Row(
                  children: [
                    Text(_formatDate(discussion.createdAt),
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    if (discussion.isEdited)
                      const Text(' (diedit)',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontStyle: FontStyle.italic)),
                  ],
                ),
                // Menu Edit/Hapus (hanya jika penulis adalah user yang sedang login)
                if (discussion.authorName == widget.name)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      onSelected: (value) {
                        if (value == 'edit') {
                          // Navigasi ke EditDiscussionScreen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditDiscussionScreen(discussion: discussion),
                            ),
                          ).then((_) => _loadMyDiscussions()); // Refresh setelah edit
                        } else if (value == 'delete') {
                          _deleteDiscussion(discussion.id); // Hapus diskusi
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Hapus'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),

            // JUDUL
            Text(discussion.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),

            // Gambar lampiran (jika ada)
            if (discussion.imagePath != null && discussion.imagePath!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Image.file(File(discussion.imagePath!)),
              ),
            const SizedBox(height: 8),
            Text(discussion.description, style: TextStyle(color: Colors.grey.shade700, height: 1.4)),
            const SizedBox(height: 12),

            // PENULIS DAN ROLE
            Row(
              children: [
                Text('Oleh : ${discussion.authorName} - ${discussion.authorRole}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 8),
                // Ikon Role
                if (discussion.authorRole == 'Guru')
                  const Icon(Icons.school, color: Colors.blueAccent, size: 16)
                else if (discussion.authorRole == 'Siswa')
                  const Icon(Icons.face, color: Colors.blueAccent, size: 16)
                else
                  const Icon(Icons.person, color: Colors.blueAccent, size: 16),
              ],
            ),
            const SizedBox(height: 4),

            // LOKASI DAN VOTE
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
                // Tombol Vote
                Row(
                  children: [
                    // Upvote Button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.thumb_up, color: hasUpvoted ? Colors.blueAccent : Colors.green, size: 18),
                      onPressed: () => _handleVote(discussion.id, true),
                    ),
                    const SizedBox(width: 4),
                    Text(discussion.upvotes.toString()),
                    const SizedBox(width: 12),
                    // Downvote Button
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
            // Jumlah Jawaban
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))],
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
        // Logika navigasi
        if (index == 0) {
          // Home: Pop semua rute hingga rute pertama
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (index == 1) {
          // Add: Navigasi ke AddDiscussionScreen (dengan pushReplacement agar tombol 'back' kembali ke Home)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AddDiscussionScreen(name: widget.name, role: widget.role)),
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