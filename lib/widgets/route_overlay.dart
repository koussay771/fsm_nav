// lib/widgets/route_overlay.dart
// Animated CustomPaint layer that sits over the map stack.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import 'route_painter.dart';

class RouteOverlay extends StatefulWidget {
  const RouteOverlay({super.key});
  @override
  State<RouteOverlay> createState() => _RouteOverlayState();
}

class _RouteOverlayState extends State<RouteOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    if (!nav.hasResult) return const SizedBox.expand();

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        painter: RoutePainter(
          path:      nav.result!.path,
          svgWidth:  nav.svgWidth,
          svgHeight: nav.svgHeight,
          animValue: _ctrl.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}
