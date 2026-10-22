import 'package:flutter/material.dart';
import 'data.dart';
import 'glass.dart';
import 'store.dart';
import 'theme.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  static const _days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];

  Widget _card(String label, String value, IconData i) => Expanded(
        child: GlassCard(
          child: Row(children: [
            Icon(i, size: 30, color: HC.cream.withValues(alpha: .8)),
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
        listenable: Listenable.merge([AppData.reading, AppData.sessions, AppData.tasks, Store.books]),
        builder: (context, _) {
          final now = DateTime.now();
          final week = [for (var i = 6; i >= 0; i--) now.subtract(Duration(days: i))];
          final secs = [for (final d in week) AppData.secondsOn(AppData.dayKey(d))];
          final maxS = secs.fold<int>(1, (a, b) => b > a ? b : a);
          final per = AppData.perBook().entries.toList()..sort((a, b) => b.value.compareTo(a.value));
          final top = per.take(5).toList();
          final focusMin = AppData.sessions.value.fold<int>(0, (a, s) => a + s.minutes);
          final doneTasks = AppData.tasks.value.where((t) => t.done).length;
          String title(String id) {
            for (final b in Store.books.value) {
              if (b.id == id) return b.title;
            }
            return 'كتاب محذوف';
          }

          return SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const PageHeader(title: 'الإحصائيات'),
              Row(children: [
                _card('إجمالي القراءة', AppData.fmtDuration(AppData.totalSeconds), Icons.auto_stories_rounded),
                const SizedBox(width: 16),
                _card('أيام متتالية', '${AppData.streak}', Icons.local_fire_department_rounded),
                const SizedBox(width: 16),
                _card('وقت التركيز', AppData.fmtDuration(focusMin * 60), Icons.timer_rounded),
                const SizedBox(width: 16),
                _card('مهام منجزة', '$doneTasks', Icons.task_alt_rounded),
              ]),
              const SizedBox(height: 16),
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  flex: 3,
                  child: GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('آخر 7 أيام', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 220,
                        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                                Text(secs[i] == 0 ? '' : '${(secs[i] / 60).round()}', style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Container(width: 28, height: 4 + 150 * secs[i] / maxS, decoration: BoxDecoration(color: HC.cream.withValues(alpha: secs[i] == 0 ? .25 : 1), borderRadius: BorderRadius.circular(6))),
                                const SizedBox(height: 6),
                                Text(_days[week[i].weekday - 1], style: TextStyle(fontSize: 11, color: HC.cream.withValues(alpha: .7))),
                              ]),
                            ),
                        ]),
                      ),
                      Text('الأرقام بالدقائق', style: TextStyle(fontSize: 11, color: HC.cream.withValues(alpha: .5))),
                    ]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: GlassCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('حسب الكتاب', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      if (top.isEmpty) Text('ابدأ القراءة لتظهر الإحصائيات', style: TextStyle(color: HC.cream.withValues(alpha: .6))),
                      for (final e in top)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(title(e.key), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              Text(AppData.fmtDuration(e.value), style: TextStyle(fontSize: 12, color: HC.cream.withValues(alpha: .65))),
                            ]),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: e.value / top.first.value, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                          ]),
                        ),
                    ]),
                  ),
                ),
              ]),
            ]),
          );
        },
      );
}
