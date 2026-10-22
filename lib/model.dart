import 'dart:ui';

String newId() => DateTime.now().microsecondsSinceEpoch.toString();

class Stroke {
  Stroke({required this.id, required this.page, required this.kind, required this.color, required this.width, required this.pts});
  final String id;
  final int page;
  final String kind; // pen | hl | arrow | circle
  final int color;
  final double width; // نسبة من عرض الصفحة
  final List<Offset> pts; // إحداثيات مطبّعة 0..1
  Map<String, dynamic> toJson() => {
        'id': id, 'p': page, 'k': kind, 'c': color, 'w': width,
        'pts': [for (final o in pts) [o.dx, o.dy]],
      };
  factory Stroke.fromJson(Map<String, dynamic> j) => Stroke(
        id: j['id'], page: j['p'], kind: j['k'], color: j['c'], width: (j['w'] as num).toDouble(),
        pts: [for (final l in j['pts'] as List) Offset((l[0] as num).toDouble(), (l[1] as num).toDouble())],
      );
}

class StickerItem {
  StickerItem({required this.id, required this.page, required this.asset, this.x = .5, this.y = .35, this.size = .22, this.rot = 0, this.text = ''});
  final String id;
  final int page;
  final String asset; // مثل png/ask.png
  double x, y, size, rot;
  String text;
  Map<String, dynamic> toJson() => {'id': id, 'p': page, 'a': asset, 'x': x, 'y': y, 's': size, 'r': rot, 't': text};
  factory StickerItem.fromJson(Map<String, dynamic> j) => StickerItem(
        id: j['id'], page: j['p'], asset: j['a'], x: (j['x'] as num).toDouble(), y: (j['y'] as num).toDouble(),
        size: (j['s'] as num).toDouble(), rot: (j['r'] as num).toDouble(), text: j['t'] ?? '');
}

class Pin {
  Pin({required this.id, required this.page, required this.x, required this.y, this.text = '', this.audio});
  final String id;
  final int page;
  final double x, y;
  String text;
  String? audio;
  Map<String, dynamic> toJson() => {'id': id, 'p': page, 'x': x, 'y': y, 't': text, 'au': audio};
  factory Pin.fromJson(Map<String, dynamic> j) => Pin(
        id: j['id'], page: j['p'], x: (j['x'] as num).toDouble(), y: (j['y'] as num).toDouble(), text: j['t'] ?? '', audio: j['au']);
}
