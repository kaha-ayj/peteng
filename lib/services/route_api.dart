import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Error yang pesannya aman ditampilkan langsung ke pengguna.
class RouteException implements Exception {
  RouteException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Satu segmen kecil pada rute beserta kondisi penerangannya.
class SegmenPenerangan {
  const SegmenPenerangan({
    required this.awal,
    required this.akhir,
    required this.panjangMeter,
    required this.status,
    required this.sumberData,
  });

  /// Koordinat awal segmen.
  final LatLng awal;

  /// Koordinat akhir segmen.
  final LatLng akhir;
  final double panjangMeter;

  /// terang, redup, gelap, atau tidak_diketahui.
  final String status;
  final String sumberData;

  factory SegmenPenerangan.fromJson(Map<String, dynamic> json) {
    final koordinatAwal = _parseGeometry(json['koordinat_awal']);
    final koordinatAkhir = _parseGeometry(json['koordinat_akhir']);
    // Abaikan segmen dengan koordinat tidak valid.
    if (koordinatAwal.isEmpty || koordinatAkhir.isEmpty) {
      throw const FormatException('Koordinat segmen penerangan tidak valid.');
    }
    return SegmenPenerangan(
      awal: koordinatAwal.first,
      akhir: koordinatAkhir.first,
      panjangMeter: _toDouble(json['panjang_meter']) ?? 0,
      status: '${json['status'] ?? 'tidak_diketahui'}',
      sumberData: '${json['sumber_data'] ?? 'tidak_tersedia'}',
    );
  }
}

/// Satu opsi rute dari backend GET /api/navigasi/rute.
class RouteOption {
  RouteOption({
    required this.nomorRute,
    required this.jarakMeter,
    required this.durasiDetik,
    required this.titik,
    this.skorAkhir,
    this.skorPenerangan,
    this.persentaseDiketahui,
    this.persentaseTidakDiketahui,
    this.statusData = '',
    this.statusPenilaian = '',
    this.direkomendasikan = false,
    this.segmenPenerangan = const [],
  });

  final int nomorRute;
  final double jarakMeter;
  final double durasiDetik;
  final List<LatLng> titik;

  /// Data setiap segmen rute dari backend.
  final List<SegmenPenerangan> segmenPenerangan;

  /// Bisa null jika data penerangan belum cukup untuk menilai rute.
  final double? skorAkhir;
  final double? skorPenerangan;
  final double? persentaseDiketahui;
  final double? persentaseTidakDiketahui;

  /// Contoh: simulasi atau belum_terverifikasi.
  final String statusData;
  final String statusPenilaian;
  final bool direkomendasikan;

  bool get dataSimulasi => statusData == 'simulasi';

  String get jarakLabel {
    if (jarakMeter < 1000) return '${jarakMeter.round()} m';
    return '${(jarakMeter / 1000).toStringAsFixed(1)} km';
  }

  String get durasiLabel {
    final menit = (durasiDetik / 60).round();

    if (menit < 1) return '< 1 mnt';
    if (menit < 60) return '$menit mnt';

    final jam = menit ~/ 60;
    final sisa = menit % 60;

    return sisa == 0 ? '$jam j' : '$jam j $sisa mnt';
  }

  factory RouteOption.fromJson(Map<String, dynamic> j) {
    final pen = _asMap(_pick(j, ['penerangan'])) ?? <String, dynamic>{};

    // Parse daftar segmen penerangan dari respons backend.
    final rawSegmen = j['segmen_penerangan'];
    final segmen = <SegmenPenerangan>[];

    if (rawSegmen is List) {
      for (final item in rawSegmen) {
        if (item is! Map) continue;

        try {
          segmen.add(
            SegmenPenerangan.fromJson(Map<String, dynamic>.from(item)),
          );
        } on FormatException {
          // Lewati segmen yang koordinatnya tidak valid.
          continue;
        }
      }
    }

    return RouteOption(
      nomorRute: _toInt(_pick(j, ['nomor_rute', 'nomorRute'])) ?? 0,
      jarakMeter: _toDouble(_pick(j, ['jarak_meter', 'jarakMeter'])) ?? 0,
      durasiDetik: _toDouble(_pick(j, ['durasi_detik', 'durasiDetik'])) ?? 0,

      titik: _parseGeometry(
        _pick(j, [
          'geometri',
          'geometry',
          'garis_rute',
          'koordinat',
          'titik',
          'polyline',
        ]),
      ),

      skorAkhir: _toDouble(_pick(j, ['skor_akhir', 'skorAkhir'])),

      skorPenerangan: _toDouble(_pick(pen, ['skor_penerangan'])),

      persentaseDiketahui: _toDouble(
        _pick(pen, ['persentase_diketahui', 'persentaseDiketahui']),
      ),

      persentaseTidakDiketahui: _toDouble(
        _pick(pen, ['persentase_tidak_diketahui', 'persentaseTidakDiketahui']),
      ),

      statusData: '${_pick(pen, ['status_data']) ?? ''}',

      statusPenilaian: '${_pick(pen, ['status_penilaian']) ?? ''}',

      direkomendasikan: _pick(j, ['direkomendasikan']) == true,

      // Inilah bagian yang membaca segmen_penerangan.
      segmenPenerangan: segmen,
    );
  }
}

class RouteApi {
  // Ganti jika IP laptop berubah.
  // Emulator Android biasanya menggunakan 10.0.2.2.
  static const String baseUrl = 'http://192.168.0.110:8080/api/navigasi';

