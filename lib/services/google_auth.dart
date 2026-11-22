import 'package:google_sign_in/google_sign_in.dart';

import 'auth_api.dart';

/// Login Google memakai google_sign_in 7.x.
///
/// ID token dikirim ke backend untuk diverifikasi. Client ID tidak
/// di-hardcode; isi lewat:
/// flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
class GoogleAuth {
  GoogleAuth._();

  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static bool _initialized = false;

  static bool get isConfigured => _serverClientId.isNotEmpty;

  static Future<String> signInAndGetIdToken() async {
    if (_serverClientId.isEmpty) {
      throw const AuthException(
        'GOOGLE_SERVER_CLIENT_ID belum diisi. Jalankan aplikasi dengan '
        '--dart-define=GOOGLE_SERVER_CLIENT_ID=...',
        code: 'google_belum_dikonfigurasi',
      );
    }

    final googleSignIn = GoogleSignIn.instance;

    if (!_initialized) {
      await googleSignIn.initialize(serverClientId: _serverClientId);
      _initialized = true;
    }

    try {
      final account = await googleSignIn.authenticate();
      final idToken = account.authentication.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw const AuthException(
          'Google tidak mengembalikan ID token. Pastikan OAuth client '
          'Android (package + SHA-1) sudah benar.',
          code: 'google_token_kosong',
        );
      }

      return idToken;
    } on GoogleSignInException catch (error) {
      throw AuthException(
        'Google Sign-In gagal: ${error.description ?? error.code.name}',
        code: 'google_gagal',
      );
    }
  }

  static Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Abaikan: sesi lokal tetap dihapus oleh AuthApi.logout().
    }
  }
}
