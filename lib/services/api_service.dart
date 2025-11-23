import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart'; // Import model data yang digunakan (misalnya: Province, City, School)


// Kelas ApiService bertanggung jawab untuk semua interaksi jaringan (HTTP Requests)
class ApiService {
  // Base URL untuk API Data Sekolah Indonesia
  final String _schoolApiBaseUrl = "https://api-sekolah-indonesia.vercel.app";
  // Base URL untuk API Data Wilayah Indonesia (Provinsi, Kota/Kabupaten)
  final String _regionApiBaseUrl = "https://ibnux.github.io/data-indonesia";

  // --- 1. Ambil Provinsi ---
  // Metode asinkron untuk mengambil daftar provinsi
  Future<List<Province>> fetchProvinces() async {
    try {
      // Melakukan permintaan GET ke endpoint provinsi
      final response = await http.get(Uri.parse('$_regionApiBaseUrl/provinsi.json'));

      // Memeriksa status kode HTTP. Kode 200 berarti sukses.
      if (response.statusCode == 200) {
        // Mendecode body respons dari JSON String menjadi List<dynamic>
        final List<dynamic> data = jsonDecode(response.body);

        // Memetakan (map) setiap elemen JSON menjadi objek Province menggunakan constructor fromJson
        return data.map((json) => Province.fromJson(json)).toList();
      } else {
        // Melempar exception jika respons gagal (misalnya 404, 500)
        throw Exception('Gagal memuat provinsi');
      }
    } catch (e) {
      // Menangani error jaringan atau error decoding/parsing
      print('Error fetching provinces: $e');
      return []; // Mengembalikan daftar kosong jika terjadi error
    }
  }

  // --- 2. Ambil Kota berdasarkan ID Provinsi ---
  // Metode asinkron untuk mengambil daftar kota/kabupaten
  Future<List<City>> fetchCities(String provinceId) async {
    try {
      // Permintaan GET dengan menyisipkan provinceId ke dalam URL (URL Interpolation)
      final response = await http.get(Uri.parse('$_regionApiBaseUrl/kabupaten/$provinceId.json'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Memetakan (map) setiap elemen JSON menjadi objek City
        return data.map((json) => City.fromJson(json)).toList();
      } else {
        throw Exception('Gagal memuat kota');
      }
    } catch (e) {
      print('Error fetching cities: $e');
      return [];
    }
  }

  // --- 3. Cari Sekolah (Dengan Filter Manual) ---
  // Metode asinkron untuk mencari sekolah berdasarkan query
  Future<List<School>> searchSchools(String query) async {
    // Validasi: Abaikan permintaan jika query terlalu pendek (< 3 karakter)
    if (query.length < 3) return [];

    print('API Service: Mencari "$query"');
    // Konversi query menjadi huruf kecil (case-insensitive search)
    final String lowercaseQuery = query.toLowerCase();

    try {
      // Melakukan permintaan GET ke endpoint sekolah.
      // Parameter 'perPage=1000' digunakan untuk mengambil data mentah dalam jumlah besar.
      final response = await http.get(
          Uri.parse('$_schoolApiBaseUrl/sekolah?q=$lowercaseQuery&perPage=1000')
      );

      if (response.statusCode == 200) {
        // Decode respons utama
        Map<String, dynamic> responseData = jsonDecode(response.body);
        // Ambil list data sekolah yang berada di key 'dataSekolah'
        final data = responseData['dataSekolah'];

        // Cek jika data kosong atau bukan berupa List
        if (data == null || data is! List) return [];

        List<dynamic> rawList = data;

        // Logika Filter Manual (Client-side filtering)
        // Ini adalah langkah filter tambahan yang dilakukan di sisi aplikasi (bukan API)
        List<dynamic> filteredList = rawList.where((json) {
          // Ambil nama sekolah, konversi ke string dan lowercase
          String schoolName = (json['sekolah'] ?? '').toString().toLowerCase();
          // Filter: Hanya ambil data yang nama sekolahnya mengandung (contains) query
          return schoolName.contains(lowercaseQuery);
        }).toList();

        // Map list yang sudah difilter menjadi objek School
        return filteredList.map((json) => School.fromJson(json)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching schools: $e');
      return [];
    }
  }
}