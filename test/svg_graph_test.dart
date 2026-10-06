// test/svg_graph_test.dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsm_nav/services/svg_parser.dart';
import 'package:fsm_nav/services/pathfinding_service.dart';

void main() {
  test('Parse real features.svg and verify door alignment and campus connectivity', () {
    final file = File('assets/features.svg');
    expect(file.existsSync(), isTrue, reason: 'assets/features.svg must exist');
    final svgString = file.readAsStringSync();

    final graph = SvgParser.parse(svgString);

    expect(graph.nodes.isNotEmpty, isTrue);
    // Canvas dimensions match INTERACTIVE MAP.png
    expect(graph.svgWidth, equals(872.0));
    expect(graph.svgHeight, equals(720.0));

    // Bounding box from border-excat-of-png
    expect(graph.pngBounds.width, equals(872.0));
    expect(graph.pngBounds.height, equals(720.0));
    expect(graph.pngBounds.left, equals(0.0));
    expect(graph.pngBounds.top, equals(0.0));

    // Verify departments are anchored directly at their physical door endpoints (single bloc 872x720 coordinates)
    final chimieNode = graph.nodes['departement-de-chimie'];
    expect(chimieNode, isNotNull);
    expect(chimieNode!.x, closeTo(446.0, 1.0));
    expect(chimieNode.y, closeTo(279.5, 1.0));

    final infoNode = graph.nodes["departement-d'informatique"];
    expect(infoNode, isNotNull);
    expect(infoNode!.x, closeTo(163.0, 1.0));
    expect(infoNode.y, closeTo(368.5, 1.0));

    final mathNode = graph.nodes['departement-math'];
    expect(mathNode, isNotNull);
    expect(mathNode!.x, closeTo(312.0, 1.0));
    expect(mathNode.y, closeTo(361.5, 1.0));

    final adminNode = graph.nodes['administration'];
    expect(adminNode, isNotNull);
    expect(adminNode!.x, closeTo(341.8, 1.0));
    expect(adminNode.y, closeTo(539.6, 1.0));

    final fsmNode = graph.nodes['rentre-de-fsm'];
    expect(fsmNode, isNotNull);
    expect(fsmNode!.x, closeTo(371.0, 2.0));
    expect(fsmNode.y, closeTo(607.5, 2.0));

    final enimNode = graph.nodes['rentre-d-enim'];
    expect(enimNode, isNotNull);
    expect(enimNode!.x, closeTo(94.0, 3.0));
    expect(enimNode.y, closeTo(198.5, 3.0));

    final svc = PathfindingService();

    // Verify continuous door-to-door routes across the campus
    final r1 = svc.findPathInGraph(graph, 'rentré de fsm', 'administration');
    expect(r1, isNotNull);
    expect(r1!.path.length, greaterThanOrEqualTo(2));
    expect(r1.path.last.id, equals('administration'));

    final r2 = svc.findPathInGraph(graph, "rentré-d'enim", "departement-d'informatique");
    expect(r2, isNotNull);
    expect(r2!.path.length, greaterThanOrEqualTo(2));
    expect(r2.path.last.id, equals("departement-d'informatique"));

    final r3 = svc.findPathInGraph(graph, 'rentré de fsm', 'departement-de-chimie');
    expect(r3, isNotNull);
    expect(r3!.path.length, greaterThanOrEqualTo(2));
    expect(r3.path.last.id, equals('departement-de-chimie'));

    final r4 = svc.findPathInGraph(graph, 'parking', 'les-amphis');
    expect(r4, isNotNull);
    expect(r4!.path.length, greaterThanOrEqualTo(2));

    final r5 = svc.findPathInGraph(graph, 'rentre-de-fsm', 'locaux-communs-4');
    expect(r5, isNotNull);
    expect(r5!.path.length, greaterThanOrEqualTo(2));

    final r6 = svc.findPathInGraph(graph, 'rentre-de-fsm', 'departement-de-physique');
    expect(r6, isNotNull);
    expect(r6!.path.length, greaterThanOrEqualTo(2));
  });
}
