# Stack Research

**Domain:** On-device OCR Flutter iOS app with vision-language model inference
**Researched:** 2026-03-16
**Confidence:** MEDIUM-HIGH (core stack verified via pub.dev and official docs; Edge-Veda verified via GitHub/pub.dev; OCR prompt patterns verified via multiple sources)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| Flutter SDK | 3.41.x (stable) | Cross-platform UI framework | Official stable channel. Only targeting iOS but Flutter gives hot-reload DX, Dart isolates for background work, and future Android optionality. Single-platform Flutter iOS apps are well-supported. | HIGH |
| Dart SDK | 3.9.x | Language runtime | Ships with Flutter 3.41.x. Isolates are critical for keeping inference off the UI thread. Sound null safety, pattern matching, and sealed classes enable robust model state handling. | HIGH |
| Edge-Veda | ^2.5.0 | On-device AI runtime | The only Flutter-native SDK providing managed VLM inference with Metal GPU, thermal monitoring, memory eviction, and persistent worker isolates. Wraps llama.cpp b7952 via XCFramework (~31 MB, auto-downloaded by CocoaPods). Directly supports SmolVLM2 as a pre-configured vision model. Zero-cloud architecture matches our offline requirement. | HIGH |
| SmolVLM2 500M (GGUF Q4_K_M) | HuggingFace release | Vision-language model for OCR | 500M params, ~607 MB on disk. Fits comfortably in iPhone 13's 4 GB RAM. Runs entirely via Metal GPU through Edge-Veda's VisionWorker. Proven OCR capability on documents per HuggingFace benchmarks. Q4_K_M quantization balances quality vs. memory (safe default for phones). | MEDIUM-HIGH |

### State Management & Architecture

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| flutter_riverpod | ^3.3.1 | State management | Community standard for 2025-2026. Compile-time safety, no BuildContext dependency, built-in async state (AsyncValue for loading/error/data). Perfect for modeling inference states (idle/loading model/processing/result/error). Code-gen support reduces boilerplate. Flutter Favorite. | HIGH |
| riverpod_annotation | ^4.0.2 | Riverpod code generation annotations | Enables @riverpod decorator pattern for provider definitions. Cleaner than manual provider creation. | HIGH |
| riverpod_generator | ^4.0.3 | Riverpod code generation | Generates provider boilerplate from annotated functions/classes. Requires build_runner. | HIGH |
| freezed | ^3.2.3 | Immutable data classes | Code-gen for sealed unions and immutable models. Use for OCR result states, processing pipeline states, and app configuration models. copyWith, equality, and pattern matching out of the box. | HIGH |
| freezed_annotation | ^3.2.3 | Freezed annotations | Runtime annotations for freezed (dependency, not dev_dependency). | HIGH |

### Navigation

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| go_router | ^17.1.0 | Declarative routing | Official Flutter team package. URL-based routing, sub-routes via ShellRoute, redirect support. For this app, manages camera/gallery/results/history screens with deep-link potential. | HIGH |

### Image Input & Camera

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| camera | ^0.12.0 | Camera preview and capture | Official Flutter plugin. Supports iOS 13+, image streaming to Dart (needed for live preview before capture). Required for the camera capture flow. | HIGH |
| image_picker | ^1.2.1 | Photo library and file selection | Official Flutter plugin. Handles iOS PHPicker (iOS 14+) for gallery selection and basic camera capture. Use for gallery/photo library input path. Returns XFile for cross-library compatibility. | HIGH |
| file_picker | ^10.3.10 | Document/file import | Supports picking from Files app, iCloud, and other document providers. Needed for the "import from files" input path. Cross-file XFile support. | HIGH |

### Permissions

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| permission_handler | ^12.0.1 | Runtime permission management | Industry standard for camera and photo library permission requests on iOS. Handles permission status checking, requesting, and directing users to Settings when denied. | HIGH |

