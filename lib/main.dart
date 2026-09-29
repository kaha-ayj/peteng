import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';

void main() {
  runApp(const PetengApp());
}

class PetengApp extends StatelessWidget {
  const PetengApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}
