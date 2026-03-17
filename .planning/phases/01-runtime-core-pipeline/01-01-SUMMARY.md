---
phase: 01-runtime-core-pipeline
plan: 01
subsystem: runtime
tags: [flutter, edge-veda, riverpod, freezed, vision-worker, model-download, go-router, smolvlm2]

# Dependency graph
requires: []
provides:
  - Flutter project scaffolded with all Phase 1 dependencies
  - ModelConfig with verified SmolVLM2 Q8_0 URLs and file sizes from ModelRegistry
  - RuntimeState freezed sealed union (5 states)
  - ModelDownloader with progress streaming and resume via Edge-Veda ModelManager
  - EdgeVedaRuntime AsyncNotifier managing VisionWorker lifecycle
  - Download screen with all 5 UI states (needsDownload/downloading/initializing/ready/error)
  - go_router navigation between download and OCR placeholder screens
affects: [01-02-PLAN, 01-03-PLAN]

# Tech tracking
tech-stack:
  added: [edge_veda ^2.5.0, flutter_riverpod ^3.3.1, riverpod_annotation ^4.0.2, freezed_annotation ^3.1.0, freezed ^3.2.5, riverpod_generator ^4.0.3, path_provider ^2.1.5, image ^4.8.0, go_router ^15.1.2, build_runner ^2.12.2]
  patterns: [Riverpod AsyncNotifier for runtime state, Freezed sealed unions for state modeling, Service-mediated inference (UI never calls VisionWorker directly), ModelManager delegation for downloads]

key-files:
  created:
    - lib/core/constants/model_config.dart
    - lib/runtime/runtime_state.dart
    - lib/runtime/runtime_state.freezed.dart
    - lib/runtime/model_downloader.dart
    - lib/runtime/edge_veda_runtime.dart
    - lib/runtime/edge_veda_runtime.g.dart
    - lib/features/onboarding/presentation/download_screen.dart
    - lib/features/onboarding/presentation/download_view_model.dart
    - lib/features/onboarding/presentation/download_view_model.g.dart
    - lib/main.dart
    - lib/app.dart
    - ios/Podfile
    - pubspec.yaml
    - analysis_options.yaml
  modified: []

key-decisions:
  - "Use Edge-Veda ModelManager instead of hand-rolling HTTP download -- ModelManager already provides resume, retry, checksum, atomic rename"
  - "Use ModelRegistry.smolvlm2_500m for verified model URLs and sizes instead of hardcoding HuggingFace URLs"
  - "Use Q8_0 quantization (417 MB) per research recommendation -- smaller and higher quality than originally planned Q4_K_M"
  - "mmproj f16 is 190 MB (not 72 MB as estimated) -- corrected from ModelRegistry actual data"
  - "freezed_annotation version constraint lowered from ^3.2.3 to ^3.1.0 (plan version does not exist on pub.dev)"
  - "iOS build verification deferred -- flutter build ios requires macOS; static analysis confirms all Dart code compiles cleanly"

patterns-established:
  - "Riverpod AsyncNotifier with keepAlive for long-lived runtime state"
  - "Freezed sealed union for exhaustive state matching in UI"
  - "ModelDownloader wraps ModelManager for combined multi-file progress"
  - "DownloadViewModel derives display-ready values from runtime state"
  - "UI -> ViewModel -> Runtime -> SDK layering (never skip layers)"

# Metrics
duration: 11min
completed: 2026-03-17
---

# Phase 1 Plan 01: Project Scaffold + Model Download Summary

**Flutter project with Edge-Veda runtime, SmolVLM2 model downloader (progress + resume via ModelManager), and first-launch download screen with 5-state UI**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-17T10:29:41Z
- **Completed:** 2026-03-17T10:40:49Z
- **Tasks:** 2
- **Files modified:** 20

## Accomplishments
- Flutter iOS project scaffolded with edge_veda, riverpod, freezed, go_router and all Phase 1 dependencies
- ModelDownloader wraps Edge-Veda's battle-tested ModelManager for combined progress tracking across model (417 MB) + mmproj (190 MB) with HTTP Range resume
- EdgeVedaRuntime AsyncNotifier manages full VisionWorker lifecycle: check model -> download -> spawn -> initVision -> ready
- Download screen renders 5 distinct states with progress percentage, MB counts, resume messaging, and error recovery
- RuntimeState freezed sealed union enables exhaustive pattern matching in UI layer

## Task Commits

Each task was committed atomically:

1. **Task 1: Scaffold Flutter project with dependencies and core architecture** - `2fe9889` (feat)
2. **Task 2: Model downloader with progress/resume and download UI screen** - `ff654b3` (feat)

## Files Created/Modified
- `pubspec.yaml` - Flutter project with Edge-Veda, Riverpod, Freezed, go_router dependencies
- `lib/main.dart` - App entry with ProviderScope
- `lib/app.dart` - MaterialApp.router with Material 3 theme and go_router routes
- `lib/core/constants/model_config.dart` - SmolVLM2 Q8_0 URLs, file sizes, and Documents directory paths
- `lib/runtime/runtime_state.dart` - Freezed sealed union: uninitialized/downloading/initializing/ready/error
- `lib/runtime/runtime_state.freezed.dart` - Generated freezed code
- `lib/runtime/model_downloader.dart` - Combined model+mmproj download with progress via ModelManager
- `lib/runtime/edge_veda_runtime.dart` - VisionWorker lifecycle as Riverpod AsyncNotifier
- `lib/runtime/edge_veda_runtime.g.dart` - Generated Riverpod provider code
- `lib/features/onboarding/presentation/download_screen.dart` - First-launch download UI with 5 states
- `lib/features/onboarding/presentation/download_view_model.dart` - Display state derivation from RuntimeState
- `lib/features/onboarding/presentation/download_view_model.g.dart` - Generated Riverpod provider code
- `ios/Podfile` - iOS deployment target 15.0 with Flutter pod integration
- `analysis_options.yaml` - Flutter lint rules

