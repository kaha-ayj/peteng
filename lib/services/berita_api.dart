import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../pages/api_config.dart';
import '../pages/laporan_api.dart' show kLaporanPath;

/// Satu berita wilayah Indramayu hasil tarikan dari web (Google News RSS).
class BeritaItem {
  BeritaItem({
    required this.judul,
    required this.sumber,
    required this.url,
    required this.waktu,
    required this.kategori,
  });

  final String judul;
  final String sumber;
  final String url;
  final DateTime? waktu;
  final String kategori;
}

/// Satu laporan warga (dari server kalau tersedia, atau simpanan lokal).
class LaporanWargaItem {
  LaporanWargaItem({
    required this.id,
    required this.kategori,
    required this.deskripsi,
    required this.lokasi,
    required this.tingkat,
    required this.waktu,
  });

  final String id;
  final String kategori;
  final String deskripsi;
  final String lokasi;
  final int tingkat;
  final DateTime waktu;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kategori': kategori,
    'deskripsi': deskripsi,
    'lokasi': lokasi,
    'tingkat': tingkat,
    'waktu': waktu.toIso8601String(),
  };

  factory LaporanWargaItem.fromJson(Map<String, dynamic> json) {
    final waktuRaw =
        json['waktu'] ?? json['created_at'] ?? json['createdAt'] ?? '';
    return LaporanWargaItem(
      id: (json['id'] ?? json['id_laporan'] ?? '').toString(),
      kategori: (json['kategori'] ?? 'Laporan Warga').toString(),
      deskripsi: (json['deskripsi'] ?? json['keterangan'] ?? '').toString(),
      lokasi: (json['lokasi'] ?? json['keterangan_lokasi'] ?? '').toString(),
      tingkat:
          int.tryParse(
            '${json['tingkat'] ?? json['tingkat_kegelapan'] ?? 0}',
          ) ??
          0,
      waktu: DateTime.tryParse(waktuRaw.toString()) ?? DateTime.now(),
    );
  }
}

/// Label waktu relatif sederhana dalam bahasa Indonesia.
String labelWaktu(DateTime? waktu) {
  if (waktu == null) return '';

  final selisih = DateTime.now().difference(waktu.toLocal());
  if (selisih.isNegative || selisih.inMinutes < 1) return 'Baru saja';
  if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
  if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
  if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';

  const bulan = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  final lokal = waktu.toLocal();
  return '${lokal.day} ${bulan[lokal.month - 1]} ${lokal.year}';
}

/// Berita seputar Indramayu: kriminalitas jalanan (begal, curanmor, dsb.)
/// dan kondisi penerangan jalan. Diambil dari Google News RSS sehingga
/// sumbernya bisa dari Kompas.com, Detik, Tribun, dan media lain.
class BeritaApi {
  BeritaApi._();

  static const String _query =
      'Indramayu begal OR kejahatan OR kriminal OR curanmor OR '
      'penerangan jalan OR lampu jalan';

