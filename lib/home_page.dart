import 'package:flutter/material.dart';
import 'data.dart';
import 'glass.dart';
import 'reader_page.dart';
import 'store.dart';
import 'theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.onOpenLibrary});
  final VoidCallback onOpenLibrary;

  Widget _stat(String label, String value, IconData icon) => Expanded(
        child: GlassCard(
          child: Row(children: [
            Icon(icon, size: 30, color: HC.cream.withValues(alpha: .8)),
            const SizedBox(width: 14),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(fontSize: 13, color: HC.cream.withValues(alpha: .65))),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([Store.books, AppData.reading, AppData.sessions, AppData.tasks]),
        builder: (context, _) {
          final recent = [...Store.books.value]..sort((a, b) => b.openedAt.compareTo(a.openedAt));
          final last = recent.isEmpty ? null : recent.first;
          final today = AppData.dayKey();
          final pending = AppData.tasks.value.where((t) => !t.done).length;
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const PageHeader(title: 'الرئيسية'),
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
                          Text(last.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          LinearProgressIndicator(value: last.progress, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                          const SizedBox(height: 6),
                          Text('صفحة ${last.lastPage} من ${last.total == 0 ? '—' : last.total}', style: TextStyle(fontSize: 13, color: HC.cream.withValues(alpha: .65))),
                          const SizedBox(height: 14),
                          FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderPage(book: last))), child: const Text('متابعة')),
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
                    Text('بحث وملخصات واختبارات', style: TextStyle(color: HC.cream.withValues(alpha: .65))),
                    const SizedBox(height: 10),
                    Chip(label: const Text('قريباً'), side: BorderSide(color: HC.cream.withValues(alpha: .3))),
                  ]),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _stat('قراءة اليوم', AppData.fmtDuration(AppData.secondsOn(today)), Icons.auto_stories_rounded),
              const SizedBox(width: 16),
              _stat('تركيز اليوم', '${AppData.focusMinutesOn(today)} د', Icons.timer_rounded),
              const SizedBox(width: 16),
              _stat('مهام متبقية', '$pending', Icons.checklist_rounded),
              const SizedBox(width: 16),
              _stat('أيام متتالية', '${AppData.streak}', Icons.local_fire_department_rounded),
            ]),
          ]);
        },
      );
}
