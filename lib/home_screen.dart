import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'report_screen.dart';
import 'auth_screens.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic>
  userData; // nangkep data yang dikirim dari halaman login tadi

  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- VARIABEL UNTUK GEOTAG REALTIME ---
  String _alamatRealtime = "Sedang mencari lokasi GPS...";
  int countLaporanProcessed = 0;
  int countLaporanSelesai = 0;
  RealtimeChannel? laporanChannel;

  @override
  void initState() {
    super.initState();
    _ambilLokasiAwal();
    getLaporan();

    laporanChannel = Supabase.instance.client
        .channel('laporan_status')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'laporan',
          callback: (payload) {
            print('Realtime triggered');
            print(payload.newRecord);

            final updatedData = payload.newRecord;

            final index = seluruhLaporan.indexWhere(
              (e) => e['id_laporan'] == updatedData['id_laporan'],
            );

            print('Index: $index');

            if (index != -1) {
              final oldStatus = seluruhLaporan[index]['status'];
              final newStatus = updatedData['status'];

              print('Old: $oldStatus');
              print('New: $newStatus');

              seluruhLaporan[index]['status'] = newStatus;

              setState(() {});
            }
          },
        )
        .subscribe((status, error) {
          print('STATUS: $status');
          print('ERROR: $error');
        });
  }

  Future<void> _ambilLokasiAwal() async {
    try {
      // A. CEK APAKAH LAYANAN GPS AKTIF
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _alamatRealtime = "GPS Mati. Aktifkan GPS Anda.");
        return;
      }

      // B. CEK DAN MINTA IZIN AKSES LOKASI HP
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

      // C. JIKA IZIN AMAN, BARU AMBIL KOORDINAT
      Position posisi = await Geolocator.getCurrentPosition(
        // desiredAccuracy: LocationAccuracy.high,
      );

      // D. TERJEMAHKAN KOORDINAT JADI ALAMAT
      List<Placemark> placemarks = await placemarkFromCoordinates(
        posisi.latitude,
        posisi.longitude,
      );

      Placemark tempat = placemarks[0];

      setState(() {
        // Gabungkan teks alamat secara aman
        _alamatRealtime =
            "${tempat.street}, ${tempat.subLocality}, ${tempat.locality}";
      });
    } catch (e) {
      setState(() {
        _alamatRealtime = "Gagal memuat alamat lokasi.";
      });
    }
  }

  // === FUNGSI BAGIAN PULL TO REFRESH DARI ATAS LAYAR ===
  Future<void> _handleRefresh() async {
    // 1. Cek dulu apakah GPS aktif pas layar ditarik kebawah
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    countLaporanProcessed = 0;
    countLaporanSelesai = 0;
    getLaporan();
    if (!serviceEnabled) {
      // Jika GPS mati, langsung jegat dengan Pop-up Dialog
      _tampilkanDialogGPSMati();
    } else {
      // Jika GPS hidup, ubah status text lalu refresh koordinat
      setState(() {
        _alamatRealtime = "Memperbarui lokasi...";
      });
      await _ambilLokasiAwal();
    }
  }

  String activeFilter = 'Semua'; // status awal filter laporan yang kepilih
  final List<Map<String, dynamic>> seluruhLaporan = [];

  Future<String> getAlamat(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);

      Placemark place = placemarks.first;

      return '${place.subAdministrativeArea}, '
          '${place.administrativeArea}, '
          '${place.country}';
    } catch (e, st) {
      debugPrint('ERROR: $e');
      debugPrintStack(stackTrace: st);
      return e.toString();
    }
  }

  Future<void> getLaporan() async {
    final data = await Supabase.instance.client
        .from('laporan')
        .select()
        .eq('pelapor_id', widget.userData['id']);

    seluruhLaporan.clear();

    countLaporanProcessed = 0;
    countLaporanSelesai = 0;
    for (final item in data) {
      final alamat = await getAlamat(item['latitude'], item['longitude']);

      item['alamat'] = alamat;
      seluruhLaporan.add(item);
      if (item['status'] == "Diproses") {
        countLaporanProcessed += 1;
      } else if (item['status'] == "Selesai") {
        countLaporanSelesai += 1;
      } else {}
    }
    setState(() {});
    print(seluruhLaporan);
  }

  String formatTanggalIndonesia(String tanggal) {
    try {
      final dateTime = DateTime.parse(tanggal);

      return DateFormat('dd MMMM yyyy', 'id_ID').format(dateTime.toLocal());
    } catch (e) {
      return '-';
    }
  }

  // === FUNGSI POP-UP JIKA GPS BELUM NYALA ===
  void _tampilkanDialogGPSMati() {
    showDialog(
      context: context,
      barrierDismissible: false, // User wajib milih tombol, gabisa klik luar
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(Icons.location_off_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text(
                'GPS Belum Aktif',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            'Layanan lokasi di HP Anda belum aktif. Silakan nyalakan GPS terlebih dahulu sebelum membuat laporan baru.',
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A64F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                await Geolocator.openLocationSettings(); // Redirect otomatis ke setting GPS HP
                _ambilLokasiAwal(); // Segarkan ulang tracker di home sesudah balik dari pengaturan
              },
              child: const Text(
                'Buka Pengaturan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // === FUNGSI PINDAH HALAMAN DENGAN PENGECEKAN GPS ===
  Future<void> _navigateToAddReport(BuildContext context) async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _tampilkanDialogGPSMati();
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddReportScreen(userData: widget.userData),
      ),
    );

    if (result == true) {
      await getLaporan();
    }
  }

  Future<void> _openProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(userData: widget.userData),
      ),
    );

    if (result != null) {
      setState(() {
        widget.userData.addAll(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //filter laporan sesuai status
    List<Map<String, dynamic>> filteredLaporan = seluruhLaporan.where((
      laporan,
    ) {
      if (activeFilter == 'Semua') return true;
      return laporan['status'] == activeFilter;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.userData['nama'] ?? 'User'),
              accountEmail: Text(widget.userData['email'] ?? 'user@email.com'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Color(0xFF1A64F2)),
              ),
              decoration: const BoxDecoration(color: Color(0xFF1A64F2)),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1A64F2)),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _openProfile();
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Keluar Akun',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A64F2),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Halo, ${widget.userData['nama']}!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 28),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddReport(context),
        backgroundColor: const Color(0xFF10B981),
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,

      // === SEKARANG BODY DIBUNGKUS DENGAN REFRESH INDICATOR ===
      body: RefreshIndicator(
        onRefresh:
            _handleRefresh, // Memanggil fungsi pengecekan GPS & lokasi saat ditarik
        color: const Color(0xFF1A64F2), // Warna lingkaran loading
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          //physics dipaksa AlwaysScrollableScrollPhysics agar layar bisa ditarik meskipun kontennya masih sedikit
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 16.0,
            bottom: 80.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Status Geo Tracker',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Color(0xFF1A64F2)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Lokasi Anda Saat Ini',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _alamatRealtime,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // === TOMBOL REFRESH IKON SUDAH DIHAPUS DARI SINI ===
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Riwayat Laporan Anda',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCounterCard(seluruhLaporan.length.toString(), 'Semua'),
                  _buildCounterCard(countLaporanProcessed.toString(), 'Proses'),
                  _buildCounterCard(countLaporanSelesai.toString(), 'Selesai'),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Semua', 'Pending', 'Diproses', 'Selesai'].map((
                  status,
                ) {
                  bool isSelected = activeFilter == status;
                  return GestureDetector(
                    onTap: () => setState(() => activeFilter = status),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF1A64F2)
                            : Colors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const Divider(height: 24),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredLaporan.length,
                itemBuilder: (context, index) {
                  final item = filteredLaporan[index];
                  return _buildReportItem(item);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterCard(String count, String title) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.28,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A64F2),
            ),
          ),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> item) {
    Color statusColor = const Color(0xFF1A64F2);
    if (item['status'] == 'Pending') statusColor = Colors.red;
    if (item['status'] == 'Selesai') statusColor = const Color(0xFF10B981);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FOTO
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item['foto_url'],
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(width: 12),

          // KONTEN KANAN
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['deskripsi'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // LOKASI
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        item['alamat'] ?? '-',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // TANGGAL
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Dilaporkan pada: ${formatTanggalIndonesia(item['created_at'])}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
