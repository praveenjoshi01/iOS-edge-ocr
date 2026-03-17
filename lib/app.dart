import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'features/image_input/presentation/camera_screen.dart';
import 'features/image_input/presentation/home_screen.dart';
import 'features/image_input/presentation/preview_screen.dart';
import 'features/ocr/presentation/ocr_test_screen.dart';
import 'features/onboarding/presentation/download_screen.dart';

/// Root application widget with Material 3 theme and go_router navigation.
class EdgeOCRApp extends StatelessWidget {
  const EdgeOCRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Edge OCR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DownloadScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/preview',
      builder: (context, state) {
        final path = state.uri.queryParameters['path']!;
        return PreviewScreen(imagePath: Uri.decodeComponent(path));
      },
    ),
    GoRoute(
      path: '/ocr',
      builder: (context, state) {
        // Accept optional path query parameter for Phase 2 integration.
        // For now, OcrTestScreen uses its own image picker internally.
        // Plan 02 will update OcrTestScreen / OcrScreen to accept path.
        return const OcrTestScreen();
      },
    ),
  ],
);