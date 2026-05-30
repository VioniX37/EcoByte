import 'dart:math' as math;

import 'package:flutter/material.dart';

class FloatingEwasteBackground extends StatefulWidget {
  const FloatingEwasteBackground({super.key});

  @override
  State<FloatingEwasteBackground> createState() =>
      _FloatingEwasteBackgroundState();
}

class _FloatingEwasteBackgroundState extends State<FloatingEwasteBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _icon({
    required double left,
    required double top,
    required double size,
    required IconData icon,
    required Color color,
    required double phase,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = (_controller.value * 2 * math.pi) + phase;
        final dx = math.sin(t) * 10;
        final dy = math.cos(t) * 12;
        final rotation = math.sin(t) * 0.06;

        return Positioned(
          left: left + dx,
          top: top + dy,
          child: Transform.rotate(
            angle: rotation,
            child: Icon(icon, size: size, color: color),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.primary.withValues(alpha: 0.28);
    final faint = scheme.primary.withValues(alpha: 0.18);

    return IgnorePointer(
      ignoring: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return Stack(
            children: [
              _icon(
                left: w * 0.08,
                top: h * 0.10,
                size: 44,
                icon: Icons.smartphone,
                color: base,
                phase: 0.0,
              ),
              _icon(
                left: w * 0.70,
                top: h * 0.12,
                size: 54,
                icon: Icons.laptop_mac,
                color: faint,
                phase: 1.2,
              ),
              _icon(
                left: w * 0.16,
                top: h * 0.55,
                size: 50,
                icon: Icons.memory,
                color: faint,
                phase: 2.4,
              ),
              _icon(
                left: w * 0.78,
                top: h * 0.48,
                size: 46,
                icon: Icons.battery_full,
                color: base,
                phase: 3.4,
              ),
              _icon(
                left: w * 0.58,
                top: h * 0.72,
                size: 56,
                icon: Icons.settings_input_component,
                color: faint,
                phase: 4.2,
              ),
              _icon(
                left: w * 0.08,
                top: h * 0.78,
                size: 52,
                icon: Icons.cable,
                color: base,
                phase: 5.0,
              ),
            ],
          );
        },
      ),
    );
  }
}
