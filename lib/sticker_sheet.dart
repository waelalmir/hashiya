import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'paper_stickers.dart';
import 'theme.dart';

Future<Map<String, dynamic>?> pickSticker(BuildContext context) async {
  final list = (jsonDecode(await rootBundle.loadString('assets/stickers/manifest.json')) as List).cast<Map<String, dynamic>>();
  if (!context.mounted) return null;
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    backgroundColor: HC.green,
    isScrollControlled: true,
    builder: (c) => SizedBox(
      height: MediaQuery.of(c).size.height * .75,
      child: DefaultTabController(
        length: 4,
        child: Column(children: [
          const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 4), child: Text('الستيكرات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
          TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelColor: HC.cream,
            unselectedLabelColor: HC.cream.withValues(alpha: .6),
            indicatorColor: HC.cream,
            dividerColor: Colors.transparent,
            tabs: const [Tab(text: 'ورق: جمل جاهزة'), Tab(text: 'ورق: فارغة'), Tab(text: 'صورة بإطار'), Tab(text: 'كلاسيك')],
          ),
          Expanded(
            child: TabBarView(children: [
              _grid(
                count: kPhrases.length,
                builder: (w, i) => PaperNote(styleIndex: i, text: kPhrases[i], width: w),
                onTap: (i) => Navigator.pop(c, {'id': 'paper', 'style': i % kPaperStyles.length, 'text': kPhrases[i]}),
              ),
              _grid(
                count: kPaperStyles.length,
                builder: (w, i) => PaperNote(styleIndex: i, text: '', hint: 'اكتب هنا', width: w),
                onTap: (i) => Navigator.pop(c, {'id': 'paper', 'style': i, 'text': '', 'blank': true}),
              ),
              _grid(
                count: kPaperStyles.length,
                builder: (w, i) => PhotoNote(styleIndex: i, width: w),
                onTap: (i) => Navigator.pop(c, {'id': 'photo', 'style': i}),
                ratio: 1.12,
              ),
              GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 170, mainAxisSpacing: 12, crossAxisSpacing: 12),
                itemCount: list.length,
                itemBuilder: (c2, i) {
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
            ]),
          ),
        ]),
      ),
    ),
  );
}

Widget _grid({required int count, required Widget Function(double w, int i) builder, required void Function(int) onTap, double ratio = .8}) {
  return GridView.builder(
    padding: const EdgeInsets.all(16),
    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 170, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1 / ratio),
    itemCount: count,
    itemBuilder: (c, i) => InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onTap(i),
      child: LayoutBuilder(builder: (c, box) => Center(child: builder(box.maxWidth - 12, i))),
    ),
  );
}

Future<String?> editText(BuildContext context, String initial, {String title = 'نص الستيكر'}) {
  final c = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(controller: c, autofocus: true, maxLines: 6, minLines: 1),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: const Text('إلغاء')),
        FilledButton(onPressed: () => Navigator.pop(d, c.text), child: const Text('حفظ')),
      ],
    ),
  );
}
