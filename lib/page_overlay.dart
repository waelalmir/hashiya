import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'annotations.dart';
import 'model.dart';
import 'paper_stickers.dart';
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
                        // بند 1: التمييز بخيارين (خط مستقيم hl أو رسم حر hlf)
                        final free = (tool == 'hl' && ann.hlFree) || tool == 'pen';
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
                        dr.pts[1] = Offset(q.dx, dr.pts[0].dy); // خط مستقيم أفقي للتمييز
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

/// أنماط الأسهم المتاحة (بند 6)
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
    canvas.drawPath(
