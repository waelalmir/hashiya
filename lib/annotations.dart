import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'model.dart';
import 'store.dart';

class Ping extends ChangeNotifier {
  void ping() => notifyListeners();
}

/// كل ملاحظات كتاب واحد + إعدادات القراءة والأدوات.
class Annotations extends ChangeNotifier {
  Annotations._(this.bookId);
  final String bookId;
  final strokes = <Stroke>[];
  final stickers = <StickerItem>[];
  final pins = <Pin>[];
  final _undo = <VoidCallback>[];
  final settings = Ping(); // يتغير عند تغيير الأداة أو وضع القراءة
  Stroke? draft;
  String tool = 'none'; // none | hl | pen | arrow | circle | erase | pin
  final toolColor = <String, int>{'hl': 0xFFFFD54F, 'pen': 0xFFE53935, 'arrow': 0xFFE53935, 'circle': 0xFFE53935};
  String mode = 'original'; // original | paper | night
  final tone = <String, List<int>>{
    'paper': [0xFFF2E8C9, 0xFF3C3B37],
    'night': [0xFF16201E, 0xFFD9D4C4],
  };
  double dim = 0;
  Timer? _t;

  File get _file => File('${Store.dir.path}/ann_$bookId.json');

  static Future<Annotations> open(String id) async {
    final a = Annotations._(id);
    if (await a._file.exists()) {
      try {
        a._load(jsonDecode(await a._file.readAsString()) as Map<String, dynamic>);
      } catch (_) {}
    }
    return a;
  }

  void _load(Map<String, dynamic> j) {
    strokes.addAll((j['strokes'] as List? ?? []).map((e) => Stroke.fromJson(e as Map<String, dynamic>)));
    stickers.addAll((j['stickers'] as List? ?? []).map((e) => StickerItem.fromJson(e as Map<String, dynamic>)));
    pins.addAll((j['pins'] as List? ?? []).map((e) => Pin.fromJson(e as Map<String, dynamic>)));
    mode = j['mode'] ?? 'original';
    dim = (j['dim'] as num?)?.toDouble() ?? 0;
    final t = j['tone'] as Map<String, dynamic>?;
    if (t != null) t.forEach((k, v) => tone[k] = List<int>.from(v as List));
  }

  Map<String, dynamic> _json() => {
        'strokes': strokes.map((e) => e.toJson()).toList(),
        'stickers': stickers.map((e) => e.toJson()).toList(),
        'pins': pins.map((e) => e.toJson()).toList(),
        'mode': mode, 'dim': dim, 'tone': tone,
      };

  void save() {
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 400), flush);
  }

  Future<void> flush() async {
    _t?.cancel();
    await _file.writeAsString(jsonEncode(_json()));
  }

  void touch() {
    notifyListeners();
    save();
  }

  void refresh() => notifyListeners();

  String get toneSig => '$mode|${tone[mode]?.join(',')}|${dim.toStringAsFixed(2)}';

  void setTool(String t) {
    tool = tool == t ? 'none' : t;
    draft = null;
    settings.ping();
    notifyListeners();
  }

  void setColor(int c) {
    if (toolColor.containsKey(tool)) toolColor[tool] = c;
    settings.ping();
  }

  void setMode(String m) {
    mode = m;
    settings.ping();
    save();
  }

  void setTone(String m, {int? bg, int? text}) {
    final t = tone[m]!;
    if (bg != null) t[0] = bg;
    if (text != null) t[1] = text;
    settings.ping();
    save();
  }

  void setDim(double v) {
    dim = v;
    settings.ping();
    save();
  }

  void addStroke(Stroke s) {
    strokes.add(s);
    _undo.add(() => strokes.removeWhere((x) => x.id == s.id));
    touch();
  }

  void commitDraft() {
    final d = draft;
    draft = null;
    if (d != null) {
      addStroke(d);
    } else {
      refresh();
    }
  }

  void addSticker(StickerItem s) {
    stickers.add(s);
    _undo.add(() => stickers.removeWhere((x) => x.id == s.id));
    touch();
  }

  void removeSticker(StickerItem s) {
    stickers.removeWhere((x) => x.id == s.id);
    touch();
  }

  void addPin(Pin p) {
    pins.add(p);
    _undo.add(() => pins.removeWhere((x) => x.id == p.id));
    touch();
  }

  void removePin(Pin p) {
    pins.removeWhere((x) => x.id == p.id);
    touch();
  }

  void undo() {
    if (_undo.isEmpty) return;
    _undo.removeLast()();
    touch();
  }

  bool eraseAt(int page, Offset q, double thr) {
    final before = strokes.length;
    strokes.removeWhere((s) => s.page == page && _hit(s, q, thr));
    if (strokes.length != before) {
      touch();
      return true;
    }
    return false;
  }

  bool _hit(Stroke s, Offset q, double thr) {
    if (s.kind == 'arrow') return _segDist(s.pts.first, s.pts.last, q) < thr;
    if (s.kind == 'circle') return Rect.fromPoints(s.pts.first, s.pts.last).inflate(thr).contains(q);
    return s.pts.any((p) => (p - q).distance < thr);
  }

  double _segDist(Offset a, Offset b, Offset p) {
    final ab = b - a;
    final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (l2 == 0) return (p - a).distance;
    final ap = p - a;
    final t = ((ap.dx * ab.dx + ap.dy * ab.dy) / l2).clamp(0.0, 1.0).toDouble();
    return (p - (a + ab * t)).distance;
  }
}
