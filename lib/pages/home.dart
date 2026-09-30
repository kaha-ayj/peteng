import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Halaman Home sementara, ditampilkan setelah login berhasil.
/// Ganti isi halaman ini dengan tampilan Home yang sebenarnya.
class Home extends StatelessWidget {
  const Home({super.key});

  static const brand = Color(0xFF172554);
  static const card = Color(0xFFF1F1EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: card,
      appBar: AppBar(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        title: Text(
          'PETENG',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: brand, size: 56),
              const SizedBox(height: 16),
              Text(
                'Login berhasil',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: brand,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Ini halaman Home sementara.\nGanti dengan tampilan Home yang sebenarnya.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
