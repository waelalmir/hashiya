import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'store.dart';

class Task {
  Task({required this.id, required this.title, this.done = false, this.bookId, this.from, this.to, this.due});
  final String id;
  String title;
  bool done;
  String? bookId;
  int? from, to, due;
  Map<String, dynamic> toJson() => {'id': id, 't': title, 'd': done, 'b': bookId, 'f': from, 'to': to, 'due': due};
  factory Task.fromJson(Map<String, dynamic> j) => Task(id: j['id'], title: j['t'], done: j['d'] ?? false, bookId: j['b'], from: j['f'], to: j['to'], due: j['due']);
}

class FocusSession {
  FocusSession({required this.at, required this.minutes, this.bookId});
  final int at, minutes;
  final String? bookId;
  Map<String, dynamic> toJson() => {'at': at, 'm': minutes, 'b': bookId};
  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(at: j['at'], minutes: j['m'], bookId: j['b']);
}

/// بيانات التطبيق العامة: مهام، جلسات تركيز، وقت القراءة، إعدادات.
class AppData {
  static final tasks = ValueNotifier<List<Task>>([]);
  static final sessions = ValueNotifier<List<FocusSession>>([]);
  static final reading = ValueNotifier<Map<String, Map<String, int>>>({}); // يوم -> كتاب -> ثواني
  static final name = ValueNotifier<String>('عبد الفتاح');
  static final bgPath = ValueNotifier<String?>(null);
  static final reduceBlur = ValueNotifier<bool>(false);
  static File get _f => File('${Store.dir.path}/data.json');

  static Future<void> load() async {
    if (!await _f.exists()) return;
    try {
      final j = jsonDecode(await _f.readAsString()) as Map<String, dynamic>;
      name.value = (j['name'] as String?) ?? name.value;
      bgPath.value = j['bg'] as String?;
      reduceBlur.value = (j['blur'] as bool?) ?? false;
      tasks.value = [for (final e in (j['tasks'] as List? ?? [])) Task.fromJson(e as Map<String, dynamic>)];
      sessions.value = [for (final e in (j['sessions'] as List? ?? [])) FocusSession.fromJson(e as Map<String, dynamic>)];
      final r = (j['reading'] as Map<String, dynamic>?) ?? {};
      reading.value = {
        for (final e in r.entries) e.key: {for (final b in (e.value as Map<String, dynamic>).entries) b.key: (b.value as num).toInt()}
      };
    } catch (_) {}
  }

  static Future<void> save() => _f.writeAsString(jsonEncode({
        'name': name.value,
        'bg': bgPath.value,
        'blur': reduceBlur.value,
        'tasks': tasks.value.map((e) => e.toJson()).toList(),
        'sessions': sessions.value.map((e) => e.toJson()).toList(),
        'reading': reading.value,
      }));

  static String dayKey([DateTime? d]) {
    final t = d ?? DateTime.now();
    return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
  }

  static int secondsOn(String key) => (reading.value[key] ?? {}).values.fold<int>(0, (a, b) => a + b);

  static int get totalSeconds => reading.value.keys.fold<int>(0, (a, k) => a + secondsOn(k));

  static Map<String, int> perBook() {
    final m = <String, int>{};
    for (final d in reading.value.values) {
      d.forEach((b, s) => m[b] = (m[b] ?? 0) + s);
    }
    return m;
  }

  static int get streak {
    var n = 0;
    var d = DateTime.now();
    if (secondsOn(dayKey(d)) < 60) d = d.subtract(const Duration(days: 1));
    while (secondsOn(dayKey(d)) >= 60) {
      n++;
      d = d.subtract(const Duration(days: 1));
    }
    return n;
  }

  static int focusMinutesOn(String key) =>
      sessions.value.where((s) => dayKey(DateTime.fromMillisecondsSinceEpoch(s.at)) == key).fold<int>(0, (a, s) => a + s.minutes);

  static void addReading(String bookId, int seconds) {
    final m = Map<String, Map<String, int>>.from(reading.value);
    final k = dayKey();
    final day = Map<String, int>.from(m[k] ?? {});
    day[bookId] = (day[bookId] ?? 0) + seconds;
    m[k] = day;
    reading.value = m;
    save();
  }

  static void addSession(FocusSession s) {
    sessions.value = [...sessions.value, s];
    save();
  }

  static void setTasks(List<Task> t) {
    tasks.value = t;
    save();
  }

  static String fmtDuration(int seconds) {
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60;
    if (h == 0) return '$m د';
    return '$h س $m د';
  }
}
