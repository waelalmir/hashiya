import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'annotations.dart';
import 'model.dart';
import 'paper_stickers.dart';
import 'reading_mode.dart';
import 'theme.dart';

typedef PinTap = void Function(Pin pin, {bool isNew});
typedef StickerAction = void Function(StickerItem s, bool longPress);

class PageOverlay extends StatelessWidget {
  const PageOverlay({super.key, required this.page, required this.ann, required this.onPin, required this.onSticker});
  final int page;
  final Annotations ann;
  final PinTap onPin;
  final StickerAction onSticker;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([ann, ann.settings]),
        builder: (context, _) => LayoutBuilder(builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          if (!w.isFinite || !h.isFinite || w <= 0 || h <= 0) return const SizedBox.shrink();
          final tool = ann.tool;
          final strokes = ann.strokes.where((s) => s.page == page).toList();
          final d = ann.draft;
          if (d != null && d.page == page) strokes.add(d);
          Offset n(Offset o) => Offset((o.dx / w).clamp(0.0, 1.0).toDouble(), (o.dy / h).clamp(0.0, 1.0).toDouble());

          final content = SizedBox(
            width: w,
            height: h,
            child: Stack(clipBehavior: Clip.none, children: [
              IgnorePointer(child: CustomPaint(size: Size(w, h), painter: StrokePainter(strokes))),
              for (final s in ann.stickers.where((s) => s.page == page))
                StickerView(key: ValueKey(s.id), item: s, w: w, h: h, ann: ann, onAction: onSticker),
              for (final p in ann.pins.where((p) => p.page == page))
                Positioned(
                  left: p.x * w - 21,
                  top: p.y * h - 21,
                  child: GestureDetector(onTap: () => onPin(p, isNew: false), child: PinIcon(pin: p)),
                ),
              if (tool != 'none')
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: tool == 'pin'
                        ? (t) {
                            final q = n(t.localPosition);
                            final pin = Pin(id: newId(), page: page, x: q.dx, y: q.dy);
                            ann.addPin(pin);
                            onPin(pin, isNew: true);
                          }
                        : null,
                    onPanStart: (t) {
                      final q = n(t.localPosition);
                      if (tool == 'erase') {
                        ann.eraseAt(page, q, .03);
                      } else if (tool != 'pin') {
                        final kind = (tool == 'hl' && ann.hlFree) ? 'hlf' : tool;
                        final base = kind == 'hl' ? .028 : (kind == 'hlf' ? .022 : (tool == 'pen' ? .004 : .005));
                        ann.draft = Stroke(
                          id: newId(),
                          page: page,
                          kind: kind,
                          color: ann.toolColor[tool] ?? 0xFFE53935,
                          width: base * ann.widthScale,
                          style: tool == 'arrow' ? ann.arrowStyle : '',
                          pts: (kind == 'arrow' || kind == 'circle' || kind == 'hl') ? [q, q] : [q],
                        );
                        ann.refresh();
                      }
                    },
                    onPanUpdate: (t) {
                      final q = n(t.localPosition);
                      if (tool == 'erase') {
                        ann.eraseAt(page, q, .03);
                        return;
                      }
                      final dr = ann.draft;
                      if (dr == null) return;
                      if (dr.kind == 'hl') {
                        dr.pts[1] = Offset(q.dx, dr.pts[0].dy);
                      } else if (dr.kind == 'arrow' || dr.kind == 'circle') {
                        dr.pts[1] = q;
                      } else {
                        dr.pts.add(q);
                      }
                      ann.refresh();
                    },
                    onPanEnd: (_) {
                      if (tool != 'erase' && tool != 'pin') ann.commitDraft();
                    },
                  ),
                ),
            ]),
          );
          return toneInverts(ann) ? ColorFiltered(colorFilter: kInvert, child: content) : content;
        }),
      );
}

const kArrowStyles = ['straight', 'curveL', 'curveR', 'wave', 'hand', 'double', 'dashed'];

int _seedOf(String id) => id.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);