## Decisions Made
- **Edge-Veda ModelManager over custom HTTP download:** ModelManager already implements resume via Range headers, retry with exponential backoff, atomic temp-file rename, checksum verification, and Hugging Face mirror fallback. Wrapping it saves significant effort and uses battle-tested code.
- **ModelRegistry for model metadata:** Edge-Veda's ModelRegistry.smolvlm2_500m provides verified download URLs, file sizes (model: 436808704 bytes, mmproj: 199470624 bytes), and model IDs. Eliminates guesswork about file names and sizes.
- **Q8_0 quantization:** Research confirmed only Q8_0 (417 MB) and F16 (820 MB) are officially available. Q8_0 is both smaller and higher quality than the originally estimated Q4_K_M.
- **Documents directory storage:** ModelConfig stores in Documents/models/ per CLAUDE.md constraint. ModelManager uses Application Support, so ModelDownloader copies to Documents after download.
- **iOS build deferred:** Cannot run `flutter build ios` on Windows. Static analysis (flutter analyze) confirms all code compiles with zero errors.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] freezed_annotation version ^3.2.3 does not exist**
- **Found during:** Task 1 (flutter pub get)
- **Issue:** Plan specified `freezed_annotation: ^3.2.3` but that version does not exist on pub.dev
- **Fix:** Changed to `freezed_annotation: ^3.1.0` and `freezed: ^3.2.5` based on available versions
- **Files modified:** pubspec.yaml
- **Verification:** flutter pub get succeeds, build_runner generates freezed code
- **Committed in:** 2fe9889 (Task 1 commit)

**2. [Rule 1 - Bug] Replaced custom HTTP download with Edge-Veda ModelManager**
- **Found during:** Task 2 (reading Edge-Veda source to understand API)
- **Issue:** Plan specified building a custom HTTP downloader with Range headers. Discovered Edge-Veda already provides ModelManager with all required functionality (resume, retry, checksum, atomic rename, HF mirror fallback) plus ModelRegistry with pre-configured SmolVLM2 model metadata.
- **Fix:** Created ModelDownloader as a thin wrapper around ModelManager that adds combined progress tracking for the two-file download (model + mmproj). This follows the research doc's "Don't Hand-Roll" principle.
- **Files modified:** lib/runtime/model_downloader.dart
- **Verification:** flutter analyze passes with zero errors
- **Committed in:** ff654b3 (Task 2 commit)

**3. [Rule 1 - Bug] Updated model file sizes from estimates to verified values**
- **Found during:** Task 2 (reading ModelRegistry source)
- **Issue:** Plan estimated mmproj at ~50-80 MB. ModelRegistry shows actual size is 199470624 bytes (~190 MB). Model size also slightly different: 436808704 vs estimated 458227712.
- **Fix:** Updated ModelConfig with exact sizes from Edge-Veda ModelRegistry
- **Files modified:** lib/core/constants/model_config.dart
- **Verification:** Constants match ModelRegistry.smolvlm2_500m and ModelRegistry.smolvlm2_500m_mmproj
- **Committed in:** ff654b3 (Task 2 commit)

**4. [Rule 1 - Bug] Fixed Riverpod 3.x API: valueOrNull -> value**
- **Found during:** Task 2 (flutter analyze)
- **Issue:** Used `state.valueOrNull` which does not exist in Riverpod 3.x; the correct API is `state.value` (returns nullable)
- **Fix:** Changed to `state.value`
- **Files modified:** lib/runtime/edge_veda_runtime.dart
- **Verification:** flutter analyze passes
- **Committed in:** ff654b3 (Task 2 commit)

---

**Total deviations:** 4 auto-fixed (1 blocking, 3 bug fixes)
**Impact on plan:** All fixes necessary for correctness. Using ModelManager is an improvement over the plan -- less code, more reliable. No scope creep.

## Issues Encountered
- iOS build verification (`flutter build ios --no-codesign`) cannot run on Windows. The `flutter build ios` subcommand is only available on macOS with Xcode. Static analysis (flutter analyze: 0 errors) confirms Dart-level compilation. Full iOS native build must be verified on macOS.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Runtime wrapper ready for Plan 02 (OCR pipeline): EdgeVedaRuntime provides describeFrame() method
- ModelConfig provides all paths Plan 02 and 03 need for model file access
- Download flow complete -- Plans 02 and 03 can assume model is on disk when RuntimeState is ready
- Image preprocessing (isolate-based resize) still needed in Plan 02

## Self-Check: PASSED

- All 14 key files verified present on disk
- Commit 2fe9889 (Task 1) verified in git log
- Commit ff654b3 (Task 2) verified in git log
- flutter analyze: 0 errors, 0 warnings

---
*Phase: 01-runtime-core-pipeline*
*Completed: 2026-03-17*
