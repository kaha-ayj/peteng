import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:peteng/services/route_api.dart';
import 'place_search.dart';
import 'peta_rute.dart';
import 'lapor.dart';

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
    if (i == 1) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PetaRutePage()));
      return;
    }
    if (i == 2) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const LaporPage()));
      return;
    }
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
        bottomNavigationBar: AppBottomNav(index: _navIndex, onTap: _onNavTap),
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
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PetaRutePage())),
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

  List<RouteOption> _routes = [];
  int _selectedRoute = 0;
  bool _searching = false;

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
        _routes = [];
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
    final result = await showModalBottomSheet<PlaceResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const PlaceSearchSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      _dest = result.point;
      _destLabel = result.name;
      _routes = [];
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

  Future<void> _searchRoute() async {
    if (_searching) return;
    if (_origin == null || _dest == null) {
      _snack('Pilih "Lokasi anda" dan "Tujuan Lokasi" dulu.');
      return;
    }
    setState(() => _searching = true);
    try {
      final routes = await RouteApi.cari(asal: _origin!, tujuan: _dest!);
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedRoute = 0;
      });
      _fitSelectedRoute();
    } on RouteException catch (e) {
      _snack(e.message);
    } catch (e) {
      debugPrint('ROUTE ERROR: $e');
      _snack('Terjadi kesalahan saat mencari rute.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _fitSelectedRoute() {
    if (_routes.isEmpty) return;
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: _routes[_selectedRoute].titik,
        padding: const EdgeInsets.all(40),
      ),
    );
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
            routes: _routes,
            selectedRoute: _selectedRoute,
          ),
          if (_routes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (var i = 0; i < _routes.length; i++)
                    ChoiceChip(
                      label: Text(
                        'Rute ${i + 1} · ${_routes[i].jarakLabel} · ${_routes[i].durasiLabel}',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: i == _selectedRoute
                              ? Colors.white
                              : AppColors.brand,
                        ),
                      ),
                      selected: i == _selectedRoute,
                      selectedColor: AppColors.brand,
                      backgroundColor: AppColors.card,
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() => _selectedRoute = i);
                        _fitSelectedRoute();
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Rute jalan tercepat. Penilaian penerangan belum aktif.',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _searching ? null : _searchRoute,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _searching
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
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
    this.routes = const [],
    this.selectedRoute = 0,
  });

  final MapController controller;
  final LatLng? origin;
  final LatLng? destination;
  final List<RouteOption> routes;
  final int selectedRoute;

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
            if (routes.isNotEmpty)
              PolylineLayer(
                polylines: [
                  // Rute alternatif (abu-abu) digambar dulu, rute terpilih di atasnya.
                  for (var i = 0; i < routes.length; i++)
                    if (i != selectedRoute)
                      Polyline(
                        points: routes[i].titik,
                        strokeWidth: 4,
                        color: const Color(0xFF9AA0B5),
                      ),
                  Polyline(
                    points: routes[selectedRoute].titik,
                    strokeWidth: 6,
                    color: AppColors.brand,
                  ),
                ],
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

/// Bottom navigation bersama. Dipakai di Home, Lapor, dan halaman lain
/// supaya tampilannya konsisten. `index` = tab yang sedang aktif.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onTap});
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