void paintArrowShape(Canvas canvas, String style, Offset a, Offset b, Paint paint, double headLen, int seed) {
  final d = b - a;
  final len = d.distance;
  if (len < 1) return;
  final dir = d / len;
  final perp = Offset(-dir.dy, dir.dx);
  double angOf(Offset v) => math.atan2(v.dy, v.dx);
  void head(Offset tip, double ang, [double hl = 1]) {
    for (final side in [-.5, .5]) {
      canvas.drawLine(tip, tip - Offset(math.cos(ang + side), math.sin(ang + side)) * (headLen * hl), paint);
    }
  }

  if (style == 'curveL' || style == 'curveR') {
    final k = style == 'curveL' ? 1.0 : -1.0;
    final c = (a + b) / 2 + perp * (len * .28 * k);
    final p = Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(c.dx, c.dy, b.dx, b.dy);
    canvas.drawPath(p, paint);
    head(b, angOf(b - c));
  } else if (style == 'wave') {
    final c1 = a + dir * (len * .33) + perp * (len * .2);
    final c2 = a + dir * (len * .66) - perp * (len * .2);
    final p = Path()..moveTo(a.dx, a.dy)..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, b.dx, b.dy);
    canvas.drawPath(p, paint);
    head(b, angOf(b - c2));
  } else if (style == 'hand') {
    final rnd = math.Random(seed);
    final amp = math.max(headLen * .1, 1.2);
    for (var pass = 0; pass < 2; pass++) {
      final n = math.max(4, (len / 22).round());
      final path = Path()..moveTo(a.dx + (rnd.nextDouble() - .5) * amp * 2, a.dy + (rnd.nextDouble() - .5) * amp * 2);
      for (var i = 1; i <= n; i++) {
        final t = i / n, tm = (i - .5) / n;
        final bow = len * .03 * (pass == 0 ? 1 : -.6);
        final p = a + d * t + perp * ((rnd.nextDouble() - .5) * amp * 2 + math.sin(math.pi * t) * bow);
        final m = a + d * tm + perp * ((rnd.nextDouble() - .5) * amp * 2 + math.sin(math.pi * tm) * bow);
        path.quadraticBezierTo(m.dx, m.dy, p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
    final ang = angOf(d);
    for (final side in [-.55, .5]) {
      final l = headLen * (.9 + rnd.nextDouble() * .3);
      final aa = ang + side + (rnd.nextDouble() - .5) * .15;
      canvas.drawLine(b, b - Offset(math.cos(aa), math.sin(aa)) * l, paint);
    }
  } else if (style == 'double') {
    canvas.drawLine(a, b, paint);
    head(b, angOf(d));
    head(a, angOf(d) + math.pi);
  } else if (style == 'dashed') {
    final path = Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy);
    final dash = headLen * .9, gap = headLen * .6;
    for (final m in path.computeMetrics()) {
      var pos = 0.0;
      while (pos < m.length) {
        canvas.drawPath(m.extractPath(pos, math.min(pos + dash, m.length)), paint);
        pos += dash + gap;
      }
    }
    head(b, angOf(d));
  } else {
    canvas.drawLine(a, b, paint);
    head(b, angOf(d));
  }
}

class ArrowPreview extends StatelessWidget {
  const ArrowPreview({super.key, required this.style, required this.color});
  final String style;
  final Color color;
  @override
  Widget build(BuildContext context) => CustomPaint(size: const Size(48, 26), painter: _ArrowPreviewPainter(style, color));
}

class _ArrowPreviewPainter extends CustomPainter {
  _ArrowPreviewPainter(this.style, this.color);
  final String style;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    paintArrowShape(canvas, style, Offset(5, size.height - 5), Offset(size.width - 5, 6), paint, 7, 11);
  }

  @override
  bool shouldRepaint(covariant _ArrowPreviewPainter old) => old.style != style || old.color != color;
}

