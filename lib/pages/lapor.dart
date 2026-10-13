import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import 'home.dart' show AppColors, AppBottomNav;
import 'laporan_api.dart';
import 'peta_rute.dart';
import 'article_page.dart';
import 'place_search.dart';


const bool kTampilkanSimulasiAI = true;

const Color _cRedup = Color(0xFFC27605);
const Color _cGelap = Color(0xFFBE003D);
const Color _cGulita = Color(0xFF7A0026);
const Color _cTerang = Color(0xFF026343);


const List<({String value, String label})> kKategoriLaporan = [
  (value: 'pju_mati_total', label: 'PJU Mati Total'),
  (value: 'pju_redup_kedip', label: 'PJU Redup / Kedip'),
  (value: 'tiang_roboh_rusak', label: 'Tiang Roboh / Rusak'),
  (value: 'belum_ada_jaringan', label: 'Belum Ada Jaringan PJU'),
  (value: 'lainnya', label: 'Lainnya'),
];

class _Tingkat {
  const _Tingkat(
    this.nilai,
    this.judul,
    this.deskripsi,
    this.icon,
    this.warna, {
    this.kritis = false,
  });

  final int nilai;
  final String judul;
  final String deskripsi;
  final IconData icon;
  final Color warna;
  final bool kritis;
}

/// Nilai 1..3 dikirim ke backend sebagai `tingkat_kegelapan`.
/// Proposal menyebut bintang 1-5, sedangkan desain terbaru memakai 3 tingkat;
/// di sini mengikuti desain. Pastikan usecase backend menerima rentang 1-3.
const List<_Tingkat> _tingkat = [
  _Tingkat(
    1,
    'Tingkat 1 • Terang',
    'Tampak siluet aspal & pohon',
    Icons.wb_twighlight,
    _cRedup,
  ),
  _Tingkat(
    2,
    'Tingkat 2 • Remang',
    'Jarak pandang mata bebas < 10 meter',
    Icons.nightlight_round,
    _cGelap,
  ),
  _Tingkat(
    3,
    'Tingkat 3 • Gelap Gulita',
    'Sangat berbahaya bagi pesepeda motor & pejalan kaki di Indramayu',
    Icons.dark_mode,
    _cGulita,
    kritis: true,
  ),
];

enum _GpsState { loading, ok, error }

class LaporPage extends StatefulWidget {
  const LaporPage({super.key});

  @override
  State<LaporPage> createState() => _LaporPageState();
}

class _LaporPageState extends State<LaporPage> {
  final TextEditingController _keteranganC = TextEditingController();

  _GpsState _gps = _GpsState.loading;
  String? _gpsError;
  LatLng? _pos;
  double? _akurasi;
  String? _alamat;

  Uint8List? _fotoBytes;
  String _fotoSumber = 'kamera';
  DateTime? _fotoWaktu;

  LatLng? _awal;
  String? _awalLabel;
  LatLng? _akhir;
  String? _akhirLabel;
  double?
  _jarakLurus; // panjang ruas gelap (meter), terisi otomatis dari dua titik
  final MapController _segMap = MapController();
  DateTime? _geoTerakhir; // pembatas 1 permintaan/detik ke Nominatim

