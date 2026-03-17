# Phase 2: Image Acquisition - Research

**Researched:** 2026-03-17
**Domain:** Flutter iOS image capture (camera, photo library, Files app), image preview, PDF page rendering, iOS permissions, navigation flow to existing OCR pipeline
**Confidence:** HIGH

## Summary

Phase 2 connects three image input sources (camera, photo library, Files app) to the OCR pipeline built in Phase 1. The core challenge is NOT the image acquisition itself -- camera, image_picker, and file_picker are mature Flutter plugins with well-documented APIs. The real challenges are: (1) memory management when displaying high-resolution photos alongside the ~600 MB model already in GPU memory, (2) camera controller lifecycle management to avoid documented memory leaks, (3) PDF-to-image rendering for Files app imports, and (4) creating a unified ImageInput model that normalizes all three input sources into a single file path before feeding the existing OCR pipeline.

The existing Phase 1 codebase already has the complete OCR pipeline (`OcrService.extractText(String imagePath)`), image preprocessing in a background isolate (`ImagePreprocessor.prepare(String imagePath)`), and a working `OcrViewModel` with state management. Phase 2 needs to replace the test screen's `image_picker`-only flow with a proper three-source input screen, add image preview before extraction, and wire the navigation from input -> preview -> OCR result.

A critical decision for this phase: the `camera` plugin (0.12.0) provides a custom viewfinder with `CameraPreview`, while `image_picker` with `ImageSource.camera` uses the native iOS camera UI. The requirement INPUT-01 specifies "live camera viewfinder," which means the `camera` plugin is required -- `image_picker`'s camera mode delegates to the system camera UI and offers no customization. However, the `camera` plugin has documented memory leak issues on iOS (Flutter issues #29586, #97941) that require careful lifecycle management.

**Primary recommendation:** Use the `camera` plugin for INPUT-01 (custom viewfinder), `image_picker` for INPUT-02 (photo library), and `file_picker` for INPUT-03 (Files app including PDF). Create a unified `ImageInput` freezed model that all three sources produce. Add an image preview screen between acquisition and OCR. Use `permission_handler` for runtime permission management. For PDF rendering, use `pdf_image_renderer` (lightweight, native OS renderers, returns image bytes directly).

## Standard Stack

### Core (Phase 2 specific -- new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| camera | ^0.12.0 | Live camera viewfinder + capture | Official Flutter plugin. Provides CameraPreview widget for custom viewfinder UI. Required by INPUT-01 for live preview. Returns XFile with path to captured image in cache directory. |
| permission_handler | ^12.0.1 | Runtime camera + photo library permissions | Industry standard for iOS permission management. Handles status checking, requesting, and directing users to Settings when permanently denied. Requires Podfile macro configuration. |
| pdf_image_renderer | ^1.0.1 | Render PDF pages to images | Lightweight, uses native OS renderers (CoreGraphics on iOS). Returns Uint8List of rendered page. No bundled PDF engine (unlike pdfrx which bundles PDFium). Minimal binary size impact. |

### Already Present (from Phase 1, reused in Phase 2)

| Library | Version | Purpose | Phase 2 Usage |
|---------|---------|---------|---------------|
| image_picker | ^1.1.2 | Photo library selection | INPUT-02: `ImageSource.gallery` for photo library import. Already in pubspec.yaml. |
| file_picker | (to add) | Files app document import | INPUT-03: Pick images and PDFs from iOS Files app. Referenced in CLAUDE.md stack but not yet in pubspec.yaml. |
| go_router | ^15.1.2 | Navigation | Add routes for camera, preview, and result screens. Already in pubspec.yaml. |
| flutter_riverpod | ^3.3.1 | State management | ViewModels for camera, preview, and input source screens. Already in pubspec.yaml. |
| freezed_annotation | ^3.1.0 | Immutable models | ImageInput model, ImageSource enum. Already in pubspec.yaml. |
| path_provider | ^2.1.5 | File system paths | Temp directory for captured images. Already in pubspec.yaml. |
| image | ^4.8.0 | Image decode/resize | Preprocessing continues to use existing ImagePreprocessor. Already in pubspec.yaml. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| camera plugin (custom viewfinder) | image_picker with ImageSource.camera | image_picker delegates to native iOS camera UI -- no custom viewfinder, no overlay hints, no branding. INPUT-01 explicitly requires "live camera viewfinder." |
| permission_handler | Manual native permission code | permission_handler is the ecosystem standard. Manual native code adds platform channel complexity for the same result. |
| pdf_image_renderer | pdfrx / pdfx | pdfrx bundles PDFium (~10 MB binary size increase) and is primarily a viewer widget, not a page-to-image renderer. pdf_image_renderer uses native CoreGraphics on iOS with zero binary overhead and directly returns image bytes. |
| pdf_image_renderer | Dart-only pdf rendering | No pure-Dart PDF renderer exists that can rasterize pages to images. PDF rendering requires native OS APIs. |

