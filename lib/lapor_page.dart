import 'dart:io'; // Untuk menghandle file foto
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart'; // Import kamera

class GeotagKameraRealtimeScreen extends StatefulWidget {
  const GeotagKameraRealtimeScreen({super.key});

  @override
  State<GeotagKameraRealtimeScreen> createState() => _GeotagKameraRealtimeScreenState();
}

class _GeotagKameraRealtimeScreenState extends State<GeotagKameraRealtimeScreen> {
  File? _fileFoto; // Tempat menyimpan hasil foto
  String _statusTeks = "Belum mengambil foto & lokasi";
  bool _isLoading = false;

  // FUNGSI UTAMA: BUKA KAMERA REALTIME & AMBIL GEOTAG
  Future<void> _ambilFotoDanLokasi() async {
    setState(() {
      _isLoading = true;
      _statusTeks = "Membuka kamera...";
    });

    try {
      // 1. CEK GPS & IZIN LOKASI DULU
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS kamu mati. Aktifkan GPS dulu.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Izin lokasi ditolak.';
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen. Ubah di pengaturan HP.';
      }

      // 2. BUKA KAMERA BAWAAN HP SECARA REALTIME
      final ImagePicker picker = ImagePicker();
      final XFile? fotoTerpilih = await picker.pickImage(
        source: ImageSource.camera, // Langsung buka kamera HP asli
        imageQuality: 50, // Mengompres foto agar tidak terlalu berat saat dikirim
      );

      // Jika user klik tombol back (batal foto)
      if (fotoTerpilih == null) {
        setState(() {
          _isLoading = false;
          _statusTeks = "Pengambilan foto dibatalkan.";
        });
        return;
      }

      // 3. JIKA BERHASIL MOTO, LANGSUNG AMBIL KOORDINAT GPS
      setState(() {
        _statusTeks = "Foto berhasil diambil. Mengunci koordinat GPS...";
      });
      
      Position posisi = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // 4. UPDATE UI TAMPILKAN FOTO DAN LOKASI
      setState(() {
        _fileFoto = File(fotoTerpilih.path); // Simpan file fotonya
        _statusTeks = "Berhasil Mendapatkan Geotag!\n\n"
            "Latitude: ${posisi.latitude}\n"
            "Longitude: ${posisi.longitude}";
      });

    } catch (error) {
      setState(() {
        _statusTeks = error.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kamera Realtime + Geotag"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true, // Judul di tengah khas aplikasi mobile
      ),
      backgroundColor: Colors.grey[50], // Background abu-abu terang khas mobile app
      body: Center(
        // === KUNCI PENGATURAN RASIO MOBILE ===
        // Menggunakan ConstrainedBox agar lebar aplikasi tertahan maksimal 450 pixel (ukuran HP)
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Membuat komponen melebar proporsional
              children: [
                // Kotak untuk menampilkan hasil jepretan foto kamera
                Container(
                  height: 320, // Sedikit ditinggikan agar pas dengan aspek rasio foto HP (3:4)
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _fileFoto != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(_fileFoto!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_enhance_rounded, size: 56, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              "Foto hasil jepretan akan muncul di sini", 
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // Kotak Status Lokasi
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple[100]!),
                  ),
                  child: Text(
                    _statusTeks,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.deepPurple),
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Utama
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                    : ElevatedButton.icon(
                        onPressed: _ambilFotoDanLokasi,
                        icon: const Icon(Icons.photo_camera),
                        label: const Text("Buka Kamera & Ambil Geotag"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}