### Output & Sharing

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| share_plus | ^12.0.1 | Native share sheet | Flutter Favorite. Triggers iOS UIActivityViewController for sharing extracted text. Supports text, URIs, and files. | HIGH |
| Flutter Clipboard API | Built-in | Copy to clipboard | `Clipboard.setData()` from `flutter/services.dart`. No external package needed for plain text copy. Show SnackBar confirmation on copy. | HIGH |

### Local Storage

| Technology | Version | Purpose | Why Recommended | Confidence |
|------------|---------|---------|-----------------|------------|
| drift | ^2.32.0 | SQLite database (OCR history) | Best-maintained SQLite wrapper for Flutter. Reactive queries, type-safe SQL, migration support. Use for persisting OCR results history (timestamp, source image path, extracted text, output format). Actively maintained unlike Isar/Hive (abandoned by original author). | MEDIUM-HIGH |
| path_provider | ^2.1.5 | File system paths | Official Flutter plugin. Required for locating app documents directory (model storage, image cache, database file). | HIGH |

### Development Tools

| Tool | Version | Purpose | Notes |
|------|---------|---------|-------|
| build_runner | ^2.12.2 | Code generation orchestrator | Runs freezed and riverpod_generator. Use `dart run build_runner build --delete-conflicting-outputs`. |
| Xcode | 16.x | iOS build toolchain | Required for iOS deployment. Minimum deployment target: iOS 15.0 (iPhone 13 ships with iOS 15). |
| CocoaPods | Latest | iOS dependency management | Edge-Veda's XCFramework downloads automatically via `pod install`. |
| Flutter DevTools | Built-in | Performance profiling | Essential for monitoring memory during model inference. Watch for >3 GB total app memory on iPhone 13 (4 GB device RAM). |

## OCR Prompt Strategy (Adapted from Ollama-OCR)

Edge-Veda's VisionWorker accepts a prompt string with each frame/image. The OCR quality depends heavily on prompt engineering. Based on Ollama-OCR patterns and VLM OCR best practices:

### Recommended Prompts

**Plain Text Extraction:**
```
Act as an OCR assistant. Analyze the provided image and:
1. Identify and transcribe all visible text exactly as it appears.
2. Preserve the original line breaks, spacing, and formatting.
3. Output only the transcribed text, nothing else.
```

**Structured/Markdown Extraction:**
```
Act as an OCR assistant. Analyze the provided image and:
1. Identify and transcribe all visible text.
2. Preserve formatting using Markdown: use headers for titles,
   bullet points for lists, and tables for tabular data.
3. Maintain the logical reading order of the document.
4. Output only the formatted transcription.
```

**Key-Value Extraction:**
```
Act as an OCR assistant. Analyze the provided image and:
1. Extract all labeled fields and their values.
2. Output as key: value pairs, one per line.
3. If a field has no value, output the key with an empty value.
```

**Critical setting:** Temperature = 0.0 for deterministic, accurate OCR output. Higher temperatures introduce hallucinated text.

Confidence: MEDIUM (prompts derived from Ollama-OCR patterns and VLM OCR best practices articles, not tested with SmolVLM2 500M specifically -- needs validation during implementation phase)

## Model Configuration

### SmolVLM2 500M Deployment

| Parameter | Recommended Value | Rationale |
|-----------|-------------------|-----------|
| Quantization | Q4_K_M | Safe default for phones. Balances quality and memory. ~607 MB on disk. |
| GPU Layers | All (default) | Edge-Veda auto-offloads to Metal GPU. iPhone 13 A15 Bionic has 5-core GPU. |
| Context Window | 2048 tokens | Sufficient for single-page OCR output. Larger windows consume more memory. |
| Temperature | 0.0 | Deterministic output for OCR accuracy. No creative sampling needed. |
| Batch Size | Default (Edge-Veda managed) | Runtime auto-tunes based on thermal state. |

### Model Storage

