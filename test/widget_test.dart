
import 'package:flutter_test/flutter_test.dart';
import 'package:peteng/main.dart';
import 'package:peteng/pages/splash_screen.dart';

void main() {
  testWidgets('PETENG menampilkan SplashScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const PetengApp());

    // Pastikan halaman splash tampil.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Jalankan timer splash selama 3 detik.
    await tester.pump(const Duration(seconds: 3));

    // Bersihkan animasi atau timer yang masih aktif.
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
    );
  });
}
