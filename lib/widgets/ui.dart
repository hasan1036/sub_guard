import 'package:flutter/material.dart';

/// SubGuard visual style: purple gradients, soft white cards, rounded shapes.
class Brand {
  static const primary = Color(0xFF6A3DF0);
  static const deep = Color(0xFF4419C8);
  static const bgLight = Color(0xFFF4F1FF);
  static const tint = Color(0xFFEDE7FF);

  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF8C5CFF), Color(0xFF5E2DE6), Color(0xFF3D16B5)],
  );

  static const shadow = [
    BoxShadow(color: Color(0x1F6A3DF0), blurRadius: 24, offset: Offset(0, 8)),
  ];
}

bool _isLight(BuildContext c) => Theme.of(c).brightness == Brightness.light;

/// Big purple gradient card with soft decorative circles.
class GradientCard extends StatelessWidget {
  const GradientCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 26,
  });

  final Widget child;
  final EdgeInsets padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [
          BoxShadow(color: Color(0x556A3DF0), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: Brand.gradient),
          child: Stack(
            children: [
              Positioned(right: -40, top: -50, child: _Circle(170, 0.10)),
              Positioned(left: -30, bottom: -60, child: _Circle(140, 0.07)),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.alpha);
  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}

/// White rounded card with a soft purple shadow.
class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ??
        (_isLight(context)
            ? Colors.white
            : Theme.of(context).colorScheme.surfaceContainerHigh);
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: _isLight(context) ? Brand.shadow : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Rounded-square "app icon" made from the service's first letter and color.
class ServiceAvatar extends StatelessWidget {
  const ServiceAvatar({
    super.key,
    required this.name,
    required this.color,
    this.size = 46,
  });

  final String name;
  final int color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Color(color);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(c, Colors.white, 0.15)!, c],
        ),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.30),
            blurRadius: size * 0.25,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Text(
        name.trim().isEmpty ? '?' : name.trim().characters.first.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.46,
        ),
      ),
    );
  }
}

/// Small light-purple square holding an icon (used in rows and fields).
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, this.color, this.size = 40});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: c, size: size * 0.55),
    );
  }
}

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: Brand.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x556A3DF0), blurRadius: 20, offset: Offset(0, 8)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white),
                const SizedBox(width: 10),
              ],
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.onSeeAll, this.icon});
  final String title;
  final VoidCallback? onSeeAll;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
          ),
          if (onSeeAll != null)
            InkWell(
              onTap: onSeeAll,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Text('See All',
                        style: TextStyle(
                            color: cs.primary, fontWeight: FontWeight.w700)),
                    Icon(Icons.arrow_forward, size: 16, color: cs.primary),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Rounded pill, e.g. "in 3 days" or a price tag.
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.strong = false});
  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: strong ? cs.primary.withValues(alpha: 0.14) : cs.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: cs.primary,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w700,
              fontSize: strong ? 15 : 13)),
    );
  }
}

/// Small orange "TRIAL" tag.
class TrialTag extends StatelessWidget {
  const TrialTag({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8A00).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('TRIAL',
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFE07000))),
      );
}

/// "32 days left" / "Tomorrow" / "Today", colored by how close it is:
/// red = 3 days or less, orange = within a week, green = later.
class DaysLeftChip extends StatelessWidget {
  const DaysLeftChip({super.key, required this.days, this.trial = false});

  final int days;
  final bool trial;

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (days <= 3) {
      color = const Color(0xFFE5484D);
    } else if (days <= 7) {
      color = const Color(0xFFE07000);
    } else {
      color = const Color(0xFF16A34A);
    }

    final String when;
    if (days < 0) {
      when = 'Overdue';
    } else if (days == 0) {
      when = 'Today';
    } else if (days == 1) {
      when = 'Tomorrow';
    } else {
      when = '$days days left';
    }
    final label = trial && days >= 0 ? 'Trial ends: $when' : when;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_bottom_rounded, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
