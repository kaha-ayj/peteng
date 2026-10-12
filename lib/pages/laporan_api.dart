import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'api_config.dart';

/// POST /api/warga/laporan (laporan_handler.go, `Create`).
/// Perlu token JWT warga di header Authorization.
///
/// PENTING: endpoint asli di backend adalah `/api/warga/laporan`, sedangkan
/// path di bawah hanya `/warga/laporan`. Pastikan `kApiBaseUrl` di
/// api_config.dart berakhiran `/api` (contoh: http://10.0.2.2:8080/api).
/// Kalau tidak, hasilnya 404.
const String kLaporanPath = '/warga/laporan';

/// Batas panjang `keterangan_lokasi` yang dikirim. Panjang kolom di database
/// belum diketahui; 255 adalah tebakan aman. Ubah kalau kolommu lebih panjang.
const int kMaksKeteranganLokasi = 255;

/// Format `foto` yang dikirim ke backend.
/// false -> base64 polos ("/9j/4AAQ...")
/// true  -> data URI ("data:image/jpeg;base64,/9j/4AAQ...")
/// Samakan dengan yang diharapkan `usecase.BuatLaporan` (cek bagian yang
/// memanggil validasi foto AI / menyimpan foto).
const bool kFotoPakaiPrefixDataUri = false;

class LaporanDraft {
  const LaporanDraft({
    required this.fotoBytes,
    required this.lokasi,
    required this.kategori,
    required this.tingkatKegelapan,
    required this.deskripsi,
    this.alamat,
    this.awalLabel,
    this.akhirLabel,
    this.panjangM,
  });

  final Uint8List fotoBytes;
  final LatLng lokasi;
  final String kategori;
  final int tingkatKegelapan; // 1..3 -> int16 di backend
  final String deskripsi; // "Keterangan Tambahan" dari pengguna
  final String? alamat; // hasil reverse geocoding lokasi GPS
  final String? awalLabel;
  final String? akhirLabel;
  final double? panjangM;

  /// Backend hanya punya satu kolom teks untuk lokasi (`keterangan_lokasi`),
  /// jadi alamat dan segmen jalur gelap digabung ke situ.
  String get keteranganLokasi {
    final bagian = <String>[];
    if (alamat != null && alamat!.isNotEmpty) bagian.add(alamat!);
    if (awalLabel != null && akhirLabel != null) {
      final p = panjangM != null ? ' (±${panjangM!.round()} m)' : '';
      bagian.add('Ruas gelap: dari $awalLabel hingga $akhirLabel$p');
    }
    final s = bagian.join(' | ');
    return s.length <= kMaksKeteranganLokasi
        ? s
        : s.substring(0, kMaksKeteranganLokasi);
  }
}

enum LaporanHasil { diterima, ditolak, gagal }

class LaporanResult {
  const LaporanResult(this.hasil, this.pesan);
  final LaporanHasil hasil;
  final String pesan;
}

class LaporanApi {
  LaporanApi._();

  /// `LaporanReq.Foto` di backend bertipe string. Dikirim sebagai base64
  /// (lihat `kFotoPakaiPrefixDataUri`). Kalau ternyata backend mengharapkan
  /// hal lain (URL unggahan terpisah, dsb.), ubah di sini saja.
  static String _fotoJson(Uint8List bytes) {
    final b64 = base64Encode(bytes);
    return kFotoPakaiPrefixDataUri ? 'data:image/jpeg;base64,$b64' : b64;
  }

  static Future<LaporanResult> kirim(LaporanDraft d) async {
    try {
      final token = await bacaToken();
      final res = await http
          .post(
            Uri.parse('$kApiBaseUrl$kLaporanPath'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'foto': _fotoJson(d.fotoBytes),
              'latitude': d.lokasi.latitude,
              'longitude': d.lokasi.longitude,
              'keterangan_lokasi': d.keteranganLokasi,
              'kategori': d.kategori,
              'tingkat_kegelapan': d.tingkatKegelapan,
              'deskripsi': d.deskripsi,
            }),
          )
          // Validasi foto oleh AI di server bisa memakan waktu.
          .timeout(const Duration(seconds: 60));

      final pesan = _pesan(res);

      // Sukses: handler membalas 201 + {"status","message","data"}.
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return LaporanResult(
          LaporanHasil.diterima,
          pesan ?? 'Laporan terkirim.',
        );
      }

      switch (res.statusCode) {
        case 401:
          // Dari handler: "ID warga tidak ditemukan dari token".
          // Dari middleware: biasanya token tidak ada / kedaluwarsa.
          return LaporanResult(
            LaporanHasil.gagal,
            pesan == null
                ? 'Sesi login habis atau belum login. Silakan login ulang.'
                : 'Sesi login bermasalah: $pesan. Silakan login ulang.',
          );
        case 404:
          return LaporanResult(
            LaporanHasil.gagal,
            pesan ??
                'Endpoint laporan tidak ditemukan. Cek kApiBaseUrl (harus berakhiran /api) dan kLaporanPath.',
          );
        case 413:
          return const LaporanResult(
            LaporanHasil.gagal,
            'Foto terlalu besar untuk dikirim. Coba foto lain.',
          );
        case 400:
        case 422:
          // Handler `Create` membalas 400 untuk error dari usecase
          // (validasi, penolakan foto, dst.), pesannya dari backend.
          return LaporanResult(
            LaporanHasil.ditolak,
            pesan ?? 'Laporan ditolak. Periksa foto dan data yang diisi.',
          );
        default:
          if (res.statusCode >= 500) {
            return LaporanResult(
              LaporanHasil.gagal,
              pesan ?? 'Server bermasalah (kode ${res.statusCode}). Coba lagi.',
            );
          }
          return LaporanResult(
            LaporanHasil.gagal,
            pesan ?? 'Permintaan gagal (kode ${res.statusCode}).',
          );
      }
    } on TimeoutException {
      return const LaporanResult(
        LaporanHasil.gagal,
        'Server terlalu lama merespons. Coba lagi.',
      );
    } on Exception {
      return const LaporanResult(
        LaporanHasil.gagal,
        'Tidak bisa terhubung ke server. Pastikan backend sedang jalan.',
      );
    }
  }

  /// Pesan dari backend. Handler membalas dua bentuk:
  /// - JSON {"status","message"} (sukses, dan `writeJSONError`)
  /// - teks polos dari `http.Error` (ada newline di akhir, di-trim di sini)
  static String? _pesan(http.Response res) {
    final body = res.body.trim();
    if (body.isEmpty) return null;
    try {
      final m = jsonDecode(body);
      if (m is Map) {
        final p = m['message'] ?? m['error'];
        if (p is String && p.isNotEmpty) return p;
      }
      return null;
    } on FormatException {
      // Bukan JSON: anggap teks polos, asal pendek dan bukan halaman HTML.
      if (body.length <= 300 && !body.startsWith('<')) return body;
      return null;
    }
  }
}
