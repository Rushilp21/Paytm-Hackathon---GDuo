import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models.dart';
import 'theme.dart';

class Brand extends StatelessWidget {
  final bool compact;
  const Brand({this.compact = false, super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 31,
        height: 31,
        decoration: BoxDecoration(
          color: blue,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(
          Icons.north_east_rounded,
          size: 24,
          color: Colors.white,
        ),
      ),
      if (!compact) ...[
        const SizedBox(width: 9),
        const Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'FIN',
                style: TextStyle(color: ink),
              ),
              TextSpan(
                text: 'PATH',
                style: TextStyle(color: blue),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
      ],
    ],
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Panel({
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(24),
    super.key,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color == Colors.white ? line : color),
    ),
    child: child,
  );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Tag(this.text, {this.color = teal, this.icon, super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .09),
      borderRadius: BorderRadius.circular(7),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    ),
  );
}

class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const IconTile(this.icon, {this.color = blue, this.size = 44, super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .085),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: color, size: size * .5),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const SectionTitle(this.title, {this.subtitle, this.trailing, super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              if (subtitle != null) ...[
                const SizedBox(height: 5),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  final Widget? action;
  const PageHeading(
    this.eyebrow,
    this.title,
    this.subtitle, {
    this.action,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 14,
      spacing: 24,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: teal,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 7),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: muted)),
          ],
        ),
        ?action,
      ],
    ),
  );
}

class ResponsiveSplit extends StatelessWidget {
  final Widget left, right;
  final int leftFlex, rightFlex;
  final double breakpoint;
  const ResponsiveSplit({
    required this.left,
    required this.right,
    this.leftFlex = 2,
    this.rightFlex = 1,
    this.breakpoint = 850,
    super.key,
  });
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => c.maxWidth >= breakpoint
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: leftFlex, child: left),
              const SizedBox(width: 24),
              Expanded(flex: rightFlex, child: right),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, const SizedBox(height: 24), right],
          ),
  );
}

class Metric extends StatelessWidget {
  final String label, value, note;
  final IconData icon;
  final Color color;
  const Metric(
    this.label,
    this.value,
    this.note,
    this.icon, {
    this.color = blue,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconTile(icon, color: color, size: 35),
            const Spacer(),
            Icon(Icons.north_east, size: 15, color: color),
          ],
        ),
        const SizedBox(height: 16),
        Text(label, style: const TextStyle(fontSize: 12, color: muted)),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w700,
            color: ink,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 7),
        Text(note, style: TextStyle(fontSize: 10.5, color: color)),
      ],
    ),
  );
}

class Notice extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;
  const Notice(
    this.text, {
    this.color = blue,
    this.icon = Icons.info_outline,
    super.key,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, height: 1.6, color: color),
          ),
        ),
      ],
    ),
  );
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
IconData goalIcon(GoalKind kind) => switch (kind) {
  GoalKind.bike => Icons.two_wheeler_rounded,
  GoalKind.car => Icons.directions_car_outlined,
  GoalKind.education => Icons.school_outlined,
  GoalKind.home => Icons.home_outlined,
  GoalKind.business => Icons.storefront_outlined,
  GoalKind.insurance => Icons.health_and_safety_outlined,
  GoalKind.personal => Icons.flag_outlined,
};

class JourneyArt extends StatelessWidget {
  const JourneyArt({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 275,
    height: 238,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: _OrbitPainter())),
        Transform.rotate(
          angle: -.12,
          child: Container(
            width: 151,
            height: 166,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDEF7ED),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .12),
                  blurRadius: 35,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.north_east_rounded, size: 35, color: teal),
                const Spacer(),
                const FittedBox(
                  child: Text(
                    'Your next chapter',
                    style: TextStyle(fontSize: 10, color: teal),
                  ),
                ),
                const SizedBox(height: 6),
                const FittedBox(
                  child: Text(
                    'Closer than\nyou think.',
                    style: TextStyle(
                      fontSize: 21,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 4,
          bottom: 4,
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: teal, size: 19),
                SizedBox(width: 7),
                Text(
                  'A plan built for you',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _OrbitPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final r in [82.0, 110.0, 138.0]) {
      c.drawCircle(Offset(s.width / 2, s.height / 2), r, p);
    }
    final dot = Paint()..color = const Color(0xFF91E7C7);
    for (var i = 0; i < 3; i++) {
      final a = i * 2.1;
      c.drawCircle(
        Offset(
          s.width / 2 + math.cos(a) * 112,
          s.height / 2 + math.sin(a) * 112,
        ),
        5,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
