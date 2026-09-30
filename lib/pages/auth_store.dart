import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final int idWarga;
  final String nama;
  final String telepon;
  final String email;

  const AppUser({
    required this.idWarga,
    required this.nama,
    required this.telepon,
    required this.email,
  });

  factory AppUser.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppUser(
      idWarga: json['id_warga'] ?? 0,
      nama: json['nama'] ?? '',
      telepon: json['nomor_telepon'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_warga': idWarga,
      'nama': nama,
      'nomor_telepon': telepon,
      'email': email,
    };
  }
}

enum LoginResult {
  success,
  notRegistered,
  wrongPassword,
  networkError,
}

class AuthStore {
  AuthStore._();

  static final AuthStore instance = AuthStore._();

  // Android Emulator
  static const String _baseUrl =
      'http://127.0.0.1:8080/api/warga';

  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'app_user';

  /// ================================================================
  /// REGISTER
  /// ================================================================

  Future<bool> register({
    required String nama,
    required String telepon,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/register'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'nama': nama.trim(),
              'nomor_telepon': telepon.trim(),
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      return response.statusCode == 200 ||
          response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  /// ================================================================
  /// LOGIN
  /// ================================================================

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/login'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'password': password,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = data['token'];

        if (token == null ||
            token.toString().isEmpty) {
          return LoginResult.networkError;
        }

        final userJson = data['user'];

        if (userJson == null) {
          return LoginResult.networkError;
        }

        final user = AppUser.fromJson(
          Map<String, dynamic>.from(userJson),
        );

        // Simpan session.
        final prefs =
            await SharedPreferences.getInstance();

        await prefs.setString(
          _tokenKey,
          token.toString(),
        );

        await prefs.setString(
          _userKey,
          jsonEncode(user.toJson()),
        );

        return LoginResult.success;
      }

      if (response.statusCode == 401) {
        final message =
            response.body.toLowerCase();

        if (message.contains(
          'email tidak ditemukan',
        )) {
          return LoginResult.notRegistered;
        }

        if (message.contains(
          'password salah',
        )) {
          return LoginResult.wrongPassword;
        }

        return LoginResult.wrongPassword;
      }

      return LoginResult.networkError;
    } catch (e) {
      return LoginResult.networkError;
    }
  }

  /// ================================================================
  /// CEK LOGIN
  /// ================================================================

  Future<bool> isLoggedIn() async {
    final prefs =
        await SharedPreferences.getInstance();

    final token = prefs.getString(_tokenKey);

    return token != null && token.isNotEmpty;
  }

  /// ================================================================
  /// AMBIL JWT
  /// ================================================================

  Future<String?> getToken() async {
    final prefs =
        await SharedPreferences.getInstance();

    return prefs.getString(_tokenKey);
  }

  /// ================================================================
  /// AMBIL USER YANG SEDANG LOGIN
  /// ================================================================

  Future<AppUser?> getCurrentUser() async {
    final prefs =
        await SharedPreferences.getInstance();

    final userString =
        prefs.getString(_userKey);

    if (userString == null ||
        userString.isEmpty) {
      return null;
    }

    try {
      final json =
          jsonDecode(userString);

      return AppUser.fromJson(
        Map<String, dynamic>.from(json),
      );
    } catch (e) {
      return null;
    }
  }

  /// ================================================================
  /// LOGOUT
  /// ================================================================

  Future<void> logout() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// ================================================================
  /// HEADER UNTUK API YANG MEMBUTUHKAN LOGIN
  /// ================================================================

  Future<Map<String, String>>
      getAuthHeaders() async {
    final token = await getToken();

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }
}