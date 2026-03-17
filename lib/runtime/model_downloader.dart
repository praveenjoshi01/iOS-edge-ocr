import 'dart:async';
import 'dart:io';

import 'package:edge_veda/edge_veda.dart';

import '../core/constants/model_config.dart';

/// Progress data for combined model + mmproj download.
class CombinedDownloadProgress {
  /// Total bytes downloaded across both files.
  final int downloadedBytes;

  /// Total bytes expected across both files.
  final int totalBytes;

  /// Progress as 0.0 to 1.0.
  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

  /// Progress as 0 to 100.
  int get progressPercent => (progress * 100).round();

  /// Which file is currently downloading.
  final String currentFile;

  const CombinedDownloadProgress({
    required this.downloadedBytes,
    required this.totalBytes,
    required this.currentFile,
  });
}

/// Downloads SmolVLM2 model files (GGUF + mmproj) with progress and resume.
///
/// Wraps Edge-Veda's [ModelManager] which provides HTTP Range header resume,
/// atomic temp-file rename, retry with exponential backoff, and checksum
/// verification. We add combined progress tracking across both files and
/// copy the final files to Documents directory for iOS persistence.
class ModelDownloader {
  final ModelManager _modelManager = ModelManager();
  final StreamController<CombinedDownloadProgress> _progressController =
      StreamController<CombinedDownloadProgress>.broadcast();

  /// Stream of combined download progress updates.
  Stream<CombinedDownloadProgress> get progressStream =>
      _progressController.stream;

  /// Download both model files sequentially with combined progress.
  ///
  /// Downloads the main GGUF model first, then the mmproj file.
  /// Yields combined progress across both files.
  /// Files are stored in Documents/models/ for iOS persistence.
  ///
  /// Returns the paths to both downloaded files as a record.
  Future<({String modelPath, String mmprojPath})> downloadAll() async {
    final totalBytes = ModelConfig.totalDownloadBytes;
    var cumulativeBytes = 0;

    // Subscribe to ModelManager progress for real-time updates
    StreamSubscription<DownloadProgress>? progressSub;

    try {
      // --- Download main model ---
      progressSub = _modelManager.downloadProgress.listen((progress) {
        final combinedDownloaded = cumulativeBytes + progress.downloadedBytes;
        _progressController.add(CombinedDownloadProgress(
          downloadedBytes: combinedDownloaded,
          totalBytes: totalBytes,
          currentFile: ModelConfig.modelFileName,
        ));
      });

      final sdkModelPath = await _modelManager.downloadModel(
        ModelConfig.modelInfo,
        verifyChecksum: false, // No checksum available in ModelRegistry
      );
      await progressSub.cancel();
      cumulativeBytes += ModelConfig.modelSizeBytes;

      // --- Download mmproj ---
      progressSub = _modelManager.downloadProgress.listen((progress) {
        final combinedDownloaded = cumulativeBytes + progress.downloadedBytes;
        _progressController.add(CombinedDownloadProgress(
          downloadedBytes: combinedDownloaded,
          totalBytes: totalBytes,
          currentFile: ModelConfig.mmprojFileName,
        ));
      });

      final sdkMmprojPath = await _modelManager.downloadModel(
        ModelConfig.mmprojInfo,
        verifyChecksum: false,
      );
      await progressSub.cancel();

      // --- Copy to Documents/models/ for iOS persistence ---
      // ModelManager stores in Application Support; we also need copies in
      // Documents/models/ since that's where VisionWorker will look.
      final modelDestPath = await ModelConfig.modelPath;
      final mmprojDestPath = await ModelConfig.mmprojPath;

      // Ensure target directory exists
      await ModelConfig.modelDir;

      // Copy if paths differ (they will if ModelManager uses Application Support)
      if (sdkModelPath != modelDestPath) {
        await File(sdkModelPath).copy(modelDestPath);
      }
      if (sdkMmprojPath != mmprojDestPath) {
        await File(sdkMmprojPath).copy(mmprojDestPath);
      }

      // Emit final 100% progress
      _progressController.add(CombinedDownloadProgress(
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        currentFile: 'complete',
      ));

      return (modelPath: modelDestPath, mmprojPath: mmprojDestPath);
    } catch (e) {
      await progressSub?.cancel();
      rethrow;
    }
  }

  /// Check if both model files are already downloaded and ready.
  Future<bool> isModelReady() => ModelConfig.isModelReady;

  /// Cancel an in-progress download.
  void cancel() {
    _modelManager.cancelDownload();
  }

  /// Dispose resources.
  void dispose() {
    _progressController.close();
    _modelManager.dispose();
  }
}
