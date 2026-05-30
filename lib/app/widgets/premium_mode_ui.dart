import 'package:flutter/material.dart';

class PremiumModeShell extends StatelessWidget {
  const PremiumModeShell({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundGradient = isDark
        ? const [
            Color(0xFF050608),
            Color(0xFF0B1116),
            Color(0xFF000000),
          ]
        : const [
            Color(0xFFF9FCFA),
            Color(0xFFE7F2EC),
            Color(0xFFD7E9E0),
          ];

    return Scaffold(
      extendBody: extendBody,
      backgroundColor: backgroundGradient.last,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: backgroundGradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -40,
              child: _ModeOrb(
                size: 180,
                color: isDark
                    ? const Color(0xFF1A5269).withValues(alpha: 0.18)
                    : const Color(0xFF2C8C6B).withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: _ModeOrb(
                size: 150,
                color: isDark
                    ? const Color(0xFF2C8C6B).withValues(alpha: 0.12)
                    : const Color(0xFF1A5269).withValues(alpha: 0.10),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class PremiumModeSurface extends StatelessWidget {
  const PremiumModeSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.gradient,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Gradient? gradient;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF12171D) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFF1A5269).withValues(alpha: 0.10);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? backgroundColor : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.08),
            blurRadius: elevation + 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class PremiumModeSectionHeader extends StatelessWidget {
  const PremiumModeSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF102A43);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF52606D);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        height: 1.35,
                      ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class PremiumModeMetricCard extends StatelessWidget {
  const PremiumModeMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PremiumModeSurface(
      padding: const EdgeInsets.all(14),
      borderRadius: 22,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.20 : 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF102A43),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.68)
                            : const Color(0xFF52606D),
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumModeActionTile extends StatelessWidget {
  const PremiumModeActionTile({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    required this.accent,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : const Color(0xFF102A43);
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.68)
        : const Color(0xFF52606D);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: SizedBox(
        height: 172,
        child: PremiumModeSurface(
          padding: const EdgeInsets.all(14),
          borderRadius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.20 : 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: accent),
              ),
              const Spacer(),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: titleColor,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: subtitleColor,
                      height: 1.25,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeOrb extends StatelessWidget {
  const _ModeOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