  static Future<List<RouteOption>> cari({
    required LatLng asal,
    required LatLng tujuan,
  }) async {
    final uri = Uri.parse('$baseUrl/rute').replace(
      queryParameters: {
        'start_lat': '${asal.latitude}',
        'start_lon': '${asal.longitude}',
        'end_lat': '${tujuan.latitude}',
        'end_lon': '${tujuan.longitude}',
      },
    );

    http.Response res;

    try {
      res = await http.get(uri).timeout(const Duration(seconds: 25));
    } on TimeoutException {
      throw RouteException('Server terlalu lama merespons. Coba lagi.');
    } on http.ClientException {
      throw RouteException(
        'Tidak bisa terhubung ke server. Pastikan backend menyala '
        'dan HP satu jaringan dengan laptop.',
      );
    }

    dynamic body;

    try {
      body = jsonDecode(res.body);
    } catch (_) {
      throw RouteException(
        'Respons server tidak dikenali (${res.statusCode}).',
      );
    }

    if (res.statusCode < 200 || res.statusCode >= 300) {
      final msg = body is Map ? body['message'] : null;

      throw RouteException(msg?.toString() ?? 'Gagal mencari rute.');
    }

    final data = body is Map ? body['data'] : null;

    final list = data is Map
        ? _pick(Map<String, dynamic>.from(data), ['rute'])
        : null;

    if (list is! List || list.isEmpty) {
      throw RouteException('Tidak ada rute yang ditemukan untuk titik ini.');
    }

    final hasil = <RouteOption>[
      for (final item in list)
        if (item is Map) RouteOption.fromJson(Map<String, dynamic>.from(item)),
    ];

    if (hasil.every((r) => r.titik.length < 2)) {
      throw RouteException(
        'Garis rute tidak terbaca dari respons backend '
        '(cek nama field geometri).',
      );
    }

    return hasil;
  }
}

dynamic _pick(Map<String, dynamic> m, List<String> keys) {
  for (final k in keys) {
    if (m.containsKey(k) && m[k] != null) {
      return m[k];
    }
  }

  return null;
}

Map<String, dynamic>? _asMap(dynamic v) {
  return v is Map ? Map<String, dynamic>.from(v) : null;
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();

  return double.tryParse('$v');
}

int? _toInt(dynamic v) => _toDouble(v)?.round();

/// Mendukung:
/// - GeoJSON {coordinates: [[lon, lat], ...]}
/// - Daftar koordinat [lon, lat]
/// - Daftar objek {lat, lon}
/// - Polyline terkode (string)
List<LatLng> _parseGeometry(dynamic g) {
  if (g == null) return [];

  if (g is String) {
    return _decodePolyline(g);
  }

  if (g is Map) {
    return _parseGeometry(g['coordinates']);
  }

  if (g is List) {
    final out = <LatLng>[];

    for (final p in g) {
      if (p is List && p.length >= 2) {
        final lon = _toDouble(p[0]);
        final lat = _toDouble(p[1]);

        if (lat != null && lon != null) {
          out.add(LatLng(lat, lon));
        }
      } else if (p is Map) {
        final lat = _toDouble(p['lat'] ?? p['latitude']);
        final lon = _toDouble(p['lon'] ?? p['lng'] ?? p['longitude']);

        if (lat != null && lon != null) {
          out.add(LatLng(lat, lon));
        }
      }
    }

    return out;
  }

  return [];
}

List<LatLng> _decodePolyline(String s, {int precision = 5}) {
  final factor = precision == 6 ? 1e6 : 1e5;
  final out = <LatLng>[];

  var index = 0;
  var lat = 0;
  var lng = 0;

  while (index < s.length) {
    for (final isLat in [true, false]) {
      var shift = 0;
      var result = 0;
      int b;

      do {
        if (index >= s.length) return out;

        b = s.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20 && index < s.length);

      final delta = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      if (isLat) {
        lat += delta;
      } else {
        lng += delta;
      }
    }

    out.add(LatLng(lat / factor, lng / factor));
  }

  return out;
}
