import 'dart:ui';

String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

class Stroke {
  Stroke({
    required this.id,
    required this.page,
    required this.kind,
    required this.color,
    required this.width,
    required this.pts,
    this.style = '',
  });
  final String id;
  final int page;
  final String kind;
  final int color;
  final double width;
  final String style;
  final List<Offset> pts;

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'kind': kind,
        'color': color,
        'width': width,
        'style': style,
        'pts': pts.map((p) => [p.dx, p.dy]).toList(),
      };

  static Stroke fromJson(Map<String, dynamic> j) => Stroke(
        id: j['id'] as String,
        page: j['page'] as int,
        kind: j['kind'] as String,
        color: j['color'] as int,
        width: (j['width'] as num).toDouble(),
        style: (j['style'] as String?) ?? '',
        pts: (j['pts'] as List).map((e) => Offset((e[0] as num).toDouble(), (e[1] as num).toDouble())).toList(),
      );
}

class StickerItem {
  StickerItem({
    required this.id,
    required this.page,
    required this.asset,
    this.x = .5,
    this.y = .35,
    this.size = .22,
    this.rot = 0,
    this.text = '',
    this.img,
    this.locked = false,
  });
  final String id;
  final int page;
  final String asset;
  double x, y, size, rot;
  String text;
  String? img;
  bool locked;

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'asset': asset,
        'x': x,
        'y': y,
        'size': size,
        'rot': rot,
        'text': text,
        if (img != null) 'img': img,
        'locked': locked,
      };

  static StickerItem fromJson(Map<String, dynamic> j) => StickerItem(
        id: j['id'] as String,
        page: j['page'] as int,
        asset: j['asset'] as String,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        size: (j['size'] as num).toDouble(),
        rot: (j['rot'] as num).toDouble(),
        text: (j['text'] as String?) ?? '',
        img: j['img'] as String?,
        locked: (j['locked'] as bool?) ?? false,
      );
}

class Pin {
  Pin({required this.id, required this.page, required this.x, required this.y, this.text = '', this.note = '', this.audio});
  final String id;
  final int page;
  final double x, y;
  String text;
  String note;
  String? audio;

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'x': x,
        'y': y,
        'text': text.isNotEmpty ? text : note,
        'note': note.isNotEmpty ? note : text,
        if (audio != null) 'audio': audio,
      };

  static Pin fromJson(Map<String, dynamic> j) {
    final t = (j['text'] as String?) ?? (j['note'] as String?) ?? '';
    return Pin(
      id: j['id'] as String,
      page: j['page'] as int,
      x: (j['x'] as num).toDouble(),
      y: (j['y'] as num).toDouble(),
      text: t,
      note: t,
      audio: j['audio'] as String?,
    );
  }
}
