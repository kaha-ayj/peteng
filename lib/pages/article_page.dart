import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'home.dart' show AppColors, AppBottomNav;
import '../theme/app_theme.dart';
import '../services/berita_api.dart';
import 'peta_rute.dart';
import 'lapor.dart';
import '../widgets/profile_button.dart';

class ArticleModel {
  const ArticleModel({
    required this.title,
    required this.description,
    required this.tag,
    required this.source,
    required this.time,
    required this.tagColor,
    this.url,
    this.gambar,
    this.lokasi,
    this.tingkat = 0,
    this.dariLaporan = false,
  });

  final String title;
  final String description;
  final String tag;
  final String source;
  final String time;
  final Color tagColor;
  final String? url;
  final String? gambar;
  final String? lokasi;
  final int tingkat;
  final bool dariLaporan;
}

class _Feed {
  const _Feed({
    required this.dishub,
    required this.laporan,
    required this.berita,
    required this.beritaOffline,
  });

  final List<ArticleModel> dishub;
  final List<ArticleModel> laporan;
  final List<ArticleModel> berita;
  final bool beritaOffline;
}

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  final int _navIndex = 3;
  int _selectedCategory = 0;
  String _searchQuery = '';
  final TextEditingController _searchC = TextEditingController();
  late Future<_Feed> _futureFeed;

  final List<String> _categories = [
    'Semua',
    'Perbaikan',
    'Artikel',
    'Kriminalitas',
    'Keselamatan',
    'Penerangan',
    'Laporan Warga',
  ];

  @override
  void initState() {
    super.initState();
    _futureFeed = _muatFeed();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  void _onNavTap(int i) {
    if (i == 3) return;

    switch (i) {
      case 0:
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PetaRutePage()),
        );
        break;
      case 2:
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LaporPage()));
        break;
    }
  }

  Future<void> _muatUlang() async {
    final feed = _muatFeed();
    setState(() => _futureFeed = feed);
    await feed;
  }

  Future<_Feed> _muatFeed() async {
    // Jalankan semua sumber secara paralel: artikel Dishub, berita web,
    // dan laporan warga. Sumber opsional dibatasi waktunya supaya halaman
    // tetap cepat tampil walau backend Dishub sedang tidak terjangkau.
    const batas = Duration(seconds: 10);

    final dishubFuture = ArtikelApi.ambil().timeout(
      batas,
      onTimeout: () => const <ArtikelDishub>[],
    );
    final laporanFuture = LaporanWargaStore.ambil().timeout(
      batas,
      onTimeout: () => const <LaporanWargaItem>[],
    );
    final beritaFuture = BeritaApi.ambilBeritaIndramayu();

    final dishub = await dishubFuture;
    final laporan = await laporanFuture;
    var berita = await beritaFuture;

    final offline = berita.isEmpty;
    if (offline) berita = _beritaContoh();

    return _Feed(
      dishub: dishub.map(_dariDishub).toList(),
      laporan: laporan.map(_dariLaporan).toList(),
      berita: berita.map(_dariBerita).toList(),
      beritaOffline: offline,
    );
  }

  ArticleModel _dariDishub(ArtikelDishub a) {
    final tag = a.perbaikan ? 'Perbaikan' : 'Artikel';
    final sumber = a.sumber.isNotEmpty
        ? a.sumber
        : (a.perbaikan ? 'Dishub Indramayu' : 'Artikel Dishub');

    return ArticleModel(
      title: a.judul,
      description: a.isi.isEmpty
          ? (a.link.isEmpty
                ? 'Artikel dari Dishub Indramayu.'
                : 'Baca artikel lengkap di ${a.sumber.isEmpty ? 'sumber asli' : a.sumber}.')
          : a.isi,
      tag: tag,
      source: sumber,
      time: labelWaktu(a.waktu),
      tagColor: _tagColor(tag),
      url: a.link.isEmpty ? null : a.link,
      gambar: a.gambar,
    );
  }

  ArticleModel _dariLaporan(LaporanWargaItem l) {
    final tingkatLabel = switch (l.tingkat) {
      1 => 'Redup',
      2 => 'Gelap',
      3 => 'Sangat gelap',
      _ => '',
    };
    final detail = [
      if (l.kategori.isNotEmpty) l.kategori,
      if (tingkatLabel.isNotEmpty) 'Tingkat: $tingkatLabel',
      if (l.lokasi.isNotEmpty) l.lokasi,
    ].join(' • ');

    return ArticleModel(
      title: l.kategori.isEmpty
          ? 'Laporan warga tentang ruas jalan gelap'
          : 'Laporan warga: ${l.kategori} di ruas jalan gelap',
      description: l.deskripsi.isEmpty
          ? (l.lokasi.isEmpty
                ? 'Warga melaporkan kondisi penerangan jalan yang minim di wilayahnya.'
                : l.lokasi)
          : l.deskripsi,
      tag: 'Laporan Warga',
      source: detail.isEmpty ? 'Warga Indramayu' : detail,
      time: labelWaktu(l.waktu),
      tagColor: _tagColor('Laporan Warga'),
      lokasi: l.lokasi,
      tingkat: l.tingkat,
      dariLaporan: true,
    );
  }

  ArticleModel _dariBerita(BeritaItem b) {
    final deskripsi = switch (b.kategori) {
      'Kriminalitas' =>
        'Kejahatan jalanan di wilayah Indramayu. Waspadai ruas jalan gelap, '
            'terutama saat melintas malam hari.',
      'Penerangan' =>
        'Kabar penerangan jalan (PJU) di Indramayu dan upaya membuat ruas '
            'jalan lebih terang.',
      'Keselamatan' =>
        'Informasi keselamatan berkendara dan kondisi jalan di Indramayu.',
      _ => 'Kabar terbaru seputar wilayah Indramayu.',
    };

    return ArticleModel(
      title: b.judul,
      description: deskripsi,
      tag: b.kategori,
      source: b.sumber,
      time: labelWaktu(b.waktu),
      tagColor: _tagColor(b.kategori),
      url: b.url,
    );
  }

  Color _tagColor(String tag) {
    final base = switch (tag) {
      'Perbaikan' => const Color(0xFF1E8E6B),
      'Artikel' => const Color(0xFF2C6BB3),
      'Laporan Warga' => const Color(0xFF6B4FBB),
      'Kriminalitas' => const Color(0xFFD92745),
      'Keselamatan' => const Color(0xFFC27605),
      'Penerangan' => const Color(0xFF2C6BB3),
      'Infrastruktur' => const Color(0xFF16834A),
      _ => const Color(0xFF46507A),
    };
    return AppColors.isDark ? Color.lerp(base, Colors.white, .35)! : base;
  }

  /// Dipakai kalau perangkat sedang offline / Google News tidak bisa diakses.
  List<BeritaItem> _beritaContoh() {
    final sekarang = DateTime.now();
    return [
      BeritaItem(
        judul: 'Waspada Begal di Ruas Jalan Minim Penerangan Indramayu',
        sumber: 'Contoh Berita',
        url: '',
        waktu: sekarang.subtract(const Duration(hours: 2)),
        kategori: 'Kriminalitas',
      ),
      BeritaItem(
        judul: 'Pemkab Indramayu Perbaiki Lampu Penerangan Jalan',
        sumber: 'Contoh Berita',
        url: '',
        waktu: sekarang.subtract(const Duration(hours: 6)),
        kategori: 'Penerangan',
      ),
      BeritaItem(
        judul: 'Tips Aman Berkendara Malam Hari di Jalan Minim Lampu',
        sumber: 'Contoh Berita',
        url: '',
        waktu: sekarang.subtract(const Duration(days: 1)),
        kategori: 'Keselamatan',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) =>
      ThemeRebuild(child: _buildPage(context));

  Widget _buildPage(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppThemeController.instance.isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: AppThemeController.instance.isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: AppColors.card,
        bottomNavigationBar: AppBottomNav(index: _navIndex, onTap: _onNavTap),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: _muatUlang,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildCategoryChips(),
                  const SizedBox(height: 20),
                  _buildFeed(),
                  const SizedBox(height: 20),
                  _buildCTACard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PORTAL INFORMASI',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .8,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Artikel & Kabar Indramayu',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Laporan warga, kriminalitas jalanan, dan kabar penerangan '
                'jalan di sekitar Indramayu.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const ProfileButton(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchC,
        onChanged: (value) => setState(() => _searchQuery = value),
        textInputAction: TextInputAction.search,
        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.ink),
        decoration: InputDecoration(
          hintText: 'Cari berita atau laporan...',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.muted),
          prefixIcon: Icon(Icons.search, color: AppColors.brand, size: 22),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  icon: const Icon(Icons.close, size: 19),
                  color: AppColors.muted,
                  onPressed: () {
                    _searchC.clear();
                    setState(() => _searchQuery = '');
                  },
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_categories.length, (i) {
          final active = i == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _categories[i],
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.brand,
                ),
              ),
              selected: active,
              selectedColor: AppColors.brandFill,
              backgroundColor: AppColors.surface,
              showCheckmark: false,
              side: active
                  ? BorderSide.none
                  : BorderSide(color: AppColors.border),
              onSelected: (_) => setState(() => _selectedCategory = i),
            ),
          );
        }),
      ),
    );
  }

  bool _cocok(ArticleModel a, String query) {
    final kategoriCocok =
        _selectedCategory == 0 ||
        a.tag == _categories[_selectedCategory] ||
        (a.dariLaporan && _categories[_selectedCategory] == 'Laporan Warga');
    if (!kategoriCocok) return false;
    if (query.isEmpty) return true;
    return a.title.toLowerCase().contains(query) ||
        a.description.toLowerCase().contains(query) ||
        a.source.toLowerCase().contains(query) ||
        a.tag.toLowerCase().contains(query);
  }

  Widget _buildFeed() {
    return FutureBuilder<_Feed>(
      future: _futureFeed,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }

        final feed = snapshot.data;
        if (feed == null) {
          return _pesanKosong(
            'Gagal memuat berita.',
            aksi: TextButton(
              onPressed: _muatUlang,
              child: const Text('Coba lagi'),
            ),
          );
        }

        final query = _searchQuery.trim().toLowerCase();
        final dishub = feed.dishub.where((a) => _cocok(a, query)).toList();
        final berita = feed.berita.where((a) => _cocok(a, query)).toList();
        // Laporan lokal hanya ditampilkan kalau artikel Dishub belum tersedia,
        // supaya tidak dobel dengan artikel hasil perbaikan.
        final laporan = feed.dishub.isEmpty
            ? feed.laporan.where((a) => _cocok(a, query)).toList()
            : const <ArticleModel>[];

        if (dishub.isEmpty && laporan.isEmpty && berita.isEmpty) {
          return _pesanKosong(
            query.isNotEmpty
                ? 'Tidak ada berita dengan kata kunci "$_searchQuery".'
                : 'Belum ada berita untuk kategori ini.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (feed.beritaOffline) ...[
              _infoOffline(),
              const SizedBox(height: 14),
            ],
            if (dishub.isNotEmpty) ...[
              _sectionHeader(
                icon: Icons.verified_outlined,
                title: 'Artikel & Perbaikan Dishub',
                subtitle: 'Ditulis Dishub dari laporan yang sudah diproses',
                jumlah: dishub.length,
              ),
              const SizedBox(height: 10),
              for (final a in dishub) _buildArticleCard(a),
              const SizedBox(height: 10),
            ],
            if (laporan.isNotEmpty) ...[
              _sectionHeader(
                icon: Icons.groups_outlined,
                title: 'Laporan Warga',
                subtitle: 'Laporan dari perangkat ini',
                jumlah: laporan.length,
              ),
              const SizedBox(height: 10),
              for (final a in laporan) _buildArticleCard(a),
              const SizedBox(height: 10),
            ],
            if (berita.isNotEmpty) ...[
              _sectionHeader(
                icon: Icons.public_outlined,
                title: 'Kabar Indramayu',
                subtitle: 'Kriminalitas & penerangan jalan dari media',
                jumlah: berita.length,
              ),
              const SizedBox(height: 10),
              for (final a in berita) _buildArticleCard(a),
            ],
          ],
        );
      },
    );
  }

  Widget _infoOffline() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Berita terbaru belum bisa dimuat. Menampilkan contoh berita.',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.muted,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: _muatUlang,
            child: Text(
              'Muat ulang',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required int jumlah,
  }) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.brand),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        Text(
          '$jumlah item',
          style: GoogleFonts.poppins(fontSize: 10.5, color: AppColors.muted),
        ),
      ],
    );
  }

  Widget _pesanKosong(String pesan, {Widget? aksi}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 42,
              color: AppColors.brand.withValues(alpha: .3),
            ),
            const SizedBox(height: 10),
            Text(
              pesan,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.muted,
              ),
            ),
            if (aksi != null) aksi,
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(ArticleModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _bukaDetail(article),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: article.tagColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.tag,
                        style: GoogleFonts.poppins(
                          color: article.tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      article.time,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  article.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  article.description,
                  style: GoogleFonts.poppins(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      article.dariLaporan
                          ? Icons.location_on_outlined
                          : Icons.newspaper_outlined,
                      size: 14,
                      color: AppColors.brand.withValues(alpha: .6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        article.source,
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (article.url != null && article.url!.isNotEmpty)
                      Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: AppColors.brand.withValues(alpha: .6),
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

  Future<void> _bukaDetail(ArticleModel article) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ThemeRebuild(
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: article.tagColor.withValues(alpha: .12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.tag,
                        style: GoogleFonts.poppins(
                          color: article.tagColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${article.source} • ${article.time}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                    if (article.gambar != null &&
                        article.gambar!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          article.gambar!,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      article.description,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppColors.ink,
                        height: 1.55,
                      ),
                    ),
                    if (article.lokasi != null &&
                        article.lokasi!.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: AppColors.brand,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                article.lokasi!,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (article.url != null && article.url!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final ok = await launchUrl(
                              Uri.parse(article.url!),
                              mode: LaunchMode.externalApplication,
                            );
                            if (!ok && ctx.mounted) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Tidak bisa membuka tautan berita.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(
                            article.source.trim().isEmpty
                                ? 'Buka tautan'
                                : 'Baca di ${article.source}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandFill,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCTACard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandFill, AppColors.brandSoft],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandFill.withValues(alpha: .22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Ruas Jalan Gelap di Sekitarmu?',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bantu warga Indramayu dengan melaporkan kondisi penerangan jalan.',
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: .75),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () => _onNavTap(2),
              icon: const Icon(Icons.campaign_outlined, size: 18),
              label: Text(
                'Lapor Sekarang',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4FF),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
