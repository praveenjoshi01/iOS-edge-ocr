import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/model_config.dart';
import '../domain/ocr_result.dart';
import '../domain/ocr_state.dart';
import 'ocr_view_model.dart';

/// Maps raw exception strings to user-friendly error messages.
///
/// The ViewModel captures raw errors (separation of concerns);
/// this function maps them to presentable text at the UI layer.
String _friendlyErrorMessage(String rawError) {
  final lower = rawError.toLowerCase();

  if (lower.contains('visionworker not initialized')) {
    return 'The AI model is not ready. Please restart the app and try again.';
  }
  if (lower.contains('failed to decode image') ||
      lower.contains('cannot read file')) {
    return 'This image could not be read. Try a different image with better quality.';
  }
  if (lower.contains('memory') || lower.contains('jetsam')) {
    return 'Not enough memory to process this image. Try closing other apps and retry.';
  }
  return 'Text extraction failed. Please try again with a different image.';
}

/// Copies [text] to the system clipboard and shows a floating SnackBar
/// confirmation with a check icon.
Future<void> _copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..clearSnackBars()
    ..showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Text copied to clipboard'),
          ],
        ),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

/// Polished result screen for the OCR pipeline.
///
/// Replaces the Phase 1 OcrTestScreen with shipping-quality UX:
/// - Loading indicators with descriptive status text (OCR-03)
/// - User-friendly error messages with retry and navigation (OCR-04)
/// - Empty-result handling with guidance (OCR-04)
/// - Copy-to-clipboard with SnackBar confirmation (OUT-01)
///
/// Requires an [imagePath] parameter -- all image source selection is
/// handled by HomeScreen before navigating here.
class ResultScreen extends ConsumerWidget {
  /// Pre-selected image path from HomeScreen/PreviewScreen.
  final String imagePath;

  const ResultScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ocrState = ref.watch(ocrViewModelProvider);

    // Auto-start extraction on first build (idle state + imagePath).
    // Schedule after build to avoid modifying state during build.
    if (ocrState is OcrStateIdle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(ocrViewModelProvider.notifier).extractFromPath(imagePath);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: switch (ocrState) {
            OcrStateIdle() => const _StatusView(
                message: 'Starting extraction...',
                subtitle: null,
                showProgress: true,
              ),
            OcrStatePickingImage() => const _StatusView(
                message: 'Opening gallery...',
                subtitle: null,
                showProgress: false,
              ),
            OcrStatePreprocessing() => const _StatusView(
                message: 'Preparing image...',
                subtitle: null,
                showProgress: true,
              ),
            OcrStateInferring() => const _StatusView(
                message: 'Extracting text...',
                subtitle: 'This may take a few seconds',
                showProgress: true,
              ),
            OcrStateComplete(:final result) =>
              result.text.trim().isEmpty
                  ? _NoTextFoundView(
                      processingTimeMs: result.processingTimeMs,
                      onRetry: () => ref
                          .read(ocrViewModelProvider.notifier)
                          .extractFromPath(imagePath),
                      onTryDifferent: () => context.go('/home'),
                    )
                  : _CompleteView(
                      result: result,
                      onCopy: () =>
                          _copyToClipboard(context, result.text),
                      onTryDifferent: () => context.go('/home'),
                    ),
            OcrStateError(:final message) => _ErrorView(
                message: message,
                onRetry: () => ref
                    .read(ocrViewModelProvider.notifier)
                    .extractFromPath(imagePath),
                onTryDifferent: () => context.go('/home'),
              ),
          },
        ),
      ),
    );
  }
}

/// Processing states: spinner with status message and optional subtitle.
class _StatusView extends StatelessWidget {
  final String message;
  final String? subtitle;
  final bool showProgress;

  const _StatusView({
    required this.message,
    required this.subtitle,
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
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Complete state: scrollable extracted text with metadata, debug info,
/// copy-to-clipboard, and navigation.
class _CompleteView extends StatefulWidget {
  final OcrResult result;
  final VoidCallback onCopy;
  final VoidCallback onTryDifferent;

  const _CompleteView({
    required this.result,
    required this.onCopy,
    required this.onTryDifferent,
  });

  @override
  State<_CompleteView> createState() => _CompleteViewState();
}

class _CompleteViewState extends State<_CompleteView> {
  bool _showDebugInfo = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = widget.result;

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
                '${result.processingTimeMs}ms',
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
                '${result.imageWidth}x${result.imageHeight}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Debug info toggle
              GestureDetector(
                onTap: () => setState(() => _showDebugInfo = !_showDebugInfo),
                child: Icon(
                  _showDebugInfo
                      ? Icons.bug_report
                      : Icons.bug_report_outlined,
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
            processingTimeMs: result.processingTimeMs,
            imageWidth: result.imageWidth,
            imageHeight: result.imageHeight,
            textLength: result.text.length,
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
                result.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Primary action: Copy Text
        FilledButton.icon(
          onPressed: widget.onCopy,
          icon: const Icon(Icons.copy),
          label: const Text('Copy Text'),
        ),
        const SizedBox(height: 8),

        // Secondary action: Try Different Image
        OutlinedButton.icon(
          onPressed: widget.onTryDifferent,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Different Image'),
        ),
      ],
    );
  }
}

/// No text found state: guidance when OCR completes but extracts no text.
class _NoTextFoundView extends StatelessWidget {
  final int processingTimeMs;
  final VoidCallback onRetry;
  final VoidCallback onTryDifferent;

  const _NoTextFoundView({
    required this.processingTimeMs,
    required this.onRetry,
    required this.onTryDifferent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Text Found',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'No text was detected in this image. Try a clearer photo with visible text.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),

          // Processing time chip
          Chip(
            avatar: Icon(
              Icons.timer_outlined,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            label: Text(
              '${processingTimeMs}ms',
              style: theme.textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: onTryDifferent,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Try Different Image'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

/// Error state: user-friendly error message with retry and navigation options.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onTryDifferent;

  const _ErrorView({
    required this.message,
    required this.onRetry,
    required this.onTryDifferent,
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
            'Extraction Failed',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _friendlyErrorMessage(message),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onTryDifferent,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Try Different Image'),
          ),
        ],
      ),
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
