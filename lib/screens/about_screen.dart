// lib/screens/about_screen.dart
// About / info screen with campus details and app info.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Text(
          'À propos',
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: const Icon(Icons.info_rounded, color: AppTheme.accent),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 20),
          _buildSection('Navigation', [
            _InfoRow(icon: Icons.route_rounded, color: AppTheme.routeColor,
                label: 'Algorithme', value: 'Dijkstra (chemin le plus court)'),
            _InfoRow(icon: Icons.hub_rounded, color: AppTheme.accent,
                label: 'Moteur', value: 'Graphe pondéré SVG'),
            _InfoRow(icon: Icons.zoom_in_rounded, color: AppTheme.startColor,
                label: 'Zoom', value: 'x0.5 — x6.0'),
            _InfoRow(icon: Icons.speed_rounded, color: const Color(0xFFFFCC00),
                label: 'Vitesse piéton', value: '1.4 m/s (84 m/min)'),
          ]),
          const SizedBox(height: 16),
          _buildSection('Campus FSM', [
            _InfoRow(icon: Icons.location_city_rounded, color: AppTheme.accent,
                label: 'Établissement',
                value: 'Faculté des Sciences de Monastir'),
            _InfoRow(icon: Icons.place_rounded, color: AppTheme.destColor,
                label: 'Adresse', value: 'Avenue de l\'environnement, 5000 Monastir'),
            _InfoRow(icon: Icons.school_rounded, color: AppTheme.startColor,
                label: 'Fondée', value: '1986'),
            _InfoRow(icon: Icons.people_rounded, color: const Color(0xFFFFCC00),
                label: 'Étudiants', value: '~5000'),
          ]),
          const SizedBox(height: 16),
          _buildSection('Application', [
            _InfoRow(icon: Icons.flutter_dash_rounded, color: AppTheme.accent,
                label: 'Framework', value: 'Flutter 3.x (Web + Mobile)'),
            _InfoRow(icon: Icons.code_rounded, color: AppTheme.startColor,
                label: 'Architecture', value: 'Clean Architecture + Provider'),
            _InfoRow(icon: Icons.map_rounded, color: AppTheme.routeColor,
                label: 'Carte', value: 'SVG interactif + PNG raster'),
            _InfoRow(icon: Icons.tag_rounded, color: const Color(0xFFFFCC00),
                label: 'Version', value: '1.0.0'),
          ]),
          const SizedBox(height: 20),
          _buildTechBadges(),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2040), Color(0xFF0A3060)],
        ),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.2),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.accent]),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accent.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.map_rounded, color: Colors.white, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            'FSM Navigator',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Navigation interactive du campus\nFaculté des Sciences de Monastir',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppTheme.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1C2B45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2E3A55)),
          ),
          child: Column(
            children: children
                .expand((w) => [w, const Divider(color: Color(0xFF1A2840), height: 1)])
                .toList()
              ..removeLast(),
          ),
        ),
      ],
    );
  }

  Widget _buildTechBadges() {
    final techs = [
      ('Flutter', Icons.flutter_dash_rounded, AppTheme.accent),
      ('Dart', Icons.code_rounded, const Color(0xFF00D2FF)),
      ('Provider', Icons.hub_rounded, AppTheme.startColor),
      ('SVG', Icons.draw_rounded, AppTheme.routeColor),
      ('Dijkstra', Icons.route_rounded, const Color(0xFFFFCC00)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: techs.map((t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: t.$3.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: t.$3.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(t.$2, color: t.$3, size: 14),
            const SizedBox(width: 6),
            Text(
              t.$1,
              style: GoogleFonts.inter(
                  color: t.$3, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
                color: const Color(0xFF7B8FAB), fontSize: 13),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
