# Architecture Research

**Domain:** On-device OCR Flutter iOS app with vision-language model inference
**Researched:** 2026-03-16
**Confidence:** MEDIUM-HIGH

## Standard Architecture

### System Overview

```
+-----------------------------------------------------------------------+
|                         PRESENTATION LAYER                            |
|  +-------------+  +-------------+  +---------------+  +----------+   |
|  | CameraView  |  | GalleryView |  | FileImportView|  | ResultView|  |
|  +------+------+  +------+------+  +-------+-------+  +-----+----+   |
|         |                |                  |                |        |
|  +------+------+  +------+------+  +-------+-------+  +-----+----+  |
|  | CameraVM    |  | GalleryVM   |  | FileImportVM  |  | ResultVM  |  |
|  +------+------+  +------+------+  +-------+-------+  +-----+----+  |
+--------+------------------+------------------+--------------+---------+
         |                  |                  |              |
+--------v------------------v------------------v--------------+---------+
|                          SERVICE LAYER                                |
|  +-------------------+  +-----------------------+  +--------------+  |
|  | ImageAcquisition  |  | OCRService            |  | ExportService|  |
|  | Service           |  | (prompt + inference)   |  | (copy/share) |  |
|  +--------+----------+  +----------+------------+  +--------------+  |
+-----------|-------------------------|----------------------------------+
            |                         |
+-----------v-------------------------v----------------------------------+
|                        INFRASTRUCTURE LAYER                            |
|  +------------------+  +-----------------------+  +----------------+  |
|  | ImagePreprocessor|  | EdgeVedaRuntime        |  | FileSystem     |  |
|  | (resize, RGB     |  | (VisionWorker,         |  | (temp images,  |  |
|  |  convert, EXIF)  |  |  generateStream,       |  |  model cache)  |  |
|  +------------------+  |  scheduler, QoS)       |  +----------------+  |
|                        +-----------------------+                       |
+-----------+-------------------------+----------------------------------+
            |                         |
+-----------v-------------------------v----------------------------------+
|                         PLATFORM LAYER                                 |
|  +------------------+  +-----------------------+  +----------------+  |
|  | camera plugin    |  | Edge-Veda XCFramework  |  | file_picker    |  |
|  | image_picker     |  | (~31MB, llama.cpp +    |  | share_plus     |  |
|  |                  |  |  Metal GPU, FFI)       |  |                |  |
|  +------------------+  +-----------------------+  +----------------+  |
+-----------------------------------------------------------------------+
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| CameraView / CameraVM | Live camera preview, capture trigger, focus/flash controls | `camera` plugin + StatefulWidget, VM manages capture state |
| GalleryView / GalleryVM | Photo library browsing and selection | `image_picker` with `ImageSource.gallery` |
| FileImportView / FileImportVM | File picker for images and PDFs from Files app | `file_picker` + `pdfrx` for PDF page rendering to images |
| ResultView / ResultVM | Display extracted text, copy/share actions, format toggle | StreamBuilder consuming inference stream, Clipboard API |
| ImageAcquisitionService | Unified interface for getting images from any source | Returns normalized `ImageInput` (path + metadata) |
| OCRService | Orchestrates preprocessing, prompt selection, and inference | Coordinates ImagePreprocessor and EdgeVedaRuntime |
| ExportService | Copy-to-clipboard, system share sheet | `flutter/services` Clipboard + `share_plus` |
| ImagePreprocessor | Resize, EXIF correction, RGB byte conversion | Dart `image` package in isolate for heavy work |
| EdgeVedaRuntime | Manages VisionWorker lifecycle, model init, streaming inference | Thin wrapper over Edge-Veda SDK VisionWorker |
| FileSystem | Temp image storage, model file path management | `path_provider` for app directories |

## Recommended Project Structure

```
lib/
+-- main.dart                    # App entry point, provider setup
+-- app.dart                     # MaterialApp, routing, theme
+-- core/                        # Cross-feature shared code
|   +-- constants/               # App-wide constants
|   |   +-- ocr_prompts.dart     # Prompt templates (from Ollama-OCR strategies)
|   |   +-- model_config.dart    # SmolVLM2 model paths, context lengths
|   +-- theme/                   # App theme definition
|   +-- utils/                   # Generic utilities
|   +-- widgets/                 # Reusable widgets (loading indicators, error banners)
+-- features/
|   +-- image_input/             # FEATURE: acquiring images from any source
|   |   +-- presentation/
|   |   |   +-- camera_screen.dart
|   |   |   +-- camera_view_model.dart
|   |   |   +-- gallery_picker_screen.dart
|   |   |   +-- file_import_screen.dart
|   |   +-- domain/
|   |   |   +-- image_input.dart           # ImageInput model (path, source, metadata)
|   |   +-- data/
|   |       +-- image_acquisition_service.dart
|   |       +-- pdf_renderer_service.dart  # PDF page -> image conversion
|   +-- ocr/                     # FEATURE: text extraction from images
|   |   +-- presentation/
|   |   |   +-- ocr_screen.dart            # Shows progress + streaming result
|   |   |   +-- ocr_view_model.dart        # Manages inference lifecycle
|   |   +-- domain/
|   |   |   +-- ocr_result.dart            # Extracted text + metadata
|   |   |   +-- extraction_format.dart     # Enum: plain, structured, keyValue
|   |   +-- data/
|   |       +-- ocr_service.dart           # Orchestrates preprocess -> infer
|   |       +-- prompt_builder.dart        # Builds prompts per format
|   |       +-- image_preprocessor.dart    # Resize, normalize, RGB conversion
|   +-- result/                  # FEATURE: displaying and exporting text
|   |   +-- presentation/
|   |   |   +-- result_screen.dart
|   |   |   +-- result_view_model.dart
|   |   +-- data/
|   |       +-- export_service.dart        # Clipboard, share sheet
+-- runtime/                     # Edge-Veda SDK integration (not a "feature")
|   +-- edge_veda_runtime.dart   # Init, lifecycle, VisionWorker management
|   +-- vision_worker_manager.dart  # Spawn, init, health monitoring
|   +-- runtime_state.dart       # Model loaded, thermal state, QoS level
|   +-- model_downloader.dart    # Model file verification, paths
ios/
+-- Podfile                      # CocoaPods with Edge-Veda XCFramework
+-- Runner/                      # Standard iOS runner
```

### Structure Rationale

- **`features/` (feature-first):** Each feature groups its presentation, domain, and data layers together. This matches the official Flutter architecture guide recommendation and scales well. Three features map cleanly to the user journey: acquire image, extract text, view/export result.
- **`runtime/`** is deliberately separate from features because Edge-Veda lifecycle management is infrastructure, not a user-facing feature. Multiple features depend on it but it has no UI of its own.
- **`core/constants/ocr_prompts.dart`** centralizes prompt templates because prompts are the primary tuning lever for OCR quality and are referenced by the OCR service. Keeping them in one file enables rapid iteration.
- **No `domain/` layer at top level:** For a focused v1 app with three features and no cross-feature data merging, the official Flutter guide recommends adding a domain/use-case layer only when needed. Premature abstraction would add indirection without benefit.

## Architectural Patterns

### Pattern 1: Service-Mediated Inference (Core Pattern)

**What:** The OCRService acts as the single orchestration point between image preprocessing and Edge-Veda inference. UI never talks to the runtime directly.

**When to use:** Always. This is the backbone of the app.

**Trade-offs:** Adds one layer of indirection, but isolates the UI from runtime complexity (model loading states, thermal throttling, memory pressure). Worth it because Edge-Veda's QoS system can degrade or pause inference at any time.

**Example:**
```dart
class OCRService {
  final EdgeVedaRuntime _runtime;
  final ImagePreprocessor _preprocessor;
  final PromptBuilder _promptBuilder;

