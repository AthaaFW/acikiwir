import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic>
  userData; // minta dikirimin data user pas panggil halaman ini
  const ProfileScreen({super.key, required this.userData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing =
      false; // ini variabel saklar buat nentuin lagi mode edit atau cuma baca aja
  bool isLoading = false;
  // nyiapin controller buat masing-masing kolom teks formnya
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _nikController;

  @override
  void initState() {
    // pas halaman pertama ngerender, isi formnya langsung diisi sama data bawaan
    super.initState();
    _nameController = TextEditingController(text: widget.userData['nama']);
    _phoneController = TextEditingController(
      text: widget.userData['no_telpon'],
    );
    _nikController = TextEditingController(text: widget.userData['nik']);
  }

  @override
  void dispose() {
    //buat buang controller yang udah dipake pas halaman ini ditutup
    _nameController.dispose();
    _phoneController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    //buat ngerefresh tampilan kalau ada variabel yang berubah nilainya
    setState(() {
      isEditing = !isEditing;
    });
  }

  Future<void> _editProfile(String nik, String name, String phone) async {
    try {
      setState(() {
        isLoading = true;
      });

      await Supabase.instance.client
          .from('profiles')
          .update({'nama': name, 'no_telpon': phone})
          .eq('nik', nik);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      setState(() {
        isEditing = false;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil gagal diperbarui'),
          backgroundColor: Color.fromARGB(255, 185, 16, 16),
        ),
      );

      print(e);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A64F2),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Center(
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Color(0xFF1A64F2),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _nameController.text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.userData['email'] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),

            _buildProfileField(Icons.article, 'Nik', _nikController, false),
            _buildProfileField(
              Icons.person_outline,
              'Nama Lengkap',
              _nameController,
              true,
            ),
            _buildProfileField(
              Icons.phone_outlined,
              'Nomor Telepon',
              _phoneController,
              true,
            ),

            const SizedBox(height: 32),
            SizedBox(
              width: 160,
              height: 40,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (isEditing) {
                          _editProfile(
                            widget.userData['nik'],
                            _nameController.text,
                            _phoneController.text,
                          );
                        } else {
                          _toggleEdit();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isEditing
                      ? const Color(0xFF10B981)
                      : const Color(0xFF1A64F2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditing ? Icons.check : Icons.edit_note,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            isEditing ? 'Simpan' : 'EDIT PROFILE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // fungsi buat bikin barisan inputan profile bareng sama icon di sebelah kirinya
  Widget _buildProfileField(
    IconData icon,
    String label,
    TextEditingController controller,
    bool editable,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Icon(icon, color: const Color(0xFF1A64F2), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: editable
                  ? isEditing
                  : false, // inputannya cuma bisa diketik kalau saklar isEditing nyala (true)
              style: const TextStyle(fontSize: 16, color: Colors.black),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.only(bottom: 4),
                suffixIcon: editable
                    ? isEditing
                          ? const Icon(Icons.edit, size: 16, color: Colors.grey)
                          : null
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
