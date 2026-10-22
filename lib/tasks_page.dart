import 'package:flutter/material.dart';
import 'data.dart';
import 'glass.dart';
import 'model.dart';
import 'reader_page.dart';
import 'store.dart';
import 'theme.dart';

class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  Book? _book(String? id) {
    for (final b in Store.books.value) {
      if (b.id == id) return b;
    }
    return null;
  }

  Future<void> _edit(BuildContext context, Task? old) async {
    final title = TextEditingController(text: old?.title ?? '');
    final from = TextEditingController(text: old?.from?.toString() ?? '');
    final to = TextEditingController(text: old?.to?.toString() ?? '');
    String? bookId = old?.bookId;
    DateTime? due = old?.due == null ? null : DateTime.fromMillisecondsSinceEpoch(old!.due!);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text(old == null ? 'مهمة جديدة' : 'تعديل المهمة'),
          content: SizedBox(
            width: 420,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: title, autofocus: true, decoration: const InputDecoration(labelText: 'العنوان')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: bookId,
                decoration: const InputDecoration(labelText: 'الكتاب (اختياري)'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('بدون كتاب')),
                  for (final b in Store.books.value) DropdownMenuItem<String?>(value: b.id, child: Text(b.title, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => set(() => bookId = v),
              ),
              if (bookId != null) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: TextField(controller: from, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'من صفحة'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: to, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'إلى صفحة'))),
                ]),
              ],
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final d = await showDatePicker(context: c, initialDate: due ?? DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2100));
                    if (d != null) set(() => due = d);
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text(due == null ? 'الموعد (اختياري)' : AppData.dayKey(due)),
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('إلغاء')),
            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('حفظ')),
          ],
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    final t = old ?? Task(id: newId(), title: '');
    t.title = title.text.trim();
    t.bookId = bookId;
    t.from = bookId == null ? null : int.tryParse(from.text);
    t.to = bookId == null ? null : int.tryParse(to.text);
    t.due = due?.millisecondsSinceEpoch;
    AppData.setTasks(old == null ? [...AppData.tasks.value, t] : [...AppData.tasks.value]);
  }

  Widget _row(BuildContext context, Task t) {
    final b = _book(t.bookId);
    final sub = <String>[
      if (b != null) b.title,
      if (t.from != null) 'ص ${t.from}${t.to != null ? '–${t.to}' : ''}',
      if (t.due != null) AppData.dayKey(DateTime.fromMillisecondsSinceEpoch(t.due!)),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          Checkbox(
            value: t.done,
            onChanged: (v) {
              t.done = v ?? false;
              AppData.setTasks([...AppData.tasks.value]);
            },
          ),
          Expanded(
            child: InkWell(
              onTap: () => _edit(context, t),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.title, style: TextStyle(fontSize: 16, decoration: t.done ? TextDecoration.lineThrough : null, color: HC.cream.withValues(alpha: t.done ? .5 : 1))),
                if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 12, color: HC.cream.withValues(alpha: .6))),
              ]),
            ),
          ),
          if (b != null)
            IconButton(
              tooltip: 'فتح الكتاب',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ReaderPage(book: b, startPage: t.from))),
              icon: const Icon(Icons.menu_book_rounded),
            ),
          IconButton(onPressed: () => AppData.setTasks(AppData.tasks.value.where((x) => x.id != t.id).toList()), icon: const Icon(Icons.delete_outline_rounded)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([AppData.tasks, Store.books]),
        builder: (context, _) {
          final all = AppData.tasks.value;
          final todo = all.where((t) => !t.done).toList();
          final done = all.where((t) => t.done).toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PageHeader(title: 'المهام', actions: [
              FilledButton.icon(onPressed: () => _edit(context, null), icon: const Icon(Icons.add), label: const Text('مهمة جديدة')),
            ]),
            Expanded(
              child: all.isEmpty
                  ? Center(child: GlassCard(padding: const EdgeInsets.all(32), child: const Text('ما في مهام بعد. أضف أول مهمة.', style: TextStyle(fontSize: 18))))
                  : ListView(children: [
                      if (todo.isNotEmpty) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('قيد التنفيذ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      for (final t in todo) _row(context, t),
                      if (done.isNotEmpty) const Padding(padding: EdgeInsets.only(top: 12, bottom: 8), child: Text('منجزة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      for (final t in done) _row(context, t),
                    ]),
            ),
          ]);
        },
      );
}
