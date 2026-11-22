import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/api_config.dart';

/// Error auth yang pesannya aman ditampilkan langsung ke pengguna.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;

  /// Kode dari backend, contoh: email_belum_diverifikasi, akun_google.
  final String? code;

  @override
  String toString() => message;
}

class RegisterResult {
  const RegisterResult({
    required this.message,
    required this.emailSent,
    this.debugCode,
    this.email,
  });

  final String message;
  final bool emailSent;
  final String? debugCode;
  final String? email;
}

class AuthApi {
  AuthApi._();

  static const Duration _timeout = Duration(seconds: 25);
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'app_user';

  static Uri _uri(String path) => Uri.parse('$kApiBaseUrl/warga$path');

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    http.Response response;

    try {
      response = await http
          .post(
            _uri(path),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw const AuthException('Server terlalu lama merespons. Coba lagi.');
    } catch (_) {
      throw const AuthException(
        'Tidak bisa terhubung ke server. Pastikan backend menyala dan '
        'HP satu jaringan dengan laptop.',
      );
    }

    final raw = response.body.trim();
    var data = <String, dynamic>{};

    if (raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);

        if (decoded is Map) {
          data = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        // Respons bukan JSON (mis. http.Error). Pesan diambil dari teks.
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _messageFrom(data, raw, response.statusCode),
        code: data['code']?.toString(),
      );
    }

    return data;
  }

  static String _messageFrom(
    Map<String, dynamic> data,
    String raw,
    int statusCode,
  ) {
    final fromJson = (data['message'] ?? data['error'])?.toString().trim();

    if (fromJson != null && fromJson.isNotEmpty) {
      return fromJson;
    }

    if (raw.isNotEmpty && !raw.startsWith('<') && raw.length <= 300) {
      return raw;
    }

    return 'Permintaan gagal (kode $statusCode).';
  }

  /// ================================================================
  /// REGISTER + VERIFIKASI EMAIL
  /// ================================================================

  static Future<RegisterResult> register({
    required String nama,
    required String nomorTelepon,
    required String email,
    required String password,
  }) async {
    final data = await _post('/register', {
      'nama': nama.trim(),
      'nomor_telepon': nomorTelepon.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    return RegisterResult(
      message: (data['message'] ?? 'Akun berhasil dibuat.').toString(),
      emailSent: data['email_sent'] == true,
      debugCode: data['debug_code']?.toString(),
      email: email.trim().toLowerCase(),
    );
  }

  static Future<RegisterResult> registerWithGoogle({
    required String idToken,
    required String password,
  }) async {
    final data = await _post('/google', {
      'id_token': idToken,
      'password': password,
    });

    return RegisterResult(
      message: (data['message'] ?? 'Akun berhasil dibuat.').toString(),
      emailSent: data['email_sent'] == true,
      debugCode: data['debug_code']?.toString(),
      email: data['email']?.toString(),
    );
  }

  static Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    await _post('/verify-email', {
      'email': email.trim().toLowerCase(),
      'code': code.trim(),
    });
  }

  static Future<RegisterResult> resendVerification({
    required String email,
  }) async {
    final data = await _post('/resend-verification', {
      'email': email.trim().toLowerCase(),
    });

    return RegisterResult(
      message: (data['message'] ?? 'Kode verifikasi dikirim ulang.').toString(),
      emailSent: data['email_sent'] == true,
      debugCode: data['debug_code']?.toString(),
      email: email.trim().toLowerCase(),
    );
  }

  /// ================================================================
  /// LOGIN
  /// ================================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _post('/login', {
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    await _saveSession(data);
    return data;
  }

  static Future<Map<String, dynamic>> loginWithGoogle({
    required String idToken,
  }) async {
    final data = await _post('/google', {'id_token': idToken});

    await _saveSession(data);
    return data;
  }

  static Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'];

    if (token == null || token.toString().isEmpty) {
      throw const AuthException('Server tidak mengirim token login.');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token.toString());

    // Simpan data warga supaya halaman profil bisa menampilkan nama,
    // email, dan nomor telepon dari akun yang sedang login.
    final user = data['user'];

    if (user is Map) {
      await prefs.setString(_userKey, jsonEncode(user));
    }
  }

  /// ================================================================
  /// SESSION
  /// ================================================================

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);

    return token != null && token.isNotEmpty;
  }

  /// Data warga yang tersimpan setelah login.
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_userKey);

    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw);
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {
      // Data lama/rusak: anggap belum ada sesi pengguna.
    }

    return null;
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
