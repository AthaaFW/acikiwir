import 'dart:io'; // Penting untuk handle file gambar
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Import untuk GPS
import 'package:geocoding/geocoding.dart'; // Import untuk terjemahin alamat
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddReportScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const AddReportScreen({super.key, required this.userData});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final TextEditingController _deskripsiController = TextEditingController();
  late Position posisi;
  // === MENGUBAH SINGLE FILE MENJADI LIST FILE ===
  final List<File> _imageFiles = [];

  String _alamatRealtime =
      "Sedang mencari lokasi GPS..."; // Untuk teks lokasi di bawah foto
  //String _coordinatText = ""; // Untuk menampung lat, long cadangan
  bool _isGettingLocation = false;

  @override
  void initState() {
    super.initState();
    _ambilLokasiOtomatis(); // Nyari lokasi langsung pas halaman form dibuka
  }

  // === FUNGSI AMBIL LOKASI DAN ALAMAT REALTIME ===
  Future<void> _ambilLokasiOtomatis() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _alamatRealtime = "GPS Mati. Aktifkan GPS Anda.");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _alamatRealtime = "Izin lokasi ditolak.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(
          () => _alamatRealtime = "Izin ditolak permanen di pengaturan.",
        );
        return;
      }

      posisi = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      //_coordinatText = "Lat: ${posisi.latitude}, Long: ${posisi.longitude}";

      List<Placemark> placemarks = await placemarkFromCoordinates(
        posisi.latitude,
        posisi.longitude,
      );

      Placemark tempat = placemarks[0];

      setState(() {
        _alamatRealtime =
            "${tempat.street}, ${tempat.subLocality}, ${tempat.locality}";
      });
    } catch (e) {
      setState(() {
        _alamatRealtime = "Gagal memuat alamat lokasi asli.";
      });
    }
  }

  // === FUNGSI MEMBUKA KAMERA (DITAMBAHKAN KE LIST) ===
  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (pickedFile != null) {
        setState(() {
          // Memasukkan foto baru ke dalam list data foto kita
          _imageFiles.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuka kamera: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // === FUNGSI HAPUS FOTO BERDASARKAN INDEX ===
  void _deletePicture(int index) {
    setState(() {
      _imageFiles.removeAt(index);
    });
  }

  // fungsi buat dijalanin pas tombol kirim di paling bawah diklik
  Future<void> _submitLaporan(id, deskripsi) async {
    // Validasi sekarang mengecek apakah list fotonya masih kosong
    if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Silakan ambil minimal 1 foto kerusakan terlebih dahulu!',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGettingLocation = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_imageFiles[0].path.split('/').last}';
      final storagePath = fileName;
      print('Up foto ke storage');
      await supabase.storage.from('Images').upload(storagePath, _imageFiles[0]);
      print('Ambil URL');
      final fotoUrl = supabase.storage.from('Images').getPublicUrl(storagePath);

      print('Send Laporan');
      final laporan = await supabase
          .from('laporan')
          .insert({
            'pelapor_id': id,
            'deskripsi': deskripsi,
            'latitude': posisi.latitude,
            'longitude': posisi.longitude,
            'status': 'Pending',
            'foto_url': fotoUrl,
          })
          .select()
          .single();

      if (laporan != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Laporan dengan ${_imageFiles.length} foto sukses dikirim!',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengirim: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A64F2),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Buat Laporan Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Foto Kerusakan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '${_imageFiles.length} Foto terpilih',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // === PENGKONDISIAN TAMPILAN AREA FOTO ===
            _imageFiles.isEmpty
                ? GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tap untuk mengambil foto',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : Center(
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFiles[0],
                            width: double.infinity,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        ),

                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _deletePicture(0),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

            // Kotak Titik Lokasi Geotag
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    color: Color(0xFF1A64F2),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tag Lokasi Kerusakan',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _alamatRealtime,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      color: Color(0xFF1A64F2),
                      size: 22,
                    ),
                    onPressed: () async {
                      bool serviceEnabled =
                          await Geolocator.isLocationServiceEnabled();
                      if (!serviceEnabled) {
                        setState(() {
                          _alamatRealtime = "GPS Mati. Aktifkan GPS Anda.";
                        });
                      } else {
                        setState(() {
                          _alamatRealtime = "Memperbarui lokasi...";
                        });
                        _ambilLokasiOtomatis();
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Deskripsi Singkat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),

            // Deskripsi Input
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Jelaskan kondisi kerusakan...',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              controller: _deskripsiController,
            ),

            // SECTION PETUNJUK PENGGUNAAN MODEL LIST TILE
            const SizedBox(height: 24),
            Row(
              children: const [
                Icon(Icons.gavel_rounded, color: Color(0xFF1A64F2), size: 20),
                SizedBox(width: 8),
                Text(
                  'Panduan Praktis & Rekomendasi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Langkah 1: Kamera
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_enhance_rounded,
                  color: Color(0xFF1A64F2),
                  size: 22,
                ),
              ),
              title: const Text(
                'Pengambilan Foto (Tegak Lurus & Jelas)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              subtitle: const Text(
                'Pastikan posisi kamera tegak lurus dengan objek kerusakan and pencahayaan cukup agar detail retakan/lubang terlihat jelas.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
              ),
            ),
            const Divider(height: 16, color: Color(0xFFE5E7EB)),

            // Langkah 2: GPS
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF1A64F2),
                  size: 22,
                ),
              ),
              title: const Text(
                'Validasi Tag Lokasi (Akurat)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              subtitle: const Text(
                'Berdirilah sedekat mungkin dengan titik kerusakan saat menekan tombol kirim agar koordinat lokasi yang terkunci tidak meleset.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
              ),
            ),
            const Divider(height: 16, color: Color(0xFFE5E7EB)),

            // Langkah 3: Deskripsi
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF1A64F2),
                  size: 22,
                ),
              ),
              title: const Text(
                'Detail Deskripsi (Estimasi Dimensi)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
              subtitle: const Text(
                'Sebutkan estimasi ukuran kerusakan pada kolom deskripsi (misal: lubang sedalam ~10cm) untuk membantu prioritas perbaikan.',
                style: TextStyle(fontSize: 12, color: Colors.grey, height: 1.3),
              ),
            ),
          ],
        ),
      ),

      // BUTTON DI BAGIAN BAWAH FIX FIXED STAY
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom: 24.0,
          top: 12.0,
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _isGettingLocation
                ? null
                : _submitLaporan(
                    widget.userData['id'],
                    _deskripsiController.text,
                  ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A64F2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isGettingLocation
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Kirim Laporan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
