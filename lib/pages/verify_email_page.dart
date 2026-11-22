import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_api.dart';
import 'login.dart';

const Color _brand = Color(0xFF172554);
const Color _cardBg = Color(0xFFF1F1EF);
const Color _muted = Color(0xFF5B6070);
const Color _glow = Color(0xFFE8D98A);

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key, required this.email, this.debugCode});

  final String email;

  /// Kode dari response backend saat SMTP belum dikonfigurasi (mode dev).
  final String? debugCode;

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final _codeC = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  int _seconds = 60;
  Timer? _timer;
  String? _devCode;

  @override
  void initState() {
    super.initState();
    _devCode = widget.debugCode;
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeC.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _timer?.cancel();

    setState(() {
      _seconds = seconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_seconds <= 1) {
        timer.cancel();
        setState(() {
          _seconds = 0;
        });
        return;
      }

      setState(() {
        _seconds -= 1;
      });
    });
  }

  void _info(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    if (_isLoading) return;

    final code = _codeC.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _info('Masukkan 6 digit kode verifikasi dari email.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthApi.verifyEmail(email: widget.email, code: code);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          icon: const Icon(
            Icons.verified_rounded,
            color: Color(0xFF026343),
            size: 44,
          ),
          title: Text(
            'Email terverifikasi',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Akun ${widget.email} sudah aktif. Silakan login.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: _muted),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(backgroundColor: _brand),
              child: Text(
                'Login',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    } on AuthException catch (error) {
      if (!mounted) return;
      _info(error.message);
    } catch (_) {
      if (!mounted) return;
      _info('Verifikasi gagal. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_isResending || _seconds > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      final result = await AuthApi.resendVerification(email: widget.email);

      if (!mounted) return;

      setState(() {
        if (result.debugCode != null && result.debugCode!.isNotEmpty) {
          _devCode = result.debugCode;
        }
      });

      _startCooldown();
      _info(result.message);
    } on AuthException catch (error) {
      if (!mounted) return;
      _info(error.message);
    } catch (_) {
      if (!mounted) return;
      _info('Gagal mengirim ulang kode. Coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: _cardBg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(24, 18, 24, 24 + bottomInset),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 22),
                  Text(
                    'VERIFIKASI EMAIL',
                    style: GoogleFonts.poppins(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .4,
                      color: _brand,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: 'Kode 6 digit sudah dikirim ke\n',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.5,
                        color: _muted,
                      ),
                      children: [
                        TextSpan(
                          text: widget.email,
                          style: const TextStyle(
                            color: _brand,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_devCode != null) ...[
                    _buildDevCode(),
                    const SizedBox(height: 14),
                  ],
                  _buildCodeField(),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        elevation: 5,
                        shadowColor: _brand.withValues(alpha: .4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Verifikasi',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Belum menerima kode?',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                        TextButton(
                          onPressed: (_seconds > 0 || _isResending)
                              ? null
                              : _resend,
                          child: _isResending
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _brand,
                                  ),
                                )
                              : Text(
                                  _seconds > 0
                                      ? 'Kirim ulang (${_seconds}s)'
                                      : 'Kirim ulang',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _brand,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: _muted,
                      ),
                      label: Text(
                        'Kembali ke Login',
                        style: GoogleFonts.poppins(fontSize: 12, color: _muted),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      decoration: BoxDecoration(
        color: _brand,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brand.withValues(alpha: .3),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF0B429), width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                'lib/assets/images/logo_bulet.png',
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.lightbulb_outline, color: _brand),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PETENG',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: _glow.withValues(alpha: .5),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              Text(
                'Satu langkah lagi',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: .85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDevCode() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6D8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8D98A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF8A6D00),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode dev (SMTP belum aktif). Kode: $_devCode',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.4,
                color: const Color(0xFF6B5400),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _codeC,
        autofocus: true,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        style: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: 10,
          color: _brand,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '••••••',
          hintStyle: GoogleFonts.poppins(
            fontSize: 26,
            letterSpacing: 10,
            color: _muted.withValues(alpha: .35),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _brand, width: 2),
          ),
        ),
        onSubmitted: (_) => _verify(),
      ),
    );
  }
}
