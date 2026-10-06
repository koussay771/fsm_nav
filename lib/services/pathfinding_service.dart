// lib/services/pathfinding_service.dart
//
// Pure Dijkstra shortest-path engine operating exclusively on
// the graph produced by SvgParser. ZERO hardcoded nodes or edges.

import 'dart:ui';

import '../models/map_node.dart';
import '../models/map_edge.dart';
import '../models/nav_result.dart';
import 'svg_parser.dart';

class PathfindingService {
  // ── Internal state ───────────────────────────────────────────────────────
  SvgGraph? _graph;

  // Calibration: SVG units per real-world metre.
  // ViewBox is 773 x 614 for ~250m campus width => ~3.1 pixels per metre.
  static const double _pixelsPerMeter = 3.2;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  bool get isReady => _graph != null && !_graph!.isEmpty;

  /// Parse features.svg and build the graph. Call once at app start.
  Future<void> initialize({String assetPath = 'assets/features.svg'}) async {
    _graph = await SvgParser.load(assetPath);
  }

  // ── Public accessors ─────────────────────────────────────────────────────

  double get svgWidth  => _graph?.svgWidth  ?? SvgParser.kMapWidth;
  double get svgHeight => _graph?.svgHeight ?? SvgParser.kMapHeight;
  Rect get pngBounds => _graph?.pngBounds ?? const Rect.fromLTWH(0, 0, SvgParser.kMapWidth, SvgParser.kMapHeight);

  Map<String, MapNode> get nodes => _graph?.nodes ?? {};

  /// Returns only user-selectable named destinations (excludes internal waypoints)
  List<MapNode> get allNodes {
    final seen = <String>{};
    final list = <MapNode>[];
    for (final n in (_graph?.nodes.values ?? <MapNode>[])) {
      if (n.id.startsWith('wp_')) continue;
      // Filter out duplicate aliases that point to the exact same node object
      if (seen.add(n.id)) {
        list.add(n);
      }
    }
    list.sort((a, b) => a.label.compareTo(b.label));
    return list;
  }

  List<MapNode> nodesByType(NodeType t) =>
      allNodes.where((n) => n.type == t).toList();

  // ── Pathfinding ──────────────────────────────────────────────────────────

  /// Returns the shortest [NavResult] from [startId] to [destId],
  /// or `null` if there is no connected path.
  NavResult? findPath(String startId, String destId) {
    final graph = _graph;
    if (graph == null) return null;
    return findPathInGraph(graph, startId, destId);
  }

  /// Finds shortest path directly in any [SvgGraph].
  NavResult? findPathInGraph(SvgGraph graph, String startId, String destId) {
    String actualStart = graph.nodes[startId]?.id ?? SvgParser.normalizeId(startId);
    String actualDest = graph.nodes[destId]?.id ?? SvgParser.normalizeId(destId);

    if (!graph.nodes.containsKey(actualStart)) {
      actualStart = SvgParser.normalizeId(startId);
    }
    if (!graph.nodes.containsKey(actualDest)) {
      actualDest = SvgParser.normalizeId(destId);
    }

    if (!graph.nodes.containsKey(actualStart) ||
        !graph.nodes.containsKey(actualDest)) {
      return null;
    }
    if (actualStart == actualDest) {
      return NavResult(
        path: [graph.nodes[actualStart]!],
        totalDistance: 0,
        realDistanceM: 0,
        estimatedSeconds: 0,
      );
    }
    return _dijkstra(graph, actualStart, actualDest);
  }

  // ── Dijkstra ─────────────────────────────────────────────────────────────

  NavResult? _dijkstra(SvgGraph graph, String startId, String destId) {
    final dist = <String, double>{};
    final prev = <String, String?>{};
    final visited = <String>{};

    for (final id in graph.nodes.keys) {
      dist[id] = double.infinity;
      prev[id] = null;
    }
    dist[startId] = 0.0;

    final queue = <String>{startId};

    while (queue.isNotEmpty) {
      final u = queue.reduce(
          (a, b) => (dist[a] ?? double.infinity) < (dist[b] ?? double.infinity) ? a : b);
      queue.remove(u);
      if (visited.contains(u)) continue;
      visited.add(u);
      if (u == destId) break;

      for (final edge in graph.adjacency[u] ?? <MapEdge>[]) {
        final v = edge.to.id;
        if (visited.contains(v)) continue;
        final alt = dist[u]! + edge.weight;
        if (alt < (dist[v] ?? double.infinity)) {
          dist[v] = alt;
          prev[v] = u;
          queue.add(v);
        }
      }
    }

    if ((dist[destId] ?? double.infinity) == double.infinity) return null;

    // Reconstruct full path including all corridor waypoints so the route polyline
    // accurately follows the exact vector curves and turns over the map.
    final path = <MapNode>[];
    String? cur = destId;
    while (cur != null) {
      path.insert(0, graph.nodes[cur]!);
      cur = prev[cur];
    }

    return NavResult.fromPath(
      path, // Full polyline path
      dist[destId]!,
      _pixelsPerMeter,
    );
  }
}
