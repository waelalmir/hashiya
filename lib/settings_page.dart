import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'data.dart';
import 'glass.dart';
import 'store.dart';
import 'theme.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final nameC = TextEditingController(text: AppData.name.value);
  static const maxBytes = 2 * 1024 * 1024;

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickBg() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    if (r == null || r.files.single.path == null) return;
    final src = File(r.files.single.path!);
    final size = await src.length();
    if (size > maxBytes) {
      _snack('حجم الصورة ${(size / 1048576).toStringAsFixed(1)} ميغا، الحد الأقصى 2 ميغا');
      return;
    }
    final ext = r.files.single.name.contains('.') ? r.files.single.name.split('.').last.toLowerCase() : 'jpg';
    final dest = '${Store.dir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await src.copy(dest);
    final old = AppData.bgPath.value;
    AppData.bgPath.value = dest;
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    await AppData.save();
  }

  Future<void> _resetBg() async {
    final old = AppData.bgPath.value;
    AppData.bgPath.value = null;
    if (old != null) {
      try {
        await File(old).delete();
      } catch (_) {}
    }
    await AppData.save();
  }

  Widget _section(String title, Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: GlassCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            child,
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const PageHeader(title: 'الإعدادات'),
          _section(
            'الملف الشخصي',
            SizedBox(
              width: 360,
              child: TextField(
                controller: nameC,
                decoration: const InputDecoration(labelText: 'الاسم'),
                onChanged: (v) {
                  AppData.name.value = v;
                  AppData.save();
                },
              ),
            ),
          ),
          _section(
            'خلفية التطبيق',
            ValueListenableBuilder<String?>(
              valueListenable: AppData.bgPath,
              builder: (context, p, _) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 220,
                    height: 124,
                    child: (p != null && File(p).existsSync()) ? Image.file(File(p), fit: BoxFit.cover) : Image.asset('assets/bg/bg.jpg', fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  FilledButton.icon(onPressed: _pickBg, icon: const Icon(Icons.image_rounded), label: const Text('اختيار صورة')),
                  const SizedBox(height: 8),
                  OutlinedButton(onPressed: p == null ? null : _resetBg, child: const Text('الخلفية الافتراضية')),
                  const SizedBox(height: 8),
                  Text('الحد الأقصى لحجم الصورة: 2 ميغا', style: TextStyle(fontSize: 12, color: HC.cream.withValues(alpha: .6))),
                ]),
              ]),
            ),
          ),
          _section(
            'الأداء',
            ValueListenableBuilder<bool>(
              valueListenable: AppData.reduceBlur,
              builder: (context, v, _) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تقليل الشفافية (أسرع)'),
                subtitle: const Text('يوقف تمويه الزجاج في الواجهة'),
                value: v,
                onChanged: (x) {
                  AppData.reduceBlur.value = x;
                  AppData.save();
                },
              ),
            ),
          ),
          _section('حول', Text('حاشية · الإصدار 1.1', style: TextStyle(color: HC.cream.withValues(alpha: .7)))),
        ]),
      );
}