  Stream<String> extractText(ImageInput input, ExtractionFormat format) async* {
    // 1. Preprocess: resize + convert to RGB bytes
    final processed = await _preprocessor.prepare(input);

    // 2. Build format-specific prompt (Ollama-OCR strategy)
    final prompt = _promptBuilder.build(format);

    // 3. Stream inference tokens from VisionWorker
    yield* _runtime.describeFrame(
      processed.rgbBytes,
      processed.width,
      processed.height,
      prompt: prompt,
    );
  }
}
```

### Pattern 2: Streaming Token Display

**What:** OCR results arrive as a token stream from Edge-Veda's `generateStream` / `describeFrame`. The UI must render tokens incrementally as they arrive, not wait for the full result.

**When to use:** Every OCR extraction. Vision inference on SmolVLM2 500M takes 2-5 seconds; streaming gives immediate feedback.

**Trade-offs:** Slightly more complex UI state (in-progress vs complete), but dramatically better perceived performance. Users see text appearing in real-time.

**Example:**
```dart
// In OCR ViewModel
class OcrViewModel extends ChangeNotifier {
  String _extractedText = '';
  OcrStatus _status = OcrStatus.idle;

  Stream<String> get textStream => _textStreamController.stream;

  Future<void> runExtraction(ImageInput input, ExtractionFormat format) async {
    _status = OcrStatus.processing;
    notifyListeners();

    final tokenStream = _ocrService.extractText(input, format);
    await for (final token in tokenStream) {
      _extractedText += token;
      _textStreamController.add(_extractedText);
    }

    _status = OcrStatus.complete;
    notifyListeners();
  }
}
```

### Pattern 3: Prompt Strategy Registry (Adapted from Ollama-OCR)

**What:** Different OCR output formats (plain text, structured/markdown, key-value pairs) are achieved by varying the prompt sent to the vision model, not by changing the model or post-processing. This is the core insight from the Ollama-OCR approach.

**When to use:** For every extraction. The prompt is the primary quality lever.

**Trade-offs:** Prompt engineering is iterative and model-specific. SmolVLM2 500M is a small model; complex prompt instructions may degrade quality compared to what Ollama-OCR achieves with larger models like LLaVA or Llama 3.2 Vision. Expect to iterate on prompts extensively.

**Example:**
```dart
class PromptBuilder {
  String build(ExtractionFormat format, {String? language}) {
    switch (format) {
      case ExtractionFormat.plainText:
        return 'Extract all visible text from this image. '
               'Return only the extracted text, nothing else.';
      case ExtractionFormat.structured:
        return 'Extract all text from this image. '
               'Preserve the document structure: headings, paragraphs, '
               'lists, and columns. Use markdown formatting.';
      case ExtractionFormat.keyValue:
        return 'Extract all key-value pairs from this image. '
               'Format each as "key: value" on its own line.';
    }
  }
}
```

### Pattern 4: Lazy Runtime Initialization

**What:** Edge-Veda model loading and VisionWorker initialization happen once, on first use, not at app startup. The runtime stays loaded for the app session.

**When to use:** App startup. SmolVLM2 loads ~600MB into memory; loading it on every extraction would add 3-5 seconds each time.

**Trade-offs:** First extraction is slower (model load + inference). Subsequent extractions are fast (inference only). This matches Edge-Veda's "persistent worker" design philosophy.

**Example:**
```dart
class EdgeVedaRuntime {
  VisionWorker? _worker;
  bool _initialized = false;

