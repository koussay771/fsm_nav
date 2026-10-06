// lib/models/map_node.dart

/// Represents a node in the navigation graph (an intersection, room entrance, or waypoint).
class MapNode {
  final String id;
  final String label;
  final double x;
  final double y;
  final NodeType type;

  const MapNode({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.type = NodeType.waypoint,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MapNode && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'MapNode($id, $label, $x, $y)';
}

enum NodeType { entrance, department, parking, amenity, waypoint }
