import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthApi {
  static const String baseUrl = 'http://10.0.142.212:8080/api/warga';

  static Future<void> register({
    required String nama,
    required String nomorTelepon,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nama': nama,
        'email': email,
        'password': password,
        'nomor_telepon': nomorTelepon,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Registrasi gagal');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(data['message'] ?? 'Login gagal');
    }

    final token = data['token'];

    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', token);

      // Simpan data warga supaya halaman profil bisa menampilkan nama,
      // email, dan nomor telepon dari akun yang sedang login.
      final user = data['user'];
      if (user is Map) {
        await prefs.setString('app_user', jsonEncode(user));
      }
    }

    return data;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token') != null;
  }

  /// Data warga yang tersimpan setelah login.
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('app_user');

    if (raw == null || raw.isEmpty) return null;

    try {
      final data = jsonDecode(raw);
      if (data is Map) return Map<String, dynamic>.from(data);
    } catch (_) {
      // Data lama/rusak: anggap belum ada sesi pengguna.
    }

    return null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('app_user');
  }
}
