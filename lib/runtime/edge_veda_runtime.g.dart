// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edge_veda_runtime.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(EdgeVedaRuntime)
final edgeVedaRuntimeProvider = EdgeVedaRuntimeProvider._();

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
final class EdgeVedaRuntimeProvider
    extends $AsyncNotifierProvider<EdgeVedaRuntime, RuntimeState> {
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
  EdgeVedaRuntimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'edgeVedaRuntimeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$edgeVedaRuntimeHash();

  @$internal
  @override
  EdgeVedaRuntime create() => EdgeVedaRuntime();
}

String _$edgeVedaRuntimeHash() => r'c749412d3d2a1405d53f0c357b816a092679625a';

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

abstract class _$EdgeVedaRuntime extends $AsyncNotifier<RuntimeState> {
  FutureOr<RuntimeState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<RuntimeState>, RuntimeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<RuntimeState>, RuntimeState>,
              AsyncValue<RuntimeState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
