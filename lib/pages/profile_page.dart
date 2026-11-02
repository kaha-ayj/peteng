import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'login.dart'; // Buka komentar ini nanti untuk fungsi logout

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Toggle untuk pengaturan notifikasi
  bool _pushNotification = true;
  bool _darkTheme = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1A1A24), size: 20),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Profil Saya',
            style: TextStyle(color: Color(0xFF1A1A24), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. Bagian Header Profil
              _buildProfileHeader(),
              const SizedBox(height: 24),

              // 2. Statistik Singkat (Opsional untuk aplikasi pelaporan)
              _buildStatistics(),
              const SizedBox(height: 24),

              // 3. Menu Pengaturan Akun
              _buildSectionTitle('Pengaturan Akun'),
              _buildMenuTile(
                icon: Icons.person_outline,
                title: 'Ubah Data Diri',
                onTap: () {},
              ),
              _buildMenuTile(
                icon: Icons.lock_outline,
                title: 'Ubah Kata Sandi',
                onTap: () {},
              ),

              const SizedBox(height: 24),

              // 4. Menu Preferensi Aplikasi
              _buildSectionTitle('Preferensi'),
              _buildSwitchTile(
                icon: Icons.notifications_active_outlined,
                title: 'Notifikasi Laporan',
                value: _pushNotification,
                onChanged: (val) => setState(() => _pushNotification = val),
              ),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Tema Gelap',
                value: _darkTheme,
                onChanged: (val) => setState(() => _darkTheme = val),
              ),

              const SizedBox(height: 24),

              // 5. Menu Bantuan & Info
              _buildSectionTitle('Lainnya'),
              _buildMenuTile(
                icon: Icons.help_outline,
                title: 'Pusat Bantuan',
                onTap: () {},
              ),
              _buildMenuTile(
                icon: Icons.info_outline,
                title: 'Tentang Peteng',
                onTap: () {},
              ),

              const SizedBox(height: 32),

              // 6. Tombol Keluar (Logout)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Logika untuk logout, hapus token, lalu pushReplacement ke halaman Login
                    // Navigator.of(context).pushAndRemoveUntil(
                    //   MaterialPageRoute(builder: (_) => const LoginPage()), 
                    //   (route) => false,
                    // );
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: const Text(
                    'Keluar Akun',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                image: const DecorationImage(
                  // Placeholder gambar profil, bisa diganti asset/network image asli
                  image: NetworkImage('https://via.placeholder.com/150'), 
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF00C4FF), // Cyan khas Peteng
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Reina Ylamaria', // Diambil dari data login desain sebelumnya
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E213A)),
        ),
        const SizedBox(height: 4),
        Text(
          'reinaylamaria@gmail.com',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('Laporan', '12', Icons.warning_amber_rounded, Colors.orange),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem('Apresiasi', '45', Icons.thumb_up_alt_outlined, Colors.green),
          Container(width: 1, height: 40, color: Colors.grey[200]),
          _buildStatItem('Rute Disimpan', '3', Icons.bookmark_border, Colors.blue),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A24))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E213A)),
        ),
      ),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1E213A).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF1E213A), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A24))),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF1E213A).withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF1E213A), size: 20),
        ),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A24))),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF00C4FF),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}