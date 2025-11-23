import 'package:flutter/material.dart';
import 'add_discussion_screen.dart'; // Navigasi ke Tambah Diskusi
import 'profile_screen.dart'; // Navigasi ke Profil
import 'discussion_list_screen.dart'; // Navigasi ke Daftar Diskusi per Kategori
import 'search_results_screen.dart'; // Navigasi ke Hasil Pencarian

// Data models sederhana untuk setiap item kategori di grid
class CategoryItem {
  final String name; // Nama kategori
  final IconData icon; // Ikon yang merepresentasikan kategori

  CategoryItem({required this.name, required this.icon});
}

// Widget utama (Stateful) untuk tampilan Beranda
class HomeScreen extends StatefulWidget {
  final String name; // Nama user yang sedang login
  final String role; // Role user yang sedang login

  const HomeScreen({Key? key, required this.name, required this.role}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller untuk text field pencarian
  final TextEditingController _searchController = TextEditingController();

  // Daftar kategori yang diinisialisasi dengan nama dan pemetaan ikon
  final List<CategoryItem> categories = [
    'Bahasa', 'Biologi', 'Matematika', 'Geografi', 'Fisika',
    'Kimia', 'Seni Budaya', 'Ekonomi', 'IT'
  ].map((name) {
    IconData icon;
    // Pemilihan ikon berdasarkan nama kategori
    switch (name) {
      case 'Bahasa':
        icon = Icons.translate;
        break;
      case 'Biologi':
        icon = Icons.biotech;
        break;
      case 'Matematika':
        icon = Icons.calculate;
        break;
      case 'Geografi':
        icon = Icons.public;
        break;
      case 'Fisika':
        icon = Icons.science_outlined;
        break;
      case 'Kimia':
        icon = Icons.science;
        break;
      case 'Seni Budaya':
        icon = Icons.palette;
        break;
      case 'Ekonomi':
        icon = Icons.monetization_on;
        break;
      case 'IT':
        icon = Icons.computer;
        break;
      default:
        icon = Icons.help;
    }
    return CategoryItem(name: name, icon: icon);
  }).toList();


  int _selectedIndex = 0; // Indeks Bottom Nav Bar (Home = 0)

  @override
  void dispose() {
    // Memastikan controller dibuang saat widget dihancurkan
    _searchController.dispose();
    super.dispose();
  }

  // Fungsi untuk menangani pencarian
  void _handleSearch(String query) {
    if (query.isNotEmpty) {
      // Navigasi ke SearchResultsScreen dengan membawa query dan info user
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SearchResultsScreen(
            query: query,
            name: widget.name,
            role: widget.role,
          ),
        ),
      );
      // Opsi: Clear text field setelah pencarian
      // _searchController.clear();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          children: [
            // Logo Aplikasi
            Center(
              child: Image.asset(
                'assets/icons/RuangDiskusi.png',
                height: 145,
              ),
            ),
            const SizedBox(height: 10),
            // Ucapan Selamat Datang (dengan nama user yang login)
            Center(
              child: Text(
                'Selamat Datang, ${widget.name}!',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            _buildSearchCard(), // Widget Card Pencarian
            const SizedBox(height: 30),
            // Label "Pilih Kategori"
            Center(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F7F7),
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
                    'Pilih Kategori',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCategoryGrid(), // Grid Kategori
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(), // Bottom Navigation Bar
    );
  }

  // Widget untuk Card Pencarian (Search Card)
  Widget _buildSearchCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: const Color(0xFF364CA7),
        borderRadius: BorderRadius.circular(40),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'Cari topik yang ingin\n kamu ketahui!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 15),
          // Input Text Field Pencarian
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Masukkan kata kunci',
              hintStyle: TextStyle(color: Colors.grey[600]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            // Menjalankan fungsi _handleSearch saat tombol 'enter' ditekan
            onSubmitted: _handleSearch,
          ),
        ],
      ),
    );
  }

  // Widget untuk Grid Tampilan Kategori
  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true, // Memastikan GridView mengambil ukuran kontennya
      physics: const NeverScrollableScrollPhysics(), // Menonaktifkan scrolling GridView (scrolling dikontrol oleh ListView induk)
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 kolom
        crossAxisSpacing: 38, // Jarak horizontal
        mainAxisSpacing: 20, // Jarak vertikal
        childAspectRatio: 1, // Rasio aspek 1:1 (kotak)
      ),
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryItem(category.icon, category.name); // Membangun item grid individual
      },
    );
  }

  // Widget untuk item Kategori individual di grid
  Widget _buildCategoryItem(IconData icon, String name) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke DiscussionListScreen saat di-tap
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiscussionListScreen(
              categoryName: name, // Kirim nama kategori
              categoryIcon: icon, // Kirim ikon kategori
              name: widget.name,
              role: widget.role,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200, width: 0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 35, color: const Color(0xFF364CA7)), // Ikon
            const SizedBox(height: 8),
            Text(
              name, // Nama Kategori
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF364CA7),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
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
          _buildNavItem(Icons.home, 'Home', 0), // Item Home
          _buildNavItem(Icons.add_circle, 'Add', 1), // Item Add
          _buildNavItem(Icons.person, 'Profile', 2), // Item Profile
        ],
      ),
    );
  }

  // Widget Item Navigasi
  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        // Logika navigasi berdasarkan indeks yang ditekan
        if (index == 1) {
          // Navigasi ke Add Discussion Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDiscussionScreen(name: widget.name, role: widget.role),
            ),
          );
        } else if (index == 2) {
          // Navigasi ke Profile Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProfileScreen(name: widget.name, role: widget.role),
            ),
          );
        } else {
          // Hanya update state jika index adalah 0 (Home), meskipun saat ini tidak melakukan navigasi
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            // Warna ikon disesuaikan dengan status selected
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
            size: 28,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            // Warna teks disesuaikan dengan status selected
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}