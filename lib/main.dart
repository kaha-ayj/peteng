import 'package:flutter/material.dart';
import 'pages/landing_page.dart';

void main() {
  runApp(const PetengApp());
}

class PetengApp extends StatelessWidget {
  const PetengApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
    );
  }
}
