import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'annotations.dart';
import 'data.dart';
import 'glass.dart';
import 'mode_sheet.dart';
import 'model.dart';
import 'page_overlay.dart';
import 'pin_sheet.dart';
import 'reading_mode.dart';
import 'sticker_sheet.dart';
import 'store.dart';
import 'theme.dart';

class ReaderPage extends StatefulWidget {
  const ReaderPage({super.key, required this.book, this.startPage});
  final Book book;
  final int? startPage;
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> with WidgetsBindingObserver {
  final controller = PdfViewerController();
  Annotations? ann;
  final pageN = ValueNotifier<int>(1);
  final totalN = ValueNotifier<int>(0);
  bool full = false;
  Timer? _saveT, _tick;
  int _secs = 0;
  bool _fg = true;

  static const _colors = [0xFFE53935, 0xFFFFD54F, 0xFF43A047, 0xFF1E88E5, 0xFFFB8C00, 0xFF8E24AA, 0xFF111111, 0xFFFFFFFF];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    pageN.value = widget.startPage ?? widget.book.lastPage;
    widget.book.openedAt = DateTime.now().millisecondsSinceEpoch;
    Future.microtask(() => Store.update(widget.book));
    _tick = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_fg) return;
      _secs += 5;
      if (_secs >= 30) _flushReading();
    });
    Annotations.open(widget.book.id).then((a) {
      if (!mounted) {
        a.dispose();
        return;
      }
      setState(() => ann = a);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _fg = state == AppLifecycleState.resumed;

  void _flushReading() {
    if (_secs <= 0) return;
    final s = _secs;
    _secs = 0;
    Future.microtask(() => AppData.addReading(widget.book.id, s));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tick?.cancel();
    _saveT?.cancel();
    _flushReading();
    widget.book.lastPage = pageN.value;
    Future.microtask(() => Store.update(widget.book));
    ann?.flush();
    ann?.dispose();
    super.dispose();
  }

  void _jump(int p) {
    final t = totalN.value;
    if (t == 0) return;
    controller.goToPage(pageNumber: p.clamp(1, t).toInt());
  }

  Future<void> _askPage() async {
    final c = TextEditingController();
    final r = await showDialog<int>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('اذهب إلى صفحة (1 - ${totalN.value})'),
        content: TextField(controller: c, autofocus: true, keyboardType: TextInputType.number, onSubmitted: (v) => Navigator.pop(d, int.tryParse(v))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(d, int.tryParse(c.text)), child: const Text('اذهب')),
        ],
      ),
    );
    if (r != null) _jump(r);
  }

  Future<void> _openPin(Pin pin, {bool isNew = false}) => showPinSheet(context, ann!, pin, isNew: isNew);

  Future<void> _addSticker() async {
    final a = ann!;
    final pick = await pickSticker(context);
    if (pick == null) return;
    final s = StickerItem(id: newId(), page: pageN.value, asset: pick['file'] as String);
    a.addSticker(s);
    if ((pick['id'] as String).startsWith('blank_') && mounted) {
      final t = await editText(context, '');
      if (t != null) {
        s.text = t;
        a.touch();
      }
    }
  }

  Future<void> _stickerAction(StickerItem s, bool long) async {
    final a = ann!;
    if (!long) {
      final t = await editText(context, s.text);
      if (t != null) {
        s.text = t;
        a.touch();
      }
      return;
    }
    final del = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف الستيكر؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (del == true) a.removeSticker(s);
  }

  @override
  Widget build(BuildContext context) {
    final a = ann;
    if (a == null) return const Scaffold(backgroundColor: HC.deep, body: Center(child: CircularProgressIndicator()));
    return Scaffold(
      backgroundColor: HC.deep,
      body: ListenableBuilder(
        listenable: a.settings,
        builder: (context, _) {
          final drawing = a.tool != 'none';
          Widget viewer = PdfViewer.file(
            widget.book.path,
            key: ValueKey(a.toneSig),
            controller: controller,
            params: PdfViewerParams(
              backgroundColor: HC.deep,
              panEnabled: !drawing,
              scaleEnabled: !drawing,
              pagePaintCallbacks: [(canvas, pageRect, pg) => paintTone(canvas, pageRect, a)],
              pageOverlaysBuilder: (context, pageRect, pg) => [
                RepaintBoundary(child: PageOverlay(page: pg.pageNumber, ann: a, onPin: _openPin, onSticker: _stickerAction)),
              ],
              onViewerReady: (document, c) {
                totalN.value = document.pages.length;
                widget.book.total = totalN.value;
                if (pageN.value > 1) c.goToPage(pageNumber: pageN.value);
              },
              onPageChanged: (n) {
                if (n == null) return;
                pageN.value = n;
                widget.book.lastPage = n;
                _saveT?.cancel();
                _saveT = Timer(const Duration(milliseconds: 700), () => Store.update(widget.book));
              },
            ),
          );
          if (toneInverts(a)) viewer = ColorFiltered(colorFilter: kInvert, child: viewer);
          return Stack(children: [
            Positioned.fill(child: viewer),
            if (!full) _scrollBar(),
            if (!full) _topBar(),
            if (!full) _bottom(a),
            if (full)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(alignment: Alignment.topLeft, child: IconButton.filled(style: IconButton.styleFrom(backgroundColor: const Color(0xE6032B27)), onPressed: () => setState(() => full = false), icon: const Icon(Icons.fullscreen_exit_rounded))),
                ),
              ),
          ]);
        },
      ),
    );
  }

  Widget _scrollBar() => Positioned(
        right: 4,
        top: 130,
        bottom: 130,
        child: ValueListenableBuilder<int>(
          valueListenable: totalN,
          builder: (context, t, _) {
            if (t < 2) return const SizedBox.shrink();
            return ValueListenableBuilder<int>(
              valueListenable: pageN,
              builder: (context, p, _) => RotatedBox(
                quarterTurns: 1,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 5,
                      activeTrackColor: HC.cream,
                      inactiveTrackColor: Colors.black38,
                      thumbColor: HC.cream,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 11),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      min: 1,
                      max: t.toDouble(),
                      value: p.clamp(1, t).toDouble(),
                      onChanged: (v) {
                        final n = v.round();
                        if (n != pageN.value) {
                          pageN.value = n;
                          _jump(n);
                        }
                      },
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _topBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: GlassCard(
              dark: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward_rounded)),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
                ValueListenableBuilder<int>(
                  valueListenable: totalN,
                  builder: (context, t, _) => ValueListenableBuilder<int>(
                    valueListenable: pageN,
                    builder: (context, p, _) => InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: _askPage,
                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), child: Text('$p من ${t == 0 ? '—' : t}', style: const TextStyle(fontSize: 16))),
                    ),
                  ),
                ),
                IconButton(onPressed: () => setState(() => full = true), icon: const Icon(Icons.fullscreen_rounded)),
              ]),
            ),
          ),
        ),
      );

  Widget _bottom(Annotations a) {
    Widget b(IconData i, String l, {String? tool, VoidCallback? onTap}) {
      final on = tool != null && a.tool == tool;
      final c = on ? HC.green : HC.cream;
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => a.setTool(tool!),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: on ? HC.cream : null, borderRadius: BorderRadius.circular(12)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 22, color: c),
            const SizedBox(height: 2),
            Text(l, style: TextStyle(fontSize: 11, color: c)),
          ]),
        ),
      );
    }

    final showColors = a.toolColor.containsKey(a.tool);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (showColors)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  dark: true,
                  radius: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    for (final c in _colors)
                      GestureDetector(
                        onTap: () => a.setColor(c),
                        child: Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(color: Color(c), shape: BoxShape.circle, border: Border.all(color: a.toolColor[a.tool] == c ? HC.cream : Colors.white24, width: a.toolColor[a.tool] == c ? 3 : 1)),
                        ),
                      ),
                  ]),
                ),
              ),
            GlassCard(
              dark: true,
              radius: 24,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  b(Icons.highlight_rounded, 'تمييز', tool: 'hl'),
                  b(Icons.edit_rounded, 'قلم', tool: 'pen'),
                  b(Icons.north_east_rounded, 'سهم', tool: 'arrow'),
                  b(Icons.panorama_fish_eye_rounded, 'دائرة', tool: 'circle'),
                  b(Icons.auto_fix_normal_rounded, 'ممحاة', tool: 'erase'),
                  b(Icons.emoji_emotions_rounded, 'ستيكر', onTap: _addSticker),
                  b(Icons.add_comment_rounded, 'تعليق', tool: 'pin'),
                  b(Icons.palette_rounded, 'المظهر', onTap: () => showModeSheet(context, a)),
                  b(Icons.undo_rounded, 'تراجع', onTap: a.undo),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
