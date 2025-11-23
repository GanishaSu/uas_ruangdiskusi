// Model data untuk merepresentasikan pengguna aplikasi.
class User {
  // Properti Wajib
  final String name;
  final String email;
  final String password; // Catatan: Menyimpan password plaintext di model adalah praktik yang tidak aman. Sebaiknya hanya menyimpan hash password.
  final String role; // Peran pengguna (misalnya: 'Student', 'Teacher', 'Admin')

  // Properti Opsional (diizinkan null)
  final String? school; // Nama sekolah
  final String? province; // Provinsi
  final String? city; // Kota/Kabupaten
  String? profileImagePath; // Path ke foto profil (bisa diubah, jadi tidak final)

  // Constructor utama
  User({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.school,
    this.province,
    this.city,
    this.profileImagePath,
  });

  // Metode untuk mengubah objek User menjadi Map<String, dynamic> (Serialization)
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'school': school,
      'province': province,
      'city': city,
      'profileImagePath': profileImagePath,
    };
  }

  // Factory constructor untuk membuat objek User dari Map<String, dynamic> (Deserialization)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'],
      email: json['email'],
      password: json['password'],
      role: json['role'],
      school: json['school'],
      // Logic fallback: Jika 'province' tidak ada, coba gunakan 'region'
      province: json['province'] ?? json['region'],
      city: json['city'],
      profileImagePath: json['profileImagePath'],
    );
  }
}

// Model data untuk merepresentasikan data Sekolah.
class School {
  final String id; // ID sekolah (misalnya NPSN)
  final String name; // Nama sekolah
  final String city; // Kota/Kabupaten
  final String province; // Provinsi

  School({
    required this.id,
    required this.name,
    required this.city,
    required this.province,
  });

  // Factory constructor untuk membuat objek School dari respons API Sekolah Indonesia.
  factory School.fromJson(Map<String, dynamic> json) {
    return School(
      // Menggunakan NPSN (Nomor Pokok Sekolah Nasional) sebagai ID. Fallback ke string kosong.
      id: json['npsn'] ?? '',
      // Menggunakan key 'sekolah' untuk nama. Fallback ke pesan error.
      name: json['sekolah'] ?? 'Nama Tidak Ditemukan',
      // Menggunakan key yang sesuai dari API. Fallback ke string kosong.
      city: json['kabupaten_kota'] ?? '',
      province: json['propinsi'] ?? '',
    );
  }

  // Override toString() untuk mempermudah penggunaan objek School dalam pencarian atau UI.
  @override
  String toString() => '$name';
}

// Model data untuk merepresentasikan data Provinsi.
class Province {
  final String id; // ID provinsi
  final String name; // Nama provinsi

  Province({required this.id, required this.name});

  // Factory constructor untuk membuat objek Province dari respons API data wilayah.
  factory Province.fromJson(Map<String, dynamic> json) {
    return Province(
      id: json['id'],
      name: json['nama'],
    );
  }

  // Override toString() untuk mempermudah menampilkan nama provinsi di UI.
  @override
  String toString() => name;
}

// Model data untuk merepresentasikan data Kota/Kabupaten.
class City {
  final String id; // ID kota/kabupaten
  final String name; // Nama kota/kabupaten

  City({required this.id, required this.name});

  // Factory constructor untuk membuat objek City dari respons API data wilayah.
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      name: json['nama'],
    );
  }

  // Override toString() untuk mempermudah menampilkan nama kota/kabupaten di UI.
  @override
  String toString() => name;
}