  Future<void> ensureInitialized() async {
    if (_initialized) return;

    _worker = VisionWorker();
    await _worker!.spawn();
    await _worker!.initVision(
      modelPath: ModelConfig.smolVlm2Path,
      mmprojPath: ModelConfig.mmprojPath,
      numThreads: 4,
      contextSize: 2048,
      useGpu: true,
    );
    _initialized = true;
  }

  Stream<String> describeFrame(
    Uint8List rgbBytes, int width, int height, {required String prompt}
  ) async* {
    await ensureInitialized();
    final result = await _worker!.describeFrame(
      rgbBytes, width, height,
      prompt: prompt,
      maxTokens: 1024,
    );
    yield result; // Or stream if Edge-Veda supports streaming vision
  }
}
```

## Data Flow

### Primary OCR Flow (Happy Path)

```
User taps "Capture" / selects image / imports file
    |
    v
ImageAcquisitionService
    |  Returns ImageInput(filePath, source, dimensions)
    v
OCRService.extractText(imageInput, format)
    |
    +---> ImagePreprocessor.prepare(imageInput)
    |         |
    |         |  [Runs in Dart isolate to avoid UI jank]
    |         |  1. Decode image from file path
    |         |  2. Read + correct EXIF orientation
    |         |  3. Resize to max 1024px (longer edge)
    |         |  4. Convert to RGB byte array
    |         |
    |         +---> Returns ProcessedImage(rgbBytes, width, height)
    |
    +---> PromptBuilder.build(format)
    |         |
    |         +---> Returns prompt string
    |
    +---> EdgeVedaRuntime.describeFrame(rgbBytes, w, h, prompt)
    |         |
    |         |  [Runs in VisionWorker isolate, Metal GPU]
    |         |  1. Ensure model initialized (lazy load)
    |         |  2. Pass RGB bytes + prompt to VisionWorker
    |         |  3. SmolVLM2 processes image + prompt
    |         |  4. Stream tokens back
    |         |
    |         +---> Yields token stream
    |
    v
OcrViewModel accumulates tokens, updates UI progressively
    |
    v
ResultScreen displays growing text, enables copy/share when complete
    |
    v
ExportService.copyToClipboard(text) / ExportService.share(text)
```

### PDF Import Sub-Flow

```
User selects PDF from Files app
    |
    v
file_picker returns file path
    |
    v
PdfRendererService
    |  1. Open PDF with pdfrx
    |  2. Render selected page to image (raster)
    |  3. Save as temp image file
    |
    v
Returns ImageInput (same as camera/gallery path)
    |
    v
Joins main OCR flow above
```

### State Flow

```
RuntimeState (singleton, app-lifetime)
    |-- modelLoaded: bool
    |-- thermalState: ThermalLevel
    |-- memoryPressure: MemoryLevel
    |-- qosLevel: QoSLevel

OcrState (per-extraction, screen-lifetime)
    |-- status: idle | preprocessing | loading_model | inferring | complete | error
    |-- extractedText: String (accumulating)
    |-- tokenCount: int
    |-- elapsedMs: int
    |-- error: String?
```

### Key Data Flows

1. **Image Acquisition -> OCR:** Unified `ImageInput` model regardless of source (camera, gallery, file, PDF page). All sources converge to a file path before OCR begins.
2. **OCR -> Result Display:** Token stream from VisionWorker flows through OCRService, into ViewModel, and to UI. Text accumulates progressively; UI rebuilds on each token.
3. **Runtime State -> UI:** Thermal throttling and memory pressure from Edge-Veda's QoS system surface as warnings in the UI (e.g., "Device is warm, inference may be slower").

## Scaling Considerations

| Concern | Current App (v1) | Future (v2+) |
|---------|-------------------|--------------|
| Model size in memory | ~600MB for SmolVLM2; fits iPhone 13+ (6GB RAM) | Larger models need model swapping or offloading |
| Concurrent extractions | One at a time; queue additional requests | Edge-Veda scheduler handles priority; vision is second priority after text |
| Batch processing | Not needed for v1 (single image) | Sequential processing with progress bar; reuse loaded model |
| PDF multi-page | Render one page at a time; user selects | Batch all pages sequentially; parallelize preprocessing |
| Result history | None in v1 (extract-copy-done) | SQLite/Isar for scan history; needs new feature module |

### Scaling Priorities

1. **First bottleneck: Inference latency.** SmolVLM2 500M vision p95 is ~2.3 seconds on A16 chip. This is fixed by hardware; optimization is via image sizing (smaller input = faster) and prompt brevity. Streaming display masks the wait.
2. **Second bottleneck: Memory pressure.** ~600MB model + app overhead on a 6GB device. Edge-Veda's QoS handles this with cross-worker eviction, but if adding more features (history DB, PDF viewer), monitor memory carefully.

## Anti-Patterns

### Anti-Pattern 1: Direct Runtime Access from UI

**What people do:** Call `VisionWorker.describeFrame()` directly from a widget's `onPressed` handler.
**Why it's wrong:** Tightly couples UI to Edge-Veda API. When the runtime needs initialization checks, error handling, thermal throttling awareness, or prompt construction, the widget becomes a god object. Also makes testing impossible without a real model.
**Do this instead:** Route all inference through OCRService. The ViewModel calls OCRService; OCRService calls EdgeVedaRuntime. Three clear layers, each testable independently.

### Anti-Pattern 2: Preprocessing on Main Isolate

**What people do:** Decode, resize, and convert images on the main Dart isolate.
**Why it's wrong:** Image decoding and resizing are CPU-heavy. A 12MP iPhone photo takes 50-200ms to decode and resize. This freezes the UI during the exact moment the user expects responsiveness (they just tapped "Extract").
**Do this instead:** Run ImagePreprocessor in a `compute()` isolate or a long-lived worker isolate. The main isolate only receives the final `Uint8List` of RGB bytes.

### Anti-Pattern 3: Loading Model on Every Extraction

**What people do:** Initialize EdgeVeda and load SmolVLM2 fresh for each OCR request.
**Why it's wrong:** Model loading takes 3-5 seconds and allocates ~600MB. Doing this per-request means every extraction starts with a multi-second delay and creates massive memory churn that triggers iOS jetsam kills.
**Do this instead:** Initialize once (lazy, on first use), keep the VisionWorker alive for the app session. This is exactly how Edge-Veda's persistent worker design is intended to work.

### Anti-Pattern 4: Blocking on Full Inference Result

**What people do:** `await` the complete text result before showing anything to the user.
**Why it's wrong:** Vision inference takes 2-5 seconds. A blank screen for that duration feels broken. Users may think the app crashed and force-quit.
**Do this instead:** Stream tokens to the UI as they arrive. Show a typing/generation animation. The text should visibly grow, giving continuous feedback that inference is working.

### Anti-Pattern 5: Hardcoded Prompts Scattered Across Codebase

**What people do:** Embed OCR prompt strings directly in service methods or view models.
**Why it's wrong:** Prompt engineering is the primary quality lever for VLM-based OCR. Prompts will be iterated dozens of times. If they're scattered across files, changes are error-prone and inconsistent.
**Do this instead:** Centralize all prompts in `PromptBuilder` or `ocr_prompts.dart`. Single source of truth. Version them if needed. This makes A/B testing prompt variations trivial.

## Integration Points

### External Packages (Platform Plugins)

| Package | Integration Pattern | Notes |
|---------|---------------------|-------|
| `edge_veda` (2.5.0) | Direct Dart SDK; FFI to XCFramework | Auto-downloaded via CocoaPods; ~31MB binary. VisionWorker runs in isolate. |
| `camera` | Platform channel to AVFoundation | Use for live preview + capture. Returns image file path. |
| `image_picker` | Platform channel to UIImagePickerController | Gallery selection. Simpler than camera for single-shot use. |
| `file_picker` | Platform channel to UIDocumentPickerViewController | File import from iCloud/Files. Returns file path. |
| `pdfrx` | FFI to PDFium (or CoreGraphics on iOS) | Renders PDF pages to raster images. Use `pdfrx_coregraphics` on iOS to avoid bundling PDFium and reduce binary size. |
| `share_plus` | Platform channel to UIActivityViewController | System share sheet for exporting text. |
| `image` (Dart) | Pure Dart; runs in isolate | Image decode, resize, RGB conversion. Use in preprocessing isolate. |
| `path_provider` | Platform channel to NSFileManager | App documents/temp directory paths for model files and temp images. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Presentation <-> Service | ViewModel calls Service methods, receives Streams/Futures | ViewModels depend on Services via constructor injection |
| OCRService <-> EdgeVedaRuntime | Method calls returning Streams | OCRService is the only consumer of EdgeVedaRuntime |
| OCRService <-> ImagePreprocessor | Method call returning ProcessedImage | Runs in separate isolate; returns Uint8List |
| ImageAcquisition <-> Platform Plugins | Thin wrapper over camera/image_picker/file_picker | Normalizes different return types into unified ImageInput |
| Features <-> Runtime | Only through Service layer | Features never import from `runtime/` directly; OCRService mediates |

## Build Order (Dependency Graph)

This ordering reflects technical dependencies. Later phases cannot function without earlier ones.

```
Phase 1: Runtime Foundation
    +-- EdgeVedaRuntime (init, VisionWorker lifecycle)
    +-- ImagePreprocessor (resize, RGB conversion)
    +-- PromptBuilder (plain text prompt only)
    +-- Minimal test harness: hardcoded image -> OCR -> print result
    |
    v