  String? _kategori;
  int _tingkatDipilih = 0;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ambilGps();
  }

  @override
  void dispose() {
    _keteranganC.dispose();
    _segMap.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------------------------------------------
  // Navigasi bawah
  // ------------------------------------------------------------------

  void _onNavTap(int i) {
    if (_sending) return; 
    switch (i) {
      case 0: 
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1: 
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PetaRutePage()),
        );
        break;
      case 2: // Lapor: sudah di halaman ini
        break;
      case 3: // Artikel
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ArticlePage()),
        );
        break;
    }
  }

  // ------------------------------------------------------------------
  // GPS + alamat
  // ------------------------------------------------------------------

  void _gpsGagal(String pesan) {
    if (!mounted) return;
    setState(() {
      _gps = _GpsState.error;
      _gpsError = pesan;
    });
  }

  Future<void> _ambilGps() async {
    setState(() {
      _gps = _GpsState.loading;
      _gpsError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _gpsGagal('GPS/Layanan lokasi mati. Aktifkan dulu di pengaturan HP.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        _gpsGagal('Izin lokasi ditolak, lokasi laporan tidak bisa diambil.');
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        _gpsGagal(
          'Izin lokasi diblokir. Aktifkan lewat Pengaturan > Aplikasi > peteng > Izin.',
        );
        return;
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      final ll = LatLng(p.latitude, p.longitude);
      setState(() {
        _pos = ll;
        _akurasi = p.accuracy;
        _gps = _GpsState.ok;
        _alamat = null;
      });
      if (_awal == null && _akhir == null) {
        try {
          _segMap.move(ll, 16);
        } catch (_) {}
      }
      final alamat = await _reverseGeocode(ll);
      if (mounted && _pos == ll) setState(() => _alamat = alamat);
    } catch (e) {
      debugPrint('GPS ERROR: $e');
      _gpsGagal('Gagal mengambil lokasi. Coba lagi.');
    }
  }

  // ------------------------------------------------------------------
  // Foto
  // ------------------------------------------------------------------

  Future<void> _pilihFoto(ImageSource sumber) async {
    try {
      final x = await ImagePicker().pickImage(
        source: sumber,
        imageQuality: 80,
        maxWidth: 1920,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      DateTime waktu = DateTime.now();
      if (sumber == ImageSource.gallery) {
        try {
          waktu = await x.lastModified();
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _fotoBytes = bytes;
        _fotoSumber = sumber == ImageSource.camera ? 'kamera' : 'galeri';
        _fotoWaktu = waktu;
      });
    } catch (e) {
      debugPrint('FOTO ERROR: $e');
      _snack(
        'Tidak bisa mengambil foto. Pastikan izin kamera/galeri diberikan.',
      );
    }
  }

  void _zoomFoto() {
    final b = _fotoBytes;
    if (b == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(child: Center(child: Image.memory(b))),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Segmen jalur gelap
  // ------------------------------------------------------------------

  Future<void> _cariTitik({required bool awal}) async {
    final r = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlaceSearchSheet(
        title: awal ? 'Cari titik awal gelap' : 'Cari titik akhir gelap',
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      if (awal) {
        _awal = r.point;
        _awalLabel = r.name;
      } else {
        _akhir = r.point;
        _akhirLabel = r.name;
      }
    });
    _hitungPanjang();
  }

  void _pakaiGps({required bool awal}) {
    final p = _pos;
    if (p == null) {
      _snack('Lokasi GPS belum tersedia.');
      return;
    }
    setState(() {
      if (awal) {
        _awal = p;
        _awalLabel = _alamat ?? 'Lokasi saya';
      } else {
        _akhir = p;
        _akhirLabel = _alamat ?? 'Lokasi saya';
      }
    });
    _hitungPanjang();
  }

  /// Panjang ruas gelap dihitung otomatis begitu titik awal & akhir terisi.
  /// Ini jarak garis lurus antar dua titik (BUKAN panjang jalan sebenarnya).
  void _hitungPanjang({bool fit = true}) {
    final a = _awal;
    final b = _akhir;
    if (a == null || b == null) {
      setState(() => _jarakLurus = null);
      if (fit) _fitSegmen();
      return;
    }
    final m = const Distance().as(LengthUnit.Meter, a, b);
    setState(() => _jarakLurus = m);
    if (fit) _fitSegmen();
  }

  /// Geser/zoom peta segmen supaya titik yang dipilih kelihatan.
  void _fitSegmen() {
    final a = _awal;
    final b = _akhir;
    try {
      if (a != null && b != null && a != b) {
        _segMap.fitCamera(
          CameraFit.coordinates(
            coordinates: [a, b],
            padding: const EdgeInsets.all(48),
          ),
        );
      } else if (a != null || b != null) {
        _segMap.move((a ?? b)!, 16);
      }
    } catch (e) {
      debugPrint('FIT SEGMEN ERROR: $e');
    }
  }

  /// Peta diketuk. Tanpa tombol pilihan: ketukan pertama = titik awal,
  /// kedua = titik akhir, berikutnya menggeser titik yang paling dekat
  /// dengan ketukan.
  Future<void> _setTitikDariPeta(LatLng p) async {
    final bool untukAwal;
    if (_awal == null) {
      untukAwal = true;
    } else if (_akhir == null) {
      untukAwal = false;
    } else {
      const jarak = Distance();
      untukAwal =
          jarak.as(LengthUnit.Meter, p, _awal!) <=
          jarak.as(LengthUnit.Meter, p, _akhir!);
    }
    setState(() {
      if (untukAwal) {
        _awal = p;
        _awalLabel = _formatKoordinat(p);
      } else {
        _akhir = p;
        _akhirLabel = _formatKoordinat(p);
      }
    });
    _hitungPanjang(fit: false); // jangan geser peta di bawah jari pengguna

    // Nama jalan: maks 1 permintaan/detik (kebijakan Nominatim).
    final sekarang = DateTime.now();
    final terakhir = _geoTerakhir;
    if (terakhir != null &&
        sekarang.difference(terakhir) < const Duration(milliseconds: 1100)) {
      return;
    }
    _geoTerakhir = sekarang;
    final label = await _reverseGeocode(p);
    if (!mounted || label == null) return;
    setState(() {
      if (untukAwal && _awal == p) _awalLabel = label;
      if (!untukAwal && _akhir == p) _akhirLabel = label;
    });
  }

  // ------------------------------------------------------------------
  // Kirim
  // ------------------------------------------------------------------

  Future<void> _kirim() async {
    if (_sending) return;

    final kurang = <String>[];
    if (_fotoBytes == null) kurang.add('foto');
    if (_pos == null) kurang.add('lokasi GPS');
    if (_kategori == null) kurang.add('kategori kendala');
    if (_tingkatDipilih == 0) kurang.add('tingkat kegelapan');
    if ((_awal == null) != (_akhir == null)) {
      kurang.add('titik awal & akhir (isi keduanya atau kosongkan keduanya)');
    }
    if (kurang.isNotEmpty) {
      _snack('Lengkapi dulu: ${kurang.join(', ')}.');
      return;
    }

    setState(() => _sending = true);
    final hasil = await LaporanApi.kirim(
      LaporanDraft(
        fotoBytes: _fotoBytes!,
        lokasi: _pos!,
        kategori: _kategori!,
        tingkatKegelapan: _tingkatDipilih,
        deskripsi: _keteranganC.text.trim(),
        alamat: _alamat,
        awalLabel: _awalLabel,
        akhirLabel: _akhirLabel,
        panjangM: (_awal != null && _akhir != null) ? _jarakLurus : null,
      ),
    );
    if (!mounted) return;
    setState(() => _sending = false);

    switch (hasil.hasil) {
      case LaporanHasil.diterima:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LaporanTerkirimPage()),
        );
        break;
      case LaporanHasil.ditolak:
        _dialogDitolak(hasil.pesan);
        break;
      case LaporanHasil.gagal:
        _snack(hasil.pesan);
        break;
    }
  }

  void _dialogDitolak(String pesan) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Laporan belum bisa diterima'),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() => _fotoBytes = null);
            },
            child: const Text('Ganti foto'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.card,
        bottomNavigationBar: AppBottomNav(index: 2, onTap: _onNavTap),
        body: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 14),
                _lokasiCard(),
                const SizedBox(height: 14),
                _fotoCard(),
                const SizedBox(height: 14),
                _segmenCard(),
                const SizedBox(height: 14),
                _kategoriCard(),
                const SizedBox(height: 14),
                _tingkatCard(),
                const SizedBox(height: 14),
                _keteranganCard(),
                const SizedBox(height: 18),
                _kirimBagian(),
                if (kTampilkanSimulasiAI) ...[
                  const SizedBox(height: 22),
                  const _AiSimulasiCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Material(
          color: Colors.white,
          elevation: 2,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => Navigator.of(context).maybePop(),
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(Icons.arrow_back, size: 20, color: AppColors.brand),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Buat Laporan',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brand),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _lokasiCard() {
    late final String chipText;
    late final Color chipColor;
    late final String judul;
    switch (_gps) {
      case _GpsState.loading:
        chipText = 'MENCARI GPS…';
        chipColor = AppColors.muted;
        judul = 'Mencari lokasi kamu…';
        break;
      case _GpsState.error:
        chipText = 'GPS BERMASALAH';
        chipColor = _cGelap;
        judul = _gpsError ?? 'Lokasi tidak tersedia.';
        break;
      case _GpsState.ok:
        final acc = (_akurasi ?? 0).round();
        final bagus = acc <= 50;
        chipText = bagus
            ? 'GPS TERKUNCI • AKURASI ${acc}M'
            : 'AKURASI RENDAH • ${acc}M';
        chipColor = bagus ? _cTerang : _cRedup;
        judul =
            _alamat ??
            '${_pos!.latitude.toStringAsFixed(5)}, ${_pos!.longitude.toStringAsFixed(5)}';
        break;
    }

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: _MiniChip(text: chipText, fg: chipColor, dot: true),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _gps == _GpsState.loading ? null : _ambilGps,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 13,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Perbarui',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 22,
                color: AppColors.brand,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  judul,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Bantu warga & Dishub Indramayu memetakan titik gelap demi keselamatan bersama.',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoCard() {
    final bytes = _fotoBytes;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.photo_camera_outlined,
            'Bukti Visual Lapangan',
            trailing: const _MiniChip(
              text: 'WAJIB • 1 FOTO',
              fg: AppColors.brand,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: bytes == null
                  ? Container(
                      color: AppColors.card,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            size: 36,
                            color: AppColors.brand.withOpacity(.45),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada foto',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.memory(bytes, fit: BoxFit.cover),
                        const Positioned(
                          top: 10,
                          left: 10,
                          child: _OverlayChip(
                            icon: Icons.hourglass_bottom,
                            text: 'Divalidasi setelah dikirim',
                          ),
                        ),
                        Positioned(
                          left: 10,
                          bottom: 10,
                          child: _OverlayChip(
                            icon: _fotoSumber == 'kamera'
                                ? Icons.photo_camera_outlined
                                : Icons.photo_library_outlined,
                            text:
                                '${_fotoSumber == 'kamera' ? 'Kamera' : 'Galeri'}'
                                '${_fotoWaktu != null ? ' • ${_jam(_fotoWaktu!)}' : ''}',
                          ),
                        ),
                        Positioned(
                          right: 10,
                          bottom: 10,
                          child: Material(
                            color: Colors.black54,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: _zoomFoto,
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  Icons.zoom_in,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => _pilihFoto(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(
                      'Ambil Foto Langsung',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: () => _pilihFoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: Text(
                      'Dari Galeri',
                      maxLines: 1,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brand,
                      side: const BorderSide(color: AppColors.brand),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmenCard() {
    final jarak = _jarakLurus;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.alt_route,
            'Segmen Jalur Gelap',
            trailing: const _MiniChip(text: 'OPSIONAL', fg: AppColors.muted),
          ),
          const SizedBox(height: 12),
          _SegmentField(
            label: 'Dari Titik (Awal Gelap)',
            value: _awalLabel ?? 'Pilih titik awal',
            filled: _awalLabel != null,
            icon: Icons.trip_origin,
            iconColor: _cGelap,
            onTap: () => _cariTitik(awal: true),
            onGps: () => _pakaiGps(awal: true),
          ),
          const SizedBox(height: 10),
          _SegmentField(
            label: 'Hingga Titik (Akhir Gelap)',
            value: _akhirLabel ?? 'Pilih titik akhir',
            filled: _akhirLabel != null,
            icon: Icons.location_on,
            iconColor: AppColors.brand,
            onTap: () => _cariTitik(awal: false),
            onGps: () => _pakaiGps(awal: false),
          ),
          const SizedBox(height: 14),
          _SegmenMap(
            controller: _segMap,
            awal: _awal,
            akhir: _akhir,
            pusat: _pos,
            petunjuk: _awal == null
                ? 'Ketuk peta: titik awal'
                : _akhir == null
                ? 'Ketuk peta: titik akhir'
                : 'Ketuk peta: geser titik terdekat',
            onTap: _setTitikDariPeta,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimasi Panjang Ruas Gelap',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.brand,
                  ),
                ),
              ),
              _MiniChip(
                text: jarak != null ? '${_fmtM(jarak)} Meter' : '— Meter',
                fg: AppColors.brand,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _BatangRuas(meter: jarak),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final t in const ['50m', '1.500m', '3.000m'])
                Text(
                  t,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (jarak == null)
            Text(
              'Pilih titik awal & akhir (lewat pencarian, GPS, atau ketuk peta) '
              'untuk mengisi panjang ruas otomatis.',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppColors.muted,
                height: 1.4,
              ),
            )
          else if (jarak < 5)
            Text(
              'Titik awal dan akhir hampir sama. Pilih titik akhir yang berbeda.',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: _cRedup,
                height: 1.4,
              ),
            )
          else ...[
            Text(
              'Terisi otomatis dari jarak garis lurus antar dua titik.',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                color: AppColors.muted,
              ),
            ),
            if (jarak > 3000)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Lebih dari 3.000 m, sebaiknya dipecah menjadi beberapa laporan.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: _cRedup,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cGelap,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: Colors.white,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(text: 'Ruas '),
                          TextSpan(
                            text: '±${_fmtM(jarak)} m',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const TextSpan(
                            text:
                                ' tanpa penerangan aktif rawan kecelakaan di malam hari & minim saksi mata.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kategoriCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.lightbulb_outline, 'Kategori Kendala PJU'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in kKategoriLaporan)
                ChoiceChip(
                  label: Text(
                    k.label,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kategori == k.value
                          ? Colors.white
                          : AppColors.brand,
                    ),
                  ),
                  selected: _kategori == k.value,
                  selectedColor: AppColors.brand,
                  backgroundColor: AppColors.card,
                  showCheckmark: false,
                  side: BorderSide.none,
                  onSelected: (_) => setState(() => _kategori = k.value),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tingkatCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(Icons.visibility_off_outlined, 'Tingkat Kegelapan'),
          const SizedBox(height: 12),
          for (final t in _tingkat)
            _TingkatTile(
              data: t,
              selected: _tingkatDipilih == t.nilai,
              onTap: () => setState(() => _tingkatDipilih = t.nilai),
            ),
        ],
      ),
    );
  }

  Widget _keteranganCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.notes,
            'Keterangan Tambahan',
            trailing: Text(
              'Konteks Lokasi',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keteranganC,
            maxLines: 4,
            maxLength: 300,
            style: GoogleFonts.poppins(fontSize: 13),
            decoration: InputDecoration(
              hintText:
                  'Contoh: lampu di dekat persawahan mati sejak beberapa hari, jalur ramai dilewati warga malam hari. (opsional)',
              hintStyle: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.muted,
              ),
              filled: true,
              fillColor: AppColors.card,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kirimBagian() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _sending ? null : _kirim,
            icon: _sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 20),
            label: Text(
              _sending ? 'Mengirim…' : 'Kirim Laporan & Verifikasi AI',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              disabledBackgroundColor: AppColors.brand.withOpacity(.6),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Foto diperiksa otomatis setelah dikirim. Laporan yang tidak sesuai akan dikembalikan agar foto bisa diganti.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: AppColors.muted,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------
// Fungsi bantu
// ----------------------------------------------------------------------

String _formatKoordinat(LatLng p) =>
    '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

/// 1240 -> "1.240" (pemisah ribuan titik, gaya Indonesia).
String _fmtM(num m) {
  final s = m.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

String _jam(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} ${d.timeZoneName}';

/// Nama jalan/desa dari koordinat, lewat Nominatim (kebijakan: maks 1
/// request/detik, jadi hanya dipanggil sekali per pengambilan GPS).
Future<String?> _reverseGeocode(LatLng p) async {
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': p.latitude.toStringAsFixed(6),
      'lon': p.longitude.toStringAsFixed(6),
      'format': 'jsonv2',
      'zoom': '17',
    });
    final res = await http
        .get(uri, headers: {'User-Agent': 'id.peteng.app'})
        .timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) return null;
    final m = jsonDecode(res.body);
    if (m is! Map) return null;
    final a = m['address'];
    if (a is Map) {
      final jalan = a['road'];
      final area =
          a['suburb'] ?? a['village'] ?? a['neighbourhood'] ?? a['town'];
      final bagian = [
        jalan,
        area,
      ].whereType<String>().where((s) => s.isNotEmpty).toList();
      if (bagian.isNotEmpty) return bagian.join(', ');
    }
    final dn = m['display_name'];
    return dn is String && dn.isNotEmpty ? dn : null;
  } catch (e) {
    debugPrint('REVERSE GEOCODE ERROR: $e');
    return null;
  }
}

// ----------------------------------------------------------------------
// Widget kecil
// ----------------------------------------------------------------------

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.text, required this.fg, this.dot = false});
  final String text;
  final Color fg;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: fg.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Batang panjang ruas (skala 50 m - 3.000 m). Hanya penunjuk, tidak bisa
/// digeser: nilainya otomatis dari jarak antar titik awal & akhir.
class _BatangRuas extends StatelessWidget {
  const _BatangRuas({required this.meter});

  final double? meter;

  static const double _min = 50;
  static const double _max = 3000;
  static const double _tinggi = 12;
  static const double _thumb = 20;

  @override
  Widget build(BuildContext context) {
    final m = meter;
    final fraksi = m == null
        ? 0.0
        : ((m - _min) / (_max - _min)).clamp(0.0, 1.0).toDouble();

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final isi = m == null
            ? 0.0
            : (w * fraksi < _tinggi ? _tinggi : w * fraksi);
        final thumbKiri = (w * fraksi - _thumb / 2)
            .clamp(0.0, w - _thumb)
            .toDouble();
        return SizedBox(
          height: _thumb,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: _tinggi,
                decoration: BoxDecoration(
                  color: AppColors.brand.withOpacity(.12),
                  borderRadius: BorderRadius.circular(_tinggi),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                width: isi,
                height: _tinggi,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(_tinggi),
                ),
              ),
              if (m != null)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  left: thumbKiri,
                  child: Container(
                    width: _thumb,
                    height: _thumb,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.brand, width: 3),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Peta kecil untuk menandai awal & akhir ruas gelap. Diketuk = mengatur
/// titik yang sedang dipilih (awal/akhir), garis menghubungkan keduanya.
class _SegmenMap extends StatelessWidget {
  const _SegmenMap({
    required this.controller,
    required this.awal,
    required this.akhir,
    required this.pusat,
    required this.petunjuk,
    required this.onTap,
  });

  final MapController controller;
  final LatLng? awal;
  final LatLng? akhir;
  final LatLng? pusat; // posisi GPS pengguna (kalau sudah ada)
  final String petunjuk; // teks petunjuk di pojok peta
  final ValueChanged<LatLng> onTap;

  static const LatLng _indramayu = LatLng(-6.3267, 108.3214);

  @override
  Widget build(BuildContext context) {
    final adaTitik = awal != null || akhir != null || pusat != null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 210,
        width: double.infinity,
        child: Stack(
          children: [
            FlutterMap(
              mapController: controller,
              options: MapOptions(
                initialCenter: awal ?? akhir ?? pusat ?? _indramayu,
                initialZoom: adaTitik ? 16 : 13,
                onTap: (_, p) => onTap(p),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'id.peteng.app',
                ),
                if (awal != null && akhir != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [awal!, akhir!],
                        strokeWidth: 4,
                        color: _cGelap,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (awal != null)
                      Marker(
                        point: awal!,
                        width: 36,
                        height: 36,
                        child: const Icon(
                          Icons.trip_origin,
                          color: _cGelap,
                          size: 28,
                        ),
                      ),
                    if (akhir != null)
                      Marker(
                        point: akhir!,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.brand,
                          size: 38,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: _OverlayChip(
                icon: Icons.touch_app_outlined,
                text: petunjuk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentField extends StatelessWidget {
  const _SegmentField({
    required this.label,
    required this.value,
    required this.filled,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onGps,
  });

  final String label;
  final String value;
  final bool filled;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onGps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 13,
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: iconColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: filled ? AppColors.brand : AppColors.muted,
                              fontWeight: filled
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Pakai lokasi saya',
                icon: const Icon(
                  Icons.my_location,
                  size: 20,
                  color: AppColors.brand,
                ),
                onPressed: onGps,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TingkatTile extends StatelessWidget {
  const _TingkatTile({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  final _Tingkat data;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = data.warna;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected ? c.withOpacity(.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? c : const Color(0xFFE3E5EC),
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: c.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(data.icon, size: 22, color: c),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              data.judul,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brand,
                              ),
                            ),
                          ),
                          if (data.kritis) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Kritis',
                                style: GoogleFonts.poppins(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.deskripsi,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 22,
                  color: selected ? c : const Color(0xFFB8BDCC),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Panel simulasi AI (DEMO, tidak memanggil backend)
// ----------------------------------------------------------------------

enum _SimState { siap, proses, valid, ditolak }

class _AiSimulasiCard extends StatefulWidget {
  const _AiSimulasiCard();

  @override
  State<_AiSimulasiCard> createState() => _AiSimulasiCardState();
}

class _AiSimulasiCardState extends State<_AiSimulasiCard> {
  _SimState _state = _SimState.siap;
  String _langkah = '';
  int _runId = 0;

  Future<void> _jalankan({required bool tolak}) async {
    final id = ++_runId;
    const langkah = [
      'Membaca metadata foto…',
      'Mendeteksi kondisi jalan & lampu…',
      'Menilai tingkat penerangan…',
    ];
    setState(() => _state = _SimState.proses);
    for (final l in langkah) {
      if (!mounted || id != _runId) return;
      setState(() => _langkah = l);
      await Future<void>.delayed(const Duration(milliseconds: 900));
    }
    if (!mounted || id != _runId) return;
    setState(() => _state = tolak ? _SimState.ditolak : _SimState.valid);
  }

  @override
  Widget build(BuildContext context) {
    late final IconData icon;
    late final Color warna;
    late final String judul;
    late final String isi;
    switch (_state) {
      case _SimState.siap:
        icon = Icons.smart_toy_outlined;
        warna = AppColors.muted;
        judul = 'Mode demo';
        isi =
            'Tidak terhubung ke sistem AI sungguhan. Tombol di atas hanya memperlihatkan contoh tampilan hasil.';
        break;
      case _SimState.proses:
        icon = Icons.hourglass_bottom;
        warna = AppColors.brand;
        judul = 'Memproses (simulasi)…';
        isi = _langkah;
        break;
      case _SimState.valid:
        icon = Icons.check_circle_outline;
        warna = _cTerang;
        judul = 'Foto sesuai (simulasi)';
        isi =
            'Contoh: laporan disimpan lalu diteruskan ke dashboard pemerintah untuk verifikasi.';
        break;
      case _SimState.ditolak:
        icon = Icons.cancel_outlined;
        warna = _cGelap;
        judul = 'Foto ditolak (simulasi)';
        isi =
            'Contoh alasan: foto buram atau bukan lokasi jalan. Pengguna diminta mengunggah foto yang sesuai.';
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E5EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Simulasi Respons Verifikasi AI',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const _MiniChip(text: 'DEMO INTERAKTIF', fg: _cRedup),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Contoh tampilan saat verifikasi menerima foto valid atau menolak foto yang tidak sesuai.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _state == _SimState.proses
                      ? null
                      : () => _jalankan(tolak: false),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: Text(
                    'Simulasi Proses AI',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _state == _SimState.proses
                      ? null
                      : () => _jalankan(tolak: true),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(
                    'Simulasi Laporan Ditolak',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _cGelap,
                    side: const BorderSide(color: _cGelap),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: warna.withOpacity(.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _state == _SimState.proses
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : Icon(icon, size: 22, color: warna),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: warna,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isi,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// Halaman setelah laporan berhasil dikirim
// ----------------------------------------------------------------------

class LaporanTerkirimPage extends StatelessWidget {
  const LaporanTerkirimPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 84, color: _cTerang),
                const SizedBox(height: 18),
                Text(
                  'Laporan Terkirim',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Terima kasih sudah membantu memetakan titik gelap di Indramayu. '
                  'Laporanmu akan diperiksa sebelum ditindaklanjuti.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.muted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Kembali',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