  static Future<List<BeritaItem>> ambilBeritaIndramayu({
    http.Client? client,
  }) async {
    final uri = Uri.https('news.google.com', '/rss/search', {
      'q': _query,
      'hl': 'id',
      'gl': 'ID',
      'ceid': 'ID:id',
    });

    final pemilik = client == null;
    final c = client ?? http.Client();

    try {
      final res = await c
          .get(
            uri,
            headers: {
              'Accept': 'application/rss+xml, application/xml, text/xml',
              'User-Agent': 'PETENG-App/1.0 (+Indramayu)',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode < 200 || res.statusCode >= 300) return const [];

      final xml = res.body;
      final items = RegExp(r'<item>(.*?)</item>', dotAll: true).allMatches(xml);

      final hasil = <BeritaItem>[];
      for (final m in items) {
        final blok = m.group(1) ?? '';
        final judul = _tag(blok, 'title');
        if (judul.isEmpty) continue;

        final sumberTag = RegExp(
          r'<source[^>]*>(.*?)</source>',
          dotAll: true,
        ).firstMatch(blok);
        var sumber = sumberTag == null ? '' : _bersih(sumberTag.group(1) ?? '');

        var judulBersih = judul;
        if (sumber.isNotEmpty && judulBersih.endsWith(' - $sumber')) {
          judulBersih = judulBersih.substring(
            0,
            judulBersih.length - sumber.length - 3,
          );
        } else if (sumber.isEmpty && judulBersih.contains(' - ')) {
          final pisah = judulBersih.lastIndexOf(' - ');
          sumber = judulBersih.substring(pisah + 3).trim();
          judulBersih = judulBersih.substring(0, pisah).trim();
        }

        final waktu = _parseTanggal(_tag(blok, 'pubDate'));

        hasil.add(
          BeritaItem(
            judul: judulBersih,
            sumber: sumber.isEmpty ? 'Google News' : sumber,
            url: _tag(blok, 'link'),
            waktu: waktu,
            kategori: _kategori(judulBersih),
          ),
        );
      }

      return hasil.take(18).toList();
    } on Exception {
      return const [];
    } finally {
      if (pemilik) c.close();
    }
  }

  static String _tag(String blok, String nama) {
    final m = RegExp(
      '<$nama[^>]*>(.*?)</$nama>',
      dotAll: true,
    ).firstMatch(blok);
    return m == null ? '' : _bersih(m.group(1) ?? '');
  }

  static String _bersih(String teks) {
    var s = teks.trim();
    if (s.startsWith('<![CDATA[')) {
      s = s.substring(9);
      if (s.endsWith(']]>')) s = s.substring(0, s.length - 3);
    }
    s = s
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.tryParse(m.group(1) ?? '') ?? 32),
        )
        .replaceAllMapped(
          RegExp(r'&#x([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(
            int.tryParse(m.group(1) ?? '', radix: 16) ?? 32,
          ),
        );
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Format tanggal RSS: `Sat, 22 Aug 2026 07:00:00 GMT` (RFC 822).
  /// `DateTime.parse` Dart tidak menerima format ini, jadi diurai manual.
  static DateTime? _parseTanggal(String raw) {
    final teks = raw.trim();
    if (teks.isEmpty) return null;

    final iso = DateTime.tryParse(teks);
    if (iso != null) return iso;

    final m = RegExp(
      r'(\d{1,2})\s+([A-Za-z]{3,})\s+(\d{4})\s+(\d{2}):(\d{2})(?::(\d{2}))?'
      r'\s*(GMT|UTC|([+-])(\d{2})(\d{2}))?',
    ).firstMatch(teks);
    if (m == null) return null;

    const bulan = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'mei': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'agu': 8,
      'ags': 8,
      'sep': 9,
      'oct': 10,
      'okt': 10,
      'nov': 11,
      'dec': 12,
      'des': 12,
    };

    final hari = int.tryParse(m.group(1) ?? '');
    final bulanKe = bulan[(m.group(2) ?? '').toLowerCase()];
    final tahun = int.tryParse(m.group(3) ?? '');
    final jam = int.tryParse(m.group(4) ?? '');
    final menit = int.tryParse(m.group(5) ?? '');
    final detik = int.tryParse(m.group(6) ?? '0');
    if (hari == null ||
        bulanKe == null ||
        tahun == null ||
        jam == null ||
        menit == null) {
      return null;
    }

    var waktu = DateTime.utc(tahun, bulanKe, hari, jam, menit, detik ?? 0);

    final tanda = m.group(8);
    if (tanda != null) {
      final offsetJam = int.tryParse(m.group(9) ?? '0') ?? 0;
      final offsetMenit = int.tryParse(m.group(10) ?? '0') ?? 0;
      final offset = Duration(hours: offsetJam, minutes: offsetMenit);
      waktu = tanda == '-' ? waktu.add(offset) : waktu.subtract(offset);
    }

    return waktu;
  }

  static String _kategori(String judul) {
    final t = judul.toLowerCase();
    const kriminal = [
      'begal',
      'curanmor',
      'curat',
      'curas',
      'perampok',
      'rampok',
      'pencuri',
      'maling',
      'jambret',
      'kejahatan',
      'kriminal',
      'pembunuhan',
      'tawuran',
      'geng motor',
      'narkoba',
      'santet',
      'hipnotis',
      'preman',
    ];
    const penerangan = [
      'penerangan',
      'pju',
      'lampu jalan',
      'lampu',
      'gelap',
      'peteng',
      'listrik',
    ];
    const keselamatan = [
      'kecelakaan',
      'tabrak',
      'lakalantas',
      'laka',
      'terserempet',
      'keselamatan',
      'bahaya',
      'rawan',
    ];

    if (kriminal.any(t.contains)) return 'Kriminalitas';
    if (penerangan.any(t.contains)) return 'Penerangan';
    if (keselamatan.any(t.contains)) return 'Keselamatan';
    return 'Indramayu';
  }

  /// Dipakai juga oleh [ArtikelApi] untuk tanggal bergaya RSS.
  static DateTime? parseTanggal(String raw) => _parseTanggal(raw);
}

