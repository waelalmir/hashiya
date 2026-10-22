import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';

Future<Map<String, dynamic>?> pickSticker(BuildContext context) async {
  final list = (jsonDecode(await rootBundle.loadString('assets/stickers/manifest.json')) as List).cast<Map<String, dynamic>>();
  if (!context.mounted) return null;
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: HC.green,
    isScrollControlled: true,
    builder: (c) => SizedBox(
      height: MediaQuery.of(c).size.height * .7,
      child: Column(children: [
        const Padding(padding: EdgeInsets.all(16), child: Text('الستيكرات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 170, mainAxisSpacing: 12, crossAxisSpacing: 12),
            itemCount: list.length,
            itemBuilder: (c, i) {
              final e = list[i];
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => Navigator.pop(c, e),
                child: Container(
                  decoration: BoxDecoration(color: HC.cream.withValues(alpha: .08), borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.all(8),
                  child: Image.asset('assets/stickers/${e['file']}', fit: BoxFit.contain),
                ),
              );
            },
          ),
        ),
      ]),
    ),
  );
}

Future<String?> editText(BuildContext context, String initial) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: const Text('نص الستيكر'),
      content: TextField(controller: c, autofocus: true, maxLines: 3, minLines: 1),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('حفظ')),
      ],
    ),
  );
}
