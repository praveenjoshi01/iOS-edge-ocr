# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-16)

**Core value:** Instant, private text extraction from any image -- entirely offline on the user's iPhone.
**Current focus:** All 3 phases complete. Thermal monitoring, inference gating, and warning UI integrated.

## Current Position

Phase: 3 of 3 (Complete User Loop)
Plan: 2 of 2 complete in current phase
Status: Phase 3 complete -- all plans executed
Last activity: 2026-03-18 -- Plan 03-02 executed (thermal monitoring, inference gating, warning banner)

Progress: [##########] 100% (2/2 plans)

## Performance Metrics

**Velocity:**
- Total plans completed: 7
- Average duration: 7min
- Total execution time: 0.9 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-runtime-core-pipeline | 3/3 | 24min | 8min |
| 02-image-acquisition | 2/2 | 19min | 10min |
| 03-complete-user-loop | 2/2 | 9min | 5min |

**Recent Trend:**
- Last 5 plans: 5min, 12min, 7min, 4min, 5min
- Trend: stable

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: 3-phase quick-depth structure isolating runtime risk in Phase 1
- [01-01]: Use Edge-Veda ModelManager instead of custom HTTP download -- already provides resume, retry, checksum, atomic rename
- [01-01]: Use ModelRegistry.smolvlm2_500m for verified model metadata (URLs, sizes) instead of hardcoding
- [01-01]: Q8_0 quantization (417 MB model + 190 MB mmproj = 607 MB total) -- officially available, smaller and higher quality than Q4_K_M
- [01-01]: freezed_annotation ^3.1.0 (plan specified ^3.2.3 which does not exist)
- [01-02]: VisionResultResponse uses .description field not .text -- verified from Edge-Veda source
- [01-02]: OcrResult requires sealed class keyword for freezed 3.x compatibility
- [01-02]: OcrViewModel uses synchronous Notifier since OcrState handles all pipeline states internally
- [01-03]: Physical device validation deferred -- requires macOS + Xcode + iPhone 13+
- [01-03]: GitHub Actions CI added for macOS iOS build verification
- [02-01]: DownloadScreen navigates to /home instead of /ocr after model ready
- [02-01]: PreviewScreen uses cacheWidth: 1024 for memory safety alongside ~600MB model
- [02-01]: Services are plain Dart classes, not Riverpod providers
- [02-02]: Camera uses ResolutionPreset.high (720p) -- ImagePreprocessor resizes to 1024px anyway
- [02-02]: HomeScreen converted to ConsumerStatefulWidget for async import state management
- [02-02]: OcrTestScreen uses addPostFrameCallback to auto-start extraction without state-during-build
- [02-02]: PermissionService exposes cameraPermission/photosPermission getters for abstraction
- [03-01]: Error mapping at UI layer (not ViewModel) for separation of concerns
- [03-01]: imagePath required on ResultScreen -- HomeScreen handles all input source selection
- [03-01]: Router redirects to /home if path query param missing (guard against malformed navigation)
- [03-02]: AsyncValue.value used instead of valueOrNull (not available in Riverpod 3.2.1)

### Pending Todos

- Physical device validation of Phase 1 (6 checks) when macOS + iPhone 13+ available

### Blockers/Concerns

- [Research]: SmolVLM2 500M scores 61% on OCRBench -- manage user expectations, never present output as guaranteed-accurate
- [Research]: 607 MB model download on first launch requires dedicated onboarding UX with progress and resume
- [Research]: Flutter camera plugin has known memory leak issues (#29586, #97941) -- test 20+ consecutive captures on device
- [01-03]: Physical device validation deferred -- 6 runtime checks need macOS + Xcode + iPhone 13+

## Session Continuity

Last session: 2026-03-18
Stopped at: Completed 03-02-PLAN.md (thermal monitoring). Phase 3 complete. All 3 phases done.
Resume file: None
