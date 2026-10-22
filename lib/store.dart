import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class Book {
  Book({required this.id, required this.title, required this.path, this.lastPage = 1, this.total = 0, this.openedAt = 0});
  final String id;
  final String title;
  final String path;
  int lastPage;
  int total;
  int openedAt;
  double get progress => total == 0 ? 0 : (lastPage / total).clamp(0, 1).toDouble();
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'path': path, 'lastPage': lastPage, 'total': total, 'openedAt': openedAt};
  factory Book.fromJson(Map<String, dynamic> j) => Book(id: j['id'], title: j['title'], path: j['path'], lastPage: j['lastPage'] ?? 1, total: j['total'] ?? 0, openedAt: j['openedAt'] ?? 0);
}

class Store {
  static final books = ValueNotifier<List<Book>>([]);
  static late Directory _dir;
  static Directory get dir => _dir;
  static File get _db => File('${_dir.path}/library.json');

  static Future<void> load() async {
    _dir = await getApplicationDocumentsDirectory();
    await Directory('${_dir.path}/books').create(recursive: true);
    if (await _db.exists()) {
      final list = jsonDecode(await _db.readAsString()) as List;
      books.value = list.map((e) => Book.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  static Future<void> _save() => _db.writeAsString(jsonEncode(books.value.map((b) => b.toJson()).toList()));

  static Future<Book?> pickAndAdd() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (r == null || r.files.isEmpty || r.files.single.path == null) return null;
    final f = r.files.single;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final dest = '${_dir.path}/books/$id.pdf';
    await File(f.path!).copy(dest);
    final title = f.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '').replaceAll('_', ' ');
    final b = Book(id: id, title: title, path: dest);
    books.value = [b, ...books.value];
    await _save();
    return b;
  }

  static Future<void> update(Book b) async {
    books.value = List.of(books.value);
    await _save();
  }

  static Future<void> remove(Book b) async {
    final f = File(b.path);
    if (await f.exists()) await f.delete();
    books.value = books.value.where((x) => x.id != b.id).toList();
    await _save();
  }
}
