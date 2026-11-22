import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_api.dart';
import '../theme/app_theme.dart';
import 'login.dart';

Color get _brand => AppColors.brand;
Color get _brandFill => AppColors.brandFill;
Color get _brandSoft => AppColors.brandSoft;
Color get _cardBg => AppColors.card;
Color get _muted => AppColors.muted;
const Color _accent = Color(0xFF00C4FF);

const String _prefNotif = 'pref_notifikasi_laporan';
const String _prefAvatar = 'foto_profil';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _loading = true;
  Map<String, dynamic>? _user;

  bool _pushNotification = true;
  bool _darkTheme = false;

  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = await AuthApi.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final avatarRaw = prefs.getString(_prefAvatar);

    Uint8List? avatar;
    if (avatarRaw != null && avatarRaw.isNotEmpty) {
      try {
        avatar = base64Decode(avatarRaw);
      } catch (_) {
        // Data foto lama/rusak: tampilkan inisial saja.
      }
    }

    if (!mounted) return;

    setState(() {
      _user = user;
      _pushNotification = prefs.getBool(_prefNotif) ?? true;
      _darkTheme = AppThemeController.instance.isDark;
      _avatarBytes = avatar;
      _loading = false;
    });
  }

  Future<void> _setNotification(bool value) async {
    setState(() => _pushNotification = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotif, value);
  }

  Future<void> _setDarkTheme(bool value) async {
    setState(() => _darkTheme = value);
    await AppThemeController.instance.setDark(value);
  }

  String get _nama {
    final nama = (_user?['nama'] ?? '').toString().trim();
    return nama.isEmpty ? 'Pengguna Peteng' : nama;
  }

  String get _email {
    final email = (_user?['email'] ?? '').toString().trim();
    return email.isEmpty ? 'Belum masuk' : email;
  }

  String get _telepon => (_user?['nomor_telepon'] ?? '').toString().trim();

  String get _initials {
    final parts = _nama
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'P';

    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts[1].substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }

  void _info(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _comingSoon(String fitur) {
    _info('Fitur $fitur belum tersedia. Nantikan pembaruan berikutnya ya.');
  }

  Future<void> _pickAvatar() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Ubah Foto Profil',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _brand,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: _brand,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Ambil dari Kamera',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Foto langsung menggunakan kamera',
                  style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _brand.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library_outlined,
                    color: _brand,
                    size: 22,
                  ),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Ambil foto dari galeri perangkat',
                  style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                ),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefAvatar, base64Encode(bytes));

      if (!mounted) return;
      setState(() => _avatarBytes = bytes);
      _info('Foto profil berhasil diperbarui.');
    } catch (e) {
      _info('Gagal mengambil foto. Pastikan izin kamera/galeri diberikan.');
    }
  }

  Future<void> _confirmLogout() async {
    final keluar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Keluar akun?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Kamu perlu login lagi untuk mengirim laporan dan menyimpan rute.',
          style: GoogleFonts.poppins(fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(
                color: _muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Keluar',
              style: GoogleFonts.poppins(
                color: Colors.redAccent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (keluar != true) return;

    await AuthApi.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _showHelp() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Pusat Bantuan',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _brand,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Panduan singkat penggunaan PETENG.',
                style: GoogleFonts.poppins(fontSize: 12, color: _muted),
              ),
              const SizedBox(height: 16),
              _helpItem(
                Icons.campaign_outlined,
                'Lapor kondisi PJU',
                'Buka tab Lapor, ambil foto, lalu isi kategori dan tingkat kegelapan.',
              ),
              _helpItem(
                Icons.near_me_outlined,
                'Cari rute aman',
                'Tentukan titik awal dan tujuan di tab Peta & Rute untuk melihat opsi rute.',
              ),
              _helpItem(
                Icons.event_note_outlined,
                'Baca informasi',
                'Kabar terbaru seputar penerangan jalan dan keselamatan ada di tab Artikel.',
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _brandFill,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: Text(
                    'Mengerti',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _helpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _brand.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      ThemeRebuild(child: _buildPage(context));

  Widget _buildPage(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppThemeController.instance.isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: AppThemeController.instance.isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: _cardBg,
        appBar: AppBar(
          backgroundColor: _cardBg,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: _brand, size: 19),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            'Profil Saya',
            style: GoogleFonts.poppins(
              color: _brand,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: _brand,
                onRefresh: _loadProfile,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 24),
                      _buildSection(
                        'Pengaturan Akun',
                        children: [
                          _menuTile(
                            icon: Icons.person_outline,
                            title: 'Ubah Data Diri',
                            subtitle: 'Nama, email, dan nomor telepon',
                            onTap: () => _comingSoon('ubah data diri'),
                          ),
                          _menuTile(
                            icon: Icons.lock_outline,
                            title: 'Ubah Kata Sandi',
                            subtitle: 'Perbarui kata sandi akunmu',
                            onTap: () => _comingSoon('ubah kata sandi'),
                          ),
                          _menuTile(
                            icon: Icons.assignment_outlined,
                            title: 'Laporan Saya',
                            subtitle: 'Riwayat laporan yang sudah dikirim',
                            onTap: () => _comingSoon('laporan saya'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        'Preferensi',
                        children: [
                          _switchTile(
                            icon: Icons.notifications_active_outlined,
                            title: 'Notifikasi Laporan',
                            subtitle: 'Info status laporan yang kamu kirim',
                            value: _pushNotification,
                            onChanged: _setNotification,
                          ),
                          _switchTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Tema Gelap',
                            subtitle:
                                'Tampilan gelap agar nyaman di malam hari',
                            value: _darkTheme,
                            onChanged: _setDarkTheme,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSection(
                        'Lainnya',
                        children: [
                          _menuTile(
                            icon: Icons.help_outline,
                            title: 'Pusat Bantuan',
                            onTap: _showHelp,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _confirmLogout,
                          icon: const Icon(Icons.logout, size: 19),
                          label: Text(
                            'Keluar Akun',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: Text(
                          'PETENG v1.0.0',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: _muted.withValues(alpha: .8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final telepon = _telepon;
    final avatar = _avatarBytes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_brandFill, _brandSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandFill.withValues(alpha: .22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: avatar != null
                    ? ClipOval(
                        child: Image.memory(
                          avatar,
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Text(
                        _initials,
                        style: GoogleFonts.poppins(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: _brand,
                        ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: 2,
                child: Material(
                  color: _accent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickAvatar,
                    child: const Padding(
                      padding: EdgeInsets.all(7),
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _nama,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            _email,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: Colors.white.withValues(alpha: .75),
            ),
          ),
          if (telepon.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: .16)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    telepon,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection(String title, {required List<Widget> children}) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        items.add(
          Divider(
            height: 1,
            thickness: 1,
            indent: 62,
            endIndent: 14,
            color: AppColors.border,
          ),
        );
      }
      items.add(children[i]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
              color: _muted,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(children: items),
          ),
        ),
      ],
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      leading: _tileIcon(icon),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle,
              style: GoogleFonts.poppins(fontSize: 10.5, color: _muted),
            ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.muted,
        size: 22,
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      secondary: _tileIcon(icon),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 10.5, color: _muted),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: _brandFill,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    );
  }

  Widget _tileIcon(IconData icon) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _brand.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: _brand, size: 19),
    );
  }
}
