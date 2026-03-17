import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../runtime/edge_veda_runtime.dart';
import '../../../runtime/runtime_state.dart';

part 'download_view_model.g.dart';

/// View model for the download screen.
///
/// Watches [EdgeVedaRuntime] state and exposes formatted display values
/// and actions for the UI layer.
@riverpod
class DownloadViewModel extends _$DownloadViewModel {
  @override
  DownloadDisplayState build() {
    final runtimeAsync = ref.watch(edgeVedaRuntimeProvider);

    return runtimeAsync.when(
      data: (runtimeState) => switch (runtimeState) {
        RuntimeStateUninitialized() => const DownloadDisplayState(
            status: DownloadStatus.needsDownload,
          ),
        RuntimeStateDownloading(:final progress, :final downloadedBytes, :final totalBytes) =>
          DownloadDisplayState(
            status: DownloadStatus.downloading,
            progressPercent: (progress * 100).round(),
            downloadedMB: (downloadedBytes / (1024 * 1024)).round(),
            totalMB: totalBytes > 0
                ? (totalBytes / (1024 * 1024)).round()
                : 607, // fallback estimate
          ),
        RuntimeStateInitializing() => const DownloadDisplayState(
            status: DownloadStatus.initializing,
          ),
        RuntimeStateReady() => const DownloadDisplayState(
            status: DownloadStatus.ready,
          ),
        RuntimeStateError(:final message) => DownloadDisplayState(
            status: DownloadStatus.error,
            errorMessage: message,
          ),
      },
      loading: () => const DownloadDisplayState(
        status: DownloadStatus.initializing,
      ),
      error: (error, _) => DownloadDisplayState(
        status: DownloadStatus.error,
        errorMessage: error.toString(),
      ),
    );
  }

  /// Start downloading the model files.
  void startDownload() {
    ref.read(edgeVedaRuntimeProvider.notifier).downloadModel();
  }

  /// Retry download after an error.
  void retryDownload() {
    ref.read(edgeVedaRuntimeProvider.notifier).retryDownload();
  }
}

/// Status enum for download screen UI states.
enum DownloadStatus {
  needsDownload,
  downloading,
  initializing,
  ready,
  error,
}

/// Immutable display state for the download screen.
///
/// Derived from [RuntimeState] with formatted values ready for display.
class DownloadDisplayState {
  final DownloadStatus status;
  final int progressPercent;
  final int downloadedMB;
  final int totalMB;
  final String? errorMessage;

  const DownloadDisplayState({
    required this.status,
    this.progressPercent = 0,
    this.downloadedMB = 0,
    this.totalMB = 607,
    this.errorMessage,
  });

  bool get isDownloading => status == DownloadStatus.downloading;
  bool get isReady => status == DownloadStatus.ready;
  bool get hasError => status == DownloadStatus.error;
  bool get needsDownload => status == DownloadStatus.needsDownload;

  /// Formatted progress string like "42%".
  String get progressText => '$progressPercent%';

  /// Formatted size string like "256 MB / 607 MB".
  String get sizeText => '$downloadedMB MB / $totalMB MB';
}
