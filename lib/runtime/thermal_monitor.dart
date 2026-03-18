import 'dart:async';
import 'package:edge_veda/edge_veda.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'thermal_monitor.g.dart';

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
@riverpod
Stream<int> thermalState(Ref ref) async* {
  final telemetry = TelemetryService();

  // Seed with initial poll (returns -1 on unsupported platforms)
  try {
    final initial = await telemetry.getThermalState();
    yield initial < 0 ? 0 : initial; // Normalize -1 to 0 (nominal)
  } catch (_) {
    yield 0; // Fallback: assume nominal
  }

  // Then stream changes
  try {
    await for (final event in telemetry.thermalStateChanges) {
      final state = event['thermalState'] as int;
      yield state < 0 ? 0 : state;
    }
  } catch (_) {
    // Stream errored (simulator, unsupported platform).
    // Stay on last yielded value. Don't rethrow -- let provider settle.
  }
}

/// Returns a user-facing message for the given thermal state.
/// Returns empty string when no message should be shown (nominal, fair).
String thermalMessage(int thermalState) {
  return switch (thermalState) {
    2 => 'Your device is warm. Processing may be slower than usual.',
    3 =>
      'Device is too hot. Please wait for it to cool down before extracting text.',
    _ => '', // 0 (nominal), 1 (fair), or unknown -- no message
  };
}

/// Whether inference should be blocked at this thermal state.
bool shouldBlockInference(int thermalState) => thermalState >= 3;

/// Whether a warning should be shown to the user at this thermal state.
bool shouldWarnUser(int thermalState) => thermalState >= 2;
