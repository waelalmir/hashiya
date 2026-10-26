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
          if (editable) SimpleDialogOption(on
