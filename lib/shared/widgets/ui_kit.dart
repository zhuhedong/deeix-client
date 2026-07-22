import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Reusable building blocks for the Graphite + Electric Indigo system.
///
/// The [BrandMark] spark is the app's signature: a gradient chip carrying a
/// hand-drawn four-point spark. It appears at sign-in, in empty states and as
/// the assistant's avatar, so the same mark greets you everywhere.

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.radius});

  final double size;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: tokens.brandLinearGradient,
        borderRadius: BorderRadius.circular(radius ?? size * 0.3),
        boxShadow: [
          BoxShadow(
            color: tokens.brandGradient.last.withValues(alpha: 0.35),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size.square(size * 0.5),
          painter: _SparkPainter(color: Colors.white),
        ),
      ),
    );
  }
}

/// Small spark chip used as the assistant's avatar beside its messages.
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) =>
      BrandMark(size: size, radius: size * 0.32);
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;
    final center = size.center(Offset.zero);
    final outer = size.width / 2;
    final valley = outer * 0.42; // pull edges toward center for the spark waist
    final path = Path();
    const tips = 4;
    const step = math.pi / tips; // half a tip-to-tip segment
    const start = -math.pi / 2;
    for (var i = 0; i < tips; i++) {
      final a = start + i * 2 * step;
      final next = start + (i + 1) * 2 * step;
      final mid = a + step;
      final tip = center + Offset(math.cos(a) * outer, math.sin(a) * outer);
      final ctrl =
          center + Offset(math.cos(mid) * valley, math.sin(mid) * valley);
      final nextTip =
          center + Offset(math.cos(next) * outer, math.sin(next) * outer);
      if (i == 0) path.moveTo(tip.dx, tip.dy);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, nextTip.dx, nextTip.dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => oldDelegate.color != color;
}

/// Primary call-to-action painted with the brand gradient.
class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.loading = false,
    this.height = 52,
    this.icon,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool loading;
  final double height;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final enabled = onPressed != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: tokens.brandLinearGradient,
          borderRadius: BorderRadius.circular(14),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: tokens.brandGradient.last.withValues(alpha: 0.3),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? onPressed : null,
            child: SizedBox(
              height: height,
              child: Center(
                child: loading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                          ],
                          DefaultTextStyle.merge(
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(color: Colors.white, fontSize: 15),
                            child: child,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated three-dot indicator shown while a reply is streaming in.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.color, this.dotSize = 7});

  final Color? color;
  final double dotSize;

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final t = (_c.value - i * 0.18) % 1.0;
            final wave = (math.sin(t * 2 * math.pi) + 1) / 2; // 0..1
            return Padding(
              padding: EdgeInsets.only(
                right: i == 2 ? 0 : widget.dotSize * 0.6,
              ),
              child: Transform.translate(
                offset: Offset(0, -wave * widget.dotSize * 0.5),
                child: Container(
                  width: widget.dotSize,
                  height: widget.dotSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.4 + wave * 0.6),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Centered empty / zero state: a soft spark, a title and a gentle nudge.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon,
    this.action,
    this.useBrandMark = false,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Widget? action;
  final bool useBrandMark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (useBrandMark)
              const BrandMark(size: 64)
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: tokens.softAccent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  icon ?? Icons.forum_outlined,
                  size: 32,
                  color: scheme.primary,
                ),
              ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}

/// Rounded-square icon chip for list rows — soft indigo wash, or the brand
/// gradient when [gradient] is set.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.gradient = false,
  });

  final IconData icon;
  final double size;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient ? null : tokens.softAccent,
        gradient: gradient ? tokens.brandLinearGradient : null,
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        icon,
        size: size * 0.48,
        color: gradient ? Colors.white : scheme.primary,
      ),
    );
  }
}

/// Small uppercase group label for settings-style sections.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key, this.padding});

  final String label;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// A grouped, hairline-bordered container for stacking list rows — the settings
/// "inset grouped" look. Children are separated by hairline dividers.
class AppCardGroup extends StatelessWidget {
  const AppCardGroup({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          Divider(height: 1, thickness: 1, indent: 16, color: tokens.hairline),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tokens.hairline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(children: rows),
      ),
    );
  }
}
