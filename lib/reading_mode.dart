import 'dart:ui';
import 'package:flutter/material.dart';
import 'annotations.dart';

double _lum(Color c) => .2126 * c.r + .7152 * c.g + .0722 * c.b;

const kInvert = ColorFilter.matrix(<double>[
  -1, 0, 0, 0, 255,
  0, -1, 0, 0, 255,
  0, 0, -1, 0, 255,
  0, 0, 0, 1, 0,
]);

/// هل الوضع الحالي يقلب الألوان (خلفية أغمق من النص)؟ في هذه الحالة نغلّف العارض بفلتر قلب،
/// ونغلّف الطبقات (ستيكرات/رسم) بنفس الفلتر فتعود لألوانها الأصلية.
bool toneInverts(Annotations a) {
  if (a.mode == 'original') return false;
  final t = a.tone[a.mode]!;
  return _lum(Color(t[0])) < _lum(Color(t[1]));
}

int _c(double v) => (v * 255).round().clamp(0, 255).toInt();

/// تلوين الصفحة باستخدام blend modes بسيطة فقط (modulate + plus) لتجنّب خطوط الشاشة.
void paintTone(Canvas canvas, Rect r, Annotations a) {
  final inv = toneInverts(a);
  if (a.mode != 'original') {
    final t = a.tone[a.mode]!;
    final bg = Color(t[0]), tx = Color(t[1]);
    if (inv) {
      // القلب يتم لاحقاً بالفلتر: y = x*(tx-bg) + (1-tx)
      canvas.drawRect(r, Paint()..color = Color.fromARGB(255, _c(tx.r - bg.r), _c(tx.g - bg.g), _c(tx.b - bg.b))..blendMode = BlendMode.modulate);
      canvas.drawRect(r, Paint()..color = Color.fromARGB(255, _c(1 - tx.r), _c(1 - tx.g), _c(1 - tx.b))..blendMode = BlendMode.plus);
    } else {
      canvas.drawRect(r, Paint()..color = Color.fromARGB(255, _c(bg.r - tx.r), _c(bg.g - tx.g), _c(bg.b - tx.b))..blendMode = BlendMode.modulate);
      canvas.drawRect(r, Paint()..color = tx..blendMode = BlendMode.plus);
    }
  }
  if (a.dim > 0) canvas.drawRect(r, Paint()..color = (inv ? Colors.white : Colors.black).withValues(alpha: a.dim));
}
