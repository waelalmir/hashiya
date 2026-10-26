import 'package:flutter/material.dart';
import 'annotations.dart';

const kInvert = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
  0, -1, 0, 0, 255,
  0, 0, -1, 0, 255,
  0, 0, 0, 1, 0,
]);

bool toneInverts(Annotations a) => a.mode == 'night';

Color invertColor(Color c) => Color.fromARGB(
      (c.a * 255).round(),
      255 - (c.r * 255).round(),
      255 - (c.g * 255).round(),
      255 - (c.b * 255).round(),
    );

void paintTone(Canvas canvas, Rect pageRect, Annotations a) {
  if (a.mode != 'Original' && a.mode != 'original') {
    final t = a.tone[a.mode];
    if (t != null && t.isNotEmpty) {
      final bg = Color(t[0]);
      final c = toneInverts(a) ? invertColor(bg) : bg;
      canvas.drawRect(
        pageRect,
        Paint()
          ..color = c
          ..blendMode = BlendMode.multiply,
      );
    }
  }
  if (a.dim > 0) {
    final d = (a.dim * 180).round().clamp(0, 200);
    canvas.drawRect(
      pageRect,
      Paint()..color = Color.fromARGB(d, 0, 0, 0),
    );
  }
}
