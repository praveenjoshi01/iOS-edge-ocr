import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      path: '/ocr',
      builder: (context, state) => const _OcrPlaceholderScreen(),
    ),
  ],
);

/// Placeholder screen for OCR functionality.
/// Will be replaced in Phase 1 Plan 02.
class _OcrPlaceholderScreen extends StatelessWidget {
  const _OcrPlaceholderScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edge OCR')),
      body: const Center(
        child: Text(
          'OCR Ready - Phase 1 Plan 02 will build this',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