**New dependencies to add to pubspec.yaml:**
```yaml
dependencies:
  camera: ^0.12.0
  file_picker: ^10.3.10
  permission_handler: ^12.0.1
  pdf_image_renderer: ^1.0.1
```

## Architecture Patterns

### Recommended Project Structure (Phase 2 additions)

```
lib/features/image_input/
+-- presentation/
|   +-- home_screen.dart              # Main screen with 3 input source buttons
|   +-- camera_screen.dart            # Live viewfinder + capture button
|   +-- camera_view_model.dart        # Camera lifecycle, permission, capture state
|   +-- camera_view_model.g.dart      # Generated
|   +-- preview_screen.dart           # Image preview + "Extract Text" button
|   +-- preview_view_model.dart       # Manages preview image path and OCR trigger
|   +-- preview_view_model.g.dart     # Generated
+-- domain/
|   +-- image_input.dart              # Freezed: ImageInput model (path, source, dimensions)
|   +-- image_input.freezed.dart      # Generated
|   +-- input_source.dart             # Enum: camera, photoLibrary, filesApp
+-- data/
    +-- permission_service.dart       # Wraps permission_handler for camera + photos
    +-- pdf_renderer_service.dart     # Renders PDF page to temp image file
```

### Navigation Flow (go_router updates)

```
/                    -> DownloadScreen (existing, Phase 1)
/home                -> HomeScreen (NEW - 3 input source buttons)
/camera              -> CameraScreen (NEW - viewfinder + capture)
/preview?path=...    -> PreviewScreen (NEW - image preview + extract button)
/ocr                 -> OcrScreen (updated from OcrTestScreen)
```

### Pattern 1: Unified ImageInput Model

**What:** All three input sources (camera, photo library, Files app) produce the same `ImageInput` model containing a file path and metadata. The OCR pipeline accepts this model, not raw bytes or platform-specific types.

**When to use:** Every image acquisition flow.

**Why:** The existing `OcrService.extractText(String imagePath)` accepts a file path. All three sources naturally produce file paths. By normalizing at the input boundary, the OCR pipeline stays untouched.

**Example:**
```dart
// lib/features/image_input/domain/image_input.dart
@freezed
sealed class ImageInput with _$ImageInput {
  const factory ImageInput({
    required String filePath,       // Absolute path to image file
    required InputSource source,    // camera, photoLibrary, filesApp
    String? originalFileName,       // For files app imports
  }) = _ImageInput;
}

enum InputSource { camera, photoLibrary, filesApp }
```

### Pattern 2: Camera Lifecycle with WidgetsBindingObserver

**What:** The camera controller must be disposed when the app is backgrounded and re-initialized when resumed. Since camera plugin 0.5.0, lifecycle handling is the developer's responsibility.

**When to use:** CameraScreen -- always.

**Why:** Failure to handle lifecycle causes camera resource leaks, black preview on resume, and potential crashes. The camera holds exclusive access to the hardware; not releasing it when backgrounded blocks other apps.

**Example:**
```dart
// Source: Flutter official cookbook + camera plugin docs
class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;
    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,   // 720p for viewfinder
      enableAudio: false,       // OCR app, no audio needed
    );
    await _controller!.initialize();
    if (mounted) setState(() {});
  }
}
```

### Pattern 3: Memory-Safe Image Preview

**What:** When displaying a captured/imported image for preview, always use `cacheWidth`/`cacheHeight` to limit decoded image size in Flutter's image cache. A 12MP image decoded at full resolution consumes ~48 MB of Dart heap -- dangerous with the ~600 MB model already in GPU memory.

