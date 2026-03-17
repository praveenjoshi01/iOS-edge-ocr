import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/model_config.dart';
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

/// Complete state: scrollable extracted text with metadata and debug info.
class _CompleteView extends StatefulWidget {
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
  State<_CompleteView> createState() => _CompleteViewState();
}

class _CompleteViewState extends State<_CompleteView> {
  bool _showDebugInfo = false;

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
                '${widget.processingTimeMs}ms',
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
                '${widget.imageWidth}x${widget.imageHeight}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Debug info toggle
              GestureDetector(
                onTap: () => setState(() => _showDebugInfo = !_showDebugInfo),
                child: Icon(
                  _showDebugInfo ? Icons.bug_report : Icons.bug_report_outlined,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        // Collapsible debug info section
        if (_showDebugInfo) ...[
          const SizedBox(height: 8),
          _DebugInfoPanel(
            processingTimeMs: widget.processingTimeMs,
            imageWidth: widget.imageWidth,
            imageHeight: widget.imageHeight,
            textLength: widget.text.length,
          ),
        ],

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
                widget.text.isEmpty ? '(No text extracted)' : widget.text,
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
          onPressed: widget.onReset,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Another'),
        ),
      ],
    );
  }
}

/// Debug info panel showing model file status and processing details.
///
/// Checks model files on disk and displays diagnostic data useful for
/// validating the OCR pipeline on a physical device.
class _DebugInfoPanel extends StatelessWidget {
  final int processingTimeMs;
  final int imageWidth;
  final int imageHeight;
  final int textLength;

  const _DebugInfoPanel({
    required this.processingTimeMs,
    required this.imageWidth,
    required this.imageHeight,
    required this.textLength,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<Map<String, String>>(
      future: _gatherDebugInfo(),
      builder: (context, snapshot) {
        final info = snapshot.data ?? {'status': 'Loading...'};

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Debug Info',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...info.entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '${e.key}: ${e.value}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _gatherDebugInfo() async {
    final info = <String, String>{};

    // Processing metrics
    info['Pipeline time'] = '${processingTimeMs}ms';
    info['Image dims'] = '${imageWidth}x$imageHeight';
    info['RGB bytes'] = '${imageWidth * imageHeight * 3}';
    info['Output chars'] = '$textLength';

    // Model file status
    try {
      final modelPath = await ModelConfig.modelPath;
      final mmprojPath = await ModelConfig.mmprojPath;
      final modelFile = File(modelPath);
      final mmprojFile = File(mmprojPath);

      if (await modelFile.exists()) {
        final size = await modelFile.length();
        info['Model file'] =
            '${(size / 1024 / 1024).toStringAsFixed(1)} MB (${size == ModelConfig.modelSizeBytes ? "OK" : "SIZE MISMATCH"})';
      } else {
        info['Model file'] = 'MISSING';
      }

      if (await mmprojFile.exists()) {
        final size = await mmprojFile.length();
        info['Mmproj file'] =
            '${(size / 1024 / 1024).toStringAsFixed(1)} MB (${size == ModelConfig.mmprojSizeBytes ? "OK" : "SIZE MISMATCH"})';
      } else {
        info['Mmproj file'] = 'MISSING';
      }
    } catch (e) {
      info['File check'] = 'Error: $e';
    }

    return info;
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
