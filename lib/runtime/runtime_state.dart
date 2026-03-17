import 'package:freezed_annotation/freezed_annotation.dart';

part 'runtime_state.freezed.dart';

/// Sealed union representing all possible states of the Edge-Veda runtime.
///
/// State transitions:
///   uninitialized -> downloading -> initializing -> ready
///                                                -> error
///   error -> downloading (retry)
@freezed
sealed class RuntimeState with _$RuntimeState {
  /// Model not yet downloaded. Initial state on first launch.
  const factory RuntimeState.uninitialized() = RuntimeStateUninitialized;

  /// Model download in progress.
  /// [progress] is 0.0 to 1.0, [downloadedBytes] and [totalBytes] for display.
  const factory RuntimeState.downloading({
    required double progress,
    required int downloadedBytes,
    required int totalBytes,
  }) = RuntimeStateDownloading;

  /// Model downloaded, VisionWorker being initialized.
  const factory RuntimeState.initializing() = RuntimeStateInitializing;

  /// VisionWorker ready for inference.
  const factory RuntimeState.ready() = RuntimeStateReady;

  /// Error occurred during download or initialization.
  const factory RuntimeState.error(String message) = RuntimeStateError;
}
