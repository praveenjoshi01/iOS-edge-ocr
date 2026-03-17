import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Image preview screen with an Extract Text button.
///
/// Receives an image file path and displays it at a memory-safe resolution
/// (cacheWidth: 1024) to avoid blowing the memory budget alongside the
/// ~600 MB SmolVLM2 model in GPU memory.
///
/// The Extract Text button navigates to the OCR screen with the image path.
class PreviewScreen extends StatelessWidget {
  /// Absolute path to the image file to preview.
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image display (memory-safe)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    cacheWidth: 1024,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 64,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load image',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            // Extract Text button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: FilledButton.icon(
                onPressed: () {
                  final encodedPath = Uri.encodeComponent(imagePath);
                  context.push('/ocr?path=$encodedPath');
                },
                icon: const Icon(Icons.text_snippet_outlined),
                label: const Text('Extract Text'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
