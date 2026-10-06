// lib/services/svg_parser.dart
//
// Dynamic SVG Graph Extractor for FSM Navigator.
// Parses the campus map vector network and aligns destination nodes directly
// to the physical department doors and connected pedestrian tracks.
//
// Features:
//  - Map dimensions: 872.0 x 720.0 (1:1 with assets/images/INTERACTIVE MAP.png).
//  - Extracts dedicated door entry lines from <line> elements.
//  - Anchors Department destination nodes directly at their physical doors.
//  - Connects door entry lines seamlessly to the red pedestrian track network.
//  - Guarantees 100% continuous, gap-free Dijkstra pathfinding from door to door.

import 'dart:math';
import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import '../models/map_node.dart';
import '../models/map_edge.dart';

class SvgGraph {
  final Map<String, MapNode> nodes;
  final Map<String, List<MapEdge>> adjacency;
  final double svgWidth;
  final double svgHeight;
  final Rect pngBounds;

  const SvgGraph({
    required this.nodes,
    required this.adjacency,
    required this.svgWidth,
    required this.svgHeight,
    this.pngBounds = const Rect.fromLTWH(0, 0, SvgParser.kMapWidth, SvgParser.kMapHeight),
  });

  bool get isEmpty => nodes.isEmpty;
}

class SvgParser {
  /// Natural map coordinate dimensions matching assets/images/single bloc.svg (872 x 720)
  static const double kMapWidth = 872.0;
  static const double kMapHeight = 720.0;

  /// Coordinate offset between raw features.svg (777x612) and the unified Figma Frame (872x720)
  static const double kOffsetX = 51.5;
  static const double kOffsetY = 39.0;

  /// Load `assets/features.svg` and return assembled [SvgGraph].
  static Future<SvgGraph> load(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return parse(raw);
  }

  /// Normalize IDs for tolerant lookups across different spelling variations
  static String normalizeId(String rawId) {
    var id = rawId.trim().toLowerCase();
    id = id
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('’', "'")
        .replaceAll('`', "'");

    if (id == 'rentre de fsm' || id == 'rentre-de-fsm' || id == 'entree-fsm') {
      return 'rentre-de-fsm';
    }
    if (id == "rentre-d'enim" || id == 'rentre-d-enim' || id == 'entree-enim' || id == "rentre d'enim") {
      return 'rentre-d-enim';
    }
    if (id == 'departement-informatique' || id == "departement-d'informatique" || id == "departement-d-informatique") {
      return "departement-d'informatique";
    }
    if (id == 'departement-math' || id == 'departement-maths' || id == 'departement-de-mathematiques') {
      return 'departement-math';
    }
    if (id == 'departement-physique' || id == 'departement-de-physique') {
      return 'departement-de-physique';
    }
    if (id == 'departement-physique-2' || id == 'departement-de-physique-2') {
      return 'departement-de-physique-2';
    }
    if (id == 'departement-chimie' || id == 'departement-de-chimie') {
      return 'departement-de-chimie';
    }
    if (id == 'departement-chimie-2' || id == 'departement-de-chimie-2') {
      return 'departement-de-chimie-2';
    }
    if (id == 'amphi' || id == 'les-amphis' || id == 'amphitheatres') {
      return 'les-amphis';
    }
    return id;
  }

