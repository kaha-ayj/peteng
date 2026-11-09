import 'package:flutter/material.dart';

import '../pages/profile_page.dart';

/// Tombol bulat untuk membuka halaman profil.
///
/// Dipakai di header halaman Peta & Rute, Lapor, dan Artikel supaya akses ke
/// profil konsisten dari mana pun pengguna berada.
class ProfileButton extends StatelessWidget {
  const ProfileButton({
    super.key,
    this.color = const Color(0xFF172554),
    this.backgroundColor = Colors.white,
    this.iconSize = 20,
  });

  final Color color;
  final Color backgroundColor;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      elevation: 2,
      shadowColor: const Color(0x33000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ProfilePage())),
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Icon(Icons.person_outline, size: iconSize, color: color),
        ),
      ),
    );
  }
}
