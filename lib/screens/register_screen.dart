import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Untuk penyimpanan data lokal
import 'dart:convert'; // Untuk JSON encode/decode
import '../models/user_model.dart'; // Import Model User, Province, City, School
import '../models/user_model.dart'; // (Duplikat, bisa dihapus)
import '../services/api_service.dart'; // Import Service API untuk data wilayah dan sekolah
import 'login_screen.dart'; // Navigasi ke Login Screen

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>(); // Kunci untuk validasi form

  // Controllers Form Input Dasar
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Controller Kode Guru (Hanya untuk Role Guru)
  final _teacherCodeController = TextEditingController();

  // Controllers & State untuk API Service
  final ApiService _apiService = ApiService();

  // Daerah - PROVINSI (Autocomplete/Search Field)
  List<Province> _provinces = []; // Daftar provinsi yang dimuat dari API
  final TextEditingController _provinceValidationController = TextEditingController(); // Controller untuk validasi Autocomplete
  Province? _selectedProvince; // Objek provinsi yang dipilih

  // Daerah - KOTA (Dropdown Field)
  List<City> _cities = []; // Daftar kota yang dimuat setelah provinsi dipilih
  bool _isLoadingCities = false; // Status loading kota
  City? _selectedCity; // Objek kota yang dipilih
  // Note: Controller teks kota tidak dibutuhkan lagi untuk Dropdown

  // Sekolah (Autocomplete/Search Field)
  final TextEditingController _schoolValidationController = TextEditingController(); // Controller untuk validasi Autocomplete Sekolah
  School? _selectedSchool; // Objek sekolah yang dipilih

  // User Data State
  bool _obscurePassword = true; // State visibility password
  bool _obscureConfirmPassword = true; // State visibility konfirmasi password
  int _selectedRoleIndex = 0; // Role yang dipilih (0: Siswa, 1: Guru)
  List<User> _users = []; // Daftar user yang sudah terdaftar

  @override
  void initState() {
    super.initState();
    _loadUsers(); // Muat data user yang sudah ada
    _loadProvincesData(); // Muat data provinsi saat screen dimulai
  }

  @override
  void dispose() {
    // Memastikan semua controller dibuang
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _teacherCodeController.dispose();
    _schoolValidationController.dispose();
    _provinceValidationController.dispose();
    super.dispose();
  }

  // --- FUNGSI PENGHUBUNG KE SERVICE API ---

  // Memuat data provinsi dari API Service
  Future<void> _loadProvincesData() async {
    final provinces = await _apiService.fetchProvinces();
    if (mounted) {
      setState(() {
        _provinces = provinces;
      });
    }
  }

  // Memuat data kota berdasarkan ID Provinsi yang dipilih
  Future<void> _loadCitiesData(String provinceId) async {
    setState(() {
      _isLoadingCities = true;
      _cities = []; // Reset list kota
      _selectedCity = null; // Reset kota yang dipilih
    });

    final cities = await _apiService.fetchCities(provinceId);

    if (mounted) {
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    }
  }

  // --- LOGIKA PENYIMPANAN USER LOKAL ---

  // Memuat data user yang sudah terdaftar dari SharedPreferences
  Future<void> _loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersString = prefs.getString('users');
    if (usersString != null && usersString.isNotEmpty) {
      final List<dynamic> userList = jsonDecode(usersString);
      if(mounted) {
        setState(() {
          _users = userList.map((user) => User.fromJson(user)).toList();
        });
      }
    }
  }

  // Menyimpan data user yang baru/diperbarui ke SharedPreferences
  Future<void> _saveUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String usersString = jsonEncode(_users.map((user) => user.toJson()).toList());
    await prefs.setString('users', usersString);
  }

  // --- FUNGSI UTAMA PENDAFTARAN ---

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      // 1. Cek Email Unik
      if (_users.any((user) => user.email == _emailController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email ini sudah terdaftar.'), backgroundColor: Colors.orange),
        );
        return;
      }

      // 2. Validasi Autocomplete (Sekolah & Provinsi)
      // Memastikan user memilih dari daftar saran (objek tidak null) DAN teks di field sesuai dengan nama objek yang dipilih.
      if (_selectedSchool == null || _schoolValidationController.text != _selectedSchool!.name) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih sekolah valid dari daftar saran'), backgroundColor: Colors.orange),
        );
        return;
      }
      if (_selectedProvince == null || _provinceValidationController.text != _selectedProvince!.name) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih provinsi valid dari daftar saran'), backgroundColor: Colors.orange),
        );
        return;
      }

      // 3. Validasi Kota (Dropdown)
      if (_selectedCity == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih kota valid dari daftar'), backgroundColor: Colors.orange),
        );
        return;
      }

      // 4. Validasi Kode Guru (Hanya jika Role = Guru)
      if (_selectedRoleIndex == 1) {
        final prefs = await SharedPreferences.getInstance();
        final String? dataString = prefs.getString('teacher_codes_db');

        List<Map<String, dynamic>> teacherCodesData = [];
        if (dataString != null) {
          teacherCodesData = List<Map<String, dynamic>>.from(jsonDecode(dataString));
        }

        String inputCode = _teacherCodeController.text.trim();
        // Cari indeks kode yang cocok
        int codeIndex = teacherCodesData.indexWhere((element) => element['code'] == inputCode);

        if (codeIndex == -1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kode Guru tidak valid/tidak ditemukan!'), backgroundColor: Colors.red),
          );
          return;
        }

        // Cek apakah kode sudah digunakan
        if (teacherCodesData[codeIndex]['isUsed'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kode ini SUDAH DIGUNAKAN oleh guru lain!'), backgroundColor: Colors.red),
          );
          return;
        }

        // Tandai kode terpakai dan simpan data pemakai (email)
        teacherCodesData[codeIndex]['isUsed'] = true;
        teacherCodesData[codeIndex]['usedBy'] = _emailController.text;
        await prefs.setString('teacher_codes_db', jsonEncode(teacherCodesData));
      }

      // Tentukan Role
      final role = _selectedRoleIndex == 0 ? 'Siswa' : 'Guru' ;

      // Buat objek User baru
      final newUser = User(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        role: role,
        school: _selectedSchool?.name,
        province: _selectedProvince?.name,
        city: _selectedCity?.name,
      );

      // Simpan User baru ke list lokal dan SharedPreferences
      setState(() {
        _users.add(newUser);
      });
      await _saveUsers();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pendaftaran berhasil! Silakan masuk.'), backgroundColor: Colors.green),
      );

      // Navigasi ke Login Screen setelah berhasil mendaftar
      if (mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/RuangDiskusi.png', height: 150),
                  const SizedBox(height: 40),

                  // Input Fields
                  _buildNameField(),
                  const SizedBox(height: 20),
                  _buildSchoolSearchField(), // Autocomplete Sekolah
                  const SizedBox(height: 20),
                  _buildProvinceSearchField(), // Autocomplete Provinsi
                  const SizedBox(height: 20),
                  _buildCityDropdown(), // Dropdown Kota/Kabupaten
                  const SizedBox(height: 20),
                  _buildEmailField(),
                  const SizedBox(height: 20),
                  _buildPasswordField(),
                  const SizedBox(height: 20),
                  _buildConfirmPasswordField(),
                  const SizedBox(height: 30),

                  // Pemilih Role
                  const Text('Daftar Sebagai :'),
                  const SizedBox(height: 12),
                  _buildRoleSelector(),
                  const SizedBox(height: 20),

                  // Field Kode Guru (Muncul kondisional)
                  if (_selectedRoleIndex == 1) ...[
                    _buildTeacherCodeField(),
                    const SizedBox(height: 20),
                  ],

                  // Tombol Daftar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleSignUp, // Panggil fungsi pendaftaran
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF364CA7),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Link ke Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Sudah punya akun ? '),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Kembali ke Login Screen
                        },
                        child: const Text('Masuk', style: TextStyle(color: Color(0xFF364CA7), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET INPUT KHUSUS ---

  // Field Kode Verifikasi Guru
  Widget _buildTeacherCodeField() {
    return TextFormField(
      controller: _teacherCodeController,
      decoration: InputDecoration(
        hintText: 'Kode Verifikasi Guru',
        prefixIcon: Icon(Icons.vpn_key, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.orange.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.orange),
        ),
      ),
      // Validator kondisional
      validator: (value) {
        if (_selectedRoleIndex == 1 && (value == null || value.isEmpty)) {
          return 'Kode Guru wajib diisi';
        }
        return null;
      },
    );
  }

  // Field Nama Lengkap
  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        hintText: 'Nama Lengkap',
        prefixIcon: Icon(Icons.person_outline, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
    );
  }

  // Field Autocomplete Pencarian Sekolah
  Widget _buildSchoolSearchField() {
    return Autocomplete<School>(
      displayStringForOption: (School option) => option.name, // Teks yang ditampilkan di field saat terpilih
      optionsBuilder: (TextEditingValue textEditingValue) {
        _schoolValidationController.text = textEditingValue.text; // Update controller validasi
        // Reset selectedSchool jika user mengetik ulang (tidak memilih dari saran)
        if (_selectedSchool != null && textEditingValue.text != _selectedSchool!.name) {
          setState(() => _selectedSchool = null);
        }
        // Panggil API Service untuk mencari sekolah (min. 3 karakter)
        return _apiService.searchSchools(textEditingValue.text);
      },
      onSelected: (School selection) {
        // Saat saran dipilih
        setState(() {
          _selectedSchool = selection;
          _schoolValidationController.text = selection.name; // Update controller validasi
        });
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        // Tampilan field input
        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            hintText: 'Ketik Nama Sekolah (min. 3 huruf)',
            prefixIcon: Icon(Icons.school_outlined, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Nama sekolah tidak boleh kosong' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        // Tampilan daftar saran yang muncul
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250), // Batasi tinggi daftar saran
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final School option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: ListTile(title: Text(option.name)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // Field Autocomplete Pencarian Provinsi
  Widget _buildProvinceSearchField() {
    return Autocomplete<Province>(
      displayStringForOption: (Province option) => option.name,
      optionsBuilder: (TextEditingValue textEditingValue) {
        _provinceValidationController.text = textEditingValue.text;
        // Hanya tampilkan saran jika ada input
        if (textEditingValue.text.isEmpty) {
          return const Iterable<Province>.empty();
        }
        // Filter daftar provinsi yang sudah dimuat (_provinces)
        return _provinces.where((Province option) {
          return option.name.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (Province selection) {
        setState(() {
          _selectedProvince = selection;
          _provinceValidationController.text = selection.name;
          _selectedCity = null; // Reset kota
          _cities = []; // Reset list kota
        });
        // Panggil fungsi untuk memuat data kota/kabupaten
        _loadCitiesData(selection.id);
        FocusScope.of(context).unfocus();
      },
      fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
        return TextFormField(
          controller: fieldController,
          focusNode: fieldFocusNode,
          decoration: InputDecoration(
            hintText: 'Cari Asal Provinsi',
            prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey.shade600),
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          ),
          validator: (value) => (value == null || value.isEmpty) ? 'Provinsi tidak boleh kosong' : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        // Tampilan daftar saran dengan batas tinggi
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final Province option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: ListTile(title: Text(option.name)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  // --- WIDGET KOTA (DROPDOWN DENGAN BATAS TINGGI) ---
  Widget _buildCityDropdown() {
    return DropdownButtonFormField<City>(
      value: _selectedCity,
      isExpanded: true,
      menuMaxHeight: 300, // Kunci: Batas tinggi menu agar tidak memenuhi layar
      decoration: InputDecoration(
        hintText: 'Asal Kota/Kabupaten',
        prefixIcon: Icon(Icons.location_city, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      // Teks hint saat Dropdown dinonaktifkan
      disabledHint: Text(_selectedProvince == null ? 'Pilih provinsi dulu' : (_isLoadingCities ? 'Memuat kota...' : 'Pilih Kota')),

      // Tombol dinonaktifkan jika _selectedProvince null atau sedang loading
      onChanged: (_selectedProvince == null || _isLoadingCities) ? null : (City? newValue) {
        setState(() {
          _selectedCity = newValue;
        });
      },

      // Membangun daftar item (City) dari list _cities
      items: _cities.map((City city) {
        return DropdownMenuItem<City>(
          value: city,
          child: Text(city.name, overflow: TextOverflow.ellipsis),
        );
      }).toList(),

      validator: (value) => value == null ? 'Kota/Kabupaten tidak boleh kosong' : null,
    );
  }

  // Field Email
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        hintText: 'Email',
        prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
        if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) return 'Format email tidak valid';
        return null;
      },
    );
  }

  // Field Password
  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Password',
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade600),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'Password tidak boleh kosong' : (value.length < 6 ? 'Min 6 karakter' : null),
    );
  }

  // Field Konfirmasi Password
  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        hintText: 'Konfirmasi Password',
        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade600),
          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
      ),
      // Validasi: harus sama dengan isi field password
      validator: (value) => value != _passwordController.text ? 'Password tidak cocok' : null,
    );
  }

  // Pemilih Role (Siswa / Guru)
  Widget _buildRoleSelector() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(30)),
      child: Row(children: [_buildRoleButton('Siswa', 0), _buildRoleButton('Guru', 1)]),
    );
  }

  // Tombol individual dalam Role Selector
  Widget _buildRoleButton(String text, int index) {
    bool isSelected = _selectedRoleIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedRoleIndex = index;
            // Jika memilih Siswa, hapus Kode Guru (jika ada)
            if (index == 0) _teacherCodeController.clear();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF364CA7) : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}