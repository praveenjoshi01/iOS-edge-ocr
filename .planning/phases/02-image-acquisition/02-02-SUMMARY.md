---
phase: 02-image-acquisition
plan: 02
subsystem: ui
tags: [flutter, camera, image_picker, file_picker, permission_handler, go_router, riverpod]

requires:
  - phase: 02-image-acquisition/01
    provides: HomeScreen, PreviewScreen, PermissionService, PdfRendererService, GoRouter navigation skeleton
  - phase: 01-runtime-core-pipeline
    provides: OcrService, OcrViewModel, EdgeVedaRuntime, OcrState
provides:
  - CameraScreen with live viewfinder, lifecycle management, and capture
  - Photo library import via ImagePicker on HomeScreen
  - Files app import via FilePicker with PDF rendering on HomeScreen
  - OcrViewModel.extractFromPath() for PreviewScreen OCR flow
  - OcrTestScreen accepts imagePath for auto-extraction
  - Complete user journey: Home -> (any input) -> Preview -> Extract Text -> OCR Result
affects: [03-user-loop]

tech-stack:
  added: []
  patterns: [ConsumerStatefulWidget with WidgetsBindingObserver for camera lifecycle, addPostFrameCallback for auto-triggering notifier methods]

key-files:
  created:
    - lib/features/image_input/presentation/camera_screen.dart
  modified:
    - lib/app.dart
    - lib/features/image_input/presentation/home_screen.dart
    - lib/features/image_input/data/permission_service.dart
    - lib/features/ocr/presentation/ocr_view_model.dart
    - lib/features/ocr/presentation/ocr_test_screen.dart

key-decisions:
  - "Camera uses ResolutionPreset.high (720p) to save memory since ImagePreprocessor resizes to 1024px"
  - "HomeScreen converted from ConsumerWidget to ConsumerStatefulWidget for async import state management"
  - "PDF rendering shows SnackBar loading indicator rather than full-screen overlay"
  - "OcrTestScreen uses addPostFrameCallback to auto-start extraction without modifying state during build"

patterns-established:
  - "Camera lifecycle: dispose on inactive, re-init on resumed via WidgetsBindingObserver"
  - "Permission denied recovery: dialog with Open Settings for permanently denied permissions"
  - "PermissionService exposes cameraPermission/photosPermission getters for isPermanentlyDenied checks"

duration: 7min
completed: 2026-03-17
---

# Plan 02-02: Image Input Wiring Summary

**CameraScreen with live viewfinder and lifecycle management, photo library and Files app imports on HomeScreen, OcrViewModel.extractFromPath for complete Home -> Input -> Preview -> OCR user journey**

## Performance

- **Duration:** 7 min
- **Started:** 2026-03-17T23:12:27Z
- **Completed:** 2026-03-17T23:19:48Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments
- CameraScreen with live viewfinder, WidgetsBindingObserver lifecycle management, capture button with double-tap guard, and permission recovery flow (INPUT-01)
- Photo Library button opens iOS gallery via ImagePicker with permission handling and permanently-denied dialog (INPUT-02)
- Import File button opens iOS Files app via FilePicker, supports images and PDFs with PdfRendererService conversion (INPUT-03)
- OcrViewModel.extractFromPath() enables PreviewScreen to trigger OCR with any pre-selected image path
- OcrTestScreen auto-starts extraction when receiving imagePath from PreviewScreen (INPUT-04)
- Complete end-to-end flow: Home -> Camera/Gallery/Files -> Preview -> Extract Text -> OCR Result
- Camera placeholder removed from GoRouter, replaced with real CameraScreen

## Task Commits

Each task was committed atomically:

1. **Task 1: Create CameraScreen with viewfinder, lifecycle, and capture** - `0d1e351` (feat)
2. **Task 2: Wire photo library, Files app imports, update OcrViewModel** - `31cb9bf` (feat)

## Files Created/Modified
- `lib/features/image_input/presentation/camera_screen.dart` - Live camera viewfinder with lifecycle management and capture
- `lib/features/image_input/presentation/home_screen.dart` - Photo Library and Files app import wired with real logic
- `lib/features/image_input/data/permission_service.dart` - Added cameraPermission/photosPermission getters
- `lib/features/ocr/presentation/ocr_view_model.dart` - Added extractFromPath() method
- `lib/features/ocr/presentation/ocr_test_screen.dart` - Accepts optional imagePath, auto-starts extraction
- `lib/app.dart` - CameraScreen replaces placeholder, /ocr route passes path query param

## Decisions Made
- Camera uses ResolutionPreset.high (720p) to save memory since ImagePreprocessor resizes to 1024px anyway
- HomeScreen converted from ConsumerWidget to ConsumerStatefulWidget for managing async import operations and loading state
- PDF rendering shows SnackBar loading indicator rather than full-screen overlay (lighter weight, non-blocking)
- OcrTestScreen uses WidgetsBinding.instance.addPostFrameCallback to schedule extractFromPath call after build completes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added cameraPermission/photosPermission getters to PermissionService**
- **Found during:** Task 1 (CameraScreen)
- **Issue:** PermissionService.isPermanentlyDenied requires a Permission object, but the service didn't expose Permission constants. Callers would need to import permission_handler directly, breaking the service abstraction.
- **Fix:** Added `cameraPermission` and `photosPermission` getters to PermissionService
- **Files modified:** lib/features/image_input/data/permission_service.dart
- **Verification:** dart analyze passes, CameraScreen and HomeScreen use getters without importing permission_handler
- **Committed in:** 0d1e351 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Essential for maintaining PermissionService abstraction. No scope creep.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All four INPUT requirements (INPUT-01 through INPUT-04) are fulfilled
- Phase 2 (Image Acquisition) is complete
- Complete user journey works: Download -> Home -> (Camera/Gallery/Files) -> Preview -> Extract Text -> OCR Result
- Ready for Phase 3 (User Loop): result display polish, copy/share, error handling improvements

## Self-Check: PASSED

All 7 files verified present on disk. Both task commits (0d1e351, 31cb9bf) verified in git log.

---
*Plan: 02-02 of phase 02-image-acquisition*
*Completed: 2026-03-17*
