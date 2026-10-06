// lib/models/map_edge.dart
import 'map_node.dart';
import 'dart:math';

/// Represents a directed edge between two nodes in the navigation graph.
class MapEdge {
  final MapNode from;
  final MapNode to;
  final double weight;

  MapEdge({required this.from, required this.to, double? weight})
      : weight = weight ??
            sqrt(pow(to.x - from.x, 2) + pow(to.y - from.y, 2));

  @override
  String toString() => 'MapEdge(${from.id} -> ${to.id}, w=${weight.toStringAsFixed(2)})';
}
