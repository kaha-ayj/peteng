import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kunci penyimpanan preferensi tema gelap di SharedPreferences.
const String kPrefTemaGelap = 'pref_tema_gelap';

/// Warna aplikasi yang otomatis menyesuaikan tema terang/gelap.
///
/// Nilainya dibaca dari [AppThemeController] sehingga seluruh halaman cukup
/// memakai `AppColors.brand`, `AppColors.surface`, dan seterusnya tanpa perlu
/// mengoper `BuildContext`.
class AppColors {
  AppColors._();

  static const Color _brandLight = Color(0xFF172554);
  static const Color _brandFillLight = Color(0xFF172554);
  static const Color _brandSoftLight = Color(0xFF243B7A);
  static const Color _cardLight = Color(0xFFF1F1EF);
  static const Color _mutedLight = Color(0xFF5B6070);
  static const Color _surfaceLight = Colors.white;
  static const Color _surfaceAltLight = Color(0xFFF1F1EF);
  static const Color _inkLight = Color(0xFF1A1A24);
  static const Color _borderLight = Color(0xFFEDEEF2);
  static const Color _glowLight = Color(0xFFE8D98A);

  static const Color _brandDark = Color(0xFFE6EDFB);
  static const Color _brandFillDark = Color(0xFF2C4A8F);
  static const Color _brandSoftDark = Color(0xFF22355E);
  static const Color _cardDark = Color(0xFF0E1320);
  static const Color _mutedDark = Color(0xFF9AA3B5);
  static const Color _surfaceDark = Color(0xFF1A2130);
  static const Color _surfaceAltDark = Color(0xFF232C3F);
  static const Color _inkDark = Color(0xFFF2F5FA);
  static const Color _borderDark = Color(0xFF2A3346);
  static const Color _glowDark = Color(0xFFE8D98A);

  static bool get _dark => AppThemeController.instance.isDark;

  /// True bila tema gelap sedang aktif.
  static bool get isDark => _dark;

  /// Warna teks & ikon judul.
  static Color get brand => _dark ? _brandDark : _brandLight;

  /// Warna solid untuk latar tombol utama (kontras dengan teks putih).
  static Color get brandFill => _dark ? _brandFillDark : _brandFillLight;

  /// Variasi brand yang lebih lembut (dipakai pada gradien).
  static Color get brandSoft => _dark ? _brandSoftDark : _brandSoftLight;

  /// Latar halaman.
  static Color get card => _dark ? _cardDark : _cardLight;

  /// Warna teks sekunder.
  static Color get muted => _dark ? _mutedDark : _mutedLight;

  /// Latar kartu / panel.
  static Color get surface => _dark ? _surfaceDark : _surfaceLight;

  /// Latar kolom input / elemen di dalam kartu.
  static Color get surfaceAlt => _dark ? _surfaceAltDark : _surfaceAltLight;

  /// Warna teks utama.
  static Color get ink => _dark ? _inkDark : _inkLight;

  /// Warna garis pemisah / border halus.
  static Color get border => _dark ? _borderDark : _borderLight;

  /// Aksen keemasan (glow).
  static Color get glow => _dark ? _glowDark : _glowLight;
}

/// Menyimpan dan menyebarkan mode tema ke seluruh aplikasi.
class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool get isDark => _mode == ThemeMode.dark;

  /// Muat preferensi tersimpan. Dipanggil sekali saat aplikasi mulai.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(kPrefTemaGelap) ?? false;
    _mode = dark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  /// Simpan preferensi dan langsung terapkan.
  Future<void> setDark(bool dark) async {
    final next = dark ? ThemeMode.dark : ThemeMode.light;
    if (next == _mode) return;
    _mode = next;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefTemaGelap, dark);
  }
}

/// Membangun [ThemeData] untuk tema terang atau gelap.
ThemeData buildAppTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? AppColors._cardDark : AppColors._cardLight;
  final surface = dark ? AppColors._surfaceDark : AppColors._surfaceLight;
  final ink = dark ? AppColors._inkDark : AppColors._inkLight;
  final muted = dark ? AppColors._mutedDark : AppColors._mutedLight;
  final border = dark ? AppColors._borderDark : AppColors._borderLight;
  final brandFill = dark ? AppColors._brandFillDark : AppColors._brandFillLight;

  final base = ThemeData(brightness: brightness, useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: bg,
    canvasColor: bg,
    dividerColor: border,
    colorScheme: base.colorScheme.copyWith(
      primary: brandFill,
      surface: surface,
      onSurface: ink,
    ),
    textTheme: GoogleFonts.poppinsTextTheme(
      base.textTheme,
    ).apply(bodyColor: ink, displayColor: ink),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      titleTextStyle: GoogleFonts.poppins(
        color: ink,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: GoogleFonts.poppins(
        color: muted,
        fontSize: 13,
        height: 1.45,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? const Color(0xFF2A3346) : const Color(0xFF2B2B33),
      contentTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 12.5,
      ),
    ),
  );
}

/// Membungkus isi halaman agar seluruh tampilan dibangun ulang saat tema
/// diganti, termasuk widget `const` yang memakai [AppColors].
class ThemeRebuild extends StatelessWidget {
  const ThemeRebuild({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, _) => KeyedSubtree(
        key: ValueKey<bool>(AppThemeController.instance.isDark),
        child: child,
      ),
    );
  }
}
