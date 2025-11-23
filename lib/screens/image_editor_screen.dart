import 'dart:typed_data'; // Untuk Uint8List (data byte gambar)
import 'dart:math' as math; // Untuk fungsi matematika (rotasi, clamp)
import 'dart:ui' as ui; // Untuk ImageByteFormat
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // Untuk RenderRepaintBoundary
import '../models/gallery_model.dart'; // Import model DrawnLine dan TextNote

// Enum untuk mendefinisikan mode editor saat ini
enum EditorMode { view, draw, erase, marker, text }

// Widget utama editor, menerima data byte gambar
class ImageEditorScreen extends StatefulWidget {
  final Uint8List imageBytes; // Data mentah byte dari gambar yang akan diedit
  const ImageEditorScreen({super.key, required this.imageBytes});

  @override
  State<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  final GlobalKey _canvasKey = GlobalKey(); // Key untuk menangkap RenderObject (digunakan saat export)

  EditorMode mode = EditorMode.view; // Mode editor saat ini (default: View/Pan)
  Color selectedColor = Colors.red; // Warna yang dipilih untuk menggambar/teks
  double strokeWidth = 4.0; // Ketebalan coretan/marker
  double textSize = 18.0; // Ukuran teks

  List<DrawnLine> lines = []; // Daftar semua coretan yang sudah dibuat
  List<TextNote> notes = []; // Daftar semua catatan teks
  DrawnLine? currentLine; // Coretan yang sedang digambar

  // Variabel untuk Transformasi Gambar (Pan, Zoom, Rotate)
  double _scale = 1.0;
  double _rotation = 0.0;
  Offset _offset = Offset.zero;

  // Variabel untuk menyimpan nilai awal saat gesture dimulai
  double _startScale = 1.0;
  double _startRotation = 0.0;
  Offset _startOffset = Offset.zero;
  Offset _startFocalPoint = Offset.zero;
  Offset _normalizedOffset = Offset.zero;

  Offset? _eraserPos; // Posisi eraser saat ini (untuk visualisasi)

  // Double-tap zoom
  double _doubleTapZoom = 2.0; // Tingkat zoom saat double-tap
  bool _zoomed = false; // Status apakah sedang dalam kondisi zoom

  // Fungsi untuk mengkonversi posisi lokal layar ke posisi relatif gambar (setelah transformasi)
  Offset _toImagePosition(Offset localPos) {
    final dx = localPos.dx - _offset.dx;
    final dy = localPos.dy - _offset.dy;
    // Rotasi balik (invers)
    final cosR = math.cos(-_rotation);
    final sinR = math.sin(-_rotation);
    // Transformasi dan Skala balik
    final x = (dx * cosR - dy * sinR) / _scale;
    final y = (dx * sinR + dy * cosR) / _scale;
    return Offset(x, y);
  }

  // Menampilkan dialog untuk input teks
  Future<String?> _showTextDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Text"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter your text"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // --- SCALE GESTURE HANDLERS ---

  // Dipanggil saat gesture skala/pan dimulai
  void _handleScaleStart(ScaleStartDetails details) {
    // Simpan status awal untuk perhitungan delta
    _startScale = _scale;
    _startRotation = _rotation;
    _startOffset = _offset;
    _startFocalPoint = details.focalPoint;

    if (mode == EditorMode.view) {
      // Hitung offset relatif terhadap titik fokus saat ini untuk zoom/pan yang mulus
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
    } else if (mode == EditorMode.draw || mode == EditorMode.marker) {
      // Mode Draw: Mulai garis baru
      final pos = _toImagePosition(details.localFocalPoint);
      currentLine = DrawnLine([pos], selectedColor, strokeWidth, isMarker: mode == EditorMode.marker);
      lines.add(currentLine!);
    } else if (mode == EditorMode.erase) {
      // Mode Erase: Mulai hapus
      final pos = _toImagePosition(details.localFocalPoint);
      _eraserPos = pos;
      // Hapus coretan yang bersinggungan dengan titik awal
      lines.removeWhere(
              (line) => line.points.any((p) => (p - pos).distance <= (line.width + strokeWidth * 0.5)));
      // Hapus teks yang bersinggungan
      notes.removeWhere((n) => (n.position - pos).distance <= 20);
    }
  }

