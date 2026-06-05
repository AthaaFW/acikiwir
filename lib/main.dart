import 'package:flutter/material.dart';
import 'auth_screens.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Perbaikan impor agar kelas LoginScreen terdeteksi
import 'package:intl/date_symbol_data_local.dart';
Future<void> main() async {
   await Supabase.initialize(
    url: 'https://rdhnrxdswxdcfapnksqv.supabase.co',
    anonKey: 'sb_publishable_VD55jS25vB4l3VFLlCdb8w__j5XnieG',
  );
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Diperbarui ke super parameter

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelaporan Fasilitas Umum',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Sans-Serif',
      ),
      home: const LoginScreen(),
    );
  }
}