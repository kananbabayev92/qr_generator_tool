import 'package:flutter/material.dart';

/// OnteroLogo - Ontero QR Generator & Scanner brend loqosu vidceti.
/// Həm statik rejimdə, həm də lazer animasiyalı rejimdə istifadə edilə bilər.
class OnteroLogo extends StatelessWidget {
  final double size;
  final bool showGlow;
  final bool showBorder;
  final double? laserProgress; // 0.0 - 1.0 (əgər splash animasiyasında lazer hərəkət edirsə)

  const OnteroLogo({
    super.key,
    this.size = 120,
    this.showGlow = true,
    this.showBorder = true,
    this.laserProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                  blurRadius: size * 0.25,
                  spreadRadius: size * 0.02,
                  offset: Offset(0, size * 0.04),
                ),
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                  blurRadius: size * 0.35,
                  spreadRadius: size * 0.01,
                  offset: Offset(0, -size * 0.02),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Əsas Loqo Şəkli
            Image.asset(
              'assets/images/ontero_logo.png',
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),

            // Əgər dinamik lazer animasiyası aktivdirsə
            if (laserProgress != null)
              Positioned(
                top: (size * 0.2) + (size * 0.6 * laserProgress!),
                left: size * 0.15,
                right: size * 0.15,
                child: Container(
                  height: 3.5,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Colors.transparent,
                        Color(0xFF06B6D4),
                        Colors.white,
                        Color(0xFF06B6D4),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.9),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.8),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
