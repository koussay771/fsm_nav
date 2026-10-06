// lib/widgets/destination_pins_layer.dart
//
// Renders clean, unobtrusive destination pins/markers on top of the PNG map.
// NO blue blocks or colored building rectangles.
// Only pins at node locations (departments, parking, entrances, amenities).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/map_node.dart';
import '../providers/nav_provider.dart';
import '../theme/app_theme.dart';

class DestinationPinsLayer extends StatelessWidget {
  final double svgWidth;
  final double svgHeight;
  final NavProvider nav;

  const DestinationPinsLayer({
    super.key,
    required this.svgWidth,
    required this.svgHeight,
    required this.nav,
  });

  @override
  Widget build(BuildContext context) {
    final nodes = nav.allNodes.where((n) => !n.id.startsWith('wp_')).toList();

    return LayoutBuilder(
      builder: (ctx, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final sx = w / svgWidth;
        final sy = h / svgHeight;

        return Stack(
          children: nodes.map((node) {
            final isStart = nav.startNode?.id == node.id;
            final isDest = nav.destNode?.id == node.id;
            final isHighlighted = nav.highlightedId == node.id;

            final px = node.x * sx;
            final py = node.y * sy;

            return Positioned(
              left: px - 60,
              top: py - 38,
              width: 120,
              height: 50,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => nav.onFeatureTapped(node.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPinIcon(node, isStart, isDest, isHighlighted),
                    const SizedBox(height: 2),
                    _buildPinBadge(node, isStart, isDest, isHighlighted),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPinIcon(
      MapNode node, bool isStart, bool isDest, bool isHighlighted) {
    if (isStart) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.startColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.startColor.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.my_location_rounded,
            color: Colors.white, size: 12),
      );
    }

    if (isDest) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppTheme.destColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppTheme.destColor.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(Icons.place_rounded, color: Colors.white, size: 13),
      );
    }

    // Default pin style by node type
    final color = _colorForType(node.type);
    final icon = _iconForType(node.type);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: isHighlighted
            ? color
            : const Color(0xFF132238).withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(
          color: isHighlighted ? Colors.white : color.withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: isHighlighted ? Colors.white : color,
        size: 10,
      ),
    );
  }

  Widget _buildPinBadge(
      MapNode node, bool isStart, bool isDest, bool isHighlighted) {
    final bgColor = isStart
        ? AppTheme.startColor
        : (isDest
            ? AppTheme.destColor
            : (isHighlighted
                ? AppTheme.primary
                : const Color(0xFF0F1B2D).withValues(alpha: 0.85)));

    final textColor = isStart || isDest || isHighlighted
        ? Colors.white
        : Colors.white.withValues(alpha: 0.9);

    final String displayLabel;
    if (isStart) {
      displayLabel = 'DÉPART';
    } else if (isDest) {
      displayLabel = 'ARRIVÉE';
    } else {
      displayLabel = node.label;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: isStart || isDest
              ? Colors.white
              : Colors.white.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Text(
        displayLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: (isStart || isDest) ? 9 : 8,
          fontWeight: (isStart || isDest) ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }

  Color _colorForType(NodeType t) => switch (t) {
        NodeType.entrance => const Color(0xFF34C759),
        NodeType.department => const Color(0xFF00AAFF),
        NodeType.parking => const Color(0xFFFFCC00),
        NodeType.amenity => const Color(0xFF9D65CD),
        NodeType.waypoint => Colors.white38,
      };

  IconData _iconForType(NodeType t) => switch (t) {
        NodeType.entrance => Icons.door_front_door_rounded,
        NodeType.department => Icons.school_rounded,
        NodeType.parking => Icons.local_parking_rounded,
        NodeType.amenity => Icons.info_outline_rounded,
        NodeType.waypoint => Icons.circle,
      };
}
