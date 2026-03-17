# Phase 3: Complete User Loop - Research

**Researched:** 2026-03-17
**Domain:** Loading states, error handling, clipboard UX, and thermal/QoS monitoring for on-device OCR
**Confidence:** HIGH

## Summary

Phase 3 closes the user loop by transforming the existing functional-but-bare OcrTestScreen into a polished result screen with loading indicators, actionable error messages, one-tap clipboard copy with visual confirmation, and thermal state awareness. This phase is low technical risk because all required APIs are available in the existing dependency set -- no new packages are needed.

The existing codebase already has partial implementations of several Phase 3 requirements: OcrTestScreen already shows CircularProgressIndicator during preprocessing/inferring states (OCR-03 partially done), already has an _ErrorView with error message display (OCR-04 partially done), and the OcrState sealed class already models all pipeline states cleanly. The primary work is elevating these from "test screen" quality to "shipping product" quality: user-friendly error messages instead of raw exception strings, a dedicated copy button with SnackBar confirmation, empty-result handling as a distinct UX state, and integration with Edge-Veda's TelemetryService/RuntimePolicy for thermal state monitoring.

Edge-Veda 2.5.0 provides a complete thermal monitoring stack that is already in the project's dependency tree but not yet integrated. The `TelemetryService` class exposes iOS ProcessInfo.thermalState via MethodChannel (values 0-3: nominal/fair/serious/critical) with both polling (`getThermalState()`) and push-based (`thermalStateChanges` EventChannel stream) APIs. The `RuntimePolicy` class maps thermal+memory+battery signals to four QoS levels (full/reduced/minimal/paused) with hysteresis to prevent oscillation. The `Scheduler` orchestrates these at a higher level, but for single-workload OCR, direct use of TelemetryService + RuntimePolicy is sufficient and simpler.

**Primary recommendation:** Upgrade the existing OcrTestScreen into a proper ResultScreen with copy-to-clipboard, improve error messages to be user-friendly, integrate TelemetryService for thermal monitoring via a Riverpod provider, and surface QoS state in the UI when thermal pressure is detected. No new dependencies needed.

## Standard Stack

### Core (Phase 3 specific -- no new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter Clipboard API | (built-in) | Copy extracted text to system clipboard | `Clipboard.setData(ClipboardData(text: ...))` from `flutter/services.dart`. Built-in, no package needed. Async with Future<void> return. |
| Flutter SnackBar | (built-in) | Visual confirmation of clipboard copy | `ScaffoldMessenger.of(context).showSnackBar(...)`. Material 3 standard pattern. |
| edge_veda TelemetryService | ^2.5.0 | iOS thermal state polling and push notifications | Already in dependency tree. Provides `getThermalState()`, `thermalStateChanges` stream, `snapshot()` for all-at-once polling. |
| edge_veda RuntimePolicy | ^2.5.0 | QoS level calculation from thermal/memory/battery signals | Already in dependency tree. Maps signals to QoSLevel enum (full/reduced/minimal/paused) with hysteresis. |
| edge_veda QoSLevel | ^2.5.0 | Four-tier quality-of-service enum | `QoSLevel.full`, `.reduced`, `.minimal`, `.paused`. Ordered by severity. |
| flutter_riverpod | ^3.3.1 | State management for thermal state provider | Already in use. New provider wraps TelemetryService stream for UI consumption. |

### Supporting (already in project)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| freezed_annotation | ^3.1.0 | Immutable state classes | If new state models needed for thermal state (may not need -- TelemetrySnapshot is already immutable). |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Edge-Veda TelemetryService | `thermal` package (v1.1.12) | Third-party package provides same iOS ProcessInfo.thermalState access but adds redundant dependency. Edge-Veda already bundles the MethodChannel implementation. Use Edge-Veda's built-in. |
| Manual RuntimePolicy integration | Edge-Veda Scheduler | Scheduler is designed for multi-workload orchestration (vision + text + STT). For single-workload OCR, Scheduler adds complexity without benefit. RuntimePolicy + TelemetryService directly is simpler. |
| SnackBar for copy confirmation | Custom overlay / toast package | SnackBar is the Material Design standard. No reason to add a third-party toast package for this single use case. |

