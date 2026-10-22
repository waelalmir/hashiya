import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'annotations.dart';
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
  const ReaderPage({super.key, required this.book});
  final Book book;
  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final controller = PdfViewerController();
  Annotations? ann;
  int page = 1;
  int total = 0;
  bool full = false;

  static const _colors = [0xFFE53935, 0xFFFFD54F, 0xFF43A047, 0xFF1E88E5, 0xFFFB8C00, 0xFF8E24AA, 0xFF111111, 0xFFFFFFFF];

  @override
  void initState() {
    super.initState();
    page = widget.book.lastPage;
    widget.book.openedAt = DateTime.now().millisecondsSinceEpoch;
    Store.update(widget.book);
    Annotations.open(widget.book.id).then((a) {
      if (!mounted) {
        a.dispose();
        return;
      }
      setState(() => ann = a);
    });
  }

  @override
  void dispose() {
    ann?.flush();
    ann?.dispose();
    super.dispose();
  }

  Future<void> _openPin(Pin pin, {bool isNew = false}) => showPinSheet(context, ann!, pin, isNew: isNew);

  Future<void> _addSticker() async {
    final a = ann!;
    final pick = await pickSticker(context);
    if (pick == null) return;
    final s = StickerItem(id: newId(), page: page, asset: pick['file'] as String);
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
          return Stack(children: [
            Positioned.fill(
              child: PdfViewer.file(
                widget.book.path,
                key: ValueKey(a.toneSig),
                controller: controller,
                params: PdfViewerParams(
                  backgroundColor: HC.deep,
                  panEnabled: !drawing,
                  scaleEnabled: !drawing,
                  pagePaintCallbacks: [(canvas, pageRect, pg) => paintTone(canvas, pageRect, a)],
                  pageOverlaysBuilder: (context, pageRect, pg) => [
                    PageOverlay(page: pg.pageNumber, ann: a, onPin: _openPin, onSticker: _stickerAction),
                  ],
                  onViewerReady: (document, c) {
                    setState(() => total = document.pages.length);
                    widget.book.total = total;
                    if (page > 1) c.goToPage(pageNumber: page);
                  },
                  onPageChanged: (n) {
                    if (n == null) return;
                    setState(() => page = n);
                    widget.book.lastPage = n;
                    Store.update(widget.book);
                  },
                ),
              ),
            ),
            if (!full) _topBar(),
            if (!full) _bottom(a),
            if (full)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton.filledTonal(onPressed: () => setState(() => full = false), icon: const Icon(Icons.fullscreen_exit_rounded)),
                  ),
                ),
              ),
          ]);
        },
      ),
    );
  }

  Widget _topBar() => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Align(
            alignment: Alignment.topCenter,
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(children: [
                IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.arrow_forward_rounded)),
                const SizedBox(width: 8),
                Expanded(child: Text(widget.book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
                Text('$page من ${total == 0 ? '—' : total}', style: TextStyle(color: HC.cream.withValues(alpha: .85))),
                const SizedBox(width: 4),
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
