import 'answer_model.dart'; // Import model Jawaban (Answer) yang sudah dibuat sebelumnya

// Model data untuk merepresentasikan satu utas diskusi atau pertanyaan
class Discussion {
  // Properti Wajib (required)
  final String id; // ID unik diskusi
  String title; // Judul diskusi. Tidak final karena bisa diedit.
  String description; // Isi/deskripsi diskusi. Tidak final karena bisa diedit.
  final String category; // Kategori diskusi (misalnya: 'Matematika', 'Fisika')
  final String authorName; // Nama pembuat diskusi
  final String authorRole; // Peran pembuat diskusi
  final DateTime createdAt; // Waktu pembuatan diskusi

  // Properti Opsional dan Metadata
  final String? authorCity; // Kota asal pembuat (opsional)
  final String? authorProvince; // Provinsi asal pembuat (opsional)
  int upvotes; // Jumlah total upvote
  int downvotes; // Jumlah total downvote
  List<String> upvotedBy; // List ID pengguna yang memberikan upvote
  List<String> downvotedBy; // List ID pengguna yang memberikan downvote
  List<Answer> answers; // Daftar objek Answer yang terkait dengan diskusi ini
  String? bestAnswerId; // ID dari jawaban yang ditandai sebagai Jawaban Terbaik (opsional)
  String? imagePath; // Path ke gambar yang diunggah bersama diskusi (opsional)
  bool isEdited; // Flag untuk menunjukkan apakah diskusi pernah diedit

  // Constructor utama
  Discussion({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.authorName,
    required this.authorRole,
    required this.createdAt,
    this.authorCity,
    this.authorProvince,
    this.upvotes = 0,
    this.downvotes = 0,
    List<String>? upvotedBy, // Parameter List<String> untuk upvotedBy
    List<String>? downvotedBy, // Parameter List<String> untuk downvotedBy
    List<Answer>? answers, // Parameter List<Answer> untuk jawaban
    this.bestAnswerId,
    this.imagePath,
    this.isEdited = false,
  })  : this.upvotedBy = upvotedBy ?? [], // Inisialisasi list, jika null set ke list kosong
        this.downvotedBy = downvotedBy ?? [], // Inisialisasi list, jika null set ke list kosong
        this.answers = answers ?? []; // Inisialisasi list jawaban, jika null set ke list kosong

  // Mengubah objek Discussion menjadi JSON untuk disimpan (Serialization)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorCity': authorCity,
      'authorProvince': authorProvince,
      'upvotes': upvotes,
      'downvotes': downvotes,
      'upvotedBy': upvotedBy,
      'downvotedBy': downvotedBy,
      // Penting: Memetakan setiap objek Answer ke representasi JSON-nya
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'bestAnswerId': bestAnswerId,
      'imagePath': imagePath,
      // Konversi DateTime ke string format ISO 8601
      'createdAt': createdAt.toIso8601String(),
      'isEdited': isEdited,
    };
  }

  // Membuat objek Discussion dari JSON saat data dibaca (Deserialization)
  factory Discussion.fromJson(Map<String, dynamic> json) {
    return Discussion(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      authorName: json['authorName'],
      authorRole: json['authorRole'],
      authorCity: json['authorCity'],
      authorProvince: json['authorProvince'],
      // Parsing string ISO 8601 kembali menjadi objek DateTime
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      // Null safety check untuk properti numerik dan boolean
      upvotes: json['upvotes'] ?? 0,
      downvotes: json['downvotes'] ?? 0,
      // Konversi List<dynamic> ke List<String> untuk daftar voting
      upvotedBy: List<String>.from(json['upvotedBy'] ?? []),
      downvotedBy: List<String>.from(json['downvotedBy'] ?? []),
      // Penting: Membaca list JSON 'answers' dan memetakannya kembali ke objek Answer
      answers: (json['answers'] as List<dynamic>?) // Cast ke List<dynamic>?
      // Jika tidak null, map setiap elemen (yang berupa JSON) menjadi objek Answer
          ?.map((answerJson) => Answer.fromJson(answerJson))
          .toList() ?? // Konversi hasil map ke List<Answer>
          [], // Jika 'answers' tidak ada atau null, kembalikan List kosong
      bestAnswerId: json['bestAnswerId'],
      imagePath: json['imagePath'],
      isEdited: json['isEdited'] ?? false,
    );

  }
}