Edge-Veda manages model downloads and storage. Models are stored in the app's documents directory (via path_provider). The SmolVLM2 500M GGUF file (~607 MB) downloads on first launch. Plan for:
- Download progress UI on first launch
- Offline validation (check model file exists before attempting inference)
- Model integrity verification (Edge-Veda handles checksums)

## Installation

```yaml
# pubspec.yaml

environment:
  sdk: ^3.9.0
  flutter: ^3.41.0

dependencies:
  # AI Runtime
  edge_veda: ^2.5.0

  # State Management
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2
  freezed_annotation: ^3.2.3

  # Navigation
  go_router: ^17.1.0

  # Image Input
  camera: ^0.12.0
  image_picker: ^1.2.1
  file_picker: ^10.3.10

  # Permissions
  permission_handler: ^12.0.1

  # Output & Sharing
  share_plus: ^12.0.1

  # Local Storage
  drift: ^2.32.0
  path_provider: ^2.1.5

dev_dependencies:
  # Code Generation
  build_runner: ^2.12.2
  riverpod_generator: ^4.0.3
  freezed: ^3.2.3
  drift_dev: ^2.32.0

  # Testing
  flutter_test:
    sdk: flutter
  mocktail: ^1.0.4
```

### iOS Configuration (ios/Podfile)

```ruby
platform :ios, '15.0'  # iPhone 13 minimum

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
  end
end
```

