import 'package:shared_preferences/shared_preferences.dart';

/// Alamat backend Go (sama dengan `baseUrl` di auth_api.dart, dipotong
/// sampai '/api'). Kalau IP komputermu berubah, ganti di sini DAN di
/// auth_api.dart.
const String kApiBaseUrl = 'http://192.168.0.108:8080/api';

/// Token JWT yang disimpan auth_api.dart saat login (kunci 'jwt_token').
Future<String?> bacaToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  } catch (_) {
    return null;
  }
}
