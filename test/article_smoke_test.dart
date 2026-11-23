import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:peteng/pages/article_page.dart';
import 'package:peteng/services/berita_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('parseTanggal menerima format RSS', () {
    final gmt = BeritaApi.parseTanggal('Sat, 22 Aug 2026 07:00:00 GMT');
    expect(gmt, DateTime.utc(2026, 8, 22, 7));

    final wib = BeritaApi.parseTanggal('Sun, 22 Nov 2026 10:15:30 +0700');
    expect(wib, DateTime.utc(2026, 11, 22, 3, 15, 30));

    expect(BeritaApi.parseTanggal('2026-08-22T07:00:00Z'), isNotNull);
    expect(BeritaApi.parseTanggal(''), isNull);
  });

  test('ArtikelApi mem-parse artikel & perbaikan dari backend', () async {
    SharedPreferences.setMockInitialValues({});

    final client = MockClient((request) async {
      if (request.url.path.endsWith('/artikel')) {
        return http.Response(
          jsonEncode({
            'data': [
              {
                'judul': 'Perbaikan PJU Jalan Raya Indramayu',
                'isi': 'Lampu jalan yang dilaporkan warga sudah diganti.',
                'link': '/artikel/1',
                'kategori': 'Perbaikan',
                'created_at': '2026-11-20T10:00:00Z',
              },
              {
                'title': 'Begal di Jalan Gelap',
                'content': 'Warga diminta waspada.',
                'url': 'https://kompas.com/berita/begal',
                'sumber': 'Kompas.com',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('[]', 404);
    });

    final hasil = await ArtikelApi.ambil(client: client);

    expect(hasil.length, 2);
    expect(hasil.first.perbaikan, isTrue);
    expect(hasil.first.link, endsWith('/artikel/1'));
    expect(hasil.last.perbaikan, isFalse);
    expect(hasil.last.link, 'https://kompas.com/berita/begal');
    expect(hasil.last.sumber, 'Kompas.com');
  });

  testWidgets('halaman artikel tampil dan memuat feed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaterialApp(home: ArticlePage()));

    expect(find.text('Artikel & Kabar Indramayu'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.text('Kabar Indramayu'), findsOneWidget);
    expect(find.textContaining('Laporan Warga'), findsWidgets);
  });
}
