// lib/screens/home_shell.dart
// Bottom navigation shell that wraps Map, Rooms, and About screens.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import 'map_screen.dart';
import 'rooms_screen.dart';
import 'about_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  final _screens = const [MapScreen(), RoomsScreen(), AboutScreen()];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      // Side navigation rail on desktop
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: const Color(0xFF111827),
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              labelType: NavigationRailLabelType.selected,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.accent]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.map_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.map_outlined),
                  selectedIcon: const Icon(Icons.map_rounded),
                  label: Text('Carte', style: GoogleFonts.inter(fontSize: 12)),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.meeting_room_outlined),
                  selectedIcon: const Icon(Icons.meeting_room_rounded),
                  label: Text('Salles', style: GoogleFonts.inter(fontSize: 12)),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.info_outline_rounded),
                  selectedIcon: const Icon(Icons.info_rounded),
                  label: Text('À propos', style: GoogleFonts.inter(fontSize: 12)),
                ),
              ],
              selectedIconTheme: const IconThemeData(color: AppTheme.accent),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF556080)),
              selectedLabelTextStyle: GoogleFonts.inter(
                  color: AppTheme.accent, fontWeight: FontWeight.w600),
              unselectedLabelTextStyle:
                  GoogleFonts.inter(color: const Color(0xFF556080)),
              indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
            ),
            const VerticalDivider(width: 1, color: Color(0xFF1A2840)),
            Expanded(child: _screens[_tab]),
          ],
        ),
      );
    }

    // Bottom nav on mobile
    return Scaffold(
      body: IndexedStack(index: _tab, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          border: const Border(
              top: BorderSide(color: Color(0xFF1A2840), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.map_outlined, color: Color(0xFF556080)),
              selectedIcon: const Icon(Icons.map_rounded, color: AppTheme.accent),
              label: 'Carte',
            ),
            NavigationDestination(
              icon: const Icon(Icons.meeting_room_outlined,
                  color: Color(0xFF556080)),
              selectedIcon: const Icon(Icons.meeting_room_rounded,
                  color: AppTheme.accent),
              label: 'Salles',
            ),
            NavigationDestination(
              icon: const Icon(Icons.info_outline_rounded,
                  color: Color(0xFF556080)),
              selectedIcon:
                  const Icon(Icons.info_rounded, color: AppTheme.accent),
              label: 'À propos',
            ),
          ],
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        ),
      ),
    );
  }
}
