// lib/providers/nav_provider.dart
// Central ChangeNotifier — wires SvgParser + PathfindingService + UI state.

import 'package:flutter/material.dart';
import '../models/map_node.dart';
import '../models/nav_result.dart';
import '../services/pathfinding_service.dart';

enum NavStatus { idle, loading, success, noPath, error }

class NavProvider extends ChangeNotifier {
  final PathfindingService _svc;
  NavProvider(this._svc);

  // ── State ────────────────────────────────────────────────────────────────
  NavStatus _status = NavStatus.idle;
  MapNode?  _start;
  MapNode?  _dest;
  NavResult? _result;
  String?   _errorMsg;
  String?   _highlightedId;

  // ── Getters ──────────────────────────────────────────────────────────────
  NavStatus  get status        => _status;
  MapNode?   get startNode     => _start;
  MapNode?   get destNode      => _dest;
  NavResult? get result        => _result;
  String?    get errorMessage  => _errorMsg;
  String?    get highlightedId => _highlightedId;
  bool       get hasResult     => _result != null && _result!.path.isNotEmpty;

  // Nodes are sourced exclusively from the parsed SVG graph:
  List<MapNode> get allNodes   => _svc.allNodes;
  List<MapNode> get entrances  => _svc.nodesByType(NodeType.entrance);
  List<MapNode> get departments=> _svc.nodesByType(NodeType.department);
  List<MapNode> get amenities  => _svc.nodesByType(NodeType.amenity);

  double get svgWidth  => _svc.svgWidth;
  double get svgHeight => _svc.svgHeight;
  Rect get pngBounds   => _svc.pngBounds;

  // ── Init ─────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _status = NavStatus.loading;
    notifyListeners();
    try {
      await _svc.initialize();
      _status = NavStatus.idle;
    } catch (e) {
      _status = NavStatus.error;
      _errorMsg = e.toString();
    }
    notifyListeners();
  }

  // ── Selection ────────────────────────────────────────────────────────────
  void setStart(MapNode? n) { _start = n; _clearResult(); notifyListeners(); }
  void setDest(MapNode? n)  { _dest  = n; _clearResult(); notifyListeners(); }
  void setHighlighted(String? id) { _highlightedId = id; notifyListeners(); }

  /// Called when user taps a map feature by SVG id.
  void onFeatureTapped(String svgId) {
    final node = _svc.nodes[svgId];
    if (node == null) return;
    setHighlighted(svgId);
    if (_start == null) {
      setStart(node);
    } else if (_dest == null) {
      setDest(node);
      findPath();
    } else {
      // Third tap → replace destination and re-route.
      setDest(node);
      findPath();
    }
  }

  // ── Pathfinding ──────────────────────────────────────────────────────────
  void findPath() {
    if (_start == null || _dest == null) return;
    _status = NavStatus.loading;
    notifyListeners();

    final r = _svc.findPath(_start!.id, _dest!.id);
    if (r == null || r.isEmpty) {
      _result = null;
      _status  = NavStatus.noPath;
    } else {
      _result = r;
      _status  = NavStatus.success;
    }
    notifyListeners();
  }

  void reset() {
    _start = null; _dest = null; _result = null;
    _highlightedId = null;
    _status = NavStatus.idle; _errorMsg = null;
    notifyListeners();
  }

  void _clearResult() { _result = null; _status = NavStatus.idle; }
}
