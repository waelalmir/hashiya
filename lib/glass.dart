import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'data.dart';
import 'theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        ValueListenableBuilder<String?>(
          valueListenable: AppData.bgPath,
          builder: (context, p, _) {
            const fallback = Image(image: AssetImage('assets/bg/bg.jpg'), fit: BoxFit.cover);
            if (p == null || !File(p).existsSync()) return fallback;
            return Image.file(File(p), fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
          },
        ),
        Container(color: HC.green.withValues(alpha: .38)),
        child,
      ]);
}

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.actions = const []});
  final String title;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          height: 48,
          child: Row(children: [
            Text(title, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600, height: 1)),
            const Spacer(),
            ...actions,
          ]),
        ),
      );
}

/// بطاقة زجاجية. dark = شريط داكن ثابت (للقارئ) بدون تمويه وبأيقونات تظهر فوق أي خلفية.
class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 20, this.dark = false});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget box(Color c) => Container(
          padding: padding,
          decoration: BoxDecoration(color: c, borderRadius: br, border: Border.all(color: HC.cream.withValues(alpha: dark ? .25 : .2))),
          child: child,
        );
    if (dark) return ClipRRect(borderRadius: br, child: box(const Color(0xE6032B27)));
    return ValueListenableBuilder<bool>(
      valueListenable: AppData.reduceBlur,
      builder: (context, reduce, _) => ClipRRect(
        borderRadius: br,
        child: reduce
            ? box(HC.cream.withValues(alpha: .16))
            : BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: box(HC.cream.withValues(alpha: .09))),
      ),
    );
  }
}
