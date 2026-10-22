import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'annotations.dart';
import 'model.dart';
import 'reading_mode.dart';
import 'theme.dart';

typedef PinTap = void Function(Pin pin, {bool isNew});
typedef StickerAction = void Function(StickerItem s, bool longPress);

/// طبقة فوق كل صفحة: رسم + ستيكرات + دبابيس. كل الإحداثيات نسب من حجم الصفحة.
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
                  left: p.x * w - 16,
                  top: p.y * h - 16,
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
                        ann.draft = Stroke(
                          id: newId(),
                          page: page,
                          kind: tool,
                          color: ann.toolColor[tool] ?? 0xFFE53935,
                          width: tool == 'hl' ? .028 : (tool == 'pen' ? .004 : .005),
                          pts: (tool == 'arrow' || tool == 'circle' || tool == 'hl') ? [q, q] : [q],
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
                        dr.pts[1] = Offset(q.dx, dr.pts[0].dy); // خط مستقيم أفقي
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

class StrokePainter extends CustomPainter {
  StrokePainter(this.strokes);
  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final sw = s.width * size.width;
      final paint = Paint()
        ..color = Color(s.color).withValues(alpha: s.kind == 'hl' ? .38 : 1)
        ..strokeWidth = sw
        ..style = PaintingStyle.stroke
        ..strokeCap = s.kind == 'hl' ? StrokeCap.butt : StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final pts = [for (final p in s.pts) Offset(p.dx * size.width, p.dy * size.height)];
      if (pts.isEmpty) continue;
      if (s.kind == 'circle') {
        canvas.drawOval(Rect.fromPoints(pts.first, pts.last), paint);
      } else if (s.kind == 'arrow') {
        final a = pts.first, b = pts.last;
        canvas.drawLine(a, b, paint);
        final ang = math.atan2(b.dy - a.dy, b.dx - a.dx);
        final len = math.max(sw * 4, size.width * .025);
        for (final side in [-.5, .5]) {
          canvas.drawLine(b, b - Offset(math.cos(ang + side), math.sin(ang + side)) * len, paint);
        }
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
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(color: HC.cream, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black38, blurRadius: 4)]),
        child: Icon(pin.audio != null ? Icons.mic_rounded : Icons.sticky_note_2_rounded, size: 18, color: HC.green),
      );
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

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final sw = it.size * widget.w;
    final blank = it.asset.contains('blank_');
    return Positioned(
      left: it.x * widget.w,
      top: it.y * widget.h,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: blank ? () => widget.onAction(it, false) : null,
          onLongPress: () => widget.onAction(it, true),
          onScaleStart: (_) {
            _s0 = it.size;
            _r0 = it.rot;
          },
          onScaleUpdate: (d) {
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
              child: Stack(alignment: Alignment.center, children: [
                Image.asset('assets/stickers/${it.asset}', width: sw),
                if (blank)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw * .22),
                    child: Text(it.text,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: TextStyle(fontFamily: 'IBMPlexSansArabic', fontWeight: FontWeight.w700, fontSize: sw * .13, color: _txt(it.asset))),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
