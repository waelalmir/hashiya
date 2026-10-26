import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

const kPaperFont = 'PlaypenSansArabic';
const kPaperInk = Color(0xFF3A3A3A);

TextStyle paperTextStyle(Color color) => TextStyle(
      fontFamily: kPaperFont,
      fontVariations: const [ui.FontVariation('wght', 600)],
      color: color,
      height: 1.25,
    );

/// نص ديناميكي يصغّر تلقائياً ليبقى داخل الحدود (بند 5)
class AutoFitText extends StatelessWidget {
  const AutoFitText(this.text, {super.key, required this.style, this.maxSize = 40, this.minSize = 6});
  final String text;
  final TextStyle style;
  final double maxSize, minSize;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final dir = Directionality.of(context);
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return const SizedBox.shrink();
      bool fits(double fs) {
        final tp = TextPainter(
          text: TextSpan(text: text, style: style.copyWith(fontSize: fs)),
          textDirection: dir,
          textAlign: TextAlign.center,
        )..layout(maxWidth: w);
        final ok = tp.height <= h;
        tp.dispose();
        return ok;
      }

      double best;
      if (fits(maxSize)) {
        best = maxSize;
      } else {
        var lo = minSize, hi = maxSize;
        for (var i = 0; i < 9; i++) {
          final mid = (lo + hi) / 2;
          if (fits(mid)) {
            lo = mid;
          } else {
            hi = mid;
          }
        }
        best = lo;
      }
      return SizedBox(
        width: w,
        height: h,
        child: Center(child: Text(text, textAlign: TextAlign.center, style: style.copyWith(fontSize: best))),
      );
    });
  }
}

class PaperStyle {
  const PaperStyle(this.paper, this.tape,
      {this.torn = false, this.curl = 0, this.grid = false, this.holes = false, this.tapeAngle = -.12, this.tapeX = .5});
  final Color paper, tape;
  final bool torn, grid, holes;
  final int curl;
  final double tapeAngle, tapeX;

  PaperStyle get frame => PaperStyle(Color.lerp(paper, Colors.white, .6)!, tape, tapeAngle: tapeAngle, tapeX: tapeX);
}

const kPaperStyles = <PaperStyle>[
  PaperStyle(Color(0xFFFFFFFF), Color(0xFFC9A6D6), torn: true, tapeAngle: -.35, tapeX: .22),
  PaperStyle(Color(0xFFEFEFEF), Color(0xFF8FB08C), curl: 1, tapeAngle: -.04, tapeX: .5),
  PaperStyle(Color(0xFFF2E9D4), Color(0xFFF0A898), torn: true, tapeAngle: -.25, tapeX: .75),
  PaperStyle(Color(0xFFF0EEE6), Color(0xFF8DBFCF), curl: -1, tapeAngle: -.3, tapeX: .25),
  PaperStyle(Color(0xFFF8F3D3), Color(0xFFB99AB8), torn: true, tapeAngle: .03, tapeX: .5),
  PaperStyle(Color(0xFFE8E0EE), Color(0xFF8FB5C9), curl: 1, tapeAngle: .3, tapeX: .75, torn: true),
  PaperStyle(Color(0xFFF5F1E8), Color(0xFFA87E5C), grid: true, tapeAngle: -.08, tapeX: .35),
  PaperStyle(Color(0xFFFFFFFF), Color(0xFFD4B66A), holes: true, tapeAngle: .1, tapeX: .8),
  PaperStyle(Color(0xFFEFE2D2), Color(0xFFD9A38F), torn: true, tapeAngle: -.2, tapeX: .5),
];

const kPhrases = <String>[
  'هام جداً',
  'للمراجعة',
  'تذكير',
  'سؤال؟',
  'مثال',
  'تعريف',
  'قاعدة',
  'ملخص',
  'لا تنسَ!',
  'للحفظ',
  'خطأ شائع',
  'يأتي بالامتحان',
  'اسأل الدكتور',
  'ابحث أكثر',
  'فكرة',
  'نقطة مهمة',
  'ممتاز',
  'صعب',
  'سهل',
  'فهمتها ✓',
  'غير واضح',
  'تحقق منها',
  'للنقاش',
  'الخلاصة',
];

class PaperPainter extends CustomPainter {
  PaperPainter(this.s, this.seed);
  final PaperStyle s;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final rnd = math.Random(seed * 7919 + 13);
    final c = s.curl == 0 ? 0.0 : w * .17;

    final path = Path()..moveTo(0, 0)..lineTo(w, 0);
    if (s.curl == 1) {
      path.lineTo(w, h - c);
      path.lineTo(w - c, h);
    } else {
      path.lineTo(w, h);
    }
    final x0 = s.curl == 1 ? w - c : w;
    final x1 = s.curl == -1 ? c : 0.0;
    if (s.torn) {
      const n = 46;
      for (var i = 1; i <= n; i++) {
        final x = x0 + (x1 - x0) * i / n;
        path.lineTo(x, h - rnd.nextDouble() * h * .025);
      }
    } else {
      path.lineTo(x1, h);
    }
    if (s.curl == -1) path.lineTo(0, h - c);
    path.close();

