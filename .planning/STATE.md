# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-16)

**Core value:** Instant, private text extraction from any image -- entirely offline on the user's iPhone.
**Current focus:** Phase 3 in progress. ResultScreen polished with copy, error handling, empty-result state.

## Current Position

Phase: 3 of 3 (Complete User Loop)
Plan: 1 of 2 complete in current phase
Status: Executing Phase 3 -- Plan 03-01 complete, Plan 03-02 next
Last activity: 2026-03-18 -- Plan 03-01 executed (ResultScreen with copy, errors, empty-result, retry)

Progress: [#####-----] 50% (1/2 plans)

## Performance Metrics

**Velocity:**
- Total plans completed: 6
- Average duration: 8min
- Total execution time: 0.8 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-runtime-core-pipeline | 3/3 | 24min | 8min |
| 02-image-acquisition | 2/2 | 19min | 10min |
| 03-complete-user-loop | 1/2 | 4min | 4min |

**Recent Trend:**
- Last 5 plans: 8min, 5min, 12min, 7min, 4min
- Trend: improving

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

### Pending Todos

- Physical device validation of Phase 1 (6 checks) when macOS + iPhone 13+ available

### Blockers/Concerns

- [Research]: SmolVLM2 500M scores 61% on OCRBench -- manage user expectations, never present output as guaranteed-accurate
- [Research]: 607 MB model download on first launch requires dedicated onboarding UX with progress and resume
- [Research]: Flutter camera plugin has known memory leak issues (#29586, #97941) -- test 20+ consecutive captures on device
- [01-03]: Physical device validation deferred -- 6 runtime checks need macOS + Xcode + iPhone 13+

## Session Continuity

Last session: 2026-03-18
Stopped at: Completed 03-01-PLAN.md (ResultScreen polish). Next: 03-02-PLAN.md.
Resume file: None
