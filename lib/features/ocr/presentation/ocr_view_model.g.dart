// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ocr_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Manages the OCR pipeline lifecycle as a Riverpod Notifier.
///
/// Orchestrates: pick image -> preprocess -> infer -> display result.
/// UI watches this provider and renders the appropriate state.
///
/// Architecture: OcrTestScreen -> OcrViewModel -> OcrService -> EdgeVedaRuntime
/// The view model never imports edge_veda or calls VisionWorker directly.

@ProviderFor(OcrViewModel)
final ocrViewModelProvider = OcrViewModelProvider._();

/// Manages the OCR pipeline lifecycle as a Riverpod Notifier.
///
/// Orchestrates: pick image -> preprocess -> infer -> display result.
/// UI watches this provider and renders the appropriate state.
///
/// Architecture: OcrTestScreen -> OcrViewModel -> OcrService -> EdgeVedaRuntime
/// The view model never imports edge_veda or calls VisionWorker directly.
final class OcrViewModelProvider
    extends $NotifierProvider<OcrViewModel, OcrState> {
  /// Manages the OCR pipeline lifecycle as a Riverpod Notifier.
  ///
  /// Orchestrates: pick image -> preprocess -> infer -> display result.
  /// UI watches this provider and renders the appropriate state.
  ///
  /// Architecture: OcrTestScreen -> OcrViewModel -> OcrService -> EdgeVedaRuntime
  /// The view model never imports edge_veda or calls VisionWorker directly.
  OcrViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ocrViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ocrViewModelHash();

  @$internal
  @override
  OcrViewModel create() => OcrViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OcrState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OcrState>(value),
    );
  }
}

String _$ocrViewModelHash() => r'9b1cb90db757b320e0c8d9268644075ee2d4d296';

/// Manages the OCR pipeline lifecycle as a Riverpod Notifier.
///
/// Orchestrates: pick image -> preprocess -> infer -> display result.
/// UI watches this provider and renders the appropriate state.
///
/// Architecture: OcrTestScreen -> OcrViewModel -> OcrService -> EdgeVedaRuntime
/// The view model never imports edge_veda or calls VisionWorker directly.

abstract class _$OcrViewModel extends $Notifier<OcrState> {
  OcrState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OcrState, OcrState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OcrState, OcrState>,
              OcrState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
