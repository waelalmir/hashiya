import 'package:flutter/material.dart';
import 'glass.dart';
import 'reader_page.dart';
import 'store.dart';
import 'theme.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  Future<void> _add(BuildContext context) async {
    final b = await Store.pickAndAdd();
    if (b != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة: ${b.title}')));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Book b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('حذف الكتاب؟'),
        content: Text(b.title),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حذف')),
        ],
      ),
    );
    if (ok == true) await Store.remove(b);
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PageHeader(title: 'المكتبة', actions: [
          FilledButton.icon(onPressed: () => _add(context), icon: const Icon(Icons.add), label: const Text('إضافة PDF')),
        ]),
        Expanded(
          child: ValueListenableBuilder<List<Book>>(
            valueListenable: Store.books,
            builder: (context, books, _) {
              if (books.isEmpty) {
                return Center(
                  child: GlassCard(
                    padding: const EdgeInsets.all(40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('مكتبتك فارغة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('أضف أول ملف PDF لتبدأ', style: TextStyle(color: HC.cream.withValues(alpha: .65))),
                      const SizedBox(height: 20),
                      FilledButton(onPressed: () => _add(context), child: const Text('+ إضافة PDF')),
                    ]),
                  ),
                );
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200, childAspectRatio: .68, crossAxisSpacing: 14, mainAxisSpacing: 14),
                itemCount: books.length,
                itemBuilder: (context, i) {
                  final b = books[i];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderPage(book: b))),
                    onLongPress: () => _confirmDelete(context, b),
                    child: GlassCard(
                      padding: const EdgeInsets.all(12),
                      radius: 18,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: HC.cream.withValues(alpha: .14), borderRadius: BorderRadius.circular(10)),
                            child: const Center(child: Icon(Icons.picture_as_pdf_rounded, size: 40)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: b.progress, minHeight: 5, borderRadius: BorderRadius.circular(3)),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]);
}
