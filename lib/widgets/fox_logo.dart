import 'package:flutter/material.dart';

import '../theme.dart';

/// Собственный логотип Fox Browser — геометрическая мордочка лисы.
class FoxLogo extends StatelessWidget {
  const FoxLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: const CustomPaint(painter: _FoxPainter()),
    );
  }
}

class _FoxPainter extends CustomPainter {
  const _FoxPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset p(double x, double y) => Offset(x * s, y * s);
    void poly(List<Offset> pts, Color color) {
      final path = Path()..addPolygon(pts, true);
      canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
    }

    const brown = FoxPalette.latte;
    const dark = FoxPalette.espresso;
    const cream = FoxPalette.cream;
    const light = Color(0xFFD6BEA0);

    poly([p(.18, .42), p(.22, .08), p(.45, .32)], brown);
    poly([p(.82, .42), p(.78, .08), p(.55, .32)], brown);
    poly([p(.24, .36), p(.255, .16), p(.40, .31)], dark);
    poly([p(.76, .36), p(.745, .16), p(.60, .31)], dark);
    poly([p(.15, .38), p(.5, .28), p(.85, .38), p(.5, .92)], brown);
    poly([p(.15, .38), p(.5, .62), p(.5, .92)], cream);
    poly([p(.85, .38), p(.5, .62), p(.5, .92)], light);
    poly([p(.455, .85), p(.545, .85), p(.5, .92)], dark);
    final eye = Paint()..color = dark;
    canvas.drawCircle(p(.37, .49), s * .035, eye);
    canvas.drawCircle(p(.63, .49), s * .035, eye);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
