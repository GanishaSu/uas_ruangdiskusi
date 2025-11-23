// Model data untuk setiap jawaban
class Answer {
  // Properti Wajib (required)
  final String id; // ID unik jawaban (biasanya dihasilkan oleh database)
  final String author; // Nama atau ID pengguna yang menjawab
  final String authorRole; // Peran pengguna (misalnya: 'Pelajar', 'Guru', 'Pakar')
  String content; // Konten atau isi dari jawaban. Properti ini tidak final karena bisa diedit.
  final DateTime createdAt; // Waktu pembuatan jawaban.

  // Properti Opsional dan Metadata
  final String? authorCity; // Kota asal penulis (opsional)
  final String? authorProvince; // Provinsi asal penulis (opsional)
  int upvotes; // Jumlah total upvote (default 0)
  int downvotes; // Jumlah total downvote (default 0)
  List<String> upvotedBy; // List ID pengguna yang memberikan upvote
  List<String> downvotedBy; // List ID pengguna yang memberikan downvote
  bool isBestAnswer; // Flag yang menandai apakah jawaban ini adalah jawaban terbaik (default false)
  String? imagePath; // Path ke gambar yang diunggah bersama jawaban (opsional)
  bool isEdited; // Flag untuk menunjukkan apakah jawaban pernah diedit (default false)

  // Constructor utama
  Answer({
    required this.id,
    required this.author,
    required this.authorRole,
    required this.content,
    required this.createdAt,
    this.authorCity,
    this.authorProvince,
    this.upvotes = 0,
    this.downvotes = 0,
    // Parameter List<String> di-null check di initializer list
    List<String>? upvotedBy,
    List<String>? downvotedBy,
    this.isBestAnswer = false,
    this.imagePath,
    this.isEdited = false,
  })  : this.upvotedBy = upvotedBy ?? [], // Inisialisasi list, jika null set ke list kosong
        this.downvotedBy = downvotedBy ?? []; // Inisialisasi list, jika null set ke list kosong

  // Mengubah objek menjadi JSON untuk disimpan (Serialization)
  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'authorRole': authorRole,
    'content': content,
    'authorCity': authorCity,
    'authorProvince': authorProvince,
    'upvotes': upvotes,
    'downvotes': downvotes,
    'upvotedBy': upvotedBy,
    'downvotedBy': downvotedBy,
    'isBestAnswer': isBestAnswer,
    'imagePath': imagePath,
    // Konversi DateTime ke string format ISO 8601 agar mudah disimpan dan dibaca kembali
    'createdAt': createdAt.toIso8601String(),
    'isEdited': isEdited,
  };

  // Membuat objek dari JSON saat data dibaca (Deserialization)
  // Factory constructor digunakan karena mengembalikan instance baru, tidak selalu instance dari kelas itu sendiri
  factory Answer.fromJson(Map<String, dynamic> json) => Answer(
    id: json['id'],
    author: json['author'],
    authorRole: json['authorRole'],
    content: json['content'],
    authorCity: json['authorCity'],
    authorProvince: json['authorProvince'],
    // Parsing string ISO 8601 kembali menjadi objek DateTime
    // Handle null case dengan memberikan DateTime.now() sebagai fallback
    createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    // Null safety check: menggunakan operator ?? untuk memberikan nilai default 0 jika key tidak ada
    upvotes: json['upvotes'] ?? 0,
    downvotes: json['downvotes'] ?? 0,
    // Konversi data dari JSON (biasanya List<dynamic>) menjadi List<String>
    upvotedBy: List<String>.from(json['upvotedBy'] ?? []),
    downvotedBy: List<String>.from(json['downvotedBy'] ?? []),
    // Null safety check: memberikan nilai default false
    isBestAnswer: json['isBestAnswer'] ?? false,
    imagePath: json['imagePath'],
    isEdited: json['isEdited'] ?? false,
  );
}