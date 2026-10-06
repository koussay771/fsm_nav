// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/nav_provider.dart';
import 'screens/splash_screen.dart';
import 'services/pathfinding_service.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FsmNavApp());
}

class FsmNavApp extends StatelessWidget {
  const FsmNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavProvider(PathfindingService()),
      child: MaterialApp(
        title: 'FSM Navigator – Faculté des Sciences de Monastir',
        theme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
