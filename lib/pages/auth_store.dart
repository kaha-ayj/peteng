/// ------------------------------------------------------------------
/// Penyimpanan akun SEMENTARA, hanya di memori aplikasi.
///
/// PENTING — batasan penyimpanan ini:
/// - Data hilang total setiap kali aplikasi ditutup/restart, karena tidak
///   disimpan ke database atau server mana pun.
/// - Password disimpan apa adanya (plain text) di memori, bukan di-hash.
///   Ini TIDAK AMAN untuk produksi.
/// - Cocok untuk mencoba alur Sign Up -> Login -> Home, TIDAK cocok
///   dipakai langsung sebagai backend aplikasi sungguhan.
///
/// Untuk produksi: ganti seluruh isi class AuthStore ini dengan
/// pemanggilan API/Firebase Auth yang sesungguhnya, dan biarkan server
/// yang menyimpan & memverifikasi kredensial (dengan password di-hash).
/// ------------------------------------------------------------------

class AppUser {
  final String nama;
  final String telepon;
  final String email;
  final String password;

  const AppUser({
    required this.nama,
    required this.telepon,
    required this.email,
    required this.password,
  });
}

enum LoginResult { success, notRegistered, wrongPassword }

class AuthStore {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  final Map<String, AppUser> _users = {}; // key: email (lowercase, trimmed)

  static String _key(String email) => email.trim().toLowerCase();

  bool isRegistered(String email) => _users.containsKey(_key(email));

  /// Mendaftarkan akun baru.
  /// Return true kalau berhasil, false kalau email sudah pernah dipakai.
  bool register({
    required String nama,
    required String telepon,
    required String email,
    required String password,
  }) {
    final key = _key(email);
    if (_users.containsKey(key)) return false;
    _users[key] = AppUser(
      nama: nama,
      telepon: telepon,
      email: email,
      password: password,
    );
    return true;
  }

  /// Mengecek kombinasi email + password terhadap akun yang tersimpan.
  LoginResult login({required String email, required String password}) {
    final user = _users[_key(email)];
    if (user == null) return LoginResult.notRegistered;
    if (user.password != password) return LoginResult.wrongPassword;
    return LoginResult.success;
  }
}
