import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/ocr_state.dart';
import 'ocr_view_model.dart';

/// Minimal test screen for end-to-end OCR validation.
///
/// Allows user to pick an image from their photo library and displays
/// the extracted text from on-device SmolVLM2 inference.
///
/// This is a Phase 1 test screen -- functional correctness is the goal.
/// Phase 2 replaces this with the full image input flow.
/// Phase 3 adds loading polish and error handling.
///
/// Architecture: This screen only imports from presentation/ and domain/.
/// It never imports edge_veda or accesses VisionWorker directly.
class OcrTestScreen extends ConsumerWidget {
  const OcrTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Test'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: switch (ocrState) {
            OcrStateIdle() => _IdleView(
                onPickImage: () =>
                    ref.read(ocrViewModelProvider.notifier).pickAndExtract(),
              ),
            OcrStatePickingImage() => const _StatusView(
                message: 'Opening gallery...',
                showProgress: false,
              ),
            OcrStatePreprocessing() => const _StatusView(
                message: 'Preprocessing image...',
                showProgress: true,
              ),
            OcrStateInferring() => const _StatusView(
                message: 'Extracting text...',
                showProgress: true,
              ),
            OcrStateComplete(:final result) => _CompleteView(
                text: result.text,
                processingTimeMs: result.processingTimeMs,
                imageWidth: result.imageWidth,
                imageHeight: result.imageHeight,
                onReset: () =>
                    ref.read(ocrViewModelProvider.notifier).reset(),
              ),
            OcrStateError(:final message) => _ErrorView(
                message: message,
                onRetry: () =>
                    ref.read(ocrViewModelProvider.notifier).reset(),
              ),
          },
        ),
      ),
    );
  }
}

/// Idle state: large "Pick Image" button.
class _IdleView extends StatelessWidget {
  final VoidCallback onPickImage;

  const _IdleView({required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.document_scanner_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onPickImage,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Pick Image'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 16,
              ),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Select an image to extract text',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Processing states: spinner with status message.
class _StatusView extends StatelessWidget {
  final String message;
  final bool showProgress;

  const _StatusView({
    required this.message,
    required this.showProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showProgress)
            const SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(),
            ),
          if (showProgress) const SizedBox(height: 24),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

/// Complete state: scrollable extracted text with metadata.
class _CompleteView extends StatelessWidget {
  final String text;
  final int processingTimeMs;
  final int imageWidth;
  final int imageHeight;
  final VoidCallback onReset;

  const _CompleteView({
    required this.text,
    required this.processingTimeMs,
    required this.imageWidth,
    required this.imageHeight,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Metadata row
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${processingTimeMs}ms',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Icon(
                Icons.image_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${imageWidth}x$imageHeight',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Extracted text (scrollable)
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                text.isEmpty ? '(No text extracted)' : text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Try Another button
        FilledButton.icon(
          onPressed: onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Another'),
        ),
      ],
    );
  }
}

/// Error state: error message with retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'OCR Failed',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
