// lib/screens/rooms_screen.dart
// Rooms browser — Supabase-ready. Currently shows empty state until
// rooms are loaded from Supabase. parentDepartmentSvgId matches SVG ids.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/map_node.dart';
import '../models/room.dart';
import '../providers/nav_provider.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  String _query = '';
  // TODO: Replace with Supabase stream when ready.
  // For now: empty list to show Supabase-ready structure.
  final List<Room> _rooms = [];

  List<MapNode> _depts(NavProvider nav) => nav.departments
      .where((n) => n.label.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  List<Room> _filteredRooms(String? deptSvgId) {
    var r = _rooms;
    if (deptSvgId != null) {
      r = r.where((x) => x.parentDepartmentSvgId == deptSvgId).toList();
    }
    if (_query.isNotEmpty) {
      r = r.where((x) =>
          x.roomName.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return r;
  }

  MapNode? _selectedDept;

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF0D1520),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111827),
        elevation: 0,
        title: Text('Salles & Départements',
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w700)),
        leading:
            const Icon(Icons.school_rounded, color: AppTheme.accent),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Rechercher salle ou département...',
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.accent, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF8899BB), size: 18),
                        onPressed: () => setState(() => _query = ''))
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: Row(children: [
        // Dept sidebar
        SizedBox(
          width: 190,
          child: Container(
            color: const Color(0xFF111827),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _DeptTile(
                    node: null,
                    isSelected: _selectedDept == null,
                    onTap: () => setState(() => _selectedDept = null)),
                ..._depts(nav).map((n) => _DeptTile(
                      node: n,
                      isSelected: _selectedDept?.id == n.id,
                      onTap: () => setState(() => _selectedDept = n),
                    )),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, color: Color(0xFF1A2840)),
        // Rooms list
        Expanded(
          child: _filteredRooms(_selectedDept?.id).isEmpty
              ? _emptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredRooms(_selectedDept?.id).length,
                  itemBuilder: (_, i) =>
                      _RoomCard(room: _filteredRooms(_selectedDept?.id)[i])),
        ),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.meeting_room_outlined,
            color: Color(0xFF3A4A66), size: 48),
        const SizedBox(height: 12),
        Text('Aucune salle enregistrée',
            style: GoogleFonts.inter(
                color: const Color(0xFF556080), fontSize: 15)),
        const SizedBox(height: 6),
        Text('Les salles seront chargées depuis Supabase.',
            style: GoogleFonts.inter(
                color: const Color(0xFF3A4A66), fontSize: 12)),
      ]),
    );
  }
}

class _DeptTile extends StatelessWidget {
  final MapNode? node;
  final bool isSelected;
  final VoidCallback onTap;
  const _DeptTile({this.node, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary.withValues(alpha: 0.2)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isSelected
            ? Border.all(color: AppTheme.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(children: [
        Icon(
          node == null ? Icons.grid_view_rounded : Icons.school_rounded,
          color: isSelected ? AppTheme.accent : const Color(0xFF556080),
          size: 15,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            node == null ? 'Tout' : node!.label,
            style: GoogleFonts.inter(
              color: isSelected ? Colors.white : const Color(0xFF8899BB),
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ]),
    ),
  );
}

class _RoomCard extends StatelessWidget {
  final Room room;
  const _RoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavProvider>();
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(_roomIcon(room.type),
              color: AppTheme.accent, size: 20),
        ),
        title: Text(room.roomName,
            style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(room.parentDepartmentSvgId,
            style: GoogleFonts.inter(
                color: AppTheme.accent, fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.navigation_rounded,
              color: AppTheme.accent, size: 20),
          onPressed: () {
            final node = nav.allNodes.firstWhere(
              (n) => n.id == room.parentDepartmentSvgId,
              orElse: () => nav.allNodes.first,
            );
            nav.setDest(node);
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const MapScreen()));
          },
        ),
      ),
    );
  }

  IconData _roomIcon(RoomType t) => switch (t) {
    RoomType.amphitheater => Icons.theater_comedy_rounded,
    RoomType.lab          => Icons.science_rounded,
    RoomType.library      => Icons.menu_book_rounded,
    RoomType.cafeteria    => Icons.coffee_rounded,
    RoomType.office       => Icons.business_center_rounded,
    _                     => Icons.meeting_room_rounded,
  };
}