### iOS Info.plist Permissions

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is needed to capture documents for text extraction.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access is needed to select images for text extraction.</string>
```

## Alternatives Considered

| Recommended | Alternative | Why Not |
|-------------|-------------|---------|
| Edge-Veda (managed runtime) | flutter_llama (raw llama.cpp bindings) | flutter_llama is a thin wrapper -- no thermal management, no memory eviction, no worker lifecycle. You would need to build all runtime supervision yourself. Edge-Veda provides this out of the box. |
| Edge-Veda (managed runtime) | Google ML Kit Text Recognition | ML Kit uses a traditional OCR engine, not a VLM. Cannot handle complex layouts, handwriting diversity, or structured extraction as well as prompt-based VLM OCR. Also requires Google Play Services on Android (irrelevant for iOS-only, but limits architecture). |
| Edge-Veda (managed runtime) | ai_edge (Google AI Edge SDK) | Google's Flutter AI Edge SDK (v0.1.0) is very early stage. Targets TFLite/MediaPipe models, not GGUF/llama.cpp. No VLM support for OCR. |
| SmolVLM2 500M | SmolVLM2 2.2B | 2.2B is too large for sustained inference on iPhone 13 (would consume ~3+ GB RAM, leaving almost nothing for the OS and app). 500M fits comfortably with ~1.8 GB GPU RAM. |
| SmolVLM2 500M | SmolVLM2 256M | 256M sacrifices too much OCR accuracy. 500M is the sweet spot for phone-class devices with acceptable quality. |
| Riverpod 3.x | BLoC 9.x | BLoC's event-driven architecture adds significant boilerplate for a single-developer app. Riverpod's functional providers are faster to write and maintain. BLoC is better for large enterprise teams needing audit trails. |
| Riverpod 3.x | GetX | GetX mixes concerns (state, DI, routing, HTTP) into one opinionated package. Community consensus has shifted away from it. Poor testability. |
| Drift (SQLite) | Hive / Isar | Both abandoned by their original author. Now community-maintained with uncertain futures. Drift is built on SQLite (bulletproof, decades of stability) and actively maintained. |
| go_router | Navigator 2.0 raw API | Navigator 2.0 is verbose and error-prone. go_router is the official Flutter team abstraction over it. |
| Q4_K_M quantization | Q8_0 quantization | Q8_0 produces larger model files (~1.2 GB vs ~607 MB) and uses more RAM. Marginal quality improvement for OCR tasks does not justify the memory cost on a phone. |
| Q4_K_M quantization | Q2_K quantization | Too much quality loss. OCR accuracy drops noticeably at extreme quantization levels. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| google_mlkit_text_recognition | Traditional OCR engine, not VLM-based. Cannot do structured extraction, struggles with handwriting, no prompt customization. | Edge-Veda + SmolVLM2 (prompt-based VLM OCR) |
| Tesseract OCR (via tesseract_ocr plugin) | Legacy C++ OCR engine. Poor accuracy on complex layouts, no context understanding, no structured output. Requires bundling large language data files. | Edge-Veda + SmolVLM2 |
| Provider (state management) | Deprecated in favor of Riverpod by the same author. BuildContext-dependent, runtime errors instead of compile-time. | flutter_riverpod ^3.3.1 |
| GetX | Anti-pattern for production apps. Mixes concerns, poor testability, falling community support. | flutter_riverpod ^3.3.1 |
| Hive / Isar (local DB) | Both abandoned by original author (Simon Leier). Community forks exist but maintenance is uncertain. | Drift ^2.32.0 |
| flutter_mobile_vision | Deprecated. Wraps old Google Mobile Vision API which has been replaced by ML Kit. | camera ^0.12.0 + Edge-Veda VisionWorker |
| TensorFlow Lite (tflite_flutter) | Wrong model format. SmolVLM2 uses GGUF, not TFLite. Would require model conversion and lose llama.cpp Metal optimizations. | Edge-Veda (native GGUF/llama.cpp support) |

## Stack Patterns by Variant

**If targeting iPhone 13 (4 GB RAM) -- our primary target:**
- Use SmolVLM2 500M with Q4_K_M quantization
- Set Edge-Veda memory ceiling to ~2.0 GB to leave headroom for iOS
- Monitor thermal state; expect throttling after ~60s continuous inference
- Single model loaded at a time (no concurrent text + vision models)

**If targeting iPhone 15 Pro+ (8 GB RAM) in a future version:**
- Could upgrade to SmolVLM2 2.2B for better OCR accuracy
- Could run concurrent models (e.g., vision + embeddings for searchable history)
- Q5_K_M quantization becomes viable for quality improvement
- Longer context windows (4096+ tokens) for multi-page documents

**If adding Android support later:**
- Edge-Veda supports Android (CPU only, validation pending per their docs)
- Performance will be significantly slower without Metal GPU
- May need to drop to SmolVLM2 256M on lower-end Android devices
- Same Dart/Flutter code, different runtime performance profile

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| edge_veda ^2.5.0 | Flutter ^3.41.0, iOS 13.0+ | XCFramework auto-downloads via CocoaPods. Set deployment target to iOS 15.0 for iPhone 13 minimum. |
| flutter_riverpod ^3.3.1 | riverpod_annotation ^4.0.2, riverpod_generator ^4.0.3 | These three must stay in sync. Update together. |
| freezed ^3.2.3 | freezed_annotation ^3.2.3, build_runner ^2.12.2 | freezed (dev) and freezed_annotation (runtime) versions must match. |
| drift ^2.32.0 | drift_dev ^2.32.0, sqlite3 ^3.1.5 | drift and drift_dev versions must match. sqlite3 is a transitive dependency. |
| camera ^0.12.0 | Flutter ^3.35.0 | Breaking change in recent versions: Android switched to CameraX. iOS unchanged. |
| go_router ^17.1.0 | Flutter ^3.32.0 | Official Flutter team package. Updates alongside Flutter SDK releases. |

## Edge-Veda API Quick Reference

```dart
// Initialize runtime
final runtime = EdgeVeda();

// Load vision model (SmolVLM2 500M)
final visionWorker = await runtime.createVisionWorker(
  model: EvModel.smolVLM2,  // Pre-configured 500M GGUF
);

// Process a single image for OCR
final result = await visionWorker.describeFrame(
  rgbBytes: imageBytes,     // Uint8List of RGB pixel data
  width: imageWidth,
  height: imageHeight,
  prompt: 'Act as an OCR assistant. Analyze the provided image and '
          'transcribe all visible text exactly as it appears. '
          'Preserve line breaks and formatting. Output only the text.',
);

