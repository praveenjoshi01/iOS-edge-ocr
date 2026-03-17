import 'dart:async';
import 'dart:typed_data';

import 'package:edge_veda/edge_veda.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/constants/model_config.dart';
import 'model_downloader.dart';
import 'runtime_state.dart';

part 'edge_veda_runtime.g.dart';

/// Manages the Edge-Veda VisionWorker lifecycle as a Riverpod AsyncNotifier.
///
/// State transitions:
///   uninitialized -> downloading -> initializing -> ready
///                                                -> error
///   error -> downloading (retry)
///
/// On build: checks if model files exist. If yes, spawns VisionWorker and
/// transitions to ready. If no, returns uninitialized (waiting for user
/// to trigger download).
@Riverpod(keepAlive: true)
class EdgeVedaRuntime extends _$EdgeVedaRuntime {
  VisionWorker? _worker;
  ModelDownloader? _downloader;

  @override
  FutureOr<RuntimeState> build() async {
    // Clean up VisionWorker when provider is disposed
    ref.onDispose(() {
      _worker?.dispose();
      _downloader?.dispose();
    });

    // Check if model is already downloaded
    if (await ModelConfig.isModelReady) {
      // Model exists -- initialize VisionWorker
      return _initializeWorker();
    }

    // Model not present -- wait for user to trigger download
    return const RuntimeState.uninitialized();
  }

  /// Download both model files with progress updates.
  ///
  /// Call this when user taps "Download" on the onboarding screen.
  /// Updates state with downloading progress, then initializes the
  /// VisionWorker once download completes.
  Future<void> downloadModel() async {
    // Guard: don't start download if already downloading or ready
    final currentState = state.value;
    if (currentState is RuntimeStateDownloading ||
        currentState is RuntimeStateReady) {
      return;
    }

    state = const AsyncData(RuntimeState.downloading(
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: 0,
    ));

    try {
      _downloader = ModelDownloader();

      // Listen to progress and update state
      final progressSub = _downloader!.progressStream.listen((progress) {
        state = AsyncData(RuntimeState.downloading(
          progress: progress.progress,
          downloadedBytes: progress.downloadedBytes,
          totalBytes: progress.totalBytes,
        ));
      });

      // Start the download (blocks until complete)
      await _downloader!.downloadAll();
      await progressSub.cancel();

      // Download complete -- initialize VisionWorker
      state = AsyncData(await _initializeWorker());
    } catch (e) {
      _downloader?.dispose();
      _downloader = null;
      state = AsyncData(RuntimeState.error(
        'Download failed: ${e.toString()}',
      ));
    }
  }

  /// Retry after an error. Re-attempts download from where it left off
  /// (ModelManager supports resume via HTTP Range headers).
  Future<void> retryDownload() async {
    await downloadModel();
  }

  /// Run vision inference on an image.
  ///
  /// [rgbBytes] must be interleaved RGB (3 bytes per pixel, R0G0B0R1G1B1...).
  /// Byte count must equal width * height * 3.
  ///
  /// Throws [StateError] if VisionWorker is not initialized.
  Future<VisionResultResponse> describeFrame(
    Uint8List rgbBytes,
    int width,
    int height, {
    String prompt = 'Extract all visible text from this image. '
        'Return only the extracted text, nothing else.',
    int maxTokens = 1024,
    double temperature = 0.0,
  }) async {
    final worker = _worker;
    if (worker == null) {
      throw StateError(
        'VisionWorker not initialized. '
        'Ensure runtime state is RuntimeState.ready() before calling describeFrame.',
      );
    }

    return worker.describeFrame(
      rgbBytes,
      width,
      height,
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
    );
  }

  /// Initialize the VisionWorker with downloaded model files.
  ///
  /// Spawns a persistent worker isolate, loads the model + mmproj,
  /// and transitions to ready state.
  Future<RuntimeState> _initializeWorker() async {
    state = const AsyncData(RuntimeState.initializing());

    try {
      final modelPath = await ModelConfig.modelPath;
      final mmprojPath = await ModelConfig.mmprojPath;

      _worker = VisionWorker();
      await _worker!.spawn();
      await _worker!.initVision(
        modelPath: modelPath,
        mmprojPath: mmprojPath,
        numThreads: 4,
        contextSize: 2048,
        useGpu: true,
      );

      return const RuntimeState.ready();
    } catch (e) {
      _worker = null;
      return RuntimeState.error('Failed to initialize model: ${e.toString()}');
    }
  }
}
