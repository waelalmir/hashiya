import 'package:flutter/material.dart';
import 'glass.dart';
import 'reader_page.dart';
import 'store.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenLibrary});
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<List<Book>>(
        valueListenable: Store.books,
        builder: (context, books, _) {
          final recent = [...books]..sort((a, b) => b.openedAt.compareTo(a.openedAt));
          final last = recent.isEmpty ? null : recent.first;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('الرئيسية', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                flex: 3,
                child: GlassCard(
                  child: last == null
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Text('ابدأ من هنا', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          const Text('أضف أول ملف PDF إلى مكتبتك'),
                          const SizedBox(height: 14),
                          FilledButton(onPressed: onOpenLibrary, child: const Text('فتح المكتبة')),
                        ])
                      : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('متابعة القراءة', style: TextStyle(color: HC.cream.withValues(alpha: .65))),
                          const SizedBox(height: 6),
                          Text(last.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: last.progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                          const SizedBox(height: 6),
                          Text('صفحة ${last.lastPage} من ${last.total == 0 ? '—' : last.total}',
                              style: TextStyle(fontSize: 13, color: HC.cream.withValues(alpha: .65))),
                          const SizedBox(height: 14),
                          FilledButton(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderPage(book: last))),
                              child: const Text('متابعة')),
                        ]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: GlassCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('المساعد الذكي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Chip(label: const Text('قريباً'), side: BorderSide(color: HC.cream.withValues(alpha: .3))),
                  ]),
                ),
              ),
            ]),
          ]);
        },
      );
}
