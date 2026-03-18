---
phase: 03-complete-user-loop
plan: 02
subsystem: runtime, ui
tags: [edge-veda, telemetry, thermal-monitoring, riverpod, material-banner, ios]

# Dependency graph
requires:
  - phase: 01-runtime-core-pipeline
    provides: "EdgeVedaRuntime with VisionWorker lifecycle and edge_veda dependency"
  - phase: 03-complete-user-loop/01
    provides: "ResultScreen with OCR state handling, error mapping, copy-to-clipboard"
provides:
  - "Riverpod StreamProvider for iOS thermal state via TelemetryService"
  - "Thermal-gated inference blocking at critical state (>=3)"
  - "Thermal warning MaterialBanner in ResultScreen"
  - "Helper functions: thermalMessage, shouldBlockInference, shouldWarnUser"
affects: []

# Tech tracking
tech-stack:
  added: [edge_veda TelemetryService]
  patterns: [thermal-gated inference, graceful degradation on simulator]

key-files:
  created:
    - lib/runtime/thermal_monitor.dart
    - lib/runtime/thermal_monitor.g.dart
  modified:
    - lib/features/ocr/presentation/ocr_view_model.dart
    - lib/features/ocr/presentation/ocr_view_model.g.dart
    - lib/features/ocr/presentation/result_screen.dart

key-decisions:
  - "AsyncValue.value used instead of valueOrNull (not available in Riverpod 3.2.1)"

patterns-established:
  - "Thermal gating pattern: poll getThermalState() before inference, catch and proceed on failure"
  - "Graceful degradation: thermal stream errors yield nominal (0) so app never crashes on simulator"

# Metrics
duration: 5min
completed: 2026-03-18
---

# Phase 3 Plan 02: Thermal Monitoring Summary

**iOS thermal state monitoring via Edge-Veda TelemetryService with inference gating at critical state and MaterialBanner warnings in ResultScreen**

## Performance

- **Duration:** 5 min
- **Started:** 2026-03-18T00:29:43Z
- **Completed:** 2026-03-18T00:34:19Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments
- Created thermalStateProvider StreamProvider wrapping TelemetryService.thermalStateChanges with graceful fallback to nominal on simulator
- Added thermal gating to both extractFromPath() and pickAndExtract() in OcrViewModel -- blocks inference at critical state (>=3) with user-friendly error message
- Added conditional MaterialBanner in ResultScreen with thermostat icon, severity-based colors (errorContainer for serious, error for critical)
- Full build passes: build_runner code generation + flutter analyze with 0 errors

## Task Commits

Each task was committed atomically:

1. **Task 1: Create thermal monitor provider and add thermal gating to OcrViewModel** - `408de24` (feat)
2. **Task 2: Add thermal warning banner to ResultScreen and run full build** - `86e34d3` (feat)

## Files Created/Modified
- `lib/runtime/thermal_monitor.dart` - Riverpod StreamProvider wrapping TelemetryService thermal stream with thermalMessage/shouldBlockInference/shouldWarnUser helpers
- `lib/runtime/thermal_monitor.g.dart` - Generated provider code for thermalStateProvider
- `lib/features/ocr/presentation/ocr_view_model.dart` - Thermal gate before inference in extractFromPath() and pickAndExtract()
- `lib/features/ocr/presentation/ocr_view_model.g.dart` - Regenerated after import changes
- `lib/features/ocr/presentation/result_screen.dart` - Thermal warning MaterialBanner conditionally shown when thermal state >= 2

## Decisions Made
- Used `AsyncValue.value ?? 0` instead of `valueOrNull` -- Riverpod 3.2.1 does not expose `valueOrNull` getter on AsyncValue; `.value` returns null during loading/error which serves the same purpose

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed AsyncValue.valueOrNull to AsyncValue.value**
- **Found during:** Task 2 (ResultScreen thermal banner)
- **Issue:** Plan specified `thermalAsync.valueOrNull ?? 0` but Riverpod 3.2.1 does not have `valueOrNull` getter on AsyncValue
- **Fix:** Changed to `thermalAsync.value ?? 0` which returns null during loading/error states (same behavior)
- **Files modified:** lib/features/ocr/presentation/result_screen.dart
- **Verification:** flutter analyze: 0 errors
- **Committed in:** 86e34d3 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug)
**Impact on plan:** Minor API compatibility fix. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 3 is now complete. All four requirements satisfied:
  - OCR-03: Loading indicators (Plan 03-01)
  - OCR-04: Error messages and empty-result handling (Plan 03-01)
  - OUT-01: Copy to clipboard (Plan 03-01)
  - RT-03: Thermal throttling handling (Plan 03-02)
- Physical device validation remains deferred (requires macOS + Xcode + iPhone 13+)

---
## Self-Check: PASSED

All 5 files verified on disk. Both task commits (408de24, 86e34d3) found in git log.

---
*Phase: 03-complete-user-loop*
*Completed: 2026-03-18*
