import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

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
                // Padding kiri saja (tanpa kanan) supaya _ActionPill di
                // dalam _GreetingRow bisa nempel ke tepi kanan layar.
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

/// Baris sapaan + lokasi di kiri, dan pill ikon aksi di kanan.
/// PLACEHOLDER: nama "Rei" dan alamat masih teks statis.
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
        // Cuma sudut kiri yang dibulatkan — sisi kanan nempel rata ke
        // tepi layar, jadi tidak perlu ikut dibulatkan.
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

/// Kartu putih fitur utama: "Pemetaan & Rekomendasi Rute Area Gelap".
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
            // TODO: sambungkan ke alur pencarian rute aman.
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

/// Kartu putih: kolom lokasi & tujuan, pratinjau peta, tombol cari rute.
class _RouteCard extends StatelessWidget {
  const _RouteCard();

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
          // TODO: ganti dengan field pencarian lokasi sungguhan
          // (mis. Google Places Autocomplete) saat integrasi peta/API siap.
          _LocationPill(
            icon: Icons.my_location,
            label: 'Lokasi anda',
            onTap: () {},
          ),
          const SizedBox(height: 10),
          _LocationPill(
            icon: Icons.search,
            label: 'Tujuan Lokasi',
            onTap: () {},
          ),
          const SizedBox(height: 14),
          const _MapPreview(),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              // TODO: sambungkan ke logika pencarian rute aman sungguhan.
              onPressed: () {},
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
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    color: Colors.white.withOpacity(.9),
                  ),
                ),
              ),
              Icon(icon, size: 18, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

/// PLACEHOLDER: pratinjau peta statis. Ganti dengan widget peta
/// sungguhan (Google Maps / Mapbox / dsb.) saat integrasi API siap.
class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 170,
        width: double.infinity,
        color: const Color(0xFFDCE6D5),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 40,
              color: AppColors.brand.withOpacity(.35),
            ),
            Positioned(
              bottom: 10,
              child: Text(
                'ini untuk peta - belum di sambungin',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.brand.withOpacity(.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Navigasi bawah: Home, Peta & Rute, Lapor, Artikel.
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
      aspectRatio: 1.4, // lebih pendek dari lebar, tidak lagi persegi penuh
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
