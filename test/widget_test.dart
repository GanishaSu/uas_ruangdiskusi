// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:uas_ruangdiskusi/main.dart';


// void main() {
//   testWidgets('Counter increments smoke test', (WidgetTester tester) async {
//     // Build our app and trigger a frame.
//     await tester.pumpWidget( RuangDiskusiPelajarApp());
//
//     // Verify that our counter starts at 0.
//     expect(find.text('0'), findsOneWidget);
//     expect(find.text('1'), findsNothing);
//
//     // Tap the '+' icon and trigger a frame.
//     await tester.tap(find.byIcon(Icons.add));
//     await tester.pump();
//
//     // Verify that our counter has incremented.
//     expect(find.text('0'), findsNothing);
//     expect(find.text('1'), findsOneWidget);
//   });
// }

void main() {
  // --- KODE TES DIPERBARUI AGAR SESUAI DENGAN APLIKASI ANDA ---
  testWidgets('Welcome screen animation test', (WidgetTester tester) async {
    // Build aplikasi kita dan trigger frame.
    await tester.pumpWidget(const RuangDiskusiPelajarApp());

    // 1. Verifikasi bahwa logo (Image) muncul,
    //    tetapi tombol "Masuk" dan "Daftar" BELUM muncul.
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Masuk'), findsNothing);
    expect(find.text('Daftar'), findsNothing);

    // 2. Tunggu animasi selesai.
    // Kita tunggu 3 detik untuk memastikan semua animasi selesai.
    await tester.pump(const Duration(seconds: 3));

    // 3. Setelah animasi, verifikasi bahwa tombol "Masuk" dan "Daftar" SEKARANG MUNCUL.
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Daftar'), findsOneWidget);
  });
}
