// lib/models/room.dart
// Modular Room data structure — ready to be hydrated from Supabase.
// parentDepartmentSvgId MUST match the element id in features.svg.

enum RoomType { classroom, amphitheater, lab, office, library, cafeteria, other }

class Room {
  final String roomId;                // Supabase primary key
  final String roomName;              // e.g. "Salle C101", "Labo Chimie 2"
  final String parentDepartmentSvgId; // Matches SVG id (e.g. "departement-de-chimie")
  final RoomType type;
  final String? floor;
  final int? capacity;
  final String? description;

  const Room({
    required this.roomId,
    required this.roomName,
    required this.parentDepartmentSvgId,
    this.type = RoomType.classroom,
    this.floor,
    this.capacity,
    this.description,
  });

  /// Construct from a Supabase row map.
  factory Room.fromMap(Map<String, dynamic> m) => Room(
    roomId:                m['id'] as String,
    roomName:              m['name'] as String,
    parentDepartmentSvgId: m['department_svg_id'] as String,
    type:    RoomType.values.firstWhere(
        (e) => e.name == (m['type'] ?? 'classroom'),
        orElse: () => RoomType.classroom),
    floor:    m['floor'] as String?,
    capacity: m['capacity'] as int?,
    description: m['description'] as String?,
  );

  Map<String, dynamic> toMap() => {
    'id': roomId,
    'name': roomName,
    'department_svg_id': parentDepartmentSvgId,
    'type': type.name,
    'floor': floor,
    'capacity': capacity,
    'description': description,
  };
}
