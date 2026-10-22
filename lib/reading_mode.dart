import 'dart:ui';
import 'package:flutter/material.dart';
import 'annotations.dart';

double _lum(Color c) => .2126 * c.r + .7152 * c.g + .0722 * c.b;

/// يلوّن الصفحة: الأبيض يصير لون الخلفية، والأسود يصير لون النص.
void paintTone(Canvas canvas, Rect r, Annotations a) {
  if (a.mode != 'original') {
    final t = a.tone[a.mode]!;
    final bg = Color(t[0]), tx = Color(t[1]);
    final inv = _lum(bg) < _lum(tx); // خلفية أغمق من النص = قلب الألوان
    final hi = inv ? tx : bg, lo = inv ? bg : tx;
    int c(double v) => (v * 255).round().clamp(0, 255).toInt();
    if (inv) canvas.drawRect(r, Paint()..color = const Color(0xFFFFFFFF)..blendMode = BlendMode.difference);
    canvas.drawRect(r, Paint()..color = Color.fromARGB(255, c(hi.r - lo.r), c(hi.g - lo.g), c(hi.b - lo.b))..blendMode = BlendMode.multiply);
    canvas.drawRect(r, Paint()..color = lo..blendMode = BlendMode.plus);
  }
  if (a.dim > 0) canvas.drawRect(r, Paint()..color = Colors.black.withValues(alpha: a.dim));
}
