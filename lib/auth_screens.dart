import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// halaman login
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>(); 
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // fungsi yang dijalanin pas tombol masuk diklik
Future<void> _processLogin() async {
  if (!_formKey.currentState!.validate()) return;

  try {
    final userData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('email', _emailController.text)
          .maybeSingle();

    print(userData);

    

    if (!mounted) return;

    if(userData == null){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Akun tidak ditemukan'),
        ),
      );

      return;
    }

    if(_passwordController.text != userData['password']){
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password Salah'),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Login Berhasil! Memuat data...'),
      ),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(userData: userData),
      ),
    );
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login gagal: $e'),
      ),
    );
  }
}


  //Login form
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey, // nyambungin form ini sama kunci validasi di atas
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40, // ukuran bulatannya
                  backgroundColor: Color(0xFF1A64F2),
                  child: Icon(Icons.location_on, size: 40, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Pelaporan Kerusakan\nFasilitas Umum',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Laporkan kerusakan infrastruktur dengan mudah',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextFormField( 
                  controller: _emailController, // nyambungin ke variabel email
                  // ngecek kalau kosong nanti muncul tulisan merah peringatan
                  validator: (value) => value!.isEmpty ? 'Email tidak boleh kosong' : null,
                  decoration: InputDecoration(
                    hintText: 'nama@email.com',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController, // nyambungin ke variabel password
                  obscureText: true, // bikin ketikannya jadi titik"
                  // validasi cek panjang password minimal 8 huruf/angka
                  validator: (value) => value!.length < 8 ? 'Password minimal 8 karakter' : null,
                  decoration: InputDecoration(
                    hintText: '********',
                    filled: true,
                    fillColor: const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _processLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A64F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Masuk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? '),
                    GestureDetector(
                      onTap: () {
                      
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen()));
                      },
                      child: const Text('Daftar di sini', style: TextStyle(color: Color(0xFF1A64F2), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// halaman buat daftar akun
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _registerFormKey = GlobalKey<FormState>(); // kunci validasi khusus halaman register
  
  // controller untuk menangkap setiap ketikan kolom registrasi
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController(); // controller baru untuk tempat tanggal lahir
  final TextEditingController _tempatLahirController = TextEditingController(); // controller baru khusus tempat lahir
  final TextEditingController _tanggalLahirController = TextEditingController(); // controller baru khusus tanggal lahir
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  DateTime? _selectedDate;

  // fungsi bawaan buat bersihin memori kalau halamannya ditutup
  @override
  void dispose() {
    _nameController.dispose();
    _ttlController.dispose(); // dispose controller baru agar hemat memori
    _tempatLahirController.dispose(); // dispose controller tempat lahir baru
    _tanggalLahirController.dispose(); // dispose controller tanggal lahir baru
    _nikController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // fungsi tambahan pembantu untuk memicu pemilih kalender (date picker)
  Future<void> _selectTanggalLahir(BuildContext context) async {
    DateTime initialDate = DateTime(2000, 1, 1);
    DateTime firstDate = DateTime(1940);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1A64F2), // menyamakan tema warna biru aplikasi
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        // format tampilan: tanggal-bulan-tahun eksekusi langsung ke field
        _selectedDate = picked;
        _tanggalLahirController.text = "${picked.day} ${_getNamaBulan(picked.month)} ${picked.year}";
      });
    }
  }

  // fungsi pembantu konversi nomor bulan menjadi string teks bahasa indonesia
  String _getNamaBulan(int month) {
    List<String> namaBulan = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    return namaBulan[month - 1];
  }

  // fungsi yang dijalanin pas tombol daftar diklik
  Future<void> _processRegister() async{
    if (_registerFormKey.currentState!.validate()) { // pastiin semuanya udah diisi
      //cek kecocokan password & konfirmasi password sebelum mendaftar
      if (_passwordController.text != _confirmPasswordController.text) {
        // kalau beda, munculin notif merah gagal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password dan Konfirmasi Password tidak cocok!'), backgroundColor: Colors.red),
        );
        return; // stop fungsinya di sini, gak lanjut ke bawah
      }
      
      if(!mounted) return;
      try{

        final availableUser = await Supabase.instance.client
              .from('profiles')
              .select()
              .or(
              'email.eq.${_emailController.text},nik.eq.${_nikController.text}',
              )
              .maybeSingle();
              

        if(availableUser != null){
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('NIK atau Email Sudah Digunakan.'), backgroundColor: Color.fromARGB(255, 185, 16, 16)),
        );
        } 

        await Supabase.instance.client
          .from('profiles')
          .insert({
            'nik': _nikController.text,
            'nama': _nameController.text,
            'tempat_lahir': _tempatLahirController.text,
            'tanggal_lahir': _selectedDate?.toIso8601String().split("T")[0],
            'no_telpon': _phoneController.text,
            'password': _passwordController.text,
            'email': _emailController.text
          });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pendaftaran Berhasil.'), backgroundColor: Color.fromARGB(255, 16, 185, 58)),
        );

        Navigator.pop(context);

      }catch (e) {
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _registerFormKey, // sambungin form ini sama kuncinya
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Color(0xFF1A64F2),
                  child: Icon(Icons.person_add_alt_1, size: 40, color: Colors.white), // icon tambah orang
                ),
                const SizedBox(height: 16),
                const Text(
                  'Daftar Akun Warga',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lengkapi data Anda untuk mulai melaporkan kerusakan infrastruktur',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const SizedBox(height: 24),

                // manggil fungsi bikinan di bawah buat ngerender kolom satu-satu biar kodingan ga kepanjangan
                _buildInputField('Nomor Induk', 'NIK Sesuai Kartu Keluarga, KTP', _nikController),
                _buildInputField('Nama Lengkap', 'Masukkan nama lengkap Anda', _nameController),
                _buildInputField('Email', 'Email', _emailController),
                _buildInputField('No. Telepon', 'Masukkan nomor telepon anda', _phoneController),// kolom tempat lahir baru
                _buildInputField('Tempat Lahir', 'Kota', _tempatLahirController),
                
                // wadah input field khusus tanggal lahir menggunakan kalender date picker asli
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal Lahir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _tanggalLahirController,
                        readOnly: true, // mencegah keyboard standar mengetik manual
                        onTap: () => _selectTanggalLahir(context), // menampilkan kalender saat diklik
                        validator: (value) => value!.isEmpty ? 'Bidang ini wajib diisi' : null,
                        decoration: InputDecoration(
                          hintText: 'Pilih tanggal lahir Anda',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF1A64F2)), // ikon indikator kalender
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              
                _buildInputField('Password', 'Minimal 8 karakter', _passwordController, obscure: true), // obscure true biar jadi bintang2
                _buildInputField('Konfirmasi Password', 'Ulangi password Anda', _confirmPasswordController, obscure: true),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _processRegister, // lari ke fungsi _processregister
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A64F2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Daftar Sekarang', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Sudah punya akun? '),
                    GestureDetector( // bikin teksnya bisa dipencet
                      onTap: () => Navigator.pop(context), // balikin ke halaman sebelumnya (login)
                      child: const Text('Masuk di sini', style: TextStyle(color: Color(0xFF1A64F2), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ini fungsi pembantu biar gak nulis ulang form field berkali" di atas
  Widget _buildInputField(String label, String hint, TextEditingController controller, {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), // teks judul per kolom
          const SizedBox(height: 6),
          TextFormField( 
            controller: controller, // nangkep variabel yang dikirim ke fungsi
            obscureText: obscure, // ngecek apa dia harus disensor atau enggak
            validator: (value) => value!.isEmpty ? 'Bidang ini wajib diisi' : null, // gak boleh kosong pokonya
            decoration: InputDecoration(
              hintText: hint, // teks bayangan
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF3F4F6), // warna abunya
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), // diilangin garisnya
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}