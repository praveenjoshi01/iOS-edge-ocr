---
phase: 02-image-acquisition
plan: 01
subsystem: ui
tags: [flutter, freezed, go_router, permission_handler, pdf_image_renderer, camera, file_picker]

requires:
  - phase: 01-runtime-core-pipeline
    provides: OCR pipeline (OcrService, OcrViewModel, EdgeVedaRuntime)
provides:
  - ImageInput freezed model with InputSource enum
  - PermissionService for camera and photo library permissions
  - PdfRendererService for PDF first-page rendering
  - HomeScreen with 3 input source buttons
  - PreviewScreen with memory-safe image display and Extract Text
  - GoRouter navigation skeleton (/home, /camera, /preview)
affects: [02-02]

tech-stack:
  added: [camera ^0.12.0, file_picker ^10.3.10, permission_handler ^12.0.1, pdf_image_renderer ^1.0.1]
  patterns: [feature-first file structure, service layer for platform APIs]

key-files:
  created:
    - lib/features/image_input/domain/image_input.dart
    - lib/features/image_input/domain/image_input.freezed.dart
    - lib/features/image_input/data/permission_service.dart
    - lib/features/image_input/data/pdf_renderer_service.dart
    - lib/features/image_input/presentation/home_screen.dart
    - lib/features/image_input/presentation/preview_screen.dart
  modified:
    - pubspec.yaml
    - ios/Podfile
    - ios/Runner/Info.plist
    - lib/app.dart
    - lib/features/onboarding/presentation/download_screen.dart

key-decisions:
  - "DownloadScreen navigates to /home instead of /ocr after model ready"
  - "PreviewScreen uses cacheWidth: 1024 for memory safety alongside ~600MB model"
  - "Camera placeholder used in router -- Plan 02 replaces with real CameraScreen"
  - "PermissionService and PdfRendererService are plain Dart classes, not Riverpod providers"

patterns-established:
  - "Input source cards: Card with InkWell, icon container, title/subtitle, chevron"
  - "File paths passed between screens via URI query parameters with encode/decode"

duration: 12min
completed: 2026-03-17
---

# Plan 02-01: Foundation Summary

**Phase 2 dependencies, iOS permissions, ImageInput model, PermissionService, PdfRendererService, HomeScreen with 3 input buttons, PreviewScreen with memory-safe image display, and GoRouter navigation skeleton**

## Performance

- **Duration:** 12 min
- **Tasks:** 3
- **Files created:** 6
- **Files modified:** 5

## Accomplishments
- Added camera, file_picker, permission_handler, pdf_image_renderer dependencies
- iOS Podfile configured with PERMISSION_CAMERA and PERMISSION_PHOTOS macros
- Info.plist has NSCameraUsageDescription and NSPhotoLibraryUsageDescription
- ImageInput freezed model with InputSource enum (camera, photoLibrary, filesApp)
- PermissionService wraps permission_handler for camera/photos with permanently-denied recovery
- PdfRendererService renders PDF first page to temp JPEG at up to 2048px width
- HomeScreen with 3 large card-style buttons (Camera, Photo Library, Import File)
- PreviewScreen displays image with cacheWidth: 1024 and Extract Text button
- GoRouter updated with /home, /camera (placeholder), /preview, /ocr routes
- DownloadScreen now navigates to /home after model ready

## Task Commits

1. **Task 1: Dependencies, iOS config, domain models** - `9bc90c4` (feat)
2. **Task 2: PermissionService and PdfRendererService** - `c33c155` (feat)
3. **Task 3: HomeScreen, PreviewScreen, router** - `7852563` (feat)

## Files Created/Modified
- `lib/features/image_input/domain/image_input.dart` - ImageInput freezed model with InputSource enum
- `lib/features/image_input/domain/image_input.freezed.dart` - Generated freezed code
- `lib/features/image_input/data/permission_service.dart` - Camera/photos permission requests
- `lib/features/image_input/data/pdf_renderer_service.dart` - PDF first-page to JPEG conversion
- `lib/features/image_input/presentation/home_screen.dart` - 3 input source buttons
- `lib/features/image_input/presentation/preview_screen.dart` - Image preview + Extract Text
- `pubspec.yaml` - Added 4 dependencies
- `ios/Podfile` - PERMISSION_CAMERA/PHOTOS macros
- `ios/Runner/Info.plist` - Camera and photo library usage descriptions
- `lib/app.dart` - GoRouter with /home, /camera, /preview routes
- `lib/features/onboarding/presentation/download_screen.dart` - Navigate to /home

## Decisions Made
- DownloadScreen navigates to /home instead of /ocr after model ready
- PreviewScreen uses cacheWidth: 1024 for memory safety alongside ~600MB model
- Camera placeholder in router (Plan 02 replaces with real CameraScreen)
- Services are plain Dart classes, not Riverpod providers

## Deviations from Plan
None - plan executed as written

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Navigation skeleton complete: Download -> Home -> Preview -> OCR
- HomeScreen Photo Library and Files buttons have placeholder onTap (Plan 02 wires)
- Camera route has placeholder widget (Plan 02 creates CameraScreen)
- PermissionService and PdfRendererService ready for Plan 02 to use

---
*Plan: 02-01 of phase 02-image-acquisition*
*Completed: 2026-03-17*