/// Artikel yang dibuat lewat web Dishub: bisa berupa tautan berita dari media
/// lain, atau artikel hasil laporan perbaikan warga yang sudah diproses.
class ArtikelDishub {
  ArtikelDishub({
    required this.judul,
    required this.isi,
    required this.link,
    required this.sumber,
    required this.kategori,
    required this.waktu,
    this.gambar,
    this.perbaikan = false,
  });

  final String judul;
  final String isi;
  final String link;
  final String sumber;
  final String kategori;
  final DateTime? waktu;
  final String? gambar;
  final bool perbaikan;
}

/// Mengambil artikel dari backend PETENG (dibuat lewat dashboard Dishub).
///
/// Endpoint default: `GET {API_BASE_URL}/artikel`. Kalau backend memakai path
/// lain, ubah [kArtikelPaths] di bawah.
class ArtikelApi {
  ArtikelApi._();

  /// Dicoba berurutan sampai ada yang mengembalikan data.
  static const List<String> kArtikelPaths = [
    '/artikel',
    '/berita',
    '/warga/artikel',
  ];

  static Future<List<ArtikelDishub>> ambil({http.Client? client}) async {
    final token = await bacaToken();
    final pemilik = client == null;
    final c = client ?? http.Client();

    try {
      for (final path in kArtikelPaths) {
        try {
          final hasil = await _coba(
            c,
            Uri.parse('$kApiBaseUrl$path'),
            token: token,
          );
          if (hasil.isNotEmpty) return hasil;
        } on Exception {
          // Server tidak terjangkau / timeout: hentikan percobaan path lain
          // supaya halaman tidak menunggu lama.
          break;
        }
      }
      return const [];
    } finally {
      if (pemilik) c.close();
    }
  }

  static Future<List<ArtikelDishub>> _coba(
    http.Client c,
    Uri uri, {
    String? token,
  }) async {
    final res = await c
        .get(
          uri,
          headers: {
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode < 200 || res.statusCode >= 300) return const [];
    if (res.body.trim().isEmpty) return const [];

    dynamic decoded;
    try {
      decoded = jsonDecode(res.body);
    } on FormatException {
      // Bukan JSON (mis. halaman HTML dashboard): anggap tidak ada data.
      return const [];
    }

    final raw = decoded is List
        ? decoded
        : decoded is Map
        ? (decoded['data'] ??
              decoded['artikel'] ??
              decoded['berita'] ??
              decoded['items'])
        : null;
    if (raw is! List) return const [];

    final hasil = <ArtikelDishub>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final artikel = _dariJson(Map<String, dynamic>.from(item));
      if (artikel != null) hasil.add(artikel);
    }
    return hasil;
  }

  static ArtikelDishub? _dariJson(Map<String, dynamic> m) {
    final judul = _ambil(m, ['judul', 'title', 'nama', 'nama_artikel']);
    final isi = _ambil(m, [
      'isi',
      'konten',
      'content',
      'deskripsi',
      'description',
      'ringkasan',
      'body',
    ]);
    if (judul.isEmpty && isi.isEmpty) return null;

    final link = _lengkapkanLink(
      _ambil(m, [
        'link',
        'url',
        'tautan',
        'link_artikel',
        'sumber_url',
        'source_url',
      ]),
    );
    final sumber = _ambil(m, [
      'sumber',
      'source',
      'penulis',
      'author',
      'media',
      'penerbit',
    ]);
    final kategori = _ambil(m, [
      'kategori',
      'category',
      'jenis',
      'tag',
      'tipe',
    ]);
    final gambar = _ambil(m, [
      'gambar',
      'image',
      'foto',
      'thumbnail',
      'cover',
      'gambar_url',
    ]);
    final waktuRaw = _ambil(m, [
      'created_at',
      'createdAt',
      'tanggal',
      'waktu',
      'published_at',
      'updated_at',
      'tgl',
    ]);

    final teksKategori = '$kategori $judul'.toLowerCase();
    final perbaikan =
        teksKategori.contains('perbaikan') ||
        teksKategori.contains('laporan warga') ||
        m['perbaikan'] == true ||
        m['is_perbaikan'] == true;

    return ArtikelDishub(
      judul: judul.isEmpty ? _potong(isi, 90) : judul,
      isi: isi,
      link: link,
      sumber: sumber,
      kategori: kategori,
      waktu: BeritaApi.parseTanggal(waktuRaw),
      gambar: gambar.isEmpty ? null : _lengkapkanLink(gambar),
      perbaikan: perbaikan,
    );
  }

