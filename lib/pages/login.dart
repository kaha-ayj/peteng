import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'landing_page.dart';

void main() => runApp(const PetengApp());

class AppColors {
  static const brand = Color(0x172554);
  static const brandSoft = Color(0xFF46507A); // lingkaran dekorasi
  static const page = Color(0xFFCDC8D0);
  static const card = Color(0xFFF1F1EF);
  static const muted = Color(0xFF5B6070);
  static const glow = Color(0xFFE8D98A);
}

/// Path logo kamu. Taruh file di assets/logo.png dan daftarkan di pubspec.yaml.
const String kLogoAsset = 'assets/logo.png';

/// Set false setelah logo terpasang untuk menghilangkan outline penanda.
const bool kShowLogoMarker = true;

class PetengApp extends StatelessWidget {
  const PetengApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PETENG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.brand),
        textTheme: GoogleFonts.poppinsTextTheme(),
        scaffoldBackgroundColor: AppColors.page,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _obscure = true;
  bool _remember = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // TODO: panggil API / Firebase Auth di sini.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Form valid, lanjutkan ke proses login')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final cardHeight = (constraints.maxHeight - 32)
                .clamp(740.0, 900.0)
                .toDouble();
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Container(
                      height: cardHeight,
                      color: AppColors.card,
                      child: Stack(
                        children: [
                          // Lingkaran dekorasi
                          const Positioned(
                            right: -60,
                            top: 500,
                            child: _Dot(size: 120),
                          ),
                          const Positioned(
                            left: -76,
                            bottom: -80,
                            child: _Dot(size: 200),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Header(),
                              Expanded(child: _buildForm()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Login',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
                shadows: [
                  Shadow(
                    color: AppColors.brand.withOpacity(.3),
                    offset: const Offset(1, 2),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _Label('Email'),
            _Field(
              controller: _emailC,
              hint: 'Example@gmail.com',
              icon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return 'Email wajib diisi';
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(t);
                return ok ? null : 'Format email tidak valid';
              },
            ),
            const _Label('Password'),
            _Field(
              controller: _passC,
              hint: '•••••••••••••',
              icon: Icons.lock_outline,
              obscure: _obscure,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Password wajib diisi' : null,
              suffix: IconButton(
                tooltip: _obscure
                    ? 'Tampilkan password'
                    : 'Sembunyikan password',
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.brand,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _remember = !_remember),
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: Checkbox(
                          value: _remember,
                          activeColor: AppColors.brand,
                          onChanged: (v) =>
                              setState(() => _remember = v ?? false),
                        ),
                      ),
                      Text(
                        'Remember Me',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Forgot password?',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Center(
              child: SizedBox(
                width: 130,
                height: 42,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: AppColors.brand.withOpacity(.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Login',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                width: 200,
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.muted)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'or login with',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.muted)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _SocialButton(
                  semanticLabel: 'Login dengan Google',
                  onTap: () {},
                  // Ganti dengan logo Google resmi (asset/SVG) bila perlu.
                  child: Text(
                    'G',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF4285F4),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                _SocialButton(
                  semanticLabel: 'Login dengan Facebook',
                  onTap: () {},
                  child: const Icon(
                    Icons.facebook,
                    size: 20,
                    color: Color(0xFF1877F2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Center(
              child: Text.rich(
                TextSpan(
                  text: 'Belum punya akun? ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w700,
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
}

/// Header biru dengan logo, judul, dan sapaan.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 236,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 26),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(.35),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _LogoSlot(),
              const SizedBox(width: 14),
              Text(
                'PETENG',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppColors.glow.withOpacity(.55),
                      offset: const Offset(2, 2),
                    ),
                    Shadow(
                      color: AppColors.glow.withOpacity(.5),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            'Hello !',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Welcome to PETENG',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            'Petakan Gelap, Temukan Terang',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(.95),
            ),
          ),
        ],
      ),
    );
  }
}

/// >>> TANDA LOGO <<<
/// Menampilkan gambar dari [kLogoAsset]. Jika file belum ada,
/// otomatis tampil placeholder "LOGO".
class _LogoSlot extends StatelessWidget {
  const _LogoSlot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 74,
      height: 74,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: kShowLogoMarker
            ? Border.all(color: const Color(0xFFF0B429), width: 2)
            : null,
      ),
      child: ClipOval(
        child: Image.asset(
          kLogoAsset,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 22,
                color: AppColors.brand,
              ),
              Text(
                'LOGO',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brand,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 14, 0, 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.brand,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 7,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.brand),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted),
          prefixIcon: Icon(icon, color: AppColors.brand, size: 24),
          suffixIcon: suffix,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.brand, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFB3261E), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: AppColors.card,
        elevation: 2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 66,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.muted, width: 1),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.brandSoft,
        shape: BoxShape.circle,
      ),
    );
  }
}
