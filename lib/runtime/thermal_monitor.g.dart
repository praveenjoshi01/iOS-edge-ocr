// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thermal_monitor.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Streams the iOS thermal state from Edge-Veda TelemetryService.
///
/// Values: 0=nominal, 1=fair, 2=serious, 3=critical, -1=unknown/unsupported.
///
/// Uses autoDispose so the stream subscription is cleaned up when no widget
/// is watching. Seeds with an initial poll via getThermalState() to avoid
/// a brief "loading" flash when the screen first appears.
///
/// On simulator or unsupported platforms, the stream may error. The provider
/// catches this and falls back to 0 (nominal) so the app never crashes
/// due to thermal monitoring unavailability.

@ProviderFor(thermalState)
final thermalStateProvider = ThermalStateProvider._();

/// Streams the iOS thermal state from Edge-Veda TelemetryService.
///
/// Values: 0=nominal, 1=fair, 2=serious, 3=critical, -1=unknown/unsupported.
///
/// Uses autoDispose so the stream subscription is cleaned up when no widget
/// is watching. Seeds with an initial poll via getThermalState() to avoid
/// a brief "loading" flash when the screen first appears.
///
/// On simulator or unsupported platforms, the stream may error. The provider
/// catches this and falls back to 0 (nominal) so the app never crashes
/// due to thermal monitoring unavailability.

final class ThermalStateProvider
    extends $FunctionalProvider<AsyncValue<int>, int, Stream<int>>
    with $FutureModifier<int>, $StreamProvider<int> {
  /// Streams the iOS thermal state from Edge-Veda TelemetryService.
  ///
  /// Values: 0=nominal, 1=fair, 2=serious, 3=critical, -1=unknown/unsupported.
  ///
  /// Uses autoDispose so the stream subscription is cleaned up when no widget
  /// is watching. Seeds with an initial poll via getThermalState() to avoid
  /// a brief "loading" flash when the screen first appears.
  ///
  /// On simulator or unsupported platforms, the stream may error. The provider
  /// catches this and falls back to 0 (nominal) so the app never crashes
  /// due to thermal monitoring unavailability.
  ThermalStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'thermalStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$thermalStateHash();

  @$internal
  @override
  $StreamProviderElement<int> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<int> create(Ref ref) {
    return thermalState(ref);
  }
}

String _$thermalStateHash() => r'8356181c612056ce3b705023f5561028db8e9663';