// Stream tokens for progressive display
await for (final token in visionWorker.describeFrameStream(
  rgbBytes: imageBytes,
  width: imageWidth,
  height: imageHeight,
  prompt: ocrPrompt,
)) {
  // Update UI progressively as tokens arrive
}

// Dispose when done
await visionWorker.dispose();
```

Confidence: MEDIUM (API shape derived from Edge-Veda GitHub README and pub.dev docs. Exact method signatures should be verified against the 2.5.0 API docs during implementation.)

## Sources

- [Edge-Veda pub.dev package](https://pub.dev/packages/edge_veda) -- version 2.5.0 verified, HIGH confidence
- [Edge-Veda GitHub repository](https://github.com/ramanujammv1988/edge-veda) -- architecture, API, model support verified, HIGH confidence
- [SmolVLM2 HuggingFace blog](https://huggingface.co/blog/smolvlm2) -- model capabilities and sizes, HIGH confidence
- [SmolVLM2-500M-Video-Instruct model card](https://huggingface.co/HuggingFaceTB/SmolVLM2-500M-Video-Instruct) -- 500M specs, HIGH confidence
- [GGUF Quantization Guide for iPhone/Mac](https://enclaveai.app/blog/2025/11/12/practical-quantization-guide-iphone-mac-gguf/) -- Q4_K_M recommendation, MEDIUM confidence
- [Ollama-OCR GitHub](https://github.com/imanoop7/Ollama-OCR) -- prompt-based OCR patterns, MEDIUM confidence
- [VLM OCR best practices (Ubicloud)](https://www.ubicloud.com/blog/end-to-end-ocr-with-vision-language-models) -- temperature=0.0 and prompt structure, MEDIUM confidence
- [OCR with open models (HuggingFace)](https://huggingface.co/blog/ocr-open-models) -- VLM OCR state of the art, MEDIUM confidence
- [Flutter SDK release notes](https://docs.flutter.dev/release/release-notes) -- Flutter 3.41.x stable, HIGH confidence
- [Riverpod 3.0 what's new](https://riverpod.dev/docs/whats_new) -- state management recommendation, HIGH confidence
- [flutter_riverpod pub.dev](https://pub.dev/packages/flutter_riverpod) -- version 3.3.1, HIGH confidence
- [go_router pub.dev](https://pub.dev/packages/go_router) -- version 17.1.0, HIGH confidence
- [camera pub.dev](https://pub.dev/packages/camera) -- version 0.12.0, HIGH confidence
- [image_picker pub.dev](https://pub.dev/packages/image_picker) -- version 1.2.1, HIGH confidence
- [file_picker pub.dev](https://pub.dev/packages/file_picker) -- version 10.3.10, HIGH confidence
- [permission_handler pub.dev](https://pub.dev/packages/permission_handler) -- version 12.0.1, HIGH confidence
- [share_plus pub.dev](https://pub.dev/packages/share_plus) -- version 12.0.1, HIGH confidence
- [drift pub.dev](https://pub.dev/packages/drift) -- version 2.32.0, HIGH confidence
- [path_provider pub.dev](https://pub.dev/packages/path_provider) -- version 2.1.5, HIGH confidence
- [build_runner pub.dev](https://pub.dev/packages/build_runner) -- version 2.12.2, HIGH confidence
- [Best Flutter State Management 2026 (Foresight Mobile)](https://foresightmobile.com/blog/best-flutter-state-management) -- ecosystem consensus, MEDIUM confidence
- [Flutter local database comparison (Dinko Marinac)](https://dinkomarinac.dev/best-local-database-for-flutter-apps-a-complete-guide) -- Drift recommendation, MEDIUM confidence
- [llama.cpp A-series performance discussion](https://github.com/ggml-org/llama.cpp/discussions/4508) -- iPhone thermal considerations, MEDIUM confidence

---
*Stack research for: iOS Edge OCR -- On-device VLM OCR Flutter iOS App*
*Researched: 2026-03-16*