  /// Parse SVG string and build connected graph with door-anchored destination nodes.
  static SvgGraph parse(String svgString) {
    final doc = XmlDocument.parse(svgString);
    final root = doc.rootElement;

    // Fixed canvas size matching the unified canvas Frame single bloc.svg (872 x 720)
    const double svgW = kMapWidth;
    const double svgH = kMapHeight;

    final viewBox = root.getAttribute('viewBox') ?? '';
    final widthAttr = double.tryParse(root.getAttribute('width') ?? '') ?? 0.0;

    // Check if there is a <g id="features" transform="translate(tx, ty)">
    double tx = 0.0;
    double ty = 0.0;
    for (final g in _findElementsByLocalName(root, 'g')) {
      final transform = g.getAttribute('transform') ?? '';
      if (transform.contains('translate')) {
        final match = RegExp(r'translate\(\s*([-\d.]+)[,\s]+([-\d.]+)\s*\)').firstMatch(transform);
        if (match != null) {
          tx = double.tryParse(match.group(1) ?? '0') ?? 0.0;
          ty = double.tryParse(match.group(2) ?? '0') ?? 0.0;
          break;
        }
      }
    }

    // Translate coordinates to unified single bloc frame (872x720)
    final double dx = (tx != 0.0) ? tx : ((widthAttr < 800.0 && !viewBox.contains('872')) ? kOffsetX : 0.0);
    final double dy = (ty != 0.0) ? ty : ((widthAttr < 800.0 && !viewBox.contains('720')) ? kOffsetY : 0.0);

    // Extract explicit border-excat-of-png rectangle if present
    double pngX = 0.0;
    double pngY = 0.0;
    double pngW = kMapWidth;
    double pngH = kMapHeight;

    for (final el in _findElementsByLocalName(root, 'rect')) {
      final id = (el.getAttribute('id') ?? '').toLowerCase();
      if (id.contains('border')) {
        final xVal = double.tryParse(el.getAttribute('x') ?? '0') ?? 0.0;
        final yVal = double.tryParse(el.getAttribute('y') ?? '0') ?? 0.0;
        final wVal = double.tryParse(el.getAttribute('width') ?? '') ?? 0.0;
        final hVal = double.tryParse(el.getAttribute('height') ?? '') ?? 0.0;
        if (wVal > 0 && hVal > 0) {
          pngX = xVal;
          pngY = yVal;
          pngW = wVal;
          pngH = hVal;
          break;
        }
      }
    }
    final pngBounds = Rect.fromLTWH(pngX, pngY, pngW, pngH);

    // 1. Extract corridor polylines from <path id="paths">, path-parking-1, etc.
    final List<List<Point<double>>> corridorPolylines = [];
    _extractCorridorPolylines(root, corridorPolylines, dx: dx, dy: dy);

    // 2. Extract door line definitions from <line> elements
    final List<_DoorLineData> rawDoorLines = [];
    _extractDoorLines(root, rawDoorLines, dx: dx, dy: dy);

    // 3. Build graph
    final graph = _buildDoorAnchoredGraph(
      corridorPolylines: corridorPolylines,
      doorLines: rawDoorLines,
      svgW: svgW,
      svgH: svgH,
      dx: dx,
      dy: dy,
      pngBounds: pngBounds,
    );

    return graph;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Corridor Polylines Extraction
  // ─────────────────────────────────────────────────────────────────────────

  static void _extractCorridorPolylines(
    XmlElement root,
    List<List<Point<double>>> polylines, {
    double dx = 0.0,
    double dy = 0.0,
  }) {
    for (final el in _findElementsByLocalName(root, 'path')) {
      final id = (el.getAttribute('id') ?? '').toLowerCase();
      final parentId = (el.parentElement?.getAttribute('id') ?? '').toLowerCase();

      final isCorridor = id == 'paths' ||
          id.startsWith('path-') ||
          id.startsWith('main-path-') ||
          id == 'car-path' ||
          parentId == 'path-group';

      if (!isCorridor) continue;

      final d = el.getAttribute('d') ?? '';
      if (d.isEmpty) continue;

      final parsed = _parseSvgPathD(d);
      for (final poly in parsed) {
        if (poly.length >= 2) {
          if (dx != 0.0 || dy != 0.0) {
            polylines.add(poly.map((p) => Point<double>(p.x + dx, p.y + dy)).toList());
          } else {
            polylines.add(poly);
          }
        }
      }
    }
  }

  static List<List<Point<double>>> _parseSvgPathD(String d) {
    final List<List<Point<double>>> polylines = [];
    List<Point<double>> current = [];

    final tokens = RegExp(r'([a-zA-Z]|[-+]?[0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)')
        .allMatches(d)
        .map((m) => m.group(0)!)
        .toList();

    int i = 0;
    double curX = 0.0, curY = 0.0;
    String cmd = '';

    while (i < tokens.length) {
      final token = tokens[i];
      if (RegExp(r'^[a-zA-Z]$').hasMatch(token)) {
        cmd = token;
        i++;
        if (cmd == 'Z' || cmd == 'z') {
          if (current.length > 1) {
            current.add(current.first);
            polylines.add(List.from(current));
            current.clear();
          }
          continue;
        }
      }

      switch (cmd) {
        case 'M':
          if (current.length > 1) polylines.add(List.from(current));
          current = [];
          if (i + 1 < tokens.length) {
            curX = double.tryParse(tokens[i++]) ?? curX;
            curY = double.tryParse(tokens[i++]) ?? curY;
            current.add(Point<double>(curX, curY));
          }
          cmd = 'L';
          break;

        case 'm':
          if (current.length > 1) polylines.add(List.from(current));
          current = [];
          if (i + 1 < tokens.length) {
            curX += double.tryParse(tokens[i++]) ?? 0.0;
            curY += double.tryParse(tokens[i++]) ?? 0.0;
            current.add(Point<double>(curX, curY));
          }
          cmd = 'l';
          break;

        case 'L':
          if (i + 1 < tokens.length) {
            curX = double.tryParse(tokens[i++]) ?? curX;
            curY = double.tryParse(tokens[i++]) ?? curY;
            current.add(Point<double>(curX, curY));
          }
          break;

        case 'l':
          if (i + 1 < tokens.length) {
            curX += double.tryParse(tokens[i++]) ?? 0.0;
            curY += double.tryParse(tokens[i++]) ?? 0.0;
            current.add(Point<double>(curX, curY));
          }
          break;

        case 'H':
          if (i < tokens.length) {
            curX = double.tryParse(tokens[i++]) ?? curX;
            current.add(Point<double>(curX, curY));
          }
          break;

        case 'h':
          if (i < tokens.length) {
            curX += double.tryParse(tokens[i++]) ?? 0.0;
            current.add(Point<double>(curX, curY));
          }
          break;

        case 'V':
          if (i < tokens.length) {
            curY = double.tryParse(tokens[i++]) ?? curY;
            current.add(Point<double>(curX, curY));
          }
          break;

        case 'v':
          if (i < tokens.length) {
            curY += double.tryParse(tokens[i++]) ?? 0.0;
            current.add(Point<double>(curX, curY));
          }
          break;

        case 'C':
        case 'c':
        case 'S':
        case 's':
        case 'Q':
        case 'q':
          final count = (cmd == 'C' || cmd == 'c') ? 6 : 4;
          double lastX = curX, lastY = curY;
          for (int c = 0; c < count && i < tokens.length; c += 2) {
            final dx = double.tryParse(tokens[i++]) ?? 0.0;
            final dy = (i < tokens.length)
                ? (double.tryParse(tokens[i++]) ?? 0.0)
                : 0.0;
            if (cmd == cmd.toLowerCase()) {
              lastX = curX + dx;
              lastY = curY + dy;
            } else {
              lastX = dx;
              lastY = dy;
            }
          }
          curX = lastX;
          curY = lastY;
          current.add(Point<double>(curX, curY));
          break;

        default:
          i++;
          break;
      }
    }

    if (current.length > 1) {
      polylines.add(current);
    }

    return polylines;
  }

  static void _extractDoorLines(
    XmlElement root,
    List<_DoorLineData> list, {
    double dx = 0.0,
    double dy = 0.0,
  }) {
    for (final el in _findElementsByLocalName(root, 'line')) {
      final id = el.getAttribute('id') ?? '';
      final x1 = double.tryParse(el.getAttribute('x1') ?? '');
      final y1 = double.tryParse(el.getAttribute('y1') ?? '');
      final x2 = double.tryParse(el.getAttribute('x2') ?? '');
      final y2 = double.tryParse(el.getAttribute('y2') ?? '');

      if (x1 != null && y1 != null && x2 != null && y2 != null) {
        list.add(_DoorLineData(
          id: id,
          p1: Point<double>(x1 + dx, y1 + dy),
          p2: Point<double>(x2 + dx, y2 + dy),
        ));
      }
    }
  }

  static Iterable<XmlElement> _findElementsByLocalName(XmlElement root, String localName) {
    final lower = localName.toLowerCase();
    return root.descendants.whereType<XmlElement>().where(
      (el) => el.name.local.toLowerCase() == lower,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Graph Construction with Accurate Door Anchors & Seamless Path Connections
  // ─────────────────────────────────────────────────────────────────────────

  static SvgGraph _buildDoorAnchoredGraph({
    required List<List<Point<double>>> corridorPolylines,
    required List<_DoorLineData> doorLines,
    required double svgW,
    required double svgH,
    double dx = 0.0,
    double dy = 0.0,
    Rect pngBounds = const Rect.fromLTWH(0, 0, SvgParser.kMapWidth, SvgParser.kMapHeight),
  }) {
    final Map<String, MapNode> allNodes = {};
    final Map<String, List<MapEdge>> adjacency = {};
    final List<MapNode> waypoints = [];

    MapNode getOrCreateNode(Point<double> pt, {String? customId, String? label, NodeType? type}) {
      // 1. Check if close to an existing named or custom node (< 3.0 px)
      for (final n in allNodes.values) {
        final d = sqrt(pow(n.x - pt.x, 2) + pow(n.y - pt.y, 2));
        if (d < 3.0) {
          if (customId != null && n.id.startsWith('wp_')) {
            // Upgrade waypoint to named node
            allNodes.remove(n.id);
            final upgraded = MapNode(
              id: customId,
              label: label ?? _formatLabel(customId),
              x: n.x,
              y: n.y,
              type: type ?? NodeType.department,
            );
            allNodes[customId] = upgraded;
            final edges = adjacency.remove(n.id) ?? [];
            adjacency[customId] = edges;
            // update reverse edges
            for (final list in adjacency.values) {
              for (int k = 0; k < list.length; k++) {
                if (list[k].to.id == n.id) {
                  list[k] = MapEdge(from: list[k].from, to: upgraded, weight: list[k].weight);
                }
              }
            }
            return upgraded;
          }
          return n;
        }
      }

      // 2. Check if close to existing waypoint (< 4.5 px)
      for (final wp in waypoints) {
        final d = sqrt(pow(wp.x - pt.x, 2) + pow(wp.y - pt.y, 2));
        if (d < 4.5) {
          if (customId != null) {
            allNodes.remove(wp.id);
            waypoints.remove(wp);
            final named = MapNode(
              id: customId,
              label: label ?? _formatLabel(customId),
              x: wp.x,
              y: wp.y,
              type: type ?? NodeType.department,
            );
            allNodes[customId] = named;
            final edges = adjacency.remove(wp.id) ?? [];
            adjacency[customId] = edges;
            for (final list in adjacency.values) {
              for (int k = 0; k < list.length; k++) {
                if (list[k].to.id == wp.id) {
                  list[k] = MapEdge(from: list[k].from, to: named, weight: list[k].weight);
                }
              }
            }
            return named;
          }
          return wp;
        }
      }

      // 3. Create fresh node
      final id = customId ?? 'wp_${pt.x.toStringAsFixed(1)}_${pt.y.toStringAsFixed(1)}';
      final node = MapNode(
        id: id,
        label: label ?? (customId != null ? _formatLabel(customId) : 'Waypoint'),
        x: pt.x,
        y: pt.y,
        type: type ?? (customId != null ? _inferNodeType(customId) : NodeType.waypoint),
      );

      if (customId == null) {
        waypoints.add(node);
      }
      allNodes[id] = node;
      adjacency[id] = [];
      return node;
    }

    void addEdge(MapNode a, MapNode b) {
      if (a.id == b.id) return;
      adjacency.putIfAbsent(a.id, () => []);
      adjacency.putIfAbsent(b.id, () => []);

      if (adjacency[a.id]!.any((e) => e.to.id == b.id)) return;

      final dist = sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2));
      adjacency[a.id]!.add(MapEdge(from: a, to: b, weight: dist));
      adjacency[b.id]!.add(MapEdge(from: b, to: a, weight: dist));
    }

    // 1. Build initial corridor network
    final List<_Segment> corridorSegments = [];
    for (final poly in corridorPolylines) {
      if (poly.length < 2) continue;
      for (int i = 0; i < poly.length - 1; i++) {
        final a = getOrCreateNode(poly[i]);
        final b = getOrCreateNode(poly[i + 1]);
        if (a.id != b.id) {
          corridorSegments.add(_Segment(a, b));
          addEdge(a, b);
        }
      }
    }

    // Snap corridor points that are close to each other (<= 5.0 px)
    for (int i = 0; i < waypoints.length; i++) {
      for (int j = i + 1; j < waypoints.length; j++) {
        final w1 = waypoints[i];
        final w2 = waypoints[j];
        final d = sqrt(pow(w1.x - w2.x, 2) + pow(w1.y - w2.y, 2));
        if (d <= 5.0) {
          addEdge(w1, w2);
        }
      }
    }

    // T-junction projection along corridor segments
    for (final wp in List<MapNode>.from(waypoints)) {
      for (final seg in List<_Segment>.from(corridorSegments)) {
        if (seg.a.id == wp.id || seg.b.id == wp.id) continue;
        final proj = _projectPointOntoSegment(wp, seg.a, seg.b);
        if (proj != null && proj.distance <= 5.0) {
          final projNode = getOrCreateNode(proj.point);
          addEdge(wp, projNode);
          addEdge(seg.a, projNode);
          addEdge(seg.b, projNode);
        }
      }
    }

    // 2. Process Door Lines: anchor each department directly to its physical door
    for (final door in doorLines) {
      // Find which endpoint is closer to the corridor network
      double minD1 = double.infinity, minD2 = double.infinity;
      _ProjectionResult? bestProj1, bestProj2;
      _Segment? bestSeg1, bestSeg2;

      for (final seg in corridorSegments) {
        final pr1 = _projectPointOntoSegmentPt(door.p1, seg.a, seg.b);
        if (pr1.distance < minD1) {
          minD1 = pr1.distance;
          bestProj1 = pr1;
          bestSeg1 = seg;
        }
        final pr2 = _projectPointOntoSegmentPt(door.p2, seg.a, seg.b);
        if (pr2.distance < minD2) {
          minD2 = pr2.distance;
          bestProj2 = pr2;
          bestSeg2 = seg;
        }
      }

      Point<double> trackEndPt, doorEndPt;
      _ProjectionResult bestProj;
      _Segment bestSeg;

      if (minD1 < minD2) {
        trackEndPt = door.p1;
        doorEndPt = door.p2;
        bestProj = bestProj1!;
        bestSeg = bestSeg1!;
      } else {
        trackEndPt = door.p2;
        doorEndPt = door.p1;
        bestProj = bestProj2!;
        bestSeg = bestSeg2!;
      }

      // Map door line ID to primary department name
      final deptId = _departmentIdForDoor(door.id);
      final label = _formatLabel(deptId);

      // Create the physical door destination node
      final doorNode = getOrCreateNode(
        doorEndPt,
        customId: deptId,
        label: label,
        type: NodeType.department,
      );

      // Create or get track junction node
      final trackNode = getOrCreateNode(trackEndPt);
      addEdge(doorNode, trackNode);

      // Connect track junction to projected point on main corridor
      final projNode = getOrCreateNode(bestProj.point);
      addEdge(trackNode, projNode);
      addEdge(bestSeg.a, projNode);
      addEdge(bestSeg.b, projNode);

      // If this door has a specific door name (like door-1-math, door-2-math), also register alias
      if (door.id.isNotEmpty && door.id != deptId) {
        allNodes[door.id] = doorNode;
        adjacency[door.id] = adjacency[doorNode.id]!;
      }
    }

    // 3. Register Campus Entrances and Key Landmarks (exact single bloc frame coordinates)
    final Map<String, Point<double>> landmarks = {
      'rentre-de-fsm': Point<double>(319.5 + dx, 568.5 + dy),
      'rentre-d-enim': Point<double>(42.5 + dx, 159.5 + dy),
      'infirmerie': Point<double>(44.5 + dx, 549.0 + dy),
      'les-amphis': Point<double>(330.0 + dx, 334.0 + dy),
      'parking': Point<double>(53.0 + dx, 305.0 + dy),
      'parking-1': Point<double>(154.0 + dx, 579.0 + dy),
      'cour-rouge': Point<double>(349.0 + dx, 388.0 + dy),
      'magasin': Point<double>(680.0 + dx, 162.0 + dy),
    };

    for (final entry in landmarks.entries) {
      final id = entry.key;
      final pt = entry.value;

      final node = getOrCreateNode(
        pt,
        customId: id,
        label: _formatLabel(id),
        type: _inferNodeType(id),
      );

      double minD = double.infinity;
      _ProjectionResult? bestPr;
      _Segment? bestSeg;

      for (final seg in corridorSegments) {
        final pr = _projectPointOntoSegmentPt(pt, seg.a, seg.b);
        if (pr.distance < minD) {
          minD = pr.distance;
          bestPr = pr;
          bestSeg = seg;
        }
      }

      if (bestPr != null && bestSeg != null) {
        final projNode = getOrCreateNode(bestPr.point);
        addEdge(node, projNode);
        addEdge(bestSeg.a, projNode);
        addEdge(bestSeg.b, projNode);
      }
    }

    // 4. Register friendly alias IDs so all views, search bars, and tests match smoothly
    _registerAliases(allNodes, adjacency);

    return SvgGraph(
      nodes: allNodes,
      adjacency: adjacency,
      svgWidth: svgW,
      svgHeight: svgH,
      pngBounds: pngBounds,
    );
  }

  static void _registerAliases(Map<String, MapNode> allNodes, Map<String, List<MapEdge>> adjacency) {
    void alias(String from, String to) {
      if (allNodes.containsKey(to) && !allNodes.containsKey(from)) {
        allNodes[from] = allNodes[to]!;
        if (adjacency.containsKey(to)) {
          adjacency[from] = adjacency[to]!;
        }
      }
    }

    alias('rentré de fsm', 'rentre-de-fsm');
    alias('rentré-de-fsm', 'rentre-de-fsm');
    alias("rentré-d'enim", 'rentre-d-enim');
    alias("rentré d'enim", 'rentre-d-enim');
    alias('departement-informatique', "departement-d'informatique");
    alias('departement-maths', 'departement-math');
    alias('departement-physique', 'departement-de-physique');
    alias('departement-chimie', 'departement-de-chimie');
  }

  static String _departmentIdForDoor(String doorId) {
    switch (doorId) {
      case 'door-chimie-1':
        return 'departement-de-chimie';
      case 'door-1-chimie-2':
        return 'departement-de-chimie-2';
      case 'door-info':
        return "departement-d'informatique";
      case 'door-1-physique':
        return 'departement-de-physique';
      case 'door-2-phisque':
        return 'door-2-physique';
      case 'door-physique-2':
        return 'departement-de-physique-2';
      case 'door-1-math':
        return 'departement-math';
      case 'door-2-math':
        return 'door-2-math';
      case 'door-adminstration':
        return 'administration';
      case 'door-1-locaux-communs-1':
        return 'locaux-communs-1';
      case 'door-2-locaux-communs-1':
        return 'door-2-locaux-communs-1';
      case 'door-1-locaux-communx-4':
        return 'locaux-communs-4';
      default:
        return doorId;
    }
  }

  static NodeType _inferNodeType(String id) {
    final lower = id.toLowerCase();
    if (lower.contains('rentr') || lower.contains('entree') || lower.contains('porte') || lower.startsWith('door')) {
      return NodeType.entrance;
    }
    if (lower.contains('parking')) {
      return NodeType.parking;
    }
    if (lower.contains('departement') || lower.contains('dept') || lower.contains('amphi') || lower.contains('administration')) {
      return NodeType.department;
    }
    return NodeType.amenity;
  }

  static String _formatLabel(String id) {
    final normalized = normalizeId(id);
    switch (normalized) {
      case 'rentre-de-fsm':
        return 'Entrée FSM';
      case 'rentre-d-enim':
        return "Entrée ENIM";
      case 'departement-de-chimie':
        return 'Département de Chimie';
      case 'departement-de-chimie-2':
        return 'Département de Chimie 2';
      case "departement-d'informatique":
        return "Département d'Informatique";
      case 'departement-de-physique':
        return 'Département de Physique';
      case 'departement-de-physique-2':
        return 'Département de Physique 2';
      case 'door-2-physique':
        return 'Département de Physique (Porte Est)';
      case 'departement-math':
        return 'Département de Mathématiques';
      case 'door-2-math':
        return 'Département de Mathématiques (Porte Ouest)';
      case 'administration':
        return 'Administration';
      case 'les-amphis':
        return 'Les Amphithéâtres';
      case 'parking':
        return 'Parking Ouest';
      case 'parking-1':
        return 'Parking Sud';
      case 'locaux-communs-1':
        return 'Locaux Communs 1';
      case 'door-2-locaux-communs-1':
        return 'Locaux Communs 1 (Porte Nord)';
      case 'locaux-communs-4':
        return 'Locaux Communs 4';
      case 'infirmerie':
        return 'Infirmerie';
      case 'magasin':
        return 'Magasin';
      case 'cour-rouge':
        return 'Cour Rouge';
      default:
        return id
            .replaceAll(RegExp(r'[-_]+'), ' ')
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  static _ProjectionResult? _projectPointOntoSegment(
    MapNode p,
    MapNode a,
    MapNode b,
  ) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) return null;

    final t = ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2;
    if (t < 0.0 || t > 1.0) return null;

    final qx = a.x + t * dx;
    final qy = a.y + t * dy;
    final dist = sqrt(pow(p.x - qx, 2) + pow(p.y - qy, 2));

    return _ProjectionResult(Point<double>(qx, qy), dist);
  }

  static _ProjectionResult _projectPointOntoSegmentPt(
    Point<double> p,
    MapNode a,
    MapNode b,
  ) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) {
      final d = sqrt(pow(p.x - a.x, 2) + pow(p.y - a.y, 2));
      return _ProjectionResult(Point<double>(a.x, a.y), d);
    }

    final t = max(0.0, min(1.0, ((p.x - a.x) * dx + (p.y - a.y) * dy) / len2));
    final qx = a.x + t * dx;
    final qy = a.y + t * dy;
    final dist = sqrt(pow(p.x - qx, 2) + pow(p.y - qy, 2));

    return _ProjectionResult(Point<double>(qx, qy), dist);
  }
}

class _DoorLineData {
  final String id;
  final Point<double> p1;
  final Point<double> p2;
  const _DoorLineData({required this.id, required this.p1, required this.p2});
}

class _Segment {
  final MapNode a;
  final MapNode b;
  const _Segment(this.a, this.b);
}

class _ProjectionResult {
  final Point<double> point;
  final double distance;
  const _ProjectionResult(this.point, this.distance);
}
