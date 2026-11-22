import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'home.dart' show AppColors, AppBottomNav;
import '../theme/app_theme.dart';
import 'peta_rute.dart';
import 'lapor.dart';
import '../widgets/profile_button.dart';

class ArticleModel {
  final String title;
  final String description;
  final String tag;
  final String author;
  final String time;
  final Color tagColor;

  ArticleModel({
    required this.title,
    required this.description,
    required this.tag,
    required this.author,
    required this.time,
    required this.tagColor,
  });
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
  late Future<List<ArticleModel>> _futureArticles;

  final List<String> _categories = [
    'Semua',
    'Infrastruktur',
    'Keselamatan',
    'Agenda',
  ];

  @override
  void initState() {
    super.initState();
    _futureArticles = _fetchArticles();
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

  Future<List<ArticleModel>> _fetchArticles() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    return [
      ArticleModel(
        title: 'Pemkab Indramayu Tegaskan Komitmen Perbaikan PJU',
        description:
            'Langkah strategis menjamin keamanan pemudik dan warga lokal melalui program perbaikan lampu penerangan jalan.',
        tag: 'Infrastruktur',
        author: 'Humas Indramayu',
        time: '2 jam lalu',
        tagColor: Colors.blue,
      ),
      ArticleModel(
        title: 'Jabar Punya 18 Unit Mobile Batching Plant, Bangun Jalan Desa',
        description:
            'Pemprov Jabar luncurkan fasilitas pengolah beton berjalan untuk mempermudah perbaikan jalan desa.',
        tag: 'Infrastruktur',
        author: 'Radar Cirebon',
        time: '5 jam lalu',
        tagColor: Colors.blue,
      ),
      ArticleModel(
        title: 'Tips Aman Berkendara Malam Hari di Jalan Minim Penerangan',
        description:
            'Panduan lengkap untuk pengendara motor dan mobil agar tetap aman saat melewati ruas jalan gelap.',
        tag: 'Keselamatan',
        author: 'Tim PETENG',
        time: '1 hari lalu',
        tagColor: Colors.orange,
      ),
      ArticleModel(
        title:
            'Truk Trailer dan Minibus Terbakar di SPBU Sukagumiwang Indramayu',
        description:
            'Kecelakaan akibat percikan api saat mengisi BBM, mengingatkan pentingnya keselamatan di jalan.',
        tag: 'Keselamatan',
        author: 'Berita Indramayu',
        time: '28 Sep 2026',
        tagColor: Colors.orange,
      ),
      ArticleModel(
        title: 'Agenda Musrenbang Kecamatan Indramayu Tahun 2027',
        description:
            'Jadwal dan lokasi pelaksanaan Musrenbang untuk penyusunan prioritas pembangunan infrastruktur jalan.',
        tag: 'Agenda',
        author: 'Bappeda Indramayu',
        time: '30 Sep 2026',
        tagColor: Colors.green,
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
          child: SingleChildScrollView(
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
                _buildArticleList(),
                const SizedBox(height: 20),
                _buildCTACard(),
              ],
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
                'Artikel & Buletin PJU',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brand,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Kabar terbaru seputar penerangan jalan dan keselamatan di Indramayu.',
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
          hintText: 'Cari artikel, berita...',
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

  Widget _buildArticleList() {
    return FutureBuilder<List<ArticleModel>>(
      future: _futureArticles,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppColors.brand),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text(
                'Belum ada artikel.',
                style: GoogleFonts.poppins(color: AppColors.muted),
              ),
            ),
          );
        }

        final articles = snapshot.data!;
        final query = _searchQuery.trim().toLowerCase();
        final filtered = articles.where((a) {
          final categoryMatch =
              _selectedCategory == 0 || a.tag == _categories[_selectedCategory];
          final searchMatch =
              query.isEmpty ||
              a.title.toLowerCase().contains(query) ||
              a.description.toLowerCase().contains(query) ||
              a.author.toLowerCase().contains(query) ||
              a.tag.toLowerCase().contains(query);
          return categoryMatch && searchMatch;
        }).toList();

        if (filtered.isEmpty) {
          final adaPencarian = query.isNotEmpty;
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
                    adaPencarian
                        ? 'Artikel dengan kata kunci "$_searchQuery" tidak ditemukan.'
                        : 'Tidak ada artikel untuk kategori ini.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Berita Terbaru',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brand,
                  ),
                ),
                const Spacer(),
                Text(
                  '${filtered.length} artikel',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final article in filtered) _buildArticleCard(article),
          ],
        );
      },
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
                    color: article.tagColor.withValues(alpha: .1),
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
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.brand.withValues(alpha: .6),
                ),
                const SizedBox(width: 4),
                Text(
                  article.author,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ],
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
