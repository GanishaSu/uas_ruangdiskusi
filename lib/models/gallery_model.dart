import 'package:flutter/material.dart'; // Mengimpor material.dart untuk tipe data seperti Color dan Offset

// Model data yang merepresentasikan garis atau coretan tunggal yang digambar pengguna.
class DrawnLine {
  // Daftar titik (koordinat x, y) yang membentuk garis.
  // Garis biasanya dirender dengan menghubungkan titik-titik ini.
  final List<Offset> points;

  // Warna yang digunakan untuk menggambar garis.
  final Color color;

  // Ketebalan garis.
  final double width;

  // Flag opsional yang menunjukkan apakah garis ini berfungsi sebagai penanda (marker)
  // atau coretan biasa. Marker mungkin memiliki perilaku rendering yang berbeda (misalnya semi-transparan).
  final bool isMarker;

  // Constructor untuk membuat objek DrawnLine.
  DrawnLine(this.points, this.color, this.width, {this.isMarker = false});
}

// Model data yang merepresentasikan catatan teks statis yang diletakkan pada kanvas.
class TextNote {
  // Posisi (koordinat x, y) tempat teks akan ditempatkan pada kanvas.
  final Offset position;

  // Isi string dari catatan teks.
  final String text;

  // Warna teks.
  final Color color;

  // Ukuran font teks.
  final double size;

  // Constructor untuk membuat objek TextNote.
  TextNote({
    required this.position,
    required this.text,
    required this.color,
    required this.size,
  });
}