**No new dependencies needed for Phase 3.**

## Architecture Patterns

### Recommended File Changes

```
lib/
+-- features/
|   +-- ocr/
|   |   +-- presentation/
|   |   |   +-- ocr_test_screen.dart   # RENAME to result_screen.dart, major upgrade
|   |   |   +-- ocr_view_model.dart    # Minor: add reset method for retry-with-path
|   |   +-- domain/
|   |       +-- ocr_state.dart         # No changes needed (states already cover all cases)
+-- runtime/
|   +-- edge_veda_runtime.dart         # Add thermal monitoring integration
|   +-- thermal_monitor.dart           # NEW: Riverpod provider wrapping TelemetryService
|   +-- runtime_state.dart             # No changes needed
+-- app.dart                           # Update route: /ocr -> ResultScreen with proper name
```

### Pattern 1: Clipboard Copy with SnackBar Confirmation

**What:** One-tap copy button calls `Clipboard.setData()` and shows a SnackBar with a check icon confirming success.

**When to use:** On the result screen when extracted text is available (OCR-03 complete state).

**Example:**
```dart
// Source: Flutter official services.dart API
import 'package:flutter/services.dart';

Future<void> _copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 20),
          SizedBox(width: 8),
          Text('Copied to clipboard'),
        ],
      ),
      duration: Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
```

### Pattern 2: User-Friendly Error Messages with Retry

**What:** Map raw exception types to actionable, non-technical messages. Provide a retry action that preserves the original image path.

**When to use:** When OCR pipeline fails or returns empty results.

**Example:**
```dart
// Map raw errors to user-friendly messages
String _friendlyErrorMessage(String rawError) {
  if (rawError.contains('VisionWorker not initialized')) {
    return 'The AI model is not ready. Please restart the app and try again.';
  }
  if (rawError.contains('Failed to decode image') ||
      rawError.contains('Cannot read file')) {
    return 'This image could not be read. Try a different image with better quality.';
  }
  if (rawError.contains('memory') || rawError.contains('jetsam')) {
    return 'Not enough memory to process this image. Try closing other apps and retry.';
  }
  // Generic fallback
  return 'Text extraction failed. Please try again with a different image.';
}
```

### Pattern 3: Empty Result Handling

**What:** When OCR completes successfully but returns empty or whitespace-only text, treat it as a distinct UX state rather than showing an empty result screen.

**When to use:** When `OcrResult.text.trim().isEmpty` after successful inference.

**Example:**
```dart
// In the result screen's complete state handler:
if (result.text.trim().isEmpty) {
  // Show "no text found" state with helpful guidance
  return _NoTextFoundView(
    processingTimeMs: result.processingTimeMs,
    onTryAnother: onReset,
  );
}
// Otherwise show normal result with copy button
```

### Pattern 4: Thermal State Monitoring via Riverpod Provider

**What:** Wrap Edge-Veda's TelemetryService.thermalStateChanges stream in a Riverpod StreamProvider. UI widgets watch this provider and show a thermal warning banner when state >= 2 (serious) or disable extraction when state == 3 (critical).

**When to use:** Whenever the OCR screen is visible or inference is about to start.

**Example:**
```dart
// Source: Edge-Veda TelemetryService API (verified from source)
@riverpod
Stream<int> thermalState(Ref ref) {
  final telemetry = TelemetryService();
  // Emit initial state, then stream changes
  return telemetry.thermalStateChanges.map(
    (event) => event['thermalState'] as int,
  );
}

// In UI:
final thermalState = ref.watch(thermalStateProvider);
if (thermalState.valueOrNull != null && thermalState.valueOrNull! >= 2) {
  // Show thermal warning banner
}
```

### Pattern 5: QoS-Aware Inference Gating

**What:** Before starting inference, check thermal state. If critical (3), show a message asking user to wait. If serious (2), show a warning but allow proceeding. Adjust maxTokens based on RuntimePolicy knobs for degraded levels.

**When to use:** At the start of `OcrViewModel.extractFromPath()`.

