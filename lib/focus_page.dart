import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'data.dart';
import 'glass.dart';
import 'store.dart';
import 'theme.dart';

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});
  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  String mode = 'focus'; // focus | short | long
  int minutes = 25;
  int left = 25 * 60;
  bool running = false;
  DateTime? _end;
  Timer? _t;
  String? bookId;

  int get total => minutes * 60;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _setMode(String m) {
    if (running) return;
    setState(() {
      mode = m;
      minutes = m == 'focus' ? 25 : (m == 'short' ? 5 : 15);
      left = total;
    });
  }

  void _setMinutes(int m) {
    if (running) return;
    setState(() {
      minutes = m;
      left = total;
    });
  }

  void _start() {
    _end = DateTime.now().add(Duration(seconds: left));
    setState(() => running = true);
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      final r = _end!.difference(DateTime.now()).inMilliseconds;
      if (r <= 0) {
        _finish();
      } else {
        setState(() => left = (r / 1000).ceil());
      }
    });
  }

  void _pause() {
    _t?.cancel();
    setState(() => running = false);
  }

  void _reset() {
    _t?.cancel();
    setState(() {
      running = false;
      left = total;
    });
  }

  Future<void> _finish() async {
    _t?.cancel();
    if (mode == 'focus') AppData.addSession(FocusSession(at: DateTime.now().millisecondsSinceEpoch, minutes: minutes, bookId: bookId));
    HapticFeedback.heavyImpact();
    setState(() {
      running = false;
      left = total;
    });
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(mode == 'focus' ? 'أحسنت! انتهت جلسة التركيز' : 'انتهت الاستراحة'),
        actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('تمام'))],
      ),
    );
  }

  String get _clock => '${(left ~/ 60).toString().padLeft(2, '0')}:${(left % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool on, VoidCallback f) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(label: Text(label), selected: on, onSelected: (_) => f()),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const PageHeader(title: 'التركيز'),
      Expanded(
        child: GlassCard(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              chip('تركيز', mode == 'focus', () => _setMode('focus')),
              chip('استراحة قصيرة', mode == 'short', () => _setMode('short')),
              chip('استراحة طويلة', mode == 'long', () => _setMode('long')),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: 320,
              child: ValueListenableBuilder(
                valueListenable: Store.books,
                builder: (context, books, _) => DropdownButtonFormField<String?>(
                  value: bookId,
                  decoration: const InputDecoration(labelText: 'الكتاب (اختياري)'),
                  items: [
                    const DropdownMenuItem<String?>(value: null, child: Text('بدون كتاب')),
                    for (final b in books) DropdownMenuItem<String?>(value: b.id, child: Text(b.title, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: running ? null : (v) => setState(() => bookId = v),
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: 260,
              height: 260,
              child: CustomPaint(
                painter: _RingPainter(total == 0 ? 0 : left / total),
                child: Center(child: Text(_clock, style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w600))),
              ),
            ),
            const SizedBox(height: 14),
            if (mode == 'focus')
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final m in [15, 25, 30, 45, 60]) chip('$m د', minutes == m, () => _setMinutes(m))]),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton.outlined(onPressed: _reset, icon: const Icon(Icons.replay_rounded)),
              const SizedBox(width: 16),
              FilledButton.icon(
                onPressed: running ? _pause : _start,
                icon: Icon(running ? Icons.pause_rounded : Icons.play_arrow_rounded),
                label: Text(running ? 'إيقاف مؤقت' : 'ابدأ'),
              ),
            ]),
            const SizedBox(height: 14),
            ValueListenableBuilder(
              valueListenable: AppData.sessions,
              builder: (context, _, __) => Text('جلسات اليوم: ${AppData.sessions.value.where((s) => AppData.dayKey(DateTime.fromMillisecondsSinceEpoch(s.at)) == AppData.dayKey()).length} · ${AppData.focusMinutesOn(AppData.dayKey())} دقيقة',
                  style: TextStyle(color: HC.cream.withValues(alpha: .7))),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.p);
  final double p;
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    final track = Paint()..color = HC.cream.withValues(alpha: .15)..style = PaintingStyle.stroke..strokeWidth = 12;
    canvas.drawCircle(c, r, track);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * p, false, track..color = HC.cream..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.p != p;
}
