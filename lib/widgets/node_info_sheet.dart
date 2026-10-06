// lib/widgets/node_info_sheet.dart
// Bottom sheet for a selected map node. Room list hydrated from NavProvider
// (Supabase-ready: no hardcoded room list).

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/map_node.dart';
import '../models/room.dart';
import '../providers/nav_provider.dart';
import '../theme/app_theme.dart';

class NodeInfoSheet extends StatelessWidget {
  final MapNode node;
  // Rooms for this node — pass empty list until Supabase is wired.
  final List<Room> rooms;

  const NodeInfoSheet({super.key, required this.node, this.rooms = const []});

  static Future<void> show(BuildContext ctx, MapNode node,
      {List<Room> rooms = const []}) {
    return showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NodeInfoSheet(node: node, rooms: rooms),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavProvider>();
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFF1C2B45),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: const Color(0xFF3A4A66),
                borderRadius: BorderRadius.circular(2)),
          )),
          const SizedBox(height: 16),
          // Title row
          Row(children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon(node.type), color: AppTheme.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.label,
                    style: GoogleFonts.inter(
                        color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w700)),
                Text(_typeLabel(node.type),
                    style: GoogleFonts.inter(
                        color: AppTheme.accent, fontSize: 12)),
              ],
            )),
          ]),
          const SizedBox(height: 16),
          // Action buttons
          Row(children: [
            Expanded(child: _ActionBtn(
              icon: Icons.my_location_rounded,
              label: 'Départ',
              color: AppTheme.startColor,
              onTap: () { nav.setStart(node); Navigator.pop(context); },
            )),
            const SizedBox(width: 10),
            Expanded(child: _ActionBtn(
              icon: Icons.location_on_rounded,
              label: 'Destination',
              color: AppTheme.destColor,
              onTap: () { nav.setDest(node); Navigator.pop(context); },
            )),
          ]),
          // Room list (Supabase-ready)
          if (rooms.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Salles',
                style: GoogleFonts.inter(
                    color: Colors.white, fontSize: 14,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...rooms.map((r) => _RoomTile(room: r)),
          ],
        ],
      ),
    );
  }

  IconData _typeIcon(NodeType t) => switch (t) {
    NodeType.entrance   => Icons.door_front_door_outlined,
    NodeType.department => Icons.school_rounded,
    NodeType.parking    => Icons.local_parking_rounded,
    NodeType.amenity    => Icons.star_rounded,
    NodeType.waypoint   => Icons.circle_outlined,
  };

  String _typeLabel(NodeType t) => switch (t) {
    NodeType.entrance   => 'Entrée du Campus',
    NodeType.department => 'Département / Bâtiment',
    NodeType.parking    => 'Zone de Stationnement',
    NodeType.amenity    => 'Service & Commodité',
    NodeType.waypoint   => 'Point de Passage',
  };
}

class _ActionBtn extends StatelessWidget {
  final IconData icon; final String label;
  final Color color; final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    ),
  );
}

class _RoomTile extends StatelessWidget {
  final Room room;
  const _RoomTile({required this.room});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 6),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF0E1826),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Icon(_roomIcon(room.type), color: AppTheme.accent, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.roomName,
              style: GoogleFonts.inter(
                  color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (room.floor != null || room.capacity != null)
            Text(
              [
                if (room.floor != null) 'Étage ${room.floor}',
                if (room.capacity != null) '${room.capacity} places',
              ].join(' • '),
              style: GoogleFonts.inter(
                  color: const Color(0xFF7B8FAB), fontSize: 11),
            ),
        ],
      )),
    ]),
  );

  IconData _roomIcon(RoomType t) => switch (t) {
    RoomType.amphitheater => Icons.theater_comedy_rounded,
    RoomType.lab          => Icons.science_rounded,
    RoomType.library      => Icons.menu_book_rounded,
    RoomType.cafeteria    => Icons.coffee_rounded,
    RoomType.office       => Icons.business_center_rounded,
    _                     => Icons.meeting_room_rounded,
  };
}
