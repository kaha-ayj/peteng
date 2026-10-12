import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'home.dart' show AppColors;

class PlaceResult {
  const PlaceResult(this.name, this.point);
  final String name;
  final LatLng point;
}

/// Bottom sheet pencarian tujuan, pakai Nominatim (geocoder gratis milik
/// OpenStreetMap). Pencarian dijalankan saat tombol cari/enter ditekan —
/// BUKAN tiap ketikan — karena kebijakan Nominatim melarang autocomplete
/// dan membatasi 1 request per detik:
/// https://operations.osmfoundation.org/policies/nominatim/
class PlaceSearchSheet extends StatefulWidget {
  const PlaceSearchSheet({super.key, this.title = 'Cari tujuan'});

  final String title;

  @override
  State<PlaceSearchSheet> createState() => _PlaceSearchSheetState();
}

class _PlaceSearchSheetState extends State<PlaceSearchSheet> {
  final _c = TextEditingController();
  List<PlaceResult> _results = [];
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
        return PlaceResult(
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
              widget.title,
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