**Example:**
```dart
// Check thermal state before inference
final thermalState = await TelemetryService().getThermalState();
if (thermalState >= 3) {
  state = const OcrState.error(
    'Device is too hot. Please wait a moment for it to cool down, then try again.'
  );
  return;
}

// Optionally reduce maxTokens under thermal pressure
final policy = RuntimePolicy();
final qos = policy.evaluate(
  thermalState: thermalState,
  batteryLevel: -1.0, // skip battery check
  availableMemoryBytes: 0, // skip memory check
);
final maxTokens = RuntimePolicy.knobsForLevel(qos).maxTokens;
// Use maxTokens in inference call (default 100, reduced to 75 or 50 under pressure)
```

### Anti-Patterns to Avoid

- **Showing raw exception.toString() to users:** Never display `StateError('VisionWorker not initialized...')` in the UI. Map to human-readable messages.
- **Copying empty string to clipboard:** Always check `text.trim().isNotEmpty` before enabling the copy button. Copying nothing confuses users.
- **Ignoring thermal state during inference:** Starting inference when thermal state is critical will likely cause iOS to throttle aggressively, making the 2-5 second inference take 15-30+ seconds. Check before starting.
- **Polling thermal state on a fast timer:** TelemetryService already provides push-based `thermalStateChanges` via EventChannel. Don't poll every 100ms -- use the stream. The Scheduler polls every 2 seconds; if polling manually, match that cadence.
- **Showing thermal warning when model isn't loaded:** Only show thermal state indicators on screens where inference might happen (result screen, not home screen).
- **Using HapticFeedback for copy confirmation:** iOS already provides system-level paste notification (iOS 16+). Adding haptic feedback on top is redundant and can feel jarring.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Clipboard access | Custom platform channel for clipboard | `Clipboard.setData()` from `flutter/services.dart` | Built-in, cross-platform, handles iOS UIPasteboard automatically |
| Copy confirmation UI | Custom overlay or animated widget | `ScaffoldMessenger.showSnackBar()` | Material Design standard, auto-dismisses, handles stacking, works with floating behavior |
| Thermal state monitoring | Custom MethodChannel to ProcessInfo.thermalState | `TelemetryService` from edge_veda | Already implemented, already in dependency tree, handles both polling and push notifications, graceful fallback on unsupported platforms |
| QoS level calculation | Custom thermal-to-quality mapping | `RuntimePolicy.evaluate()` from edge_veda | Implements hysteresis (immediate escalation, gradual restoration with cooldown), handles thermal+memory+battery signals, prevents oscillation |
| Error message mapping | Inline string comparisons | Dedicated error mapping function | Centralizes error-to-message logic, makes it testable, supports future localization |

**Key insight:** Phase 3 has zero dependencies to add. Every API needed is already available in Flutter core or the edge_veda package that's already integrated. The work is purely UI/UX improvement and integration of existing APIs.

## Common Pitfalls

### Pitfall 1: SnackBar Not Visible Due to Missing ScaffoldMessenger

**What goes wrong:** `ScaffoldMessenger.of(context)` fails or shows SnackBar behind the wrong Scaffold if the widget tree doesn't have a Scaffold ancestor at the correct level.

**Why it happens:** go_router creates route-level Scaffolds. If a widget tries to show a SnackBar using a context that doesn't have a ScaffoldMessenger ancestor (or has the wrong one), the SnackBar either crashes or appears on the wrong screen.

**How to avoid:** Always call `ScaffoldMessenger.of(context).showSnackBar()` from within a widget that is a descendant of the Scaffold that should display the SnackBar. In this app, the result screen has its own Scaffold, so using its context is correct.

**Warning signs:** SnackBar doesn't appear after copy, or appears at the bottom of a different screen.

### Pitfall 2: Thermal Stream Errors on Simulator

**What goes wrong:** TelemetryService's `thermalStateChanges` EventChannel emits an error on simulators or unsupported platforms because ProcessInfo.thermalState notifications aren't available.

**Why it happens:** The EventChannel on the native side requires a real device to subscribe to `ProcessInfo.thermalStateDidChangeNotification`. On simulator, the native plugin may not be registered or may error immediately.

**How to avoid:** Wrap the thermal stream subscription in error handling. The StreamProvider should catch errors gracefully and default to "nominal" (0) when thermal monitoring is unavailable. TelemetryService.getThermalState() already returns -1 on unsupported platforms.

**Warning signs:** App crashes on simulator when navigating to result screen. Thermal provider shows AsyncError instead of nominal state.

### Pitfall 3: Copy Button Active When Text Is Empty

**What goes wrong:** User taps "Copy" but `OcrResult.text` is empty (model returned no text). Clipboard gets empty string. SnackBar shows "Copied!" but there's nothing useful on the clipboard.

**Why it happens:** The OCR pipeline completes "successfully" (no exception) but the model genuinely found no text in the image. The result has `text: ""` which passes through without error.

**How to avoid:** Check `result.text.trim().isNotEmpty` before showing the copy button. When text is empty, show a distinct "No text found" state with guidance: "No text was detected in this image. Try a clearer image with visible text."

**Warning signs:** User reports "copy doesn't work" -- they're copying empty strings.

### Pitfall 4: SnackBar Stacking on Rapid Taps

**What goes wrong:** User taps the copy button 5 times quickly, queueing 5 SnackBars that display one after another for 10+ seconds.

**Why it happens:** Each `showSnackBar()` call queues a new SnackBar. ScaffoldMessenger shows them sequentially with animation.

**How to avoid:** Call `ScaffoldMessenger.of(context).clearSnackBars()` before showing a new one. Or use `ScaffoldMessenger.of(context).showSnackBar()` with short duration and call `hideCurrentSnackBar()` first.

**Warning signs:** SnackBars stack up and persist for longer than expected.

### Pitfall 5: Thermal Warning Persists After Navigation Away

**What goes wrong:** User sees thermal warning on result screen, navigates back to home screen, returns to result screen -- thermal warning state is stale or wrong.

**Why it happens:** If the thermal provider is keepAlive, it persists across screens. If it's autoDispose, it restarts when the screen is revisited, potentially missing the current thermal state until the first stream event arrives.

**How to avoid:** Use autoDispose for the thermal provider but seed it with an initial poll via `getThermalState()` before subscribing to the stream. This ensures immediate state on screen entry.

**Warning signs:** Thermal warning flickers or shows "loading" briefly when navigating to result screen.

### Pitfall 6: Retry Without Image Path

**What goes wrong:** User encounters an OCR error and taps "Retry", but the original image path is lost because OcrViewModel.reset() returns to idle state and the path was only passed via navigation.

**Why it happens:** The current OcrTestScreen receives `imagePath` via constructor, and reset() goes to idle state. Re-extraction requires calling `extractFromPath()` again with the same path, but if the screen uses addPostFrameCallback to auto-start only on idle, it would try to re-extract endlessly.

**How to avoid:** The retry button should call `extractFromPath(imagePath)` directly instead of `reset()`. The screen should track the original image path and offer a "Retry" that re-runs extraction, and a separate "Try Different Image" that navigates back to home.

**Warning signs:** Tapping retry either does nothing or causes an infinite extraction loop.

## Code Examples

Verified patterns from official sources:

### Clipboard Copy with Mounted Check
```dart
// Source: Flutter API docs - Clipboard.setData
// Breaking change (Flutter 3.10+): ClipboardData.text is non-nullable
import 'package:flutter/services.dart';

Future<void> copyText(BuildContext context, String text) async {
  if (text.trim().isEmpty) return; // Guard: don't copy empty
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) return; // Guard: widget may have been disposed
  ScaffoldMessenger.of(context)
    ..clearSnackBars() // Prevent stacking
    ..showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
```

### TelemetryService Thermal State Access
```dart
// Source: Edge-Veda 2.5.0 TelemetryService (verified from package source)
import 'package:edge_veda/edge_veda.dart';

// One-shot polling:
final telemetry = TelemetryService();
final thermalState = await telemetry.getThermalState();
// Returns: 0=nominal, 1=fair, 2=serious, 3=critical, -1=unknown

// Push-based stream:
telemetry.thermalStateChanges.listen((event) {
  final state = event['thermalState'] as int; // 0-3
  final timestamp = event['timestamp'] as double; // ms since epoch
});

// All-at-once snapshot:
final snap = await telemetry.snapshot();
// snap.thermalState, snap.batteryLevel, snap.memoryRssBytes,
// snap.availableMemoryBytes, snap.isLowPowerMode
```

