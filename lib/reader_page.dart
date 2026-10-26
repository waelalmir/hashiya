import 'dart:async';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
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
  PdfViewerController ctl = PdfViewerController();
  String? _ctlSig;
  int _restoreTo = 1;
  bool _restoring = false, _dragging = false;
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
    _restoreTo = pageN.value;
    _restoring = _restoreTo > 1;
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

  void _jump(int p, {bool instant = false}) {
    final t = totalN.value;
    if (t == 0 || !ctl.isReady) return;
    ctl.goToPage(pageNumber: p.clamp(1, t).toInt(), duration: instant ? Duration.zero : const Duration(milliseconds: 200));
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

  Future<String?> _pickPhoto() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    if (r == null || r.files.isEmpty || r.files.single.path == null) return null;
    final src = r.files.single.path!;
    final dir = Directory('${Store.dir.path}/sticker_img');
    await dir.create(recursive: true);
    final dot = src.lastIndexOf('.');
    final ext = dot > src.lastIndexOf('/') ? src.substring(dot) : '.jpg';
    final dest = '${dir.path}/${newId()}$ext';
    await File(src).copy(dest);
    return dest;
  }

  Future<void> _addSticker() async {
    final a = ann!;
    final pick = await pickSticker(context);
    if (pick == null) return;
    final id = pick['id'] as String;
    if (id == 'photo') {
      final path = await _pickPhoto();
      if (path == null || !mounted) return;
      final s = StickerItem(id: newId(), page: pageN.value, asset: 'photo:${pick['style']}', size: .32, img: path);
      a.addSticker(s);
      final t = await editText(context, '', title: 'اسم أو تعليق تحت الصورة (اختياري)');
      if (t != null) {
        s.text = t;
        a.touch();
      }
    } else if (id == 'paper') {
      final s = StickerItem(id: newId(), page: pageN.value, asset: 'paper:${pick['style']}', size: .3, text: (pick['text'] as String?) ?? '');
      a.addSticker(s);
      if (pick['blank'] == true && mounted) {
        final t = await editText(context, '');
        if (t != null) {
          s.text = t;
          a.touch();
        }
      }
    } else {
      final s = StickerItem(id: newId(), page: pageN.value, asset: pick['file'] as String);
      a.addSticker(s);
      if (id.startsWith('blank_') && mounted) {
        final t = await editText(context, '');
        if (t != null) {
          s.text = t;
          a.touch();
        }
      }
    }
  }

  Future<void> _stickerAction(StickerItem s, bool _) async {
    final a = ann!;
    final isPhoto = s.asset.startsWith('photo:');
    final editable = s.asset.contains('blank_') || s.asset.startsWith('paper:') || isPhoto;
    final r = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: const Text('الستيكر'),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'lock'), child: Text(s.locked ? 'فتح القفل (للتحريك والتكبير)' : 'قفل مكانه')),
          if (editable) SimpleDialogOption(onPressed: () => Navigator.pop(c, 'edit'), child: Text(isPhoto ? 'تعديل التعليق' : 'تعديل النص')),
          if (isPhoto) SimpleDialogOption(onPressed: () => Navigator.pop(c, 'img'), child: const Text('تغيير الصورة')),
          SimpleDialogOption(onPressed: () => Navigator.pop(c, 'del'), child: const Text('حذف')),
        ],
      ),
    );
    if (r == 'lock') {
      s.locked = !s.locked;
      a.touch();
    } else if (r == 'del') {
      a.removeSticker(s);
    } else if (r == 'edit' && mounted) {
      final t = await editText(context, s.text, title: isPhoto ? 'التعليق' : 'نص الستيكر');
      if (t != null) {
        s.text = t;
        a.touch();
      }
    } else if (r == 'img') {
      final path = await _pickPhoto();
      if (path != null) {
        s.img = path;
        a.touch();
      }
    }
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
          if (_ctlSig != a.toneSig) {
            if (_ctlSig != null) {
              ctl = PdfViewerController();
              _restoreTo = pageN.value;
              _restoring = _restoreTo > 1;
            }
            _ctlSig = a.toneSig;
          }
          Widget viewer = PdfViewer.file(
            widget.book.path,
            key: ValueKey(a.toneSig),
            controller: ctl,
            params: PdfViewerParams(
              backgroundColor: toneInverts(a) ? invertColor(HC.deep) : HC.deep,
              panEnabled: !drawing,
              scaleEnabled: !drawing,
              pagePaintCallbacks: [(canvas, pageRect, pg) => paintTone(canvas, pageRect, a)],
              pageOverlaysBuilder: (context, pageRect, pg) => [
                RepaintBoundary(child: PageOverlay(page: pg.pageNumber, ann: a, onPin: _openPin, onSticker: _stickerAction)),
              ],
              onViewerReady: (document, c) async {
                totalN.value = document.pages.length;
                widget.book.total = totalN.value;
                if (_restoreTo > 1) {
                  try {
                    await c.goToPage(pageNumber: _restoreTo, duration: Duration.zero);
                  } catch (_) {}
                }
                _restoring = false;
              },
              onPageChanged: (n) {
                if (n == null || _restoring || _dragging) return;
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
                      onChangeStart: (_) => _dragging = true,
                      onChangeEnd: (_) {
                        _dragging = false;
                        widget.book.lastPage = pageN.value;
                      },
                      onChanged: (v) {
                        final n = v.round();
                        if (n != pageN.value) {
                          pageN.value = n;
                          _jump(n, instant: true);
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
            _optionsBar(a),
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

  Widget _optionsBar(Annotations a) {
    final t = a.tool;
    if (t != 'hl' && t != 'pen' && t != 'arrow' && t != 'circle') return const SizedBox.shrink();
    Widget chip(Widget Function(Color) child, bool on, VoidCallback f) => GestureDetector(
          onTap: f,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: on ? HC.cream : Colors.white12, borderRadius: BorderRadius.circular(12)),
            child: child(on ? HC.green : HC.cream),
          ),
        );
    final items = <Widget>[];
    if (t == 'hl') {
      items.add(chip((c) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.horizontal_rule_rounded, size: 22, color: c), const SizedBox(width: 4), Text('مستقيم', style: TextStyle(fontSize: 12, color: c))]), !a.hlFree, () => a.setHlFree(false)));
      items.add(chip((c) => Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.gesture_rounded, size: 22, color: c), const SizedBox(width: 4), Text('حر', style: TextStyle(fontSize: 12, color: c))]), a.hlFree, () => a.setHlFree(true)));
      items.add(const SizedBox(width: 8));
    }
    if (t == 'arrow') {
      for (final st in kArrowStyles) {
        items.add(chip((c) => ArrowPreview(style: st, color: c), a.arrowStyle == st, () => a.setArrowStyle(st)));
      }
      items.add(const SizedBox(width: 8));
    }
    for (final e in const [(1.0, 6.0), (1.8, 11.0), (3.0, 17.0)]) {
      items.add(chip((c) => SizedBox(width: 22, height: 22, child: Center(child: Container(width: e.$2, height: e.$2, decoration: BoxDecoration(color: c, shape: BoxShape.circle)))), a.widthScale == e.$1, () => a.setWidthScale(e.$1)));
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        dark: true,
        radius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(mainAxisSize: MainAxisSize.min, children: items)),
      ),
    );
  }
}
// END OF FILE