class StrokePainter extends CustomPainter {
  StrokePainter(this.strokes);
  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final sw = s.width * size.width;
      final isHl = s.kind == 'hl' || s.kind == 'hlf';
      final paint = Paint()
        ..color = Color(s.color).withValues(alpha: isHl ? .38 : 1)
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = s.kind == 'hl' ? StrokeCap.butt : StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final pts = [for (final p in s.pts) Offset(p.dx * size.width, p.dy * size.height)];
      if (pts.isEmpty) continue;
      if (s.kind == 'circle') {
        canvas.drawOval(Rect.fromPoints(pts.first, pts.last), paint);
      } else if (s.kind == 'arrow') {
        final len = math.max(sw * 4, size.width * .025);
        paintArrowShape(canvas, s.style.isEmpty ? 'straight' : s.style, pts.first, pts.last, paint, len, _seedOf(s.id));
      } else if (pts.length == 1) {
        canvas.drawCircle(pts.first, sw / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = Path()..moveTo(pts.first.dx, pts.first.dy);
        for (final p in pts.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter old) => true;
}

class PinIcon extends StatelessWidget {
  const PinIcon({super.key, required this.pin});
  final Pin pin;
  @override
  Widget build(BuildContext context) {
    final voice = pin.audio != null;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: voice ? const Color(0xFFFFD54F) : HC.cream,
        shape: BoxShape.circle,
        border: Border.all(color: HC.green, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
      ),
      child: Icon(voice ? Icons.mic_rounded : Icons.sticky_note_2_rounded, size: 24, color: HC.green),
    );
  }
}

class StickerView extends StatefulWidget {
  const StickerView({super.key, required this.item, required this.w, required this.h, required this.ann, required this.onAction});
  final StickerItem item;
  final double w, h;
  final Annotations ann;
  final StickerAction onAction;
  @override
  State<StickerView> createState() => _StickerViewState();
}

class _StickerViewState extends State<StickerView> {
  double _s0 = .2, _r0 = 0;

  Color _txt(String asset) => (asset.contains('blank_01') || asset.contains('blank_04')) ? const Color(0xFF121358) : Colors.white;

  (double, double, Alignment) _box(String asset) {
    if (asset.contains('blank_02')) return (.70, .55, Alignment.center);
    if (asset.contains('blank_03')) return (.62, .62, Alignment.center);
    if (asset.contains('blank_04')) return (.72, .58, const Alignment(0, -.15));
    if (asset.contains('blank_05')) return (.62, .60, Alignment.center);
    if (asset.contains('blank_06')) return (.66, .56, const Alignment(.1, 0));
    return (.70, .70, Alignment.center);
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final sw = it.size * widget.w;
    final blank = it.asset.contains('blank_');
    final locked = it.locked;
    final Widget face;
    if (it.asset.startsWith('paper:')) {
      face = PaperNote(styleIndex: int.tryParse(it.asset.substring(6)) ?? 0, text: it.text, width: sw);
    } else if (it.asset.startsWith('photo:')) {
      face = PhotoNote(styleIndex: int.tryParse(it.asset.substring(6)) ?? 0, width: sw, path: it.img, caption: it.text);
    } else {
      final bx = _box(it.asset);
      face = Stack(children: [
        Image.asset('assets/stickers/${it.asset}', width: sw),
        if (blank)
          Positioned.fill(
            child: Align(
              alignment: bx.$3,
              child: FractionallySizedBox(
                widthFactor: bx.$1,
                heightFactor: bx.$2,
                child: AutoFitText(
                  it.text,
                  maxSize: sw * .13,
                  minSize: 6,
                  style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700, height: 1.2, color: _txt(it.asset)),
                ),
              ),
            ),
          ),
      ]);
    }

    return Positioned(
      left: it.x * widget.w,
      top: it.y * widget.h,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onAction(it, false),
          onScaleStart: locked
              ? null
              : (_) {
                  _s0 = it.size;
                  _r0 = it.rot;
                },
          onScaleUpdate: locked
              ? null
              : (d) {
                  it.x = (it.x + d.focalPointDelta.dx / widget.w).clamp(0.0, 1.0).toDouble();
                  it.y = (it.y + d.focalPointDelta.dy / widget.h).clamp(0.0, 1.0).toDouble();
                  if (d.pointerCount > 1) {
                    it.size = (_s0 * d.scale).clamp(.06, .8).toDouble();
                    it.rot = _r0 + d.rotation;
                  }
                  widget.ann.touch();
                },
          child: Transform.rotate(
            angle: it.rot,
            child: SizedBox(
              width: sw,
              child: Stack(clipBehavior: Clip.none, alignment: Alignment.center, children: [
                face,
                if (!locked)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        it.locked = true;
                        widget.ann.touch();
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(color: HC.cream, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 4)]),
                        child: const Icon(Icons.lock_open_rounded, size: 20, color: HC.green),
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
// END OF FILE
