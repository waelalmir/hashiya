import 'package:flutter/material.dart';
import 'glass.dart';
import 'home_page.dart';
import 'library_page.dart';
import 'theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  static const items = [
    ('الرئيسية', Icons.home_rounded),
    ('المكتبة', Icons.auto_stories_rounded),
    ('الإحصائيات', Icons.bar_chart_rounded),
    ('التركيز', Icons.timer_rounded),
    ('المهام', Icons.checklist_rounded),
    ('الإعدادات', Icons.settings_rounded),
  ];

  Widget page() {
    switch (index) {
      case 0:
        return HomePage(onOpenLibrary: () => setState(() => index = 1));
      case 1:
        return const LibraryPage();
      default:
        return Center(child: Text('${items[index].$1} · في الدفعة التالية', style: const TextStyle(fontSize: 20)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: MountainBackground(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                SizedBox(width: 190, child: _sidebar()),
                const SizedBox(width: 20),
                Expanded(child: page()),
              ]),
            ),
          ),
        ),
      );

  Widget _sidebar() => GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: Column(children: [
          CircleAvatar(radius: 32, backgroundColor: HC.cream.withValues(alpha: .3)),
          const SizedBox(height: 8),
          const Text('عبد', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Text('واصل التقدّم', style: TextStyle(fontSize: 12, color: HC.cream.withValues(alpha: .6))),
          const SizedBox(height: 20),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => index = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                      color: i == index ? HC.cream : null, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(items[i].$2, size: 20, color: i == index ? HC.green : HC.cream.withValues(alpha: .7)),
                    const SizedBox(width: 10),
                    Text(items[i].$1,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                            color: i == index ? HC.green : HC.cream.withValues(alpha: .7))),
                  ]),
                ),
              ),
            ),
        ]),
      );
}
