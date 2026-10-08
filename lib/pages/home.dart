import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AppColors {
  static const brand = Color(0xFF172554);
  static const card = Color(0xFFF1F1EF);
  static const muted = Color(0xFF5B6070);
  static const glow = Color(0xFFE8D98A);
}

const String kLogoAsset = 'lib/assets/images/logo_sejajar.png';
const bool kShowLogoMarker = false;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _navIndex = 0;

  void _onNavTap(int i) {
    setState(() => _navIndex = i);
  }

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
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: _TopBar(),
                ),
                const SizedBox(height: 18),
                const Padding(
                  padding: EdgeInsets.only(left: 20),
                  child: _GreetingRow(),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FeatureCard(),
                      const SizedBox(height: 22),
                      _SectionTitle(
                        icon: Icons.near_me_outlined,
                        label: 'Analisis Rute',
                      ),
                      const SizedBox(height: 12),
                      const _RouteCard(),
                      const SizedBox(height: 16),
                      const _LightConditionCard(),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _BottomNav(index: _navIndex, onTap: _onNavTap),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: kShowLogoMarker
          ? BoxDecoration(
              border: Border.all(color: const Color(0xFFF0B429), width: 1.5),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: kShowLogoMarker ? const EdgeInsets.all(4) : EdgeInsets.zero,
      child: Image.asset(
        kLogoAsset,
        height: 100,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (_, __, ___) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.image_outlined, size: 28, color: AppColors.brand),
            const SizedBox(width: 6),
            Text(
              'LOGO PETENG',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.brand,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GreetingRow extends StatelessWidget {
  const _GreetingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, Rei !',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Pamayahan, Indramayu, Jawa Barat',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const _ActionPill(),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 16, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withOpacity(.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _PillIcon(icon: Icons.checklist_outlined, onTap: () {}),
          const SizedBox(width: 2),
          _PillIcon(icon: Icons.notifications_none_outlined, onTap: () {}),
          const SizedBox(width: 2),
          _PillIcon(icon: Icons.person_outline, onTap: () {}),
        ],
      ),
    );
  }
}

class _PillIcon extends StatelessWidget {
  const _PillIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 19, color: Colors.white),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pemetaan & Rekomendasi\nRute Area Gelap',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Temukan rute yang lebih terang dan laporkan kondisi '
            'penerangan jalan di Kabupaten Indramayu.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Temukan rute aman',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.brand),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
        ),
      ],
    );
  }
}

class _RouteCard extends StatefulWidget {
  const _RouteCard();

  @override
  State<_RouteCard> createState() => _RouteCardState();
}

class _RouteCardState extends State<_RouteCard> {
  final MapController _mapController = MapController();