  static String _ambil(Map<String, dynamic> m, List<String> kunci) {
    for (final k in kunci) {
      final v = m[k];
      if (v == null) continue;
      final teks = v.toString().trim();
      if (teks.isNotEmpty && teks.toLowerCase() != 'null') return teks;
    }
    return '';
  }

  static String _lengkapkanLink(String link) {
    if (link.isEmpty) return '';
    final uri = Uri.tryParse(link);
    if (uri != null && uri.hasScheme) return link;

    final base = Uri.parse(kApiBaseUrl);
    if (link.startsWith('/')) {
      return '${base.scheme}://${base.authority}$link';
    }
    return '${base.origin}/$link';
  }

  static String _potong(String teks, int maks) {
    if (teks.length <= maks) return teks;
    return '${teks.substring(0, maks - 3)}...';
  }
}

/// Menyimpan laporan warga yang dikirim dari perangkat ini, lalu
/// menampilkannya lagi di halaman Artikel. Kalau backend menyediakan
/// endpoint daftar laporan, data server dipakai lebih dulu.
class LaporanWargaStore {
  LaporanWargaStore._();

  static const String _prefKey = 'laporan_warga_lokal';
  static const int _maks = 20;

  static Future<void> simpan({
    required String id,
    required String kategori,
    required String deskripsi,
    required String lokasi,
    required int tingkat,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final daftar = prefs.getStringList(_prefKey) ?? <String>[];
      final item = LaporanWargaItem(
        id: id,
        kategori: kategori,
        deskripsi: deskripsi,
        lokasi: lokasi,
        tingkat: tingkat,
        waktu: DateTime.now(),
      );

      daftar.insert(0, jsonEncode(item.toJson()));
      if (daftar.length > _maks) {
        daftar.removeRange(_maks, daftar.length);
      }
      await prefs.setStringList(_prefKey, daftar);
    } on Exception {
      // Riwayat lokal hanya pelengkap; kegagalan menyimpan tidak fatal.
    }
  }

  static Future<List<LaporanWargaItem>> bacaLokal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final daftar = prefs.getStringList(_prefKey) ?? <String>[];
      final hasil = <LaporanWargaItem>[];
      for (final raw in daftar) {
        try {
          final json = jsonDecode(raw);
          if (json is Map) {
            hasil.add(
              LaporanWargaItem.fromJson(Map<String, dynamic>.from(json)),
            );
          }
        } on FormatException {
          // Lewati entri rusak.
        }
      }
      return hasil;
    } on Exception {
      return const [];
    }
  }

  /// Coba ambil dari server, kalau tidak tersedia pakai simpanan lokal.
  static Future<List<LaporanWargaItem>> ambil() async {
    final server = await _ambilServer();
    if (server.isNotEmpty) return server;
    return bacaLokal();
  }

  static Future<List<LaporanWargaItem>> _ambilServer() async {
    try {
      final token = await bacaToken();
      if (token == null || token.isEmpty) return const [];

      final res = await http
          .get(
            Uri.parse('$kApiBaseUrl$kLaporanPath'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 12));

      if (res.statusCode < 200 || res.statusCode >= 300) return const [];

      final decoded = jsonDecode(res.body);
      final raw = decoded is List
          ? decoded
          : decoded is Map
          ? (decoded['data'] ?? decoded['laporan'])
          : null;
      if (raw is! List) return const [];

      return raw
          .whereType<Map>()
          .map((m) => LaporanWargaItem.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } on Exception {
      return const [];
    }
  }
}
