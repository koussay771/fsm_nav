// lib/screens/map_screen.dart
//
// Main map screen:
//   InteractiveViewer
//     └─ AspectRatio (matches 872 / 720)
//          └─ Stack (clipBehavior: Clip.hardEdge)
//               ├─ [0] Image.asset(INTERACTIVE MAP.png)   ← Base raster campus map (100% visible)
//               ├─ [1] SvgPicture.asset(TRACKS_OVERLAY)   ← 1:1 Vector tracks overlay
//               ├─ [2] DestinationPinsLayer               ← Destination pins/markers
//               ├─ [3] _HitLayer                          ← Transparent tap-catcher
//               └─ [4] RouteOverlay                       ← 1:1 Animated red route

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/destination_pins_layer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/nav_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/route_overlay.dart';
import '../widgets/search_panel.dart';
import '../widgets/legend_panel.dart';
import '../models/map_node.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _txCtrl = TransformationController();

  @override
  void dispose() { _txCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();

    if (nav.status == NavStatus.loading && nav.allNodes.isEmpty) {
      return _buildSplashLoading();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D1520),
      body: Stack(
        children: [
          // ── Full-screen pan/zoom map ─────────────────────────────────
          Positioned.fill(
            child: InteractiveViewer(
              transformationController: _txCtrl,
              minScale: 1.0,
              maxScale: 6.0,
              boundaryMargin: EdgeInsets.zero,
              clipBehavior: Clip.hardEdge,
              child: Center(
                child: _buildMapContent(nav),
              ),
            ),
          ),

          // ── Search panel (top-left / full-width mobile) ──────────────
          const SearchPanel(),

          // ── Legend (bottom-right) ─────────────────────────────────────
          const LegendPanel(),

          // ── Zoom controls (bottom-left) ───────────────────────────────
          _buildZoomControls(),

          // ── Graph stats badge (top-right) ─────────────────────────────
          _buildStatBadge(nav),

          // ── No-path banner ────────────────────────────────────────────
          if (nav.status == NavStatus.noPath) _buildNoPathBanner(),
        ],
      ),
    );
  }

  // ── MAP CONTENT STACK ─────────────────────────────────────────────────────
  Widget _buildMapContent(NavProvider nav) {
    final svgW = nav.svgWidth;
    final svgH = nav.svgHeight;
    final bounds = nav.pngBounds;

    return Center(
      child: AspectRatio(
        aspectRatio: svgW / svgH,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final scaleX = constraints.maxWidth / svgW;
          final scaleY = constraints.maxHeight / svgH;

          final pngLeft = bounds.left * scaleX;
          final pngTop = bounds.top * scaleY;
          final pngWidth = bounds.width * scaleX;
          final pngHeight = bounds.height * scaleY;

          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Layer 0: Base Map PNG (aligned to border-excat-of-png bounds) ──
              // NOTE: Flutter Web double-encodes spaces in asset URLs (%20→%2520)
              // so we use the underscore variant INTERACTIVE_MAP.png as primary.
              Positioned(
                left: pngLeft,
                top: pngTop,
                width: pngWidth,
                height: pngHeight,
                child: Image.asset(
                  'assets/images/INTERACTIVE_MAP.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/single_bloc.png',
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, __, ___) => _GridFallback(w: svgW, h: svgH),
                  ),
                ),
              ),

              // ── Layer 1: SVG Tracks Overlay (1:1 directly stacked over PNG with zero offset) ──
              Positioned.fill(
                child: SvgPicture.asset(
                  'assets/images/TRACKS_OVERLAY.svg',
                  fit: BoxFit.fill,
                  placeholderBuilder: (_) => const SizedBox.expand(),
                ),
              ),

              // ── Layer 2: Clean destination pins/markers (no solid blocks) ───
              Positioned.fill(
                child: DestinationPinsLayer(
                  svgWidth: svgW,
                  svgHeight: svgH,
                  nav: nav,
                ),
              ),

              // ── Layer 3: Transparent tap-hit layer ────────────────────
              Positioned.fill(
                child: _HitLayer(svgW: svgW, svgH: svgH, nav: nav),
              ),

              // ── Layer 4: Animated route overlay (1:1 identical bounds) ───────
              const Positioned.fill(child: RouteOverlay()),
            ],
          );
        }),
      ),
    );
  }

  // ── ZOOM CONTROLS ─────────────────────────────────────────────────────────
  Widget _buildZoomControls() {
    return Positioned(
      bottom: 28,
      left: 16,
      child: Column(
        children: [
          _ZoomBtn(icon: Icons.add_rounded,        onTap: () => _zoom(1.35)),
          const SizedBox(height: 6),
          _ZoomBtn(icon: Icons.remove_rounded,     onTap: () => _zoom(1 / 1.35)),
          const SizedBox(height: 6),
          _ZoomBtn(icon: Icons.fit_screen_rounded, onTap: _reset),
        ],
      ),
    );
  }

  void _zoom(double f) {
    final cur = _txCtrl.value.clone();
    final cx = MediaQuery.of(context).size.width  / 2;
    final cy = MediaQuery.of(context).size.height / 2;
    final mat = Matrix4.identity()
      ..translateByDouble(cx, cy, 0, 1)
      ..scaleByDouble(f, f, 1.0, 1.0)
      ..translateByDouble(-cx, -cy, 0, 1);
    _txCtrl.value = mat * cur;
  }

  void _reset() => _txCtrl.value = Matrix4.identity();

  // ── STAT BADGE ────────────────────────────────────────────────────────────
  Widget _buildStatBadge(NavProvider nav) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 12,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C2B45).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hub_rounded, color: AppTheme.accent, size: 14),
            const SizedBox(width: 6),
            Text(
              '${nav.allNodes.where((n) => !n.id.startsWith("wp_")).length} lieux',
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ── NO-PATH BANNER ────────────────────────────────────────────────────────
  Widget _buildNoPathBanner() {
    return Positioned(
      bottom: 100,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.destColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.destColor.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppTheme.destColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Aucun chemin trouvé entre ces deux points.',
                style: GoogleFonts.inter(
                    color: AppTheme.destColor, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LOADING SCREEN ────────────────────────────────────────────────────────
  Widget _buildSplashLoading() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.accent]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.map_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text('FSM Navigator',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Analyse du graphe SVG en cours…',
                style: GoogleFonts.inter(
                    color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 28),
            const SizedBox(
              width: 36, height: 36,
              child: CircularProgressIndicator(
                  color: AppTheme.accent, strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HIT LAYER ────────────────────────────────────────────────────────────────
// A transparent GestureDetector that converts tap coordinates to SVG space
// and dispatches to NavProvider.onFeatureTapped(svgId).
class _HitLayer extends StatelessWidget {
  final double svgW, svgH;
  final NavProvider nav;

  const _HitLayer({required this.svgW, required this.svgH, required this.nav});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (d) => _onTap(d, context),
    );
  }

  void _onTap(TapUpDetails d, BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final local = box.globalToLocal(d.globalPosition);
    final tapX = (local.dx / box.size.width)  * svgW;
    final tapY = (local.dy / box.size.height) * svgH;

    // Find the nearest named node within tap tolerance.
    const kTolerance = 48.0; // Map units
    MapNode? best;
    double bestDist2 = kTolerance * kTolerance;

    for (final node in nav.allNodes) {
      if (node.id.startsWith('wp_')) continue; // skip anonymous waypoints
      final dx = node.x - tapX;
      final dy = node.y - tapY;
      final d2 = dx * dx + dy * dy;
      if (d2 < bestDist2) {
        bestDist2 = d2;
        best = node;
      }
    }

    if (best != null) {
      nav.onFeatureTapped(best.id);
      _snack(ctx, best);
    }
  }

  void _snack(BuildContext ctx, MapNode node) {
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Row(children: [
          Icon(_iconFor(node.type), color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(node.label,
              style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
        backgroundColor: AppTheme.surfaceCard,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ));
  }

  IconData _iconFor(NodeType t) => switch (t) {
    NodeType.entrance   => Icons.door_front_door_outlined,
    NodeType.department => Icons.school_outlined,
    NodeType.parking    => Icons.local_parking_rounded,
    NodeType.amenity    => Icons.star_outline_rounded,
    NodeType.waypoint   => Icons.radio_button_unchecked,
  };
}

// ── ZOOM BUTTON ───────────────────────────────────────────────────────────────
class _ZoomBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2B45).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(
            color: Colors.black.withValues(alpha: 0.35), blurRadius: 8)],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

// ── GRID FALLBACK ─────────────────────────────────────────────────────────────
// Shown only when INTERACTIVE_MAP.png is missing from assets.
// Does NOT draw coloured building boxes — just a neutral dark grid.
class _GridFallback extends StatelessWidget {
  final double w, h;
  const _GridFallback({required this.w, required this.h});

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _GridPainter(),
    child: const SizedBox.expand(),
  );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFF0D1825));
    final p = Paint()..color = const Color(0xFF1A2840)..strokeWidth = 0.6;
    const step = 50.0;
    for (double x = 0; x < size.width;  x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }
  @override bool shouldRepaint(_GridPainter o) => false;
}