  LatLng? _origin;
  String? _originLabel;
  LatLng? _dest;
  String? _destLabel;
  bool _locating = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// "Lokasi anda": ambil posisi GPS perangkat.
  Future<void> _useMyLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _snack('GPS/Layanan lokasi mati. Aktifkan dulu di pengaturan HP.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied) {
        _snack('Izin lokasi ditolak, jadi lokasi kamu tidak bisa diambil.');
        return;
      }
      if (perm == LocationPermission.deniedForever) {
        _snack(
          'Izin lokasi diblokir. Aktifkan lewat Pengaturan > Aplikasi > peteng > Izin.',
        );
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _origin = LatLng(pos.latitude, pos.longitude);
        _originLabel = 'Lokasi saat ini';
      });
      _refocusMap();
    } catch (e) {
      _snack('Gagal mengambil lokasi. Coba lagi.');
      debugPrint('LOCATION ERROR: $e');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// "Tujuan Lokasi": buka pencarian tempat.
  Future<void> _pickDestination() async {
    final result = await showModalBottomSheet<_PlaceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PlaceSearchSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _dest = result.point;
      _destLabel = result.name;
    });
    _refocusMap();
  }

  /// Geser/zoom peta supaya titik yang dipilih kelihatan.
  void _refocusMap() {
    final o = _origin;
    final d = _dest;
    if (o != null && d != null && o != d) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(o, d),
          padding: const EdgeInsets.all(40),
        ),
      );
    } else {
      _mapController.move((d ?? o)!, 15);
    }
  }

  void _searchRoute() {
    if (_origin == null || _dest == null) {
      _snack('Pilih "Lokasi anda" dan "Tujuan Lokasi" dulu.');
      return;
    }
    // TODO: kirim _origin & _dest ke backend untuk hitung rute aman,
    // lalu gambar hasilnya di peta sebagai Polyline.
    _snack('Pencarian rute belum tersambung ke backend.');
  }

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        children: [
          _LocationPill(
            icon: Icons.my_location,
            label: _originLabel ?? 'Lokasi anda',
            loading: _locating,
            onTap: _useMyLocation,
          ),
          const SizedBox(height: 10),
          _LocationPill(
            icon: Icons.search,
            label: _destLabel ?? 'Tujuan Lokasi',
            onTap: _pickDestination,
          ),
          const SizedBox(height: 14),
          _RealMap(
            controller: _mapController,
            origin: _origin,
            destination: _dest,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _searchRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Cari rute aman',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: loading ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.white.withOpacity(.9),
                  ),
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// Peta OpenStreetMap (flutter_map), berpusat di Kabupaten Indramayu.
/// Menampilkan marker "Lokasi anda" (biru) dan "Tujuan" (merah) kalau sudah dipilih.
class _RealMap extends StatelessWidget {
  const _RealMap({
    required this.controller,
    required this.origin,
    required this.destination,
  });

  final MapController controller;
  final LatLng? origin;
  final LatLng? destination;

  // Titik tengah Kabupaten Indramayu (perkiraan pusat kota/alun-alun).
  static const LatLng _indramayuCenter = LatLng(-6.3267, 108.3214);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 190,
        width: double.infinity,
        child: FlutterMap(
          mapController: controller,
          options: const MapOptions(
            initialCenter: _indramayuCenter,
            initialZoom: 13,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'id.peteng.app',
            ),
            MarkerLayer(
              markers: [
                if (origin != null)
                  Marker(
                    point: origin!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF1565C0),
                      size: 30,
                    ),
                  ),
                if (destination != null)
                  Marker(
                    point: destination!,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: Color(0xFFD32F2F),
                      size: 38,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceResult {
  const _PlaceResult(this.name, this.point);
  final String name;
  final LatLng point;
}

/// Bottom sheet pencarian tujuan, pakai Nominatim (geocoder gratis milik
/// OpenStreetMap). Pencarian dijalankan saat tombol cari/enter ditekan —
/// BUKAN tiap ketikan — karena kebijakan Nominatim melarang autocomplete
/// dan membatasi 1 request per detik:
/// https://operations.osmfoundation.org/policies/nominatim/
class _PlaceSearchSheet extends StatefulWidget {
  const _PlaceSearchSheet();

  @override
  State<_PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<_PlaceSearchSheet> {
  final _c = TextEditingController();
  List<_PlaceResult> _results = [];
  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _c.text.trim();
    if (q.length < 3) {
      setState(() => _message = 'Ketik minimal 3 huruf.');
      return;
    }
    setState(() {
      _loading = true;
      _message = null;
      _results = [];
    });
    try {
      // Dibatasi ke area Kabupaten Indramayu (bounded=1). Kalau mau cari di
      // seluruh Indonesia, hapus viewbox & bounded.
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'jsonv2',
        'limit': '8',
        'countrycodes': 'id',
        'viewbox': '107.85,-6.0,108.65,-6.75',
        'bounded': '1',
      });
      final res = await http
          .get(uri, headers: {'User-Agent': 'id.peteng.app'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        setState(() => _message = 'Pencarian gagal (kode ${res.statusCode}).');
        return;
      }
      final list = jsonDecode(res.body) as List<dynamic>;
      final results = list.map((e) {
        final m = e as Map<String, dynamic>;
        return _PlaceResult(
          (m['display_name'] as String?) ?? 'Tanpa nama',
          LatLng(
            double.parse(m['lat'] as String),
            double.parse(m['lon'] as String),
          ),
        );
      }).toList();
      setState(() {
        _results = results;
        if (results.isEmpty) {
          _message =
              'Tidak ada hasil di wilayah Indramayu. Coba kata kunci lain.';
        }
      });
    } catch (e) {
      debugPrint('SEARCH ERROR: $e');
      if (mounted)
        setState(() => _message = 'Tidak bisa terhubung. Cek internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottom),
      child: SizedBox(
        height: 380,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cari tujuan',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _c,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nama jalan, tempat, atau desa',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppColors.muted,
                ),
                filled: true,
                fillColor: AppColors.card,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search, color: AppColors.brand),
                  onPressed: _search,
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_message != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _message!,
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: AppColors.muted,
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _results[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.place_outlined,
                        color: AppColors.brand,
                      ),
                      title: Text(
                        r.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12.5),
                      ),
                      onTap: () => Navigator.of(context).pop(r),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    (
      icon: Icons.near_me_outlined,
      activeIcon: Icons.near_me,
      label: 'Peta & Rute',
    ),
    (icon: Icons.campaign_outlined, activeIcon: Icons.campaign, label: 'Lapor'),
    (
      icon: Icons.event_note_outlined,
      activeIcon: Icons.event_note,
      label: 'Artikel',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (i) {
          final item = _items[i];
          final active = i == index;
          final color = active ? AppColors.brand : AppColors.muted;
          return InkWell(
            onTap: () => onTap(i),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    active ? item.activeIcon : item.icon,
                    size: 22,
                    color: color,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.label,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _LightConditionCard extends StatelessWidget {
  const _LightConditionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kondisi Penerangan Sekitar',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Indikator tingkat cahaya pada jalan',
            style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _LightTile(
                  label: 'Gelap',
                  color: Color.fromARGB(255, 190, 0, 61),
                  icon: Icons.nightlight_round,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LightTile(
                  label: 'Remang',
                  color: Color.fromARGB(255, 194, 118, 5),
                  icon: Icons.wb_twighlight,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _LightTile(
                  label: 'Terang',
                  color: Color.fromARGB(255, 2, 99, 67),
                  icon: Icons.wb_sunny,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LightTile extends StatelessWidget {
  const _LightTile({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.4,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 5),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
