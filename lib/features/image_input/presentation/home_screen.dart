import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main input selection screen with three large buttons for image sources.
///
/// The user arrives here after model download is complete. Each button
/// navigates to a different input flow:
/// - Camera: live capture via /camera route
/// - Photo Library: picks from device gallery (wired in Plan 02)
/// - Import File: picks from Files app (wired in Plan 02)
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 48),
              // App title
              Icon(
                Icons.document_scanner_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Edge OCR',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Extract text from images, entirely on-device',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Input source buttons
              _InputSourceCard(
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'Capture a document or photo',
                onTap: () => context.push('/camera'),
                theme: theme,
              ),
              const SizedBox(height: 16),
              _InputSourceCard(
                icon: Icons.photo_library,
                title: 'Photo Library',
                subtitle: 'Select from your photos',
                onTap: () {
                  // Plan 02 wires the photo library import logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo Library -- coming in Plan 02'),
                    ),
                  );
                },
                theme: theme,
              ),
              const SizedBox(height: 16),
              _InputSourceCard(
                icon: Icons.file_open,
                title: 'Import File',
                subtitle: 'Pick from Files app (images & PDFs)',
                onTap: () {
                  // Plan 02 wires the Files app import logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Import File -- coming in Plan 02'),
                    ),
                  );
                },
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A large card-style button for an input source.
class _InputSourceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;

  const _InputSourceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
