// lib/models/nav_result.dart
import 'map_node.dart';

/// The result of a pathfinding query.
class NavResult {
  final List<MapNode> path;      // Ordered list of nodes from start to destination
  final double totalDistance;    // Euclidean pixel distance
  final double realDistanceM;    // Estimated real-world distance in metres
  final int estimatedSeconds;    // Estimated walking time

  const NavResult({
    required this.path,
    required this.totalDistance,
    required this.realDistanceM,
    required this.estimatedSeconds,
  });

  bool get isEmpty => path.isEmpty;

  /// Average walking speed ~1.4 m/s (84 m/min)
  static NavResult fromPath(List<MapNode> path, double pixelDistance, double pixelsPerMeter) {
    final meters = pixelDistance / pixelsPerMeter;
    const walkSpeedMs = 1.4;
    final seconds = (meters / walkSpeedMs).round();
    return NavResult(
      path: path,
      totalDistance: pixelDistance,
      realDistanceM: meters,
      estimatedSeconds: seconds,
    );
  }

  String get distanceLabel {
    if (realDistanceM < 1000) return '${realDistanceM.toStringAsFixed(0)}m';
    return '${(realDistanceM / 1000).toStringAsFixed(1)}km';
  }

  String get timeLabel {
    if (estimatedSeconds < 60) return '< 1 min walk';
    final mins = (estimatedSeconds / 60).ceil();
    return '~$mins min walk';
  }
}
