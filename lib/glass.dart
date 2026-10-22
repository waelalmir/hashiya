import 'dart:ui';
import 'package:flutter/material.dart';
import 'theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset('assets/bg/bg.jpg', fit: BoxFit.cover),
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

class GlassCard extends StatelessWidget {
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.radius = 20});
  final Widget child;
  final EdgeInsets padding;
  final double radius;
  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: HC.cream.withValues(alpha: .09),
            borderRadius: br,
            border: Border.all(color: HC.cream.withValues(alpha: .2)),
          ),
          child: child,
        ),
      ),
    );
  }
}
