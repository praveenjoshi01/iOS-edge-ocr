import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'download_view_model.dart';

/// First-launch screen that handles model download and runtime initialization.
///
/// Shows different UI based on runtime state:
/// - needsDownload: Download prompt with model size info and Wi-Fi recommendation
/// - downloading: Progress indicator with percentage and MB counts
/// - initializing: Loading spinner while VisionWorker starts
/// - ready: Success message with navigation to OCR screen
/// - error: Error message with retry button
class DownloadScreen extends ConsumerWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayState = ref.watch(downloadViewModelProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: switch (displayState.status) {
              DownloadStatus.needsDownload => _NeedsDownloadView(
                  theme: theme,
                  onDownload: () {
                    ref.read(downloadViewModelProvider.notifier).startDownload();
                  },
                ),
              DownloadStatus.downloading => _DownloadingView(
                  theme: theme,
                  displayState: displayState,
                ),
              DownloadStatus.initializing => _InitializingView(theme: theme),
              DownloadStatus.ready => _ReadyView(
                  theme: theme,
                  onContinue: () => context.go('/ocr'),
                ),
              DownloadStatus.error => _ErrorView(
                  theme: theme,
                  errorMessage: displayState.errorMessage ?? 'Unknown error',
                  onRetry: () {
                    ref
                        .read(downloadViewModelProvider.notifier)
                        .retryDownload();
                  },
                ),
            },
          ),
        ),
      ),
    );
  }
}

class _NeedsDownloadView extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onDownload;

  const _NeedsDownloadView({
    required this.theme,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_download_outlined,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Download AI Model',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Edge OCR needs a one-time download of the AI model '
          'for offline text extraction.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: Icons.storage_outlined,
                text: 'Model size: ~607 MB total',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.wifi_outlined,
                text: 'Wi-Fi recommended',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.wifi_off_outlined,
                text: 'Works fully offline after download',
                theme: theme,
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onDownload,
          icon: const Icon(Icons.download),
          label: const Text('Download'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 56),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _DownloadingView extends StatelessWidget {
  final ThemeData theme;
  final DownloadDisplayState displayState;

  const _DownloadingView({
    required this.theme,
    required this.displayState,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: displayState.progressPercent / 100.0,
                  strokeWidth: 8,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Text(
                displayState.progressText,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Downloading AI Model...',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          displayState.sizeText,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Download resumes automatically if interrupted',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InitializingView extends StatelessWidget {
  final ThemeData theme;

  const _InitializingView({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(),
        ),
        const SizedBox(height: 24),
        Text(
          'Loading AI Model...',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Preparing for offline text extraction',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ReadyView extends StatelessWidget {
  final ThemeData theme;
  final VoidCallback onContinue;

  const _ReadyView({
    required this.theme,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Ready!',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'AI model loaded and ready for offline OCR',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Continue'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 56),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ThemeData theme;
  final String errorMessage;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.theme,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 80,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 24),
        Text(
          'Download Failed',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Download will resume from where it left off',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(200, 56),
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final ThemeData theme;

  const _InfoRow({
    required this.icon,
    required this.text,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