**When to use:** PreviewScreen -- always.

**Example:**
```dart
// Source: Flutter Image class docs, ResizeImage
Image.file(
  File(imagePath),
  cacheWidth: 1024,  // Limit decoded size to 1024px width
  fit: BoxFit.contain,
  filterQuality: FilterQuality.medium,
)
```

### Pattern 4: PDF Page to Image Conversion

**What:** When a user imports a PDF from the Files app, render the first page to a temporary image file, then feed that file path into the standard OCR pipeline.

**When to use:** When file_picker returns a PDF file (detected by extension).

**Example:**
```dart
// Source: pdf_image_renderer docs
class PdfRendererService {
  /// Renders the first page of a PDF to a temp JPEG file.
  /// Returns the file path to the rendered image.
  Future<String> renderFirstPage(String pdfPath) async {
    final renderer = PdfImageRenderer(path: pdfPath);
    await renderer.open();
    await renderer.openPage(pageIndex: 0);

    // Get page dimensions
    final size = await renderer.getPageSize(pageIndex: 0);

    // Render at 2x scale for OCR readability, cap at 2048px
    final scale = (2048 / size.width).clamp(0.0, 3.0);

    final imageBytes = await renderer.renderPage(
      pageIndex: 0,
      x: 0,
      y: 0,
      width: size.width.toInt(),
      height: size.height.toInt(),
      scale: scale,
      background: Colors.white,
    );

    await renderer.closePage(pageIndex: 0);
    await renderer.close();

    // Save to temp file
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes!);

    return tempFile.path;
  }
}
```

### Pattern 5: Permission Request Flow

**What:** Request camera and photo library permissions at the point of use (not on app launch). Handle all states: granted, denied, permanently denied (redirect to Settings).

**When to use:** Before opening camera or photo library.

**Example:**
```dart
// Source: permission_handler docs
class PermissionService {
  /// Request camera permission. Returns true if granted.
  Future<bool> requestCamera() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Request photo library permission. Returns true if granted or limited.
  Future<bool> requestPhotos() async {
    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Check if permanently denied and open app settings.
  Future<bool> openSettingsIfDenied(Permission permission) async {
    final status = await permission.status;
    if (status.isPermanentlyDenied) {
      return openAppSettings();
    }
    return false;
  }
}
```

### Anti-Patterns to Avoid

- **Passing raw image bytes between screens:** Pass file paths (strings) via go_router query parameters or Riverpod state. Never put Uint8List in navigation arguments -- it serializes through the platform channel.
- **Requesting all permissions on app launch:** Request camera permission only when user taps camera button. Request photo library permission only when user taps gallery button. This follows Apple's recommendation and improves approval rates.
- **Using ResolutionPreset.max for camera:** `max` captures at full sensor resolution (12MP+). This wastes memory since ImagePreprocessor will resize to 1024px anyway. Use `ResolutionPreset.high` (720p) or `ResolutionPreset.veryHigh` (1080p).
- **Not disposing camera controller on screen exit:** Camera holds exclusive hardware access. Failing to dispose blocks the camera for other apps and leaks memory.
- **Loading full-resolution image in Flutter Image widget:** A 12MP JPEG decoded at full resolution uses ~48 MB of Dart heap. Always specify `cacheWidth`/`cacheHeight` when displaying preview images.
- **Skipping EXIF handling for camera captures:** takePicture() may save images with EXIF rotation data rather than physically rotating pixels. The existing ImagePreprocessor.prepare() handles this via `bakeOrientation`, so always use the preprocessing pipeline.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Camera viewfinder | Custom AVFoundation code via platform channels | `camera` plugin CameraPreview widget | Plugin wraps AVCaptureSession properly, handles orientation, focus, and iOS camera permissions. Custom native code would take weeks. |
| Photo library picker | Custom PHPicker implementation | `image_picker` with ImageSource.gallery | Plugin already uses PHPicker on iOS 14+, handles limited photo access, returns XFile. |
| Files app document picker | Custom UIDocumentPickerViewController | `file_picker` plugin | Plugin wraps UIDocumentPickerViewController, handles iCloud, returns file path. |
| iOS permission management | Manual native permission checking | `permission_handler` package | Handles all permission states (granted, denied, limited, permanentlyDenied), provides `openAppSettings()` for recovery flow. |
| PDF page rendering | Custom CoreGraphics PDF rendering via platform channel | `pdf_image_renderer` package | Uses native CoreGraphics on iOS automatically. Returns Uint8List of rendered page. One method call vs. hundreds of lines of native code. |
| Image display memory management | Manual image decode/resize for preview | Flutter's `cacheWidth`/`cacheHeight` on Image.file | Built into the framework. Decodes at specified resolution, avoiding full-resolution heap allocation. |

