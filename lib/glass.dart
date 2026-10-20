import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

class MountainBackground extends StatelessWidget {
  const MountainBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        const CustomPaint(painter: _MountainPainter()),
        child,
      ]);
}

class _MountainPainter extends CustomPainter {
  const _MountainPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0E6B61), HC.deep])
              .createShader(r));
    canvas.drawCircle(Offset(s.width * .70, s.height * .54), s.width * .18,
        Paint()..color = HC.cream.withValues(alpha: .12));
    void poly(List<List<double>> pts, Color c) {
      final p = Path();
      for (var i = 0; i < pts.length; i++) {
        final x = pts[i][0] / 1280 * s.width, y = pts[i][1] / 800 * s.height;
        i == 0 ? p.moveTo(x, y) : p.lineTo(x, y);
      }
      canvas.drawPath(p..close(), Paint()..color = c);
    }
    poly([[0, 520], [160, 400], [300, 500], [480, 360], [640, 490], [820, 380], [1000, 500], [1150, 410], [1280, 480], [1280, 800], [0, 800]], HC.mid);
    poly([[0, 620], [200, 500], [380, 610], [560, 490], [760, 620], [960, 520], [1140, 630], [1280, 560], [1280, 800], [0, 800]], const Color(0xFF06403A));
    poly([[0, 720], [140, 660], [300, 730], [520, 650], [700, 730], [900, 670], [1100, 740], [1280, 690], [1280, 800], [0, 800]], HC.deep);
  }
  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 20});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: HC.cream.withValues(alpha: .09),
            borderRadius: br,
            border: Border.all(color: HC.cream.withValues(alpha: .2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
