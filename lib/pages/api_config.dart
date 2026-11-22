import 'package:shared_preferences/shared_preferences.dart';

/// Alamat backend Go.
///
/// Bisa dioverride saat menjalankan aplikasi tanpa mengubah kode:
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8080/api
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.0.103:8080/api',
);

/// Token JWT yang disimpan auth_api.dart saat login (kunci 'jwt_token').
Future<String?> bacaToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  } catch (_) {
    return null;
  }
}