    canvas.drawPath(
      path.shift(Offset(w * .012, h * .02)),
      Paint()
        ..color = const Color(0x55000000)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .02),
    );
    canvas.drawPath(path, Paint()..color = s.paper);

    canvas.save();
    canvas.clipPath(path);
    if (s.grid) {
      final g = Paint()
        ..color = const Color(0x2A5C7A99)
        ..strokeWidth = 1;
      final step = w / 12;
      for (var x = step; x < w; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, h), g);
      }
      for (var y = step; y < h; y += step) {
        canvas.drawLine(Offset(0, y), Offset(w, y), g);
      }
    }
    if (s.holes) {
      final hp = Paint()..color = const Color(0x40000000);
      for (var x = w * .08; x < w; x += w * .09) {
        canvas.drawCircle(Offset(x, h * .05), w * .016, hp);
      }
    }
    canvas.restore();

    if (s.curl != 0) {
      final flap = Path();
      final Rect r;
      if (s.curl == 1) {
        flap..moveTo(w, h - c)..lineTo(w - c, h)..lineTo(w - c, h - c)..close();
        r = Rect.fromLTWH(w - c, h - c, c, c);
      } else {
        flap..moveTo(0, h - c)..lineTo(c, h)..lineTo(c, h - c)..close();
        r = Rect.fromLTWH(0, h - c, c, c);
      }
      canvas.drawPath(
        flap,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFCDCDCD)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(r),
      );
    }

    canvas.save();
    canvas.translate(w * s.tapeX, h * .03);
    canvas.rotate(s.tapeAngle);
    final tw = w * .34, th = h * .1;
    const teeth = 4;
    final tooth = th / teeth;
    final tp = Path()..moveTo(-tw / 2, -th / 2)..lineTo(tw / 2, -th / 2);
    for (var i = 0; i < teeth; i++) {
      tp.lineTo(tw / 2 - tooth * .45, -th / 2 + tooth * (i + .5));
      tp.lineTo(tw / 2, -th / 2 + tooth * (i + 1));
    }
    tp.lineTo(-tw / 2, th / 2);
    for (var i = teeth - 1; i >= 0; i--) {
      tp.lineTo(-tw / 2 + tooth * .45, -th / 2 + tooth * (i + .5));
      tp.lineTo(-tw / 2, -th / 2 + tooth * i);
    }
    tp.close();
    canvas.drawPath(tp, Paint()..color = s.tape.withValues(alpha: .8));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant PaperPainter old) => old.s != s || old.seed != seed;
}

class PaperNote extends StatelessWidget {
  const PaperNote({super.key, required this.styleIndex, required this.text, required this.width, this.hint = ''});
  final int styleIndex;
  final String text;
  final double width;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final st = kPaperStyles[styleIndex % kPaperStyles.length];
    final h = width * .8;
    final shown = text.isEmpty ? hint : text;
    return SizedBox(
      width: width,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: PaperPainter(st, styleIndex % kPaperStyles.length))),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(width * .1, h * .2, width * .1, h * .14),
            child: AutoFitText(
              shown,
              maxSize: width * .2,
              minSize: 6,
              style: paperTextStyle(text.isEmpty ? kPaperInk.withValues(alpha: .35) : kPaperInk),
            ),
          ),
        ),
      ]),
    );
  }
}

class PhotoNote extends StatelessWidget {
  const PhotoNote({super.key, required this.styleIndex, required this.width, this.path, this.caption = ''});
  final int styleIndex;
  final double width;
  final String? path;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final idx = styleIndex % kPaperStyles.length;
    final st = kPaperStyles[idx].frame;
    final h = width * 1.12;
    final hasCap = caption.isNotEmpty;
    Widget placeholder(IconData i) => Container(color: const Color(0x14000000), child: Icon(i, size: width * .25, color: const Color(0x44000000)));
    Widget photo;
    if (path == null) {
      photo = placeholder(Icons.image_rounded);
    } else {
      photo = Image.file(
        File(path!),
        fit: BoxFit.cover,
        cacheWidth: 700,
        errorBuilder: (_, __, ___) => placeholder(Icons.broken_image_rounded),
      );
    }
    return SizedBox(
      width: width,
      height: h,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(child: CustomPaint(painter: PaperPainter(st, idx))),
        Positioned(
          left: width * .07,
          right: width * .07,
          top: h * .11,
          bottom: hasCap ? h * .25 : h * .07,
          child: ClipRRect(borderRadius: BorderRadius.circular(3), child: photo),
        ),
        if (hasCap)
          Positioned(
            left: width * .1,
            right: width * .1,
            bottom: h * .035,
            height: h * .18,
            child: AutoFitText(caption, maxSize: width * .12, minSize: 6, style: paperTextStyle(kPaperInk)),
          ),
      ]),
    );
  }
}
