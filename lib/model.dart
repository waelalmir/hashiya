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
  Pin({required this.id, required this.page, required this.x, required this.y, this.note = '', this.audio});
  final String id;
  final int page;
  final double x, y;
  String note;
  String? audio;

  Map<String, dynamic> toJson() => {
        'id': id,
        'page': page,
        'x': x,
        'y': y,
        'note': note,
        if (audio != null) 'audio': audio,
      };

  static Pin fromJson(Map<String, dynamic> j) => Pin(
        id: j['id'] as String,
        page: j['page'] as int,
        x: (j['x'] as num).toDouble(),
        y: (j['y'] as num).toDouble(),
        note: (j['note'] as String?) ?? '',
        audio: j['audio'] as String?,
      );
}

class Book {
  Book({
    required this.id,
    required this.title,
    required this.path,
    this.folder = '',
    this.lastPage = 1,
    this.total = 0,
    this.openedAt = 0,
  });
  final String id;
  String title;
  final String path;
  String folder;
  int lastPage;
  int total;
  int openedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'folder': folder,
        'lastPage': lastPage,
        'total': total,
        'openedAt': openedAt,
      };

  static Book fromJson(Map<String, dynamic> j) => Book(
        id: j['id'] as String,
        title: j['title'] as String,
        path: j['path'] as String,
        folder: (j['folder'] as String?) ?? '',
        lastPage: (j['lastPage'] as int?) ?? 1,
        total: (j['total'] as int?) ?? 0,
        openedAt: (j['openedAt'] as int?) ?? 0,
      );
}
