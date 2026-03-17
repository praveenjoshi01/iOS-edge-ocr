// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'download_view_model.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// View model for the download screen.
///
/// Watches [EdgeVedaRuntime] state and exposes formatted display values
/// and actions for the UI layer.

@ProviderFor(DownloadViewModel)
final downloadViewModelProvider = DownloadViewModelProvider._();

/// View model for the download screen.
///
/// Watches [EdgeVedaRuntime] state and exposes formatted display values
/// and actions for the UI layer.
final class DownloadViewModelProvider
    extends $NotifierProvider<DownloadViewModel, DownloadDisplayState> {
  /// View model for the download screen.
  ///
  /// Watches [EdgeVedaRuntime] state and exposes formatted display values
  /// and actions for the UI layer.
  DownloadViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'downloadViewModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$downloadViewModelHash();

  @$internal
  @override
  DownloadViewModel create() => DownloadViewModel();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DownloadDisplayState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DownloadDisplayState>(value),
    );
  }
}

String _$downloadViewModelHash() => r'b48e2e1e35cfc74e9c05a40fb305632e07e00e98';

/// View model for the download screen.
///
/// Watches [EdgeVedaRuntime] state and exposes formatted display values
/// and actions for the UI layer.

abstract class _$DownloadViewModel extends $Notifier<DownloadDisplayState> {
  DownloadDisplayState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DownloadDisplayState, DownloadDisplayState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DownloadDisplayState, DownloadDisplayState>,
              DownloadDisplayState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
