import 'package:flutter/material.dart';

class ArticlePage extends StatelessWidget {
  const ArticlePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Icon(Icons.wb_sunny, color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            Text('Siang', style: TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('INDRAMAYU', style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Teks
              Text(
                'PORTAL KOMUNIKASI PUBLIK',
                style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pusat Informasi & Buletin PJU',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1A24)),
              ),
              const SizedBox(height: 8),
              Text(
                'Kabar resmi progres perbaikan penerangan jalan, edukasi keselamatan malam, & agenda Dishub Indramayu.',
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Cari artikel, nama jalan, atau pengumuman',
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
                    _buildChip('Semua Berita', isActive: false),
                    _buildChip('Progres Perbaikan PJU', isActive: true),
                    _buildChip('Edukasi Keselamatan', isActive: false),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Featured Article Card
              _buildFeaturedArticle(),

              const SizedBox(height: 24),
              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Buletin Lapangan Terbaru',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A24)),
                  ),
                  Text(
                    'Update 5 Menit Lalu',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // List Artikel
              _buildArticleItem(
                tag: 'Progres Perbaikan',
                title: 'Perbaikan Total Tiang PJU Ambruk di Ruas Balongan',
                desc: 'Hasil respon kilat dari aduan warga via PETENG...',
                author: 'Tim Reaksi Cepat PJU',
                time: '2 Jam lalu',
                tagColor: Colors.green,
              ),
              _buildArticleItem(
                tag: 'Edukasi Keselamatan',
                title: 'Tips Berkendara Malam di Jalur Pantura Indramayu...',
                desc: 'Panduan mitigasi kecelakaan di malam hari saat melewati simpang tak...',
                author: 'Satlantas & Dishub',
                time: 'Kemarin',
                tagColor: Colors.orange,
              ),

              const SizedBox(height: 16),
              // Call to Action Card
              _buildCTACard(),
            ],
          ),
        ),
      ),
      
      // Bottom Navigation Bar (Sesuai referensi gambar ke-2)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E213A), // Warna navy gelap khas Peteng
        unselectedItemColor: Colors.grey,
        currentIndex: 3, // Aktif di tab Artikel
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Peta & Rute'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber_rounded), label: 'Lapor'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Artikel'),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C4FF) : Colors.white, // Biru terang untuk aktif, putih untuk pasif
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar placeholder
          Container(
            height: 180,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              color: Colors.grey,
              image: DecorationImage(
                image: NetworkImage('https://via.placeholder.com/400x200'), // Ganti dengan asset gambarmu
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
                  'Pemkab & Dishub Indramayu Tuntaskan 45 Titik PJU Baru di Jalur Rawan Begal Lohbener - Sukagumiwang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1A24)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Langkah strategis menjamin keamanan pemudik dan warga lokal di malam hari dengan teknologi...',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.remove_red_eye, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text('1.8k Pembaca', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 16),
                    Icon(Icons.thumb_up, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text('420 Apresiasi', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const Spacer(),
                    Text('Baca Selengkapnya >', style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildArticleItem({required String tag, required String title, required String desc, required String author, required String time, required Color tagColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: tagColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(tag, style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A24))),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.person, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(author, style: TextStyle(color: Colors.grey[500], fontSize: 10)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(time, style: TextStyle(color: Colors.grey[400], fontSize: 10)),
              const SizedBox(height: 8),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[300],
                  image: const DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/70'), // Ganti dengan asset gambarmu
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          )
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
              const Icon(Icons.lightbulb_outline, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: const Text(
                  'Ingin Ruas Jalan Anda Masuk Rencana Perbaikan?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Setiap laporan titik gelap yang Anda ajukan dianalisis oleh Dishub untuk prioritas pemasangan PJU baru.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add_location_alt, color: Colors.black87),
              label: const Text('Lapor Sekarang di Tab Lapor', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C4FF), // Warna cyan/biru muda dari tombol CTA di gambar 1
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          )
        ],
      ),
    );
  }
}