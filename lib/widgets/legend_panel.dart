// lib/widgets/legend_panel.dart
// Compact floating legend & compass widget.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class LegendPanel extends StatelessWidget {
  const LegendPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF1C2B45).withValues(alpha: 0.95),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Légende',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            _LegendItem(color: AppTheme.startColor, icon: Icons.my_location_rounded, label: 'Départ'),
            _LegendItem(color: AppTheme.destColor, icon: Icons.location_on_rounded, label: 'Destination'),
            _LegendItem(color: AppTheme.routeColor, icon: Icons.timeline_rounded, label: 'Itinéraire'),
            _LegendItem(color: AppTheme.accent, icon: Icons.school_rounded, label: 'Département'),
            _LegendItem(color: const Color(0xFFFFCC00), icon: Icons.local_parking_rounded, label: 'Parking'),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _LegendItem({required this.color, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(color: const Color(0xFFB8C4D8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
