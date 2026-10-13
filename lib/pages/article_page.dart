import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Pastikan untuk menyesuaikan lokasi import file-file di bawah ini dengan project kamu
import 'home.dart';
import 'peta_rute.dart';
import 'lapor.dart';
// import '../widgets/app_bottom_nav.dart'; // Asumsi lokasi file AppBottomNav
// import '../utils/app_colors.dart'; // Asumsi lokasi warna AppColors

// Model data untuk artikel
class ArticleModel {
  final String title;
  final String description;
  final String tag;
  final String author;
  final String time;
  final Color tagColor;
  final String imageUrl;

  ArticleModel({
    required this.title,
    required this.description,
    required this.tag,
    required this.author,
    required this.time,
    required this.tagColor,
    required this.imageUrl,
  });
}

class ArticlePage extends StatefulWidget {
  const ArticlePage({Key? key}) : super(key: key);

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  // Index 3 adalah untuk tab Artikel
  int _navIndex = 3;
  late Future<List<ArticleModel>> _futureArticles;

  @override
  void initState() {
    super.initState();
    _futureArticles = fetchRealIndramayuNews();
  }

  // Fungsi navigasi yang disamakan dengan lapor.dart & peta_rute.dart
  void _onNavTap(int i) {
    if (i == 3) return; // Sudah di halaman Artikel, tidak perlu pindah

    switch (i) {
      case 0: // Home
        Navigator.of(context).popUntil((r) => r.isFirst);
        break;
      case 1: // Peta & Rute
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PetaRutePage()),
        );
        break;
      case 2: // Lapor
        Navigator.of(
          context,
        ).pushReplacement(MaterialPageRoute(builder: (_) => const LaporPage()));
        break;
    }
  }

  Future<List<ArticleModel>> fetchRealIndramayuNews() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    return [
      ArticleModel(
        title: 'Jabar Punya 18 Unit Mobile Batching Plant, Bangun Jalan...',
        description:
            'Pemprov Jabar luncurkan fasilitas pengolah beton berjalan untuk mempermudah perbaikan jalan desa.',
        tag: 'Infrastruktur Jalan',
        author: 'Radar Cirebon',
        time: 'Terkini',
        tagColor: Colors.blue,
        imageUrl: 'https://via.placeholder.com/150/4G829',
      ),
      ArticleModel(
        title:
            'Truk Trailer dan Minibus Terbakar di SPBU Sukagumiwang Indramayu',
        description:
            'Kecelakaan akibat percikan api saat mengisi BBM, mengingatkan pentingnya keselamatan.',
        tag: 'Edukasi Keselamatan',
        author: 'Berita Indramayu',
        time: '28 Sep 2026',
        tagColor: Colors.orange,
        imageUrl: 'https://via.placeholder.com/150/FF6B6B',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Mempertahankan style dari Home (opsional, sesuaikan AppColors.card jika ada)
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Scaffold(
        backgroundColor: const Color(
          0xFFF8F9FA,
        ), // atau AppColors.card menyesuaikan temamu
        // Memakai AppBottomNav persis seperti di halaman Home
        bottomNavigationBar: AppBottomNav(index: _navIndex, onTap: _onNavTap),

        appBar: AppBar(
          automaticallyImplyLeading:
              false, // Menghilangkan tombol back bawaan Scaffold
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Siang',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'INDRAMAYU',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PORTAL KOMUNIKASI PUBLIK',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pusat Informasi & Buletin PJU',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A24),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kabar resmi progres perbaikan jalan, edukasi keselamatan malam, & agenda terbaru Indramayu.',
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                ),
                const SizedBox(height: 16),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari artikel, nama jalan...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kategori Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('Semua Berita', isActive: true),
                      _buildChip('Infrastruktur', isActive: false),
                      _buildChip('Edukasi Keselamatan', isActive: false),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildFeaturedArticle(),

                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Berita Indramayu Terbaru',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A24),
                      ),
                    ),
                    Text(
                      'Real-time',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                FutureBuilder<List<ArticleModel>>(
                  future: _futureArticles,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return Column(
                        children: snapshot.data!
                            .map((a) => _buildArticleItem(a))
                            .toList(),
                      );
                    }
                    return const Center(child: Text('Tidak ada artikel.'));
                  },
                ),

                const SizedBox(height: 16),
                _buildCTACard(),
                const SizedBox(
                  height: 20,
                ), // Spasi ekstra di bawah agar tidak tertutup nav bar
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---
  Widget _buildChip(String label, {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C4FF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? null : Border.all(color: Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedArticle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey,
              image: DecorationImage(
                image: NetworkImage('https://via.placeholder.com/400x200'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pemkab Indramayu Tegaskan Komitmen Perbaikan PJU',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A24),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Langkah strategis menjamin keamanan pemudik dan warga lokal...',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.remove_red_eye,
                      size: 16,
                      color: Colors.blue[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '1.2k Pembaca',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleItem(ArticleModel article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: article.tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    article.tag,
                    style: TextStyle(
                      color: article.tagColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A24),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  article.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[300],
              image: DecorationImage(
                image: NetworkImage(article.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCTACard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[900]!, const Color(0xFF1E213A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ingin Ruas Jalan Anda Masuk Rencana Perbaikan?',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _onNavTap(2); // Otomatis arahkan ke tab Lapor (index 2)
              },
              icon: const Icon(Icons.add_location_alt, color: Colors.black87),
              label: const Text(
                'Lapor Sekarang',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
