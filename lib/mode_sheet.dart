import 'package:flutter/material.dart';
import 'annotations.dart';
import 'theme.dart';

const _bgs = [0xFFF2E8C9, 0xFFEFE0B8, 0xFFF7F3E8, 0xFFDCE6DC, 0xFF16201E, 0xFF0E1116, 0xFF000000, 0xFF1B1B24];
const _txs = [0xFF3C3B37, 0xFF2B2B2B, 0xFF000000, 0xFFD9D4C4, 0xFFEDE5D3, 0xFFBFBFBF, 0xFFE6C07B, 0xFFA8C7B8];

Future<void> showModeSheet(BuildContext context, Annotations ann) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: HC.green,
    isScrollControlled: true,
    builder: (c) => StatefulBuilder(builder: (c, set) {
      Widget card(String id, String name, Color bg, Color tx) => Expanded(
            child: GestureDetector(
              onTap: () {
                ann.setMode(id);
                set(() {});
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: ann.mode == id ? HC.cream : Colors.transparent, width: 3)),
                child: Column(children: [Text('Aa', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: tx)), const SizedBox(height: 4), Text(name, style: TextStyle(color: tx))]),
              ),
            ),
          );
      Widget swatches(List<int> list, int cur, void Function(int) pick) => Wrap(spacing: 10, runSpacing: 10, children: [
            for (final v in list)
              GestureDetector(
                onTap: () {
                  pick(v);
                  set(() {});
                },
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(v), shape: BoxShape.circle, border: Border.all(color: cur == v ? HC.cream : Colors.white24, width: cur == v ? 3 : 1))),
              ),
          ]);
      final t = ann.tone[ann.mode];
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('وضع القراءة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          Row(children: [
            card('original', 'الأصلي', Colors.white, Colors.black),
            card('paper', 'ورقي', const Color(0xFFF2E8C9), const Color(0xFF3C3B37)),
            card('night', 'ليلي', const Color(0xFF16201E), const Color(0xFFD9D4C4)),
          ]),
          if (t != null) ...[
            const SizedBox(height: 18),
            const Text('لون الخلفية'),
            const SizedBox(height: 8),
            swatches(_bgs, t[0], (v) => ann.setTone(ann.mode, bg: v)),
            const SizedBox(height: 14),
            const Text('لون النص'),
            const SizedBox(height: 8),
            swatches(_txs, t[1], (v) => ann.setTone(ann.mode, text: v)),
          ],
          const SizedBox(height: 14),
          Row(children: [
            const Text('تعتيم الصفحة'),
            Expanded(child: Slider(value: ann.dim, min: 0, max: .6, onChanged: (v) => set(() => ann.dim = v), onChangeEnd: ann.setDim)),
          ]),
          const Text('ملاحظة: الأوضاع الملوّنة تغيّر ألوان الصور داخل الصفحة أيضاً.', style: TextStyle(fontSize: 12, color: Colors.white60)),
        ]),
      );
    }),
  );
}
