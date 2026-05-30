import 'package:flutter/material.dart';

const Color premiumBackground = Color(0xFFEAF5F0);
const Color premiumSurface = Color(0xFFFFFFFF);
const Color premiumPrimary = Color(0xFF1A5269);
const Color premiumAccent = Color(0xFF2C8C6B);
const Color premiumWarm = Color(0xFFF4E8D8);

PageRouteBuilder<T> premiumPageRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final offset = Tween<Offset>(begin: const Offset(0.05, 0.04), end: Offset.zero)
          .animate(curved);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(position: offset, child: child),
      );
    },
  );
}

class PremiumBackground extends StatelessWidget {
  const PremiumBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      ignoring: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF091419), const Color(0xFF112128), const Color(0xFF152A33)]
                : [const Color(0xFFF8FCFA), const Color(0xFFE3F2EC), const Color(0xFFD4EAE2)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: _BlurOrb(
                size: 180,
                color: (isDark ? scheme.secondary : premiumAccent).withValues(alpha: 0.16),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: _BlurOrb(
                size: 140,
                color: (isDark ? scheme.primary : premiumPrimary).withValues(alpha: 0.12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumShell extends StatelessWidget {
  const PremiumShell({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.extendBody = false,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool extendBody;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: extendBody,
      backgroundColor: scheme.surface,
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: Stack(
        children: [
          const Positioned.fill(child: PremiumBackground()),
          child,
        ],
      ),
    );
  }
}

class PremiumSurface extends StatelessWidget {
  const PremiumSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = 24,
    this.elevation = 0,
    this.gradient,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double elevation;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? scheme.surfaceContainerHighest : null,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: elevation + 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class PremiumSectionHeader extends StatelessWidget {
  const PremiumSectionHeader({
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class PremiumEmptyState extends StatelessWidget {
  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconSize = compact ? 54.0 : 72.0;
    final padding = compact ? 16.0 : 24.0;
    final isDark = theme.brightness == Brightness.dark;
    
    return SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: PremiumSurface(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: iconSize,
                  width: iconSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        (isDark ? scheme.secondaryContainer : premiumAccent).withValues(alpha: 0.18),
                        (isDark ? scheme.primaryContainer : premiumPrimary).withValues(alpha: 0.16),
                      ],
                    ),
                  ),
                  child: Icon(icon, color: scheme.primary, size: compact ? 24 : 34),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    fontSize: compact ? 16 : null,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: compact ? 12 : null,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                if (action != null) ...[const SizedBox(height: 18), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PremiumHeroBanner extends StatelessWidget {
  const PremiumHeroBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
    this.icon,
    this.inlineIconOnMobile = false,
  });

  final String title;
  final String subtitle;
  final Widget? action;
  final IconData? icon;
  final bool inlineIconOnMobile;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    const padding = EdgeInsets.all(20);
    const heroGradient = LinearGradient(
      colors: [premiumPrimary, premiumAccent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    return SingleChildScrollView(
      child: PremiumSurface(
        padding: padding,
        gradient: heroGradient,
        child: isMobile && inlineIconOnMobile
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                            fontSize: 13,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (action != null) ...[const SizedBox(height: 16), Flexible(child: action!)],
                      ],
                    ),
                  ),
                ],
              )
            : isMobile
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      height: 64,
                      width: 64,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                      fontSize: 13,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (action != null) ...[const SizedBox(height: 16), Flexible(child: action!)],
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (action != null) ...[const SizedBox(height: 16), Flexible(child: action!)],
                      ],
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 16),
                    Container(
                      height: 84,
                      width: 84,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 40),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({required this.size, required this.color});

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