// lib/widgets/route_painter.dart
// Draws the Dijkstra route as an animated glowing polyline + S/D markers.
// Coordinates come 100% from NavResult.path (SVG graph nodes).

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/map_node.dart';
import '../theme/app_theme.dart';

class RoutePainter extends CustomPainter {
  final List<MapNode> path;
  final double svgWidth;
  final double svgHeight;
  final double animValue; // 0..1 from AnimationController

  const RoutePainter({
    required this.path,
    required this.svgWidth,
    required this.svgHeight,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (path.isEmpty) return;

    final sx = size.width  / svgWidth;
    final sy = size.height / svgHeight;
    final pts = path.map((n) => Offset(n.x * sx, n.y * sy)).toList();

    if (pts.length == 1) {
      _drawMarker(canvas, pts.first, isStart: true);
      return;
    }

    // Build path object once
    final routePath = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) { routePath.lineTo(pts[i].dx, pts[i].dy); }

    // ── Outer glow ────────────────────────────────────────────────────────
    canvas.drawPath(
      routePath,
      Paint()
        ..color = AppTheme.routeColor.withValues(alpha: 0.28)
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // ── Solid base line ───────────────────────────────────────────────────
    canvas.drawPath(
      routePath,
      Paint()
        ..color = AppTheme.routeColor
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    // ── Animated white dashes ─────────────────────────────────────────────
    _paintDashes(canvas, pts);

    // ── Start / Destination markers ───────────────────────────────────────
    _drawMarker(canvas, pts.first, isStart: true);
    _drawMarker(canvas, pts.last,  isStart: false);
  }

  void _paintDashes(Canvas canvas, List<Offset> pts) {
    const dashLen = 14.0, gapLen = 10.0;
    final period = dashLen + gapLen;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    double carry = animValue * period;
    for (int i = 0; i < pts.length - 1; i++) {
      final a = pts[i], b = pts[i + 1];
      final segLen = (b - a).distance;
      if (segLen == 0) continue;
      final dir = (b - a) / segLen;
      double pos = 0;
      while (pos < segLen) {
        final phase = carry % period;
        if (phase < dashLen) {
          final take = min(dashLen - phase, segLen - pos);
          canvas.drawLine(a + dir * pos, a + dir * (pos + take), dashPaint);
          pos   += take;
          carry += take;
        } else {
          final skip = min(period - phase, segLen - pos);
          pos   += skip;
          carry += skip;
        }
      }
    }
  }

  void _drawMarker(Canvas canvas, Offset center, {required bool isStart}) {
    final color = isStart ? AppTheme.startColor : AppTheme.destColor;

    // Pulse ring
    canvas.drawCircle(center, 20,
        Paint()..color = color.withValues(alpha: 0.22)..style = PaintingStyle.fill);
    // White border
    canvas.drawCircle(center, 13,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
    // Coloured fill
    canvas.drawCircle(center, 10,
        Paint()..color = color..style = PaintingStyle.fill);
    // Letter
    final tp = TextPainter(
      text: TextSpan(
        text: isStart ? 'A' : 'B',
        style: const TextStyle(color: Colors.white, fontSize: 10,
            fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(RoutePainter old) =>
      old.path != path || old.animValue != animValue;
}
