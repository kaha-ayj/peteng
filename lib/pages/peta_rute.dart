import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'article_page.dart';
import 'home.dart' show AppColors;
import 'place_search.dart';
import '../services/route_api.dart';
import 'lapor.dart';

const String kSosNumber = '112';

const Color _cTerang = Color(0xFF026343);
const Color _cGelap = Color(0xFFBE003D);
const Color _cSimulasi = Color(0xFF8A5A00);

class PetaRutePage extends StatefulWidget {
  const PetaRutePage({super.key});

  @override
  State<PetaRutePage> createState() => _PetaRutePageState();
}

class _PetaRutePageState extends State<PetaRutePage> {
  final MapController _map = MapController();

  LatLng? _origin;
  String? _originLabel;
  LatLng? _dest;
  String? _destLabel;

  int _mode = 0;
  List<RouteOption> _routes = [];
  int _selected = 0;
  bool _searching = false;
  bool _locating = false;
  String? _error;
  int _reqId = 0; // penanda pencarian terbaru, untuk membuang hasil yang basi

  static const LatLng _indramayu = LatLng(-6.3267, 108.3214);

  static const _modes = [
    (icon: Icons.two_wheeler, label: 'Motor'),
    (icon: Icons.directions_car, label: 'Mobil'),
    (icon: Icons.directions_walk, label: 'Jalan Kaki'),
  ];

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ------------------------------------------------------------------
  // Memilih titik
  // ------------------------------------------------------------------

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
      _onPointsChanged();
    } catch (e) {
      debugPrint('LOCATION ERROR: $e');
      _snack('Gagal mengambil lokasi. Coba lagi.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickPoint({required bool isOrigin}) async {
    final r = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) =>
          PlaceSearchSheet(title: isOrigin ? 'Cari titik awal' : 'Cari tujuan'),
    );
    if (r == null || !mounted) return;
    setState(() {
      if (isOrigin) {
        _origin = r.point;
        _originLabel = r.name;
      } else {
        _dest = r.point;
        _destLabel = r.name;
      }
    });
    _onPointsChanged();
  }

  void _swap() {
    if (_origin == null && _dest == null) return;
    setState(() {
      final p = _origin;
      final l = _originLabel;
      _origin = _dest;
      _originLabel = _destLabel;
      _dest = p;
      _destLabel = l;
    });
    _onPointsChanged();
  }

  void _onPointsChanged() {
    final o = _origin;
    final d = _dest;
    if (o == null || d == null) {
      _reqId++; // batalkan pencarian yang masih berjalan
      setState(() {
        _routes = [];
        _error = null;
        _searching = false;
      });
      _fitPoints();
      return;
    }
    _findRoutes(o, d);
  }

  Future<void> _findRoutes(LatLng o, LatLng d) async {
    final id = ++_reqId;
    setState(() {
      _searching = true;
      _error = null;
      _routes = [];
      _selected = 0;
    });
    try {
      final r = await RouteApi.cari(asal: o, tujuan: d);
      if (!mounted || id != _reqId) return;
      // Maksimal 2 opsi rute ditampilkan.
      final list = r.take(2).toList();
      final rec = list.indexWhere((x) => x.direkomendasikan);
      setState(() {
        _routes = list;
        _selected = rec < 0 ? 0 : rec;
      });
      _fitRoute();
    } on RouteException catch (e) {
      if (mounted && id == _reqId) setState(() => _error = e.message);
    } catch (e) {
      debugPrint('ROUTE ERROR: $e');
      if (mounted && id == _reqId) {
        setState(() => _error = 'Terjadi kesalahan saat mencari rute.');
      }
    } finally {
      if (mounted && id == _reqId) setState(() => _searching = false);
    }
  }

  void _fitPoints() {
    final pts = <LatLng>[
      if (_origin != null) _origin!,
      if (_dest != null) _dest!,
    ];
    if (pts.isEmpty) {
      _map.move(_indramayu, 13);
    } else if (pts.length == 1 || pts[0] == pts[1]) {
      _map.move(pts.first, 15);
    } else {
      _map.fitCamera(
        CameraFit.coordinates(
          coordinates: pts,
          padding: const EdgeInsets.all(48),
        ),
      );
    }
  }

  void _fitRoute() {
    if (_routes.isEmpty) return _fitPoints();
    _map.fitCamera(
      CameraFit.coordinates(
        coordinates: _routes[_selected].titik,
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  Future<void> _sos() async {
    var ok = false;
    try {
      ok = await launchUrl(Uri(scheme: 'tel', path: kSosNumber));
    } catch (e) {
      debugPrint('SOS ERROR: $e');
    }
    if (!ok && mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Tidak bisa membuka telepon'),
          content: Text(
            'Hubungi $kSosNumber secara manual dari aplikasi telepon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    }
  }

  void _startNavigation() {
    if (_routes.isEmpty) {
      _snack('Pilih titik berangkat dan tujuan dulu.');
      return;
    }
    // TODO: navigasi langkah-demi-langkah belum ada.
    _snack('Navigasi langkah-demi-langkah belum tersedia.');
  }

  void _onNavTap(int i) {
    if (i == 0) {
      Navigator.of(context).popUntil((r) => r.isFirst);
    } else if (i == 1) {
      // Sudah di halaman Peta & Rute.
    } else if (i == 2) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LaporPage()));
    } else if (i == 3) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ArticlePage()));
      return;
    }
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                const SizedBox(height: 14),
                _pointsCard(),
                const SizedBox(height: 12),
                _modeRow(),
                const SizedBox(height: 14),
                _mapCard(),
                const SizedBox(height: 18),
                _optionsSection(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBar(),
            _BottomNav(index: 1, onTap: _onNavTap),
          ],
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
        Expanded(
          child: Text(
            'Peta & Rute',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.brand,
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _cardDeco({double radius = 22}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 4)),
    ],
  );

  Widget _pointsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: _cardDeco(),
      child: Column(
        children: [
          _PointRow(
            icon: Icons.trip_origin,
            iconColor: AppColors.brand,
            label: 'Titik Awal',
            value: _originLabel ?? 'Pilih titik awal keberangkatan',
            filled: _originLabel != null,
            onTap: () => _pickPoint(isOrigin: true),
            trailing: _locating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    tooltip: 'Pakai lokasi saya',
                    icon: const Icon(
                      Icons.my_location,
                      color: AppColors.brand,
                      size: 22,
                    ),
                    onPressed: _useMyLocation,
                  ),
          ),
          const Divider(height: 1),
          _PointRow(
            icon: Icons.location_on,
            iconColor: const Color(0xFFD32F2F),
            label: 'Tujuan Akhir',
            value: _destLabel ?? 'Pilih tujuan',
            filled: _destLabel != null,
            onTap: () => _pickPoint(isOrigin: false),
            trailing: IconButton(
              tooltip: 'Tukar titik',
              icon: const Icon(
                Icons.swap_vert,
                color: AppColors.brand,
                size: 22,
              ),
              onPressed: _swap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < _modes.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _ModeTile(
                  icon: _modes[i].icon,
                  label: _modes[i].label,
                  selected: i == _mode,
                  onTap: () => setState(() => _mode = i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Mode kendaraan.',
          style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _mapCard() {
    final hasRoute = _routes.isNotEmpty;

    return Container(
      decoration: _cardDeco(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: 250,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: const MapOptions(
                  initialCenter: _indramayu,
                  initialZoom: 13,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'id.peteng.app',
                  ),
                  if (hasRoute)
                    PolylineLayer(
                      polylines: [
                        for (var i = 0; i < _routes.length; i++)
                          if (i != _selected)
                            Polyline(
                              points: _routes[i].titik,
                              strokeWidth: 4,
                              color: const Color(0xFF9AA0B5),
                            ),
                        Polyline(
                          points: _routes[_selected].titik,
                          strokeWidth: 6,
                          color: AppColors.brand,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (_origin != null)
                        Marker(
                          point: _origin!,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.my_location,
                            color: Color(0xFF1565C0),
                            size: 30,
                          ),
                        ),
                      if (_dest != null)
                        Marker(
                          point: _dest!,
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
              Positioned(
                top: 10,
                left: 10,
                child: _MapPill(
                  icon: Icons.map_outlined,
                  text: 'PETA RUTE',
                  fg: AppColors.brand,
                  bg: Colors.white.withOpacity(.92),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: Colors.white,
                  elevation: 2,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _fitRoute,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.center_focus_strong,
                        size: 20,
                        color: AppColors.brand,
                      ),
                    ),
                  ),
                ),
              ),
              if (_searching)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x80FFFFFF),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionsSection() {
    Widget body;
    if (_searching) {
      body = const SizedBox.shrink();
    } else if (_error != null) {
      body = _hint(Icons.error_outline, _error!, color: _cGelap);
    } else if (_routes.isEmpty) {
      body = _hint(
        Icons.alt_route,
        'Pilih titik berangkat dan tujuan untuk melihat opsi rute.',
      );
    } else {
      body = Column(
        children: [
          if (!_routes.any((r) => r.direkomendasikan))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _hint(
                Icons.info_outline,
                'Belum ada rute yang direkomendasikan karena data penerangan '
                'belum cukup.',
              ),
            ),
          for (var i = 0; i < _routes.length; i++)
            _OptionCard(
              index: i,
              route: _routes[i],
              selected: i == _selected,
              onTap: () {
                setState(() => _selected = i);
                _fitRoute();
              },
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opsi Rute Malam',
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
        ),
        const SizedBox(height: 8),
        body,
      ],
    );
  }

  Widget _hint(IconData icon, String text, {Color color = AppColors.muted}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(radius: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol SOS dan Mulai Navigasi, menempel di atas bar navigasi.
  Widget _actionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x14000000))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 118,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _sos,
              icon: const Icon(Icons.call, size: 18),
              label: Text(
                'SOS $kSosNumber',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _cGelap,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton.icon(
                onPressed: _startNavigation,
                icon: const Icon(Icons.navigation_outlined, size: 18),
                label: Text(
                  'Mulai Navigasi Aman',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
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

class _PointRow extends StatelessWidget {
  const _PointRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.filled,
    required this.onTap,
    required this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool filled;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: iconColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            color: AppColors.muted,
                          ),
                        ),
                        Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: filled ? AppColors.brand : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ModeTile extends StatelessWidget {
  const _ModeTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : AppColors.brand;
    return Material(
      color: selected ? AppColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: selected ? 0 : 1,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: fg),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapPill extends StatelessWidget {
  const _MapPill({
    required this.icon,
    required this.text,
    required this.fg,
    required this.bg,
  });

  final IconData icon;
  final String text;
  final Color fg;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kartu opsi rute. Semua isinya dari respons backend.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.index,
    required this.route,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final RouteOption route;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final rec = route.direkomendasikan;
    final skorPenerangan = route.skorPenerangan;
    final skorAkhir = route.skorAkhir;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? AppColors.brand : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _Tag(
                      text: rec ? 'REKOMENDASI TERBAIK' : 'ALTERNATIF',
                      color: rec ? _cTerang : AppColors.muted,
                    ),
                    if (route.dataSimulasi) ...[
                      const SizedBox(width: 6),
                      const _Tag(text: 'DATA SIMULASI', color: _cSimulasi),
                    ],
                    const Spacer(),
                    if (selected)
                      const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: AppColors.brand,
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Rute ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                Text(
                  skorPenerangan != null
                      ? 'Skor penerangan ${skorPenerangan.toStringAsFixed(0)}/100'
                      : 'Data penerangan belum cukup untuk menilai rute ini.',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    _Stat(icon: Icons.schedule, text: route.durasiLabel),
                    _Stat(icon: Icons.straighten, text: route.jarakLabel),
                    if (skorAkhir != null)
                      _Stat(
                        icon: Icons.shield_outlined,
                        text: 'Skor ${skorAkhir.toStringAsFixed(0)}',
                        color: _cTerang,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.icon,
    required this.text,
    this.color = AppColors.brand,
  });
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.brand,
          ),
        ),
      ],
    );
  }
}