Phase 2: Core OCR Pipeline
    +-- OCRService (orchestrates preprocess -> prompt -> infer)
    +-- OcrViewModel + OcrScreen (streaming token display)
    +-- Basic result display (text area with accumulated tokens)
    |
    v
Phase 3: Image Acquisition
    +-- ImageAcquisitionService (unified interface)
    +-- CameraScreen (live preview + capture)
    +-- Gallery picker integration
    +-- File import integration
    |
    v
Phase 4: Result & Export
    +-- ResultScreen (formatted text display)
    +-- Copy-to-clipboard
    +-- Share sheet integration
    +-- Format toggle (plain text vs structured)
    |
    v
Phase 5: PDF Support & Polish
    +-- PdfRendererService (page -> image conversion)
    +-- Additional prompt formats (key-value, structured)
    +-- Runtime state UI (thermal warnings, model loading indicator)
    +-- Error handling and edge cases
```

**Rationale for this order:**
- Phase 1 must come first because everything depends on the runtime working. If Edge-Veda cannot load SmolVLM2 and produce text from an image, nothing else matters.
- Phase 2 before Phase 3 because you can test OCR with a hardcoded image before building camera/gallery UI. This isolates "does inference work?" from "does image capture work?"
- Phase 3 before Phase 4 because you need images flowing in before export makes sense.
- Phase 5 is last because PDF support is additive (not core loop) and prompt refinement is ongoing.

## Sources

- [Edge-Veda GitHub Repository](https://github.com/ramanujammv1988/edge-veda) - Architecture details, API documentation, worker system -- HIGH confidence
- [Edge-Veda pub.dev package](https://pub.dev/packages/edge_veda) - Version 2.5.0, API examples, performance metrics -- HIGH confidence
- [Flutter Official Architecture Guide](https://docs.flutter.dev/app-architecture/guide) - MVVM, service/repository pattern, layer structure -- HIGH confidence
- [Flutter Project Structure: Feature-first or Layer-first?](https://codewithandrea.com/articles/flutter-project-structure/) - Feature-first recommendation and rationale -- HIGH confidence
- [Ollama-OCR GitHub](https://github.com/imanoop7/Ollama-OCR) - Prompt strategies for VLM-based OCR -- MEDIUM confidence (Python library, adapted not used directly)
- [Roboflow: Base vs Fine-Tuned SmolVLM2 for OCR](https://blog.roboflow.com/base-vs-fine-tuned-smolvlm2-ocr/) - SmolVLM2 OCR performance characteristics -- MEDIUM confidence
- [SmolVLM to SmolVLM2 (PyImageSearch)](https://pyimagesearch.com/2025/06/23/smolvlm-to-smolvlm2-compact-models-for-multi-image-vqa/) - Model capabilities and benchmarks -- MEDIUM confidence
- [Building AI-Powered Mobile Apps: On-Device LLMs in Flutter](https://medium.com/@stepan_plotytsia/building-ai-powered-mobile-apps-running-on-device-llms-in-android-and-flutter-2025-guide-0b440c0ae08b) - Flutter + on-device LLM architecture patterns -- LOW confidence (general guidance)
- [Deploying LLMs On-Device with Flutter Method Channels](https://medium.com/@debasishkumardas5/deploying-llms-on-device-in-android-and-ios-gemma-2b-model-with-flutter-method-channels-32c698c63c31) - Platform channel patterns for LLM inference -- LOW confidence (different runtime)

---
*Architecture research for: On-device OCR Flutter iOS app with Edge-Veda + SmolVLM2*
*Researched: 2026-03-16*