  // Dipanggil saat gesture skala/pan diperbarui
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (mode == EditorMode.view) {
      // Mode View: Hitung transformasi baru
      setState(() {
        _scale = (_startScale * details.scale).clamp(0.2, 5.0); // Batasi zoom antara 0.2x hingga 5.0x
        _rotation = _startRotation + details.rotation;
        // Hitung offset baru berdasarkan titik fokus dan skala
        _offset = details.focalPoint - _normalizedOffset * _scale;
      });
    } else if (mode == EditorMode.draw && currentLine != null) {
      // Mode Draw: Tambahkan titik baru ke garis saat ini
      final pos = _toImagePosition(details.localFocalPoint);
      setState(() => currentLine!.points.add(pos));
    } else if (mode == EditorMode.erase) {
      // Mode Erase: Perbarui posisi eraser dan hapus elemen yang bersinggungan
      final pos = _toImagePosition(details.localFocalPoint);
      setState(() {
        _eraserPos = pos;
        lines.removeWhere(
                (line) => line.points.any((p) => (p - pos).distance <= (line.width + strokeWidth * 0.5)));
        notes.removeWhere((n) => (n.position - pos).distance <= 20);
      });
    }
  }

  // Dipanggil saat gesture skala/pan berakhir
  void _handleScaleEnd(ScaleEndDetails details) {
    currentLine = null; // Hentikan gambar garis
    _eraserPos = null; // Hapus visualisasi eraser
  }

  // Menangani Double Tap untuk zoom in/out cepat
  void _handleDoubleTap(Offset localPos) {
    if (mode != EditorMode.view) return; // Hanya berfungsi di mode View

    setState(() {
      if (!_zoomed) {
        // Zoom In: Hitung skala baru dan offset agar fokus tetap di titik double-tap
        final newScale = _doubleTapZoom;
        _offset = localPos - (localPos - _offset) * (newScale / _scale);
        _scale = newScale;
      } else {
        // Zoom Out: Kembalikan ke posisi dan skala awal
        _scale = 1.0;
        _offset = Offset.zero;
        _rotation = 0.0;
      }
      _zoomed = !_zoomed;
    });
  }

  // EXPORT FUNGSI
  Future<Uint8List?> _exportImage() async {
    try {
      // Dapatkan RenderObject dari RepaintBoundary menggunakan _canvasKey
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      // Render boundary ke objek ui.Image dengan pixelRatio yang lebih tinggi (3.0)
      final image = await boundary.toImage(pixelRatio: 3.0);
      // Konversi ui.Image ke byte data PNG
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List(); // Kembalikan Uint8List
    } catch (e) {
      print("Error exporting image: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Image Editor"),
        actions: [
          // Tombol Selesai/Simpan
          IconButton(
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            onPressed: () async {
              final result = await _exportImage(); // Ekspor gambar
              Navigator.pop(context, result); // Kirim hasil byte kembali ke screen sebelumnya
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Area Kanvas (Gambar dan Coretan)
          Positioned.fill(
            top: 70,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) async {
                final pos = _toImagePosition(details.localPosition);
                if (mode == EditorMode.marker) {
                  // Mode Marker: Tambahkan garis titik (marker)
                  setState(() {
                    lines.add(DrawnLine([pos], selectedColor, strokeWidth, isMarker: true));
                  });
                } else if (mode == EditorMode.text) {
                  // Mode Text: Tampilkan dialog input teks
                  final text = await _showTextDialog();
                  if (text != null && text.isNotEmpty) {
                    setState(() {
                      notes.add(TextNote(
                        position: pos,
                        text: text,
                        color: selectedColor,
                        size: textSize,
                      ));
                    });
                  }
                }
              },
              onDoubleTapDown: (details) => _handleDoubleTap(details.localPosition), // Double-tap zoom
              child: RepaintBoundary( // Penting untuk menangkap gambar hasil akhir
                key: _canvasKey,
                child: Stack(
                  children: [
                    // Gambar Asli (Diterapkan Transformasi)
                    Transform(
                      alignment: Alignment.topLeft,
                      transform: Matrix4.identity()
                        ..translate(_offset.dx, _offset.dy) // Pan
                        ..rotateZ(_rotation) // Rotate
                        ..scale(_scale), // Scale
                      child: Image.memory(widget.imageBytes, fit: BoxFit.contain),
                    ),
                    // CustomPainter untuk Coretan (di atas gambar)
                    GestureDetector(
                      onScaleStart: _handleScaleStart,
                      onScaleUpdate: _handleScaleUpdate,
                      onScaleEnd: _handleScaleEnd,
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _EditorPainter(
                          lines,
                          notes,
                          _eraserPos,
                          strokeWidth,
                          // Kirim parameter transformasi untuk digunakan Painter dalam perhitungan posisi eraser
                          offset: _offset,
                          scale: _scale,
                          rotation: _rotation,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Toolbar Kontrol (di atas kanvas)
          Positioned(top: 0, left: 0, right: 0, child: _buildToolbar()),
        ],
      ),
    );
  }

  // Widget Toolbar
  Widget _buildToolbar() {
    return Container(
      color: Colors.grey.shade200,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tombol Mode Editor
            _toolButton(Icons.pan_tool, EditorMode.view),
            _toolButton(Icons.brush, EditorMode.draw),
            _toolButton(Icons.cleaning_services, EditorMode.erase),
            _toolButton(Icons.circle, EditorMode.marker),
            _toolButton(Icons.text_fields, EditorMode.text),
            const SizedBox(width: 20),
            // Pemilih Warna
            _colorCircle(Colors.red),
            _colorCircle(Colors.green),
            _colorCircle(Colors.blue),
            _colorCircle(Colors.yellow),
            _colorCircle(Colors.black),
            const SizedBox(width: 20),
            // Slider Ketebalan Coretan (Stroke Width)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Stroke", style: TextStyle(fontSize: 12)),
                SizedBox(
                  width: 120,
                  child: Slider(
                    min: 1,
                    max: 40,
                    value: strokeWidth,
                    onChanged: (v) => setState(() => strokeWidth = v),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            // Dropdown Ukuran Teks (Text Size)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Text", style: TextStyle(fontSize: 12)),
                DropdownButton<double>(
                  value: textSize,
                  items: [12, 14, 16, 18, 20, 24, 28, 32, 36, 40, 48, 56, 60]
                      .map((size) => DropdownMenuItem(
                    value: size.toDouble(),
                    child: Text(size.toString(), style: const TextStyle(fontSize: 14)),
                  ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => textSize = value);
                  },
                  underline: Container(height: 1, color: Colors.grey),
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper untuk Tombol Tool
  Widget _toolButton(IconData icon, EditorMode m) {
    final active = mode == m;
    return IconButton(
      onPressed: () => setState(() => mode = m),
      icon: Icon(icon, color: active ? Colors.blue : Colors.black54),
    );
  }

  // Helper untuk Lingkaran Warna
  Widget _colorCircle(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          // Border menandakan warna yang sedang aktif
          border: Border.all(color: selectedColor == color ? Colors.black : Colors.white, width: 2),
        ),
      ),
    );
  }
}

// --- CUSTOM PAINTER UNTUK MERENDER CORETAAN DAN TEKS ---
class _EditorPainter extends CustomPainter {
  final List<DrawnLine> lines; // Coretan yang sudah selesai
  final List<TextNote> notes; // Catatan teks
  final Offset? eraserPos; // Posisi eraser (untuk visualisasi)
  final double strokeWidth; // Ketebalan eraser visual

  // Transformasi (dilewatkan dari state widget)
  final Offset offset;
  final double scale;
  final double rotation;

  _EditorPainter(this.lines, this.notes, this.eraserPos, this.strokeWidth,
      {this.offset = Offset.zero, this.scale = 1.0, this.rotation = 0.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Terapkan Transformasi pada canvas agar coretan mengikuti gambar
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    canvas.rotate(rotation);
    canvas.scale(scale);

    // 1. Gambar Coretan (Lines)
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      if (line.isMarker && line.points.isNotEmpty) {
        // Render Marker (diasumsikan sebagai lingkaran besar di titik pertama)
        canvas.drawCircle(line.points.first, line.width * 2, paint);
      } else if (line.points.length == 1) {
        // Render titik tunggal (sebagai lingkaran kecil)
        canvas.drawCircle(line.points.first, line.width / 2, paint);
      } else if (line.points.length > 1) {
        // Render Path (garis coretan)
        final path = Path()..moveTo(line.points.first.dx, line.points.first.dy);
        for (int i = 1; i < line.points.length; i++) {
          path.lineTo(line.points[i].dx, line.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    // 2. Gambar Catatan Teks (Text Notes)
    for (final note in notes) {
      final textPainter = TextPainter(
        text: TextSpan(text: note.text, style: TextStyle(color: note.color, fontSize: note.size)),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, note.position); // Render teks di posisi yang tersimpan
    }

    // 3. Gambar Visualisasi Eraser (jika sedang mode erase)
    if (eraserPos != null) {
      final eraserPaint = Paint()
        ..color = Colors.grey.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      // Gambar lingkaran di posisi eraser
      canvas.drawCircle(eraserPos!, strokeWidth * 2, eraserPaint);
    }

    canvas.restore(); // Kembalikan canvas ke transformasi semula
  }

  @override
  // Selalu repaint agar perubahan coretan dan posisi terlihat
  bool shouldRepaint(_EditorPainter oldDelegate) => true;
}