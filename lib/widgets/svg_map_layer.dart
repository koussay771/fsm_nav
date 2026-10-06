// lib/widgets/svg_map_layer.dart
// Renders the SVG overlay. Tap handling delegates to NavProvider.onFeatureTapped().

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';

class SvgMapLayer extends StatelessWidget {
  final double svgWidth;
  final double svgHeight;
  const SvgMapLayer({super.key, required this.svgWidth, required this.svgHeight});

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (d) => _onTap(d, context, nav),
      child: SvgPicture.asset(
        'assets/features.svg',
        width: svgWidth, height: svgHeight,
        fit: BoxFit.fill,
        placeholderBuilder: (_) => const SizedBox.expand(),
      ),
    );
  }

  void _onTap(TapUpDetails d, BuildContext ctx, NavProvider nav) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    final tapX = (local.dx / box.size.width)  * svgWidth;
    final tapY = (local.dy / box.size.height) * svgHeight;

    const tol = 55.0;
    String? bestId;
    double bestDist = tol + 1;

    for (final node in nav.allNodes) {
      if (node.id.startsWith('wp_')) continue;
      final dist = ((node.x - tapX).abs() + (node.y - tapY).abs());
      if (dist < bestDist) { bestDist = dist; bestId = node.id; }
    }
    if (bestId != null) nav.onFeatureTapped(bestId);
  }
}