**Key insight:** Phase 2 is an integration phase, not a building-from-scratch phase. Every input source has a mature Flutter plugin. The work is wiring them together correctly with proper lifecycle, permission, and memory management.

## Common Pitfalls

### Pitfall 1: Camera Plugin Memory Leak on iOS

**What goes wrong:** The Flutter camera plugin has documented memory leaks on iOS (Flutter issues #29586, #97941). Memory usage climbs with consecutive captures and is never fully freed, eventually causing jetsam kills -- especially dangerous with ~600 MB model already in memory.

**Why it happens:** Camera image buffers allocated in native code are not always released promptly. The image stream mode (`startImageStream`) is the worst offender, but even `takePicture()` can leak if the controller is not properly disposed.

**How to avoid:**
- Use `takePicture()` only, never `startImageStream()` (not needed for OCR -- we want a single still capture, not a stream)
- Dispose camera controller immediately after capture, before navigating to preview
- Implement WidgetsBindingObserver to dispose on backgrounding
- Use `ResolutionPreset.high` (720p), not `max` (full sensor) -- smaller buffers leak less
- Test 20+ consecutive captures on a physical iPhone 13 and monitor memory in Instruments

**Warning signs:** Memory in Instruments climbs after each capture without returning to baseline. App crashes after 10-15 consecutive captures.

### Pitfall 2: Permission Denied with No Recovery Path

**What goes wrong:** User denies camera or photo library permission on first prompt. iOS does not show the permission dialog again -- subsequent requests return `permanentlyDenied`. Without a recovery path, the feature is permanently broken.

**Why it happens:** iOS's one-shot permission model. Once denied, the only recovery is the user manually navigating to Settings > App > Permissions. If the app doesn't guide them there, they think the feature is broken.

**How to avoid:**
- Check permission status before attempting access
- If `permanentlyDenied`, show a dialog explaining why the permission is needed with a "Open Settings" button that calls `openAppSettings()`
- Never silently fail -- always tell the user what happened and how to fix it
- For `limited` photo access (iOS 14+), treat as granted -- the user will see only their selected photos in the picker

**Warning signs:** Users report "camera doesn't work" or "can't access photos" after initially denying permission.

### Pitfall 3: Large Image Preview Exhausts Memory Budget

**What goes wrong:** Displaying a 12MP camera capture or photo library import at full resolution in Flutter's Image widget allocates ~48 MB on the Dart heap. Combined with the ~600 MB model in GPU memory and ~120 MB Flutter engine overhead, this pushes iPhone 13 (4 GB) dangerously close to the jetsam threshold.

**Why it happens:** Flutter's `Image.file` decodes the full image into a Skia bitmap by default. Developers see a correctly displayed image and don't realize the underlying memory cost.

**How to avoid:**
- Always specify `cacheWidth: 1024` (or screen width * devicePixelRatio) when creating `Image.file`
- A 1024px-wide decoded image uses ~4 MB vs ~48 MB for full resolution
- Do not load the original and the preprocessed image simultaneously -- the preview screen should display the original at reduced cache size, then the OCR pipeline processes from the file path separately

**Warning signs:** App crashes on the preview screen, especially with high-resolution images from photo library.

### Pitfall 4: PDF Files from Files App Not Handled

**What goes wrong:** User imports a PDF from the Files app expecting OCR, but the app only handles image files. The PDF file path goes to ImagePreprocessor, which fails to decode it (the Dart `image` package cannot read PDF).

**Why it happens:** `file_picker` returns any file the user selects. If the allowed extensions include PDF (per INPUT-03), the app must convert PDF pages to images before OCR.

**How to avoid:**
- Detect file type by extension after file_picker returns
- If PDF: render first page to a temp image using `pdf_image_renderer`, then feed the temp image path to the OCR pipeline
- If image (JPEG, PNG, HEIC): pass directly to OCR pipeline
- If unsupported type: show clear error message

**Warning signs:** "Failed to decode image" errors when user imports PDFs.

### Pitfall 5: Camera Captured Image in Cache Directory Gets Evicted

**What goes wrong:** `takePicture()` saves the captured image to the app's cache directory. iOS can evict cache files at any time under storage pressure. If the user captures an image, backgrounds the app, and iOS evicts the cache, the preview screen shows nothing or crashes when trying to load the file.

**Why it happens:** Camera plugin docs state: "Images picked using the camera are saved to your application's local cache, and should therefore be expected to only be around temporarily."

**How to avoid:**
- After capture, copy the image from cache to the app's temp directory (or Documents directory if persistence is needed)
- Better yet: move directly to preview and OCR. Don't rely on the cached file being available for long periods
- The current architecture (capture -> preview -> OCR -> result) is fast enough that cache eviction is unlikely mid-flow, but handle FileNotFoundException gracefully

**Warning signs:** Intermittent "file not found" errors on preview screen after backgrounding.

### Pitfall 6: HEIC Images from Photo Library

**What goes wrong:** iOS photo library may return HEIC images. While the Dart `image` package supports JPEG, PNG, WebP, BMP, TIFF, and GIF, HEIC support is not built-in.

**Why it happens:** iOS stores photos in HEIC format by default since iOS 11. The `image_picker` plugin typically converts to JPEG when returning, but behavior may vary with different iOS versions and PHPicker configurations.

**How to avoid:**
- `image_picker` with PHPicker typically returns JPEG even for HEIC source photos -- verify this behavior
- As a fallback, the existing ImagePreprocessor.prepare() will throw an `ArgumentError` if decoding fails -- catch this and show a user-friendly error
- Consider setting `requestFullMetadata: false` on image_picker to ensure consistent JPEG output

**Warning signs:** Decoding failures only on certain photos from the library, especially recent photos.

### Pitfall 7: permission_handler Requires Podfile Configuration

**What goes wrong:** Adding `permission_handler` to pubspec.yaml and running `pod install` is not sufficient. iOS permissions are disabled by default in the plugin. Without adding `GCC_PREPROCESSOR_DEFINITIONS` macros in the Podfile, permission requests silently fail or crash.

**Why it happens:** permission_handler uses compile-time macros to include/exclude permission-specific native code. This reduces binary size by excluding unused permission handlers. But it means the developer must manually enable each permission type.

**How to avoid:**
- Add to Podfile's `post_install` block:
  ```ruby
  config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
    '$(inherited)',
    'PERMISSION_CAMERA=1',
    'PERMISSION_PHOTOS=1',
  ]
  ```
- After modifying Podfile, run `cd ios && pod install && cd ..`
- Verify permissions work on a real device (simulator may behave differently)

**Warning signs:** Permission request returns `.denied` immediately without showing a dialog, even on first request.

## Code Examples

### Complete Camera Capture Flow

```dart
// Source: Flutter camera cookbook + camera plugin docs
// CameraScreen with viewfinder, capture, and lifecycle management

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,            // Back camera
      ResolutionPreset.high,    // 720p -- good enough, saves memory
      enableAudio: false,       // OCR app, no microphone needed
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      // Handle camera init failure (permission denied, hardware error)
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (_isTakingPicture) return; // Prevent double-tap

    setState(() => _isTakingPicture = true);

    try {
      final xFile = await controller.takePicture();
      if (!mounted) return;

      // Navigate to preview with file path
      context.push('/preview?path=${Uri.encodeComponent(xFile.path)}');
    } catch (e) {
      // Handle capture error
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Stack(
        children: [
          // Full-screen camera preview
          Positioned.fill(child: CameraPreview(controller)),
          // Capture button at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton.large(
                onPressed: _isTakingPicture ? null : _takePicture,
                child: _isTakingPicture
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.camera_alt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Photo Library Import

```dart
// Source: image_picker docs
Future<ImageInput?> pickFromGallery() async {
  final picker = ImagePicker();
  final xFile = await picker.pickImage(
    source: ImageSource.gallery,
    // Don't set maxWidth/maxHeight -- ImagePreprocessor handles resize
    // with proper aspect ratio and RGB conversion for VisionWorker.
  );

  if (xFile == null) return null; // User cancelled

  return ImageInput(
    filePath: xFile.path,
    source: InputSource.photoLibrary,
    originalFileName: xFile.name,
  );
}
```

### Files App Import (Image + PDF)

```dart
// Source: file_picker docs + pdf_image_renderer docs
Future<ImageInput?> pickFromFiles() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'heic', 'webp', 'pdf'],
  );

  if (result == null || result.files.isEmpty) return null;

  final file = result.files.single;
  final filePath = file.path!;
  final extension = file.extension?.toLowerCase() ?? '';

  if (extension == 'pdf') {
    // Render first PDF page to temp image
    final renderedPath = await PdfRendererService().renderFirstPage(filePath);
    return ImageInput(
      filePath: renderedPath,
      source: InputSource.filesApp,
      originalFileName: file.name,
    );
  }

  // Image file -- pass through directly
  return ImageInput(
    filePath: filePath,
    source: InputSource.filesApp,
    originalFileName: file.name,
  );
}
```

### Preview Screen with Memory-Safe Image Display

```dart
// Source: Flutter Image class docs
class PreviewScreen extends ConsumerWidget {
  final String imagePath;

