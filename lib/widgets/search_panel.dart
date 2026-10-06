// lib/widgets/search_panel.dart
// Floating glassmorphic panel.
// CRITICAL: dropdowns are populated ONLY from nav.allNodes (parsed SVG).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/map_node.dart';
import '../providers/nav_provider.dart';
import '../theme/app_theme.dart';

class SearchPanel extends StatefulWidget {
  const SearchPanel({super.key});
  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fadeAnim;
  bool _expanded = true;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.reverse() : _ctrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      left: isCompact ? 12 : 20,
      right: isCompact ? 12 : null,
      width: isCompact ? null : 344,
      child: _buildCard(context, isCompact),
    );
  }

  Widget _buildCard(BuildContext context, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1C2B45).withValues(alpha: 0.97),
            const Color(0xFF111827).withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
            color: AppTheme.primary.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppTheme.primary.withValues(alpha: 0.14),
              blurRadius: 24, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 16),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          SizeTransition(
            sizeFactor: ReverseAnimation(_fadeAnim),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(color: Color(0xFF2E3A55), height: 1),
                _buildBody(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggle,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('FSM Navigator',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 15,
                        fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                Text('Faculté des Sciences de Monastir',
                    style: GoogleFonts.inter(
                        color: const Color(0xFF8899BB), fontSize: 11)),
              ]),
            ),
            AnimatedRotation(
              turns: _expanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 240),
              child: const Icon(Icons.keyboard_arrow_up_rounded,
                  color: Color(0xFF8899BB)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final nav = context.watch<NavProvider>();

    // Nodes sourced exclusively from the parsed SVG (no hardcoded lists)
    final named = nav.allNodes.where((n) => !n.id.startsWith('wp_')).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NodeDropdown(
            label: 'Départ',
            icon: Icons.my_location_rounded,
            color: AppTheme.startColor,
            value: nav.startNode,
            nodes: named,
            onChanged: nav.setStart,
          ),
          const SizedBox(height: 10),
          _NodeDropdown(
            label: 'Destination',
            icon: Icons.location_on_rounded,
            color: AppTheme.destColor,
            value: nav.destNode,
            nodes: named,
            onChanged: nav.setDest,
          ),
          const SizedBox(height: 14),
          _buildActions(nav),
          if (nav.hasResult) ...[
            const SizedBox(height: 12),
            _buildRouteInfo(nav),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _buildActions(NavProvider nav) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed:
                nav.startNode != null && nav.destNode != null ? nav.findPath : null,
            icon: nav.status == NavStatus.loading
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.directions_walk_rounded, size: 18),
            label: const Text('Trouver le chemin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              disabledBackgroundColor: const Color(0xFF2E3A55),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: nav.reset,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF2E3A55)),
            foregroundColor: const Color(0xFF8899BB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          child: const Icon(Icons.refresh_rounded, size: 18),
        ),
      ],
    );
  }

  Widget _buildRouteInfo(NavProvider nav) {
    final r = nav.result!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _InfoChip(icon: Icons.straighten_rounded,
              label: r.distanceLabel, color: AppTheme.accent),
          Container(width: 1, height: 28, color: const Color(0xFF2E3A55)),
          _InfoChip(icon: Icons.directions_walk_rounded,
              label: r.timeLabel, color: AppTheme.startColor),
          Container(width: 1, height: 28, color: const Color(0xFF2E3A55)),
          _InfoChip(icon: Icons.route_rounded,
              label: '${r.path.length} étapes', color: AppTheme.routeColor),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _NodeDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final MapNode? value;
  final List<MapNode> nodes;
  final void Function(MapNode?) onChanged;

  const _NodeDropdown({
    required this.label, required this.icon, required this.color,
    required this.value, required this.nodes, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.inter(
                  color: color, fontSize: 11,
                  fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ]),
        const SizedBox(height: 5),
        DropdownButtonFormField<MapNode>(
          initialValue: value,
          isExpanded: true,
          hint: Text('Choisir un lieu...',
              style: GoogleFonts.inter(
                  color: const Color(0xFF556080), fontSize: 13)),
          dropdownColor: const Color(0xFF1C2B45),
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF8899BB)),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            prefixIcon: Icon(icon, color: color, size: 16),
          ),
          items: nodes.map((n) => DropdownMenuItem(
            value: n,
            child: Row(children: [
              Icon(_typeIcon(n.type), size: 13,
                  color: color.withValues(alpha: 0.7)),
              const SizedBox(width: 7),
              Expanded(
                child: Text(n.label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 13)),
              ),
            ]),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  IconData _typeIcon(NodeType t) => switch (t) {
    NodeType.entrance   => Icons.door_front_door_outlined,
    NodeType.department => Icons.school_outlined,
    NodeType.parking    => Icons.local_parking_rounded,
    NodeType.amenity    => Icons.star_outline_rounded,
    NodeType.waypoint   => Icons.radio_button_unchecked,
  };
}

class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 15),
      const SizedBox(height: 3),
      Text(label,
          style: GoogleFonts.inter(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
    ],
  );
}