### RuntimePolicy QoS Evaluation
```dart
// Source: Edge-Veda 2.5.0 RuntimePolicy (verified from package source)
import 'package:edge_veda/edge_veda.dart';

final policy = RuntimePolicy(
  escalationCooldown: Duration(seconds: 30),
  restoreCooldown: Duration(seconds: 60),
  availableMemoryMinBytes: 200 * 1024 * 1024, // 200 MB
);

// Evaluate with telemetry snapshot
final snap = await TelemetryService().snapshot();
final qosLevel = policy.evaluate(
  thermalState: snap.thermalState,
  batteryLevel: snap.batteryLevel,
  availableMemoryBytes: snap.availableMemoryBytes,
  isLowPowerMode: snap.isLowPowerMode,
);

// Map QoS level to inference parameters
final knobs = RuntimePolicy.knobsForLevel(qosLevel);
// knobs.maxFps (2/1/1/0)
// knobs.resolution (640/480/320/0)
// knobs.maxTokens (100/75/50/0)

// For OCR: use knobs.maxTokens to limit inference under pressure
// QoSLevel.paused -> don't start inference at all
```

### Thermal State to User Message Mapping
```dart
// Thermal state to user-facing message
String thermalMessage(int thermalState) {
  return switch (thermalState) {
    0 => '', // Nominal: no message
    1 => '', // Fair: no message (minor, don't alarm user)
    2 => 'Your device is warm. Processing may be slower than usual.',
    3 => 'Device is too hot. Please wait for it to cool down before extracting text.',
    _ => '', // Unknown: no message
  };
}

// Thermal state to QoS action
bool shouldBlockInference(int thermalState) => thermalState >= 3;
bool shouldWarnUser(int thermalState) => thermalState >= 2;
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw exception.toString() in error UI | Mapped, user-friendly error messages | Industry standard | Users understand what went wrong and what to do about it |
| No copy confirmation | SnackBar with check icon after clipboard copy | Material Design 2+ | Users trust the copy action succeeded without needing to paste-to-verify |
| No thermal awareness | TelemetryService + RuntimePolicy from Edge-Veda | Edge-Veda 2.5.0 | Prevents silent degradation; user knows why processing is slow |
| Custom toast/overlay for confirmations | ScaffoldMessenger SnackBar | Flutter 2.0+ (deprecated Scaffold.of) | ScaffoldMessenger is the canonical way; survives route transitions |

**Deprecated/outdated:**
- `Scaffold.of(context).showSnackBar()`: Deprecated in Flutter 2.0. Use `ScaffoldMessenger.of(context).showSnackBar()`.
- `ClipboardData(text: null)`: No longer allowed since Flutter 3.10.0. Text parameter is non-nullable.

## Open Questions

1. **Exact thermal EventChannel behavior on simulator**
   - What we know: TelemetryService.getThermalState() returns -1 on unsupported platforms. The thermalStateChanges stream uses EventChannel which may emit error on simulator.
   - What's unclear: Whether the stream silently emits nothing or throws a PlatformException when no native plugin is available (simulator).
   - Recommendation: Wrap stream subscription in error handling with fallback to nominal state. Test on simulator during development.
   - **Confidence:** MEDIUM -- need empirical validation on simulator.

2. **Edge-Veda RuntimePolicy maxTokens interaction with OCR quality**
   - What we know: RuntimePolicy maps QoS levels to maxTokens: full=100, reduced=75, minimal=50. Our current OCR inference uses maxTokens=1024.
   - What's unclear: Whether 100 tokens is sufficient for OCR text extraction (typical document text can be 200-500 tokens). The 100-token limit seems designed for continuous video frame description, not single-image OCR.
   - Recommendation: Use RuntimePolicy for thermal-aware gating (block at critical, warn at serious) but do NOT use its maxTokens knobs for OCR. OCR needs more tokens than video description. Use the full 1024 maxTokens at all QoS levels, and only block inference entirely at QoSLevel.paused.
   - **Confidence:** HIGH -- the knob values are verified from source, and 100 tokens is clearly insufficient for OCR output.

3. **Whether to rename OcrTestScreen to ResultScreen**
   - What we know: The roadmap architecture defines `features/result/` as a separate feature. Current OcrTestScreen is in `features/ocr/presentation/`.
   - What's unclear: Whether the planner should create a new ResultScreen in `features/result/` (matching architecture) or upgrade OcrTestScreen in-place.
   - Recommendation: Upgrade OcrTestScreen in-place and rename it to `ResultScreen`. Moving to a new feature directory adds file churn without benefit -- the result screen is tightly coupled to OcrState and OcrViewModel which live in `features/ocr/`. Keep it in `features/ocr/presentation/`.
   - **Confidence:** HIGH -- architectural simplicity favors keeping it in `features/ocr/`.

## Sources

### Primary (HIGH confidence)
- **Edge-Veda TelemetryService source** (`edge_veda-2.5.0/lib/src/telemetry_service.dart`) -- Full API: getThermalState(), thermalStateChanges stream, snapshot(), TelemetrySnapshot class. Verified from local pub cache.
- **Edge-Veda RuntimePolicy source** (`edge_veda-2.5.0/lib/src/runtime_policy.dart`) -- QoSLevel enum (full/reduced/minimal/paused), QoSKnobs class, evaluate() method with hysteresis, knobsForLevel() mapping. Verified from local pub cache.
- **Edge-Veda Scheduler source** (`edge_veda-2.5.0/lib/src/scheduler.dart`) -- onBudgetViolation stream, workload registration, per-workload QoS management. Verified from local pub cache.
- **Edge-Veda Budget source** (`edge_veda-2.5.0/lib/src/budget.dart`) -- EdgeVedaBudget, BudgetConstraint enum, BudgetViolation class, adaptive profiles. Verified from local pub cache.
- **Edge-Veda barrel export** (`edge_veda-2.5.0/lib/edge_veda.dart`) -- Confirms TelemetryService, RuntimePolicy, QoSLevel, QoSKnobs, Scheduler, EdgeVedaBudget are all publicly exported.
- [Flutter Clipboard.setData API](https://api.flutter.dev/flutter/services/Clipboard/setData.html) -- Static Future<void>, ClipboardData(text: String) non-nullable since Flutter 3.10.
- [Flutter SnackBar cookbook](https://docs.flutter.dev/cookbook/design/snackbars) -- ScaffoldMessenger.of(context).showSnackBar() pattern.
- [Apple ProcessInfo.ThermalState](https://developer.apple.com/documentation/foundation/processinfo/thermalstate-swift.enum) -- Four states: nominal, fair, serious, critical.
- **Existing codebase** -- OcrTestScreen, OcrViewModel, OcrState, OcrResult, EdgeVedaRuntime verified from current source files.

### Secondary (MEDIUM confidence)
- [Flutter ClipboardData breaking change](https://docs.flutter.dev/release/breaking-changes/clipboard-data-required) -- text parameter non-nullable since Flutter 3.10.0.
- [GeeksforGeeks - Flutter Copy to Clipboard](https://www.geeksforgeeks.org/flutter/flutter-add-copy-to-clipboard-without-package/) -- Standard pattern confirmation.
- [Edge-Veda GitHub README](https://github.com/ramanujammv1988/edge-veda) -- High-level architecture description confirming TelemetryService, RuntimePolicy, Scheduler roles.
- [Edge-Veda pub.dev](https://pub.dev/packages/edge_veda) -- Version 2.5.0 confirmed, QoS level descriptions verified.

### Tertiary (LOW confidence)
- Thermal EventChannel behavior on iOS simulator -- needs empirical validation on simulator during development.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- All APIs verified from Flutter core docs and Edge-Veda source code in local pub cache. No new dependencies needed.
- Architecture patterns: HIGH -- Patterns follow existing codebase conventions (Riverpod providers, Freezed states, go_router navigation). Changes are incremental additions to existing files.
- Pitfalls: HIGH -- Clipboard and SnackBar pitfalls verified from Flutter docs. Thermal pitfalls verified from Edge-Veda source code (error handling, fallback values documented in source).
- Thermal/QoS API: HIGH -- All class signatures, method parameters, and return types verified from Edge-Veda 2.5.0 source code in local pub cache (not documentation -- actual source).

**Research date:** 2026-03-17
**Valid until:** 2026-04-17 (30 days -- stable domain, all APIs from dependencies already in project)