  const PreviewScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Column(
        children: [
          // Memory-safe image display
          Expanded(
            child: Image.file(
              File(imagePath),
              cacheWidth: 1024,  // Decode at max 1024px width
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('Unable to display image'),
                );
              },
            ),
          ),
          // Extract Text button
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () {
                // Navigate to OCR with image path
                context.push('/ocr?path=${Uri.encodeComponent(imagePath)}');
              },
              icon: const Icon(Icons.text_fields),
              label: const Text('Extract Text'),
            ),
          ),
        ],
      ),
    );
  }
}
```

### go_router Configuration Update

```dart
// Source: go_router docs
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const DownloadScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/camera',
      builder: (context, state) => const CameraScreen(),
    ),
    GoRoute(
      path: '/preview',
      builder: (context, state) {
        final path = state.uri.queryParameters['path']!;
        return PreviewScreen(imagePath: Uri.decodeComponent(path));
      },
    ),
    GoRoute(
      path: '/ocr',
      builder: (context, state) {
        final path = state.uri.queryParameters['path'];
        return OcrScreen(imagePath: path);
      },
    ),
  ],
);
```

## iOS Configuration Required

### Info.plist additions

```xml
<!-- Camera access for document capture -->
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to capture documents for text extraction.</string>

<!-- Photo library access for importing existing images -->
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to select images for text extraction.</string>
```

Note: NSMicrophoneUsageDescription is NOT needed since we set `enableAudio: false` on CameraController.

### Podfile additions for permission_handler

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      # Enable permission_handler macros for camera and photos
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_CAMERA=1',
        'PERMISSION_PHOTOS=1',
      ]
    end
  end
end
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `image_picker` for camera | `camera` plugin with CameraPreview | Since camera plugin matured | Custom viewfinder, overlay hints, branding. image_picker still used for gallery. |
| Request all permissions on app launch | Request at point of use | Apple guideline, reinforced 2024+ | Better user experience, higher permission grant rates |
| PHPickerViewController (UIKit) | image_picker uses PHPicker automatically on iOS 14+ | image_picker 0.8.1+ | Limited photo access supported, no full library access needed for single-select |
| Manual PDF rendering via CoreGraphics | pdf_image_renderer package | 2024 | One-method-call page rendering, no native code to write |

**Deprecated/outdated:**
- `UIImagePickerController` for camera: Replaced by `camera` plugin for custom viewfinder
- `UIImagePickerController` for gallery: Replaced by PHPicker (via image_picker) on iOS 14+
- Requesting `NSPhotoLibraryAddUsageDescription`: Not needed for read-only photo access

## Open Questions

1. **image_picker HEIC-to-JPEG automatic conversion**
   - What we know: image_picker with PHPicker on iOS 14+ reportedly converts HEIC to JPEG on return
   - What's unclear: Whether this is guaranteed behavior across all iOS versions, or if HEIC files can sometimes be returned
   - Recommendation: Trust image_picker's conversion but handle decode failure in ImagePreprocessor gracefully with a user-friendly error

2. **Camera resolution for OCR quality**
   - What we know: ResolutionPreset.high (720p) saves memory, but OCR might benefit from higher resolution input before the 1024px resize
   - What's unclear: Whether the quality difference between high (720p) and veryHigh (1080p) matters after ImagePreprocessor resizes to 1024px
   - Recommendation: Start with ResolutionPreset.high. If OCR quality testing reveals issues with small text, upgrade to veryHigh (1080p). Never use max.

3. **file_picker copy behavior on iOS**
   - What we know: file_picker may copy files from iCloud to a temporary location before returning the path
   - What's unclear: Whether the copied file persists long enough for OCR processing to complete
   - Recommendation: Process the file immediately after selection. Don't rely on the path being valid after extended delays.

## Sources

### Primary (HIGH confidence)
- [camera pub.dev v0.12.0](https://pub.dev/packages/camera) -- API, ResolutionPreset, lifecycle docs
- [image_picker pub.dev v1.2.1](https://pub.dev/packages/image_picker) -- PHPicker integration, XFile return type
- [file_picker pub.dev v10.3.10](https://pub.dev/packages/file_picker) -- iOS Files app integration, custom extensions
- [permission_handler pub.dev v12.0.1](https://pub.dev/packages/permission_handler) -- iOS permission macros, Podfile setup
- [pdf_image_renderer pub.dev v1.0.1](https://pub.dev/packages/pdf_image_renderer) -- Native PDF page rendering API
- [Flutter official camera cookbook](https://docs.flutter.dev/cookbook/plugins/picture-using-camera) -- CameraController lifecycle, takePicture(), preview pattern
- [Flutter Image class docs](https://api.flutter.dev/flutter/widgets/Image-class.html) -- cacheWidth/cacheHeight for memory optimization
- [Flutter camera issue #29586](https://github.com/flutter/flutter/issues/29586) -- iOS memory leak documentation
- [Flutter camera issue #97941](https://github.com/flutter/flutter/issues/97941) -- startImageStream memory crash on iOS

### Secondary (MEDIUM confidence)
- [ResizeImage class docs](https://api.flutter.dev/flutter/painting/ResizeImage-class.html) -- Memory reduction up to 96% for decoded images
- [permission_handler GitHub Podfile example](https://github.com/Baseflow/flutter-permission-handler/blob/main/permission_handler/example/ios/Podfile) -- GCC_PREPROCESSOR_DEFINITIONS setup
- [go_router pub.dev v15.1.2](https://pub.dev/packages/go_router) -- Query parameter navigation patterns
- [Camera plugin: fix for dispatch queue pixel buffer synchronization](https://pub.dev/packages/camera/changelog) -- Recent iOS fixes for race conditions

### Tertiary (LOW confidence, needs validation)
- image_picker guaranteed HEIC-to-JPEG conversion on all iOS versions -- inferred from PHPicker behavior, not explicitly documented
- Camera ResolutionPreset.high impact on OCR quality -- needs empirical testing with SmolVLM2
- file_picker iCloud file copy persistence duration -- behavior varies by iOS version and storage pressure

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages verified on pub.dev with current versions, APIs well-documented
- Architecture patterns: HIGH -- follows existing Phase 1 patterns (service-mediated, file-path-based), extends with proven Flutter patterns
- Navigation flow: HIGH -- go_router query parameters are standard pattern, existing router just needs new routes
- Permissions: HIGH -- permission_handler setup is well-documented, Podfile macros are mandatory and documented
- Camera lifecycle: HIGH -- WidgetsBindingObserver pattern is from Flutter official cookbook
- Memory management: HIGH -- cacheWidth/cacheHeight is documented Flutter API, memory impact is well-characterized
- PDF rendering: MEDIUM -- pdf_image_renderer is less widely used than pdfrx but its API is simpler for our use case
- Pitfalls: HIGH -- camera memory leaks, permission handling, and image memory are well-documented in Flutter issue tracker

**Research date:** 2026-03-17
**Valid until:** 2026-04-17 (30 days -- stable domain, plugins update infrequently)
