# Phase 1: Runtime & Core Pipeline - Research

**Researched:** 2026-03-17
**Domain:** Edge-Veda SDK integration, SmolVLM2 500M vision inference, model download management, image preprocessing for on-device OCR
**Confidence:** MEDIUM-HIGH

## Summary

Phase 1 is the highest-risk phase in the entire project. It proves (or disproves) that the core technology works: Edge-Veda loading SmolVLM2 500M, processing a test image, and producing readable OCR text via Metal GPU acceleration on an iPhone 13+. Everything in Phases 2 and 3 depends on this working correctly.

The research reveals three critical integration points that must be validated on day one: (1) the ChatTemplateFormat for SmolVLM2 -- Edge-Veda documentation explicitly warns that the wrong format produces garbage output, and evidence points to SmolVLM2 using a format compatible with `ChatTemplateFormat.chatML` or a SmolVLM-specific variant; (2) the model download flow for a 607 MB GGUF file that must support progress reporting and resume-on-interrupt; and (3) memory management ensuring the app stays within iOS jetsam limits on 4 GB devices while holding ~600 MB of model weights in GPU memory.

Edge-Veda 2.5.0 provides a well-structured `VisionWorker` API that runs in a persistent background isolate, loads the model once, and handles Metal GPU offloading automatically. The SDK also includes thermal monitoring, memory pressure detection, and QoS-aware scheduling. However, model download management is NOT built into Edge-Veda -- it expects a file path to an already-downloaded GGUF file. Model downloading with progress, resume, and integrity verification must be implemented by the app using Dart HTTP client or a dedicated downloader package.

**Primary recommendation:** Build the model download manager first (it is the first user-facing flow), then integrate Edge-Veda VisionWorker with a hardcoded test image to validate inference end-to-end, then add image preprocessing in an isolate. Validate ChatTemplateFormat with a smoke test before building anything else.

## Standard Stack

### Core (Phase 1 specific)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| edge_veda | ^2.5.0 | On-device AI runtime (VisionWorker for vision inference) | Only Flutter SDK providing managed VLM inference with Metal GPU, thermal monitoring, QoS, persistent worker isolates. Wraps llama.cpp via XCFramework (~31 MB). |
| flutter_riverpod | ^3.3.1 | State management | Compile-time safe, AsyncValue for loading/error/data states, code-gen support. Handles model download state, runtime state, inference state. |
| riverpod_annotation | ^4.0.2 | Riverpod code generation annotations | @riverpod decorator for clean provider definitions |
| riverpod_generator | ^4.0.3 | Code generation for Riverpod providers | Generates provider boilerplate from annotated functions/classes |
| freezed_annotation | ^3.2.3 | Immutable data class annotations | Runtime annotations for freezed models |
| freezed | ^3.2.3 | Immutable data class code generation (dev_dependency) | Generates sealed unions for OCR state, runtime state, download state |
| path_provider | ^2.1.5 | File system paths | Required for locating Documents directory for model storage |
| image | ^4.8.0 | Image decode, resize, RGB conversion | Pure Dart, runs in isolate. Needed for preprocessing images before inference |
| http | (bundled with edge_veda) | HTTP client for model download | Edge-Veda already depends on http package; use for download with progress |
| build_runner | ^2.12.2 | Code generation orchestrator (dev_dependency) | Runs freezed and riverpod_generator |

### Supporting (Phase 1 specific)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| background_downloader | ^9.x | Background download with resume support | If custom HTTP download with Range headers proves unreliable. Supports iOS background downloads, pause/resume, progress callbacks. Consider if Edge-Veda does not provide download APIs. |
| crypto | (bundled with edge_veda) | SHA-256 for model integrity verification | Verify downloaded GGUF file checksum before declaring download complete |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Custom HTTP download manager | background_downloader package | background_downloader adds iOS background download support and automatic resume, but adds a dependency. Custom HTTP gives full control. Start custom, switch if needed. |
| Dart `image` package in isolate | Native-side preprocessing | Native preprocessing avoids platform channel overhead for image bytes, but couples preprocessing to iOS. Dart isolate keeps preprocessing cross-platform and testable. Edge-Veda's VisionWorker already handles the native inference; preprocessing in Dart is acceptable for Phase 1. |
| Riverpod AsyncNotifier | Manual StreamController | Riverpod's built-in AsyncValue handles loading/error/data transitions automatically. Manual streams require more boilerplate for the same result. |

**Installation (Phase 1 pubspec.yaml):**
```yaml
dependencies:
  edge_veda: ^2.5.0
  flutter_riverpod: ^3.3.1
  riverpod_annotation: ^4.0.2
  freezed_annotation: ^3.2.3
  path_provider: ^2.1.5
  image: ^4.8.0

dev_dependencies:
  build_runner: ^2.12.2
  riverpod_generator: ^4.0.3
  freezed: ^3.2.3
  flutter_test:
    sdk: flutter
```

## Architecture Patterns

### Recommended Project Structure (Phase 1 scope only)
```
lib/
+-- main.dart                      # App entry, ProviderScope
+-- app.dart                       # MaterialApp.router, theme
+-- core/
|   +-- constants/
|   |   +-- ocr_prompts.dart       # Centralized prompt templates
|   |   +-- model_config.dart      # Model URLs, file names, checksums, sizes
|   +-- utils/
|       +-- image_utils.dart       # Resize, RGB conversion helpers
+-- features/
|   +-- ocr/
|   |   +-- presentation/
|   |   |   +-- ocr_test_screen.dart    # Phase 1: minimal test UI (pick image + show result)
|   |   |   +-- ocr_view_model.dart     # Manages inference lifecycle via Riverpod
|   |   +-- domain/
|   |   |   +-- ocr_result.dart         # Freezed: extraction result + metadata
|   |   |   +-- ocr_state.dart          # Freezed: idle/preprocessing/inferring/complete/error
|   |   +-- data/
|   |       +-- ocr_service.dart        # Orchestrates preprocess -> prompt -> infer
|   |       +-- prompt_builder.dart     # Builds format-specific prompts
|   |       +-- image_preprocessor.dart # Resize + RGB conversion in isolate
+-- runtime/
|   +-- edge_veda_runtime.dart     # VisionWorker lifecycle: spawn, initVision, describeFrame, dispose
|   +-- runtime_state.dart         # Freezed: uninitialized/downloading/ready/error
|   +-- model_downloader.dart      # HTTP download with progress, resume, checksum
|   +-- model_config.dart          # SmolVLM2 URLs, file sizes, checksums
```

### Pattern 1: Lazy Runtime Initialization with Download Gate

**What:** The Edge-Veda VisionWorker initializes only after the model file is confirmed present and valid. The app gates all inference features behind model readiness.

**When to use:** Always. This is the foundation of the entire app.

**Example:**
```dart
// Source: Edge-Veda GitHub README + pub.dev docs
@riverpod
class EdgeVedaRuntimeNotifier extends _$EdgeVedaRuntimeNotifier {
  VisionWorker? _worker;

  @override
  FutureOr<RuntimeState> build() async {
    // Check if model file exists and is valid
    final modelPath = await _getModelPath();
    final mmprojPath = await _getMmprojPath();

    if (!await File(modelPath).exists()) {
      return const RuntimeState.needsDownload();
    }

    // Initialize VisionWorker
    _worker = VisionWorker();
    await _worker!.spawn();
    await _worker!.initVision(
      modelPath: modelPath,
      mmprojPath: mmprojPath,
      numThreads: 4,
      contextSize: 2048,
      useGpu: true,
    );

    return const RuntimeState.ready();
  }

  Future<FrameDescription> describeFrame(
    Uint8List rgbBytes, int width, int height,
    {required String prompt, int maxTokens = 1024}
  ) async {
    final worker = _worker;
    if (worker == null) throw StateError('Runtime not initialized');
    return worker.describeFrame(
      rgbBytes, width, height,
      prompt: prompt,
      maxTokens: maxTokens,
    );
  }
}
```

### Pattern 2: Model Download with Progress and Resume

**What:** Download the 607 MB GGUF model file with byte-level progress reporting and HTTP Range header resume support. Store in Documents directory (not Caches).

**When to use:** First app launch when model file is not present.

**Example:**
```dart
// Model download with resume using HTTP Range headers
class ModelDownloader {
  final HttpClient _client = HttpClient();

  Stream<DownloadProgress> download(String url, String destPath) async* {
    final file = File(destPath);
    final tempFile = File('$destPath.tmp');
    int downloadedBytes = 0;

    // Resume support: check for partial download
    if (await tempFile.exists()) {
      downloadedBytes = await tempFile.length();
    }

    final request = await _client.getUrl(Uri.parse(url));
    if (downloadedBytes > 0) {
      request.headers.set('Range', 'bytes=$downloadedBytes-');
    }

    final response = await request.close();
    final totalBytes = downloadedBytes +
        (response.contentLength > 0 ? response.contentLength : 0);

    final sink = tempFile.openWrite(mode: FileMode.append);
    await for (final chunk in response) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      yield DownloadProgress(
        downloadedBytes: downloadedBytes,
        totalBytes: totalBytes,
        percentage: totalBytes > 0 ? downloadedBytes / totalBytes : 0,
      );
    }
    await sink.close();

    // Verify checksum before renaming
    // ... SHA-256 verification ...

    // Atomic rename: temp -> final
    await tempFile.rename(destPath);
  }
}
```

### Pattern 3: Image Preprocessing in Dart Isolate

**What:** Resize images to max 1024px longer edge, correct EXIF orientation, convert to RGB byte array -- all in a background isolate to avoid UI jank.

**When to use:** Before every inference call.

**Critical detail:** SmolVLM2's vision encoder (SigLIP) operates on 512x512 patches by default. The image processor resizes so the longest edge is 4*512 = 2048px, then decomposes into 512x512 patches. However, for the 500M model on iPhone 13 with 4 GB RAM, larger images consume more visual tokens and memory. Cap input at 1024px longest edge as specified in CLAUDE.md constraints.

**Example:**
```dart
// Run in isolate via compute()
class ImagePreprocessor {
  static Future<ProcessedImage> prepare(String imagePath) async {
    return compute(_processImage, imagePath);
  }

  static ProcessedImage _processImage(String imagePath) {
    final bytes = File(imagePath).readAsBytesSync();
    var image = img.decodeImage(bytes)!;

    // EXIF orientation correction
    image = img.bakeOrientation(image);

    // Resize: cap longest edge at 1024px
    final maxEdge = 1024;
    if (image.width > maxEdge || image.height > maxEdge) {
      if (image.width >= image.height) {
        image = img.copyResize(image,
          width: maxEdge,
          interpolation: img.Interpolation.linear,
        );
      } else {
        image = img.copyResize(image,
          height: maxEdge,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    // Convert to RGB byte array (3 bytes per pixel, interleaved R0G0B0R1G1B1...)
    final rgbBytes = Uint8List(image.width * image.height * 3);
    int offset = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        rgbBytes[offset++] = pixel.r.toInt();
        rgbBytes[offset++] = pixel.g.toInt();
        rgbBytes[offset++] = pixel.b.toInt();
      }
    }

    return ProcessedImage(
      rgbBytes: rgbBytes,
      width: image.width,
      height: image.height,
    );
  }
}
```

### Pattern 4: Service-Mediated Inference

**What:** OCRService orchestrates preprocessing, prompt construction, and inference. UI never calls VisionWorker directly.

**When to use:** Every OCR operation.

**Example:**
```dart
class OCRService {
  final EdgeVedaRuntimeNotifier _runtime;
  final ImagePreprocessor _preprocessor;
  final PromptBuilder _promptBuilder;

  Future<String> extractText(String imagePath) async {
    // 1. Preprocess in isolate
    final processed = await ImagePreprocessor.prepare(imagePath);

    // 2. Build prompt (plain text for Phase 1)
    final prompt = _promptBuilder.buildPlainText();

    // 3. Run inference via VisionWorker
    final result = await _runtime.describeFrame(
      processed.rgbBytes,
      processed.width,
      processed.height,
      prompt: prompt,
      maxTokens: 1024,
    );

    return result.text; // Post-process: strip artifacts, normalize whitespace
  }
}
```

### Anti-Patterns to Avoid

- **Calling VisionWorker from UI widgets:** Couples UI to SDK, makes testing impossible, bypasses state management. Always go through OCRService -> RuntimeNotifier.
- **Loading model on every inference call:** Model loading takes 3-5 seconds and allocates ~600 MB. Load once, keep alive for session. VisionWorker is designed for persistent use.
- **Preprocessing on main isolate:** Image decoding + resizing is CPU-heavy (50-200ms for 12MP). Always use `compute()` or a dedicated isolate.
- **Storing model in Caches directory:** iOS evicts Caches under storage pressure. A 607 MB re-download is unacceptable. Use Documents directory via `getApplicationDocumentsDirectory()`.
- **Skipping checksum verification after download:** A corrupted 607 MB file produces cryptic inference failures. Always verify SHA-256 before marking download complete.
- **Passing raw image bytes across platform channel:** Edge-Veda's VisionWorker runs in a Dart isolate, not across the platform channel. Pass file paths to Dart-side preprocessing, pass RGB bytes within Dart to VisionWorker. No Flutter-to-native image serialization needed.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| VLM inference engine | Custom llama.cpp FFI bindings | Edge-Veda VisionWorker | Edge-Veda handles isolate management, model loading, Metal GPU offloading, memory eviction, thermal QoS. Custom FFI would require months of work to reach the same stability. |
| Image resize + EXIF correction | Custom pixel manipulation | Dart `image` package (`copyResize`, `bakeOrientation`) | The `image` package handles JPEG/PNG/HEIC decoding, EXIF rotation, and high-quality resize with interpolation. Hand-rolling this is error-prone, especially EXIF orientation (8 rotation variants). |
| Async state management | Manual StreamControllers + setState | Riverpod AsyncNotifier + AsyncValue | AsyncValue handles loading/error/data transitions, refresh, and disposal automatically. Manual streams require explicit error handling and cleanup that is easy to get wrong. |
| Immutable state classes | Manual `==` and `hashCode` overrides | Freezed sealed unions | Freezed generates `copyWith`, equality, pattern matching, and JSON serialization. Hand-rolling these for 5+ state classes is tedious and bug-prone. |
| HTTP download with resume | Manual socket-level download | Dart `http` package with Range headers (or `background_downloader`) | HTTP Range header resume is a solved problem. Manual socket management adds complexity without benefit. |

**Key insight:** Phase 1 has zero novel problems. Every component (model download, image preprocessing, VLM inference, state management) has a well-tested library solution. The risk is integration correctness, not algorithmic novelty.

## Common Pitfalls

### Pitfall 1: Wrong ChatTemplateFormat Produces Garbage Output

**What goes wrong:** Edge-Veda documentation explicitly warns: "Using the wrong ChatTemplateFormat produces garbage output." SmolVLM2 requires a specific prompt template. Wrong template = incoherent text, random tokens, or repeated patterns.

**Why it happens:** GGUF models are trained with specific prompt formats. SmolVLM2 is based on SmolLM2 (Llama architecture) but uses a different chat template than standard Llama models. The Edge-Veda SDK provides `ChatTemplateFormat.chatML`, `.llama3Instruct`, `.qwen3`, and `.generic`. Evidence from HuggingFace suggests SmolVLM2 uses a template with `<|im_start|>User:` prefix style, which aligns with ChatML-like formatting.

**How to avoid:**
1. Day-one validation: Run a known image (photo of "Hello World" text) through inference. If output contains "Hello World", template is correct. If garbage, try other ChatTemplateFormat values.
2. For VisionWorker `describeFrame`, the prompt is passed directly without chat template wrapping -- the API handles template application internally. Verify whether VisionWorker applies its own template or expects raw prompt text.
3. Log raw model output during development to catch template issues immediately.

**Warning signs:** Output is random characters, unrelated English text, repeated tokens, or empty strings. Changing prompt text has no effect on output.

**Confidence:** MEDIUM -- ChatTemplateFormat for SmolVLM2 via Edge-Veda VisionWorker needs empirical validation. The VisionWorker API may handle template internally (describeFrame takes a plain prompt string, not a ChatSession).

### Pitfall 2: iOS Memory Pressure Kills App During Inference

**What goes wrong:** SmolVLM2 500M uses ~600 MB persistently. iPhone 13 has 4 GB total. iOS jetsam kills apps exceeding ~50% of physical memory. Flutter engine overhead (80-120 MB) + unresized camera image (48 MB for 12MP) can push past the threshold.

**Why it happens:** GPU and CPU share unified memory on Apple Silicon. Model weights in GPU memory compete with everything else. Developers test on 6-8 GB devices and never see the issue.

**How to avoid:**
- Always resize images before inference (max 1024px longer edge per CLAUDE.md constraints)
- Profile on iPhone 13 (4 GB) as minimum target device
- Process images sequentially: capture, resize, release original, infer, return result
- Use Edge-Veda's built-in memory monitoring (QoS callbacks)
- Target peak app memory under 1.5 GB (600 MB model + 120 MB Flutter + buffer)

**Warning signs:** App crashes without error logs on older iPhones. Memory in Instruments climbs without returning to baseline.

### Pitfall 3: 607 MB Model Download UX Destroys First Launch

**What goes wrong:** App requires one-time 607 MB download before any OCR works. iOS cellular download prompt triggers at 200 MB. Interrupted downloads leave corrupt partial files with no recovery.

**Why it happens:** Edge-Veda does NOT manage model downloads -- it expects a file path to an already-downloaded GGUF. The app must implement download management. This is the first interaction users have with the app.

**How to avoid:**
- Dedicated first-launch screen: "One-time download of ~600 MB required for offline AI. Wi-Fi recommended."
- Show progress: percentage, MB downloaded/total, estimated time
- Implement resume: use HTTP Range headers to resume from partial `.tmp` file
- Verify integrity: SHA-256 checksum after download completes
- Store in Documents directory (never Caches or tmp)
- Test the full flow: fresh install -> start download -> kill app -> relaunch -> resume

**Warning signs:** "Doesn't work" app reviews, high uninstall rate in first 5 minutes.

### Pitfall 4: VisionWorker Requires Two Model Files (GGUF + mmproj)

**What goes wrong:** SmolVLM2 is a vision-language model. It requires TWO files: the main GGUF model file AND a multimodal projector file (mmproj). Edge-Veda's `initVision()` takes both `modelPath` and `mmprojPath` parameters. Forgetting the mmproj file means vision inference silently fails or produces text-only output.

**Why it happens:** VLMs have separate vision and language components. The mmproj file bridges the vision encoder output to the language model input. Without it, the model cannot "see" images.

**How to avoid:**
- Download BOTH files during first-launch setup
- Verify both files exist before enabling inference UI
- SmolVLM2 GGUF files are published at `ggml-org/SmolVLM2-500M-Video-Instruct-GGUF` on HuggingFace
- The mmproj file is typically named `mmproj-SmolVLM2-500M-Video-Instruct-f16.gguf` or similar

**Warning signs:** Model loads successfully but describeFrame returns empty or text-only results unrelated to the image.

**Confidence:** HIGH -- Edge-Veda VisionWorker.initVision() explicitly requires mmprojPath parameter.

### Pitfall 5: SmolVLM2 GGUF Quantization Variants Differ From Project Estimates

**What goes wrong:** The project estimates 607 MB for Q4_K_M quantization. However, the official ggml-org GGUF repository for SmolVLM2-500M lists only Q8_0 (437 MB) and F16 (820 MB) variants. Q4_K_M may not be available as an official pre-built quantization.

**Why it happens:** Not all quantization levels are pre-built for every model. Q4_K_M must be manually quantized using llama.cpp's `quantize` tool, or a community-quantized version must be found.

**How to avoid:**
- Use Q8_0 (437 MB) as the primary target -- it is officially available and smaller than estimated
- Q8_0 at 437 MB is actually better than Q4_K_M at 607 MB: smaller download AND higher quality
- Verify the exact model files available at download time
- Update model_config.dart with actual file sizes and URLs

**Warning signs:** Model URL returns 404, downloaded file size does not match expected.

**Confidence:** HIGH -- ggml-org/SmolVLM2-500M-Video-Instruct-GGUF HuggingFace page lists Q8_0 (437 MB) and F16 (820 MB) only.

### Pitfall 6: Image RGB Byte Format Mismatch

**What goes wrong:** VisionWorker.describeFrame expects `Uint8List rgbBytes` in interleaved RGB format (R0G0B0R1G1B1...), 3 bytes per pixel. If the byte order is wrong (e.g., RGBA, BGR, or planar format), the model sees corrupted visual input and produces garbage output.

**Why it happens:** Different image libraries use different pixel formats. The Dart `image` package uses RGBA by default. iOS camera produces YUV420. Conversion must be explicit.

**How to avoid:**
- Convert explicitly to RGB (3 channels, no alpha) before passing to describeFrame
- Verify byte count equals width * height * 3
- Test with a simple solid-color image first to verify color channels are correct (e.g., red image should produce recognizable output)

**Warning signs:** Model output is coherent text but describes wrong visual content, or colors appear shifted.

## Code Examples

### Complete VisionWorker Lifecycle (from Edge-Veda docs)
```dart
// Source: Edge-Veda pub.dev + GitHub README
// 1. Create and spawn worker
final visionWorker = VisionWorker();
await visionWorker.spawn();

// 2. Initialize with model paths and GPU
await visionWorker.initVision(
  modelPath: '/path/to/SmolVLM2-500M-Video-Instruct-Q8_0.gguf',
  mmprojPath: '/path/to/mmproj-SmolVLM2-500M-Video-Instruct-f16.gguf',
  numThreads: 4,
  contextSize: 2048,
  useGpu: true,  // Metal GPU on iOS
);

// 3. Describe a frame (OCR inference)
final result = await visionWorker.describeFrame(
  rgbBytes,    // Uint8List: interleaved RGB, 3 bytes/pixel
  width,       // int: image width in pixels
  height,      // int: image height in pixels
  prompt: 'Extract all visible text from this image. '
          'Return only the extracted text, nothing else.',
  maxTokens: 1024,
);
print(result.text);  // Extracted OCR text

// 4. Dispose when app terminates
await visionWorker.dispose();
```

### Model File Path Management
```dart
// Source: path_provider docs + CLAUDE.md constraints
import 'package:path_provider/path_provider.dart';

class ModelConfig {
  // SmolVLM2 500M GGUF files from HuggingFace ggml-org
  static const modelFileName = 'SmolVLM2-500M-Video-Instruct-Q8_0.gguf';
  static const mmprojFileName = 'mmproj-SmolVLM2-500M-Video-Instruct-f16.gguf';

  // HuggingFace download URLs
  static const modelUrl =
    'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/$modelFileName';
  static const mmprojUrl =
    'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/$mmprojFileName';

  // CRITICAL: Store in Documents, not Caches
  // iOS can evict Caches under storage pressure
  static Future<String> get modelDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/models');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get modelPath async =>
    '${await modelDir}/$modelFileName';

  static Future<String> get mmprojPath async =>
    '${await modelDir}/$mmprojFileName';

  static Future<bool> get isModelReady async {
    final model = File(await modelPath);
    final mmproj = File(await mmprojPath);
    return await model.exists() && await mmproj.exists();
  }
}
```

### Riverpod AsyncNotifier for Runtime State
```dart
// Source: Riverpod 3.x docs + codewithandrea.com patterns
@freezed
class RuntimeState with _$RuntimeState {
  const factory RuntimeState.uninitialized() = _Uninitialized;
  const factory RuntimeState.downloading({
    required double progress,
    required int downloadedBytes,
    required int totalBytes,
  }) = _Downloading;
  const factory RuntimeState.initializing() = _Initializing;
  const factory RuntimeState.ready() = _Ready;
  const factory RuntimeState.error(String message) = _Error;
}

@riverpod
class RuntimeNotifier extends _$RuntimeNotifier {
  @override
  FutureOr<RuntimeState> build() async {
    if (await ModelConfig.isModelReady) {
      return const RuntimeState.initializing();
      // ... init VisionWorker, return RuntimeState.ready()
    }
    return const RuntimeState.uninitialized();
  }

  Future<void> downloadModel() async {
    state = const AsyncData(RuntimeState.downloading(
      progress: 0, downloadedBytes: 0, totalBytes: 0,
    ));
    // ... download with progress updates ...
  }
}
```

### OCR Prompt (Plain Text -- Phase 1)
```dart
// Source: Adapted from Ollama-OCR + CLAUDE.md
// Simplified for SmolVLM2 500M capacity (short, direct instructions)
class PromptBuilder {
  static const plainTextPrompt =
    'Extract all visible text from this image. '
    'Return only the extracted text, preserving line breaks. '
    'Do not add any commentary.';

  String buildPlainText() => plainTextPrompt;
}
```

### Performance Benchmarks (Edge-Veda on iPhone A16)
```dart
// Source: Edge-Veda pub.dev benchmarks
// Text throughput: 42-43 tokens/second
// TTFT (time to first token): <500 ms
// Steady-state memory: 400-550 MB
// Vision p95 latency: 2,283 ms (2.3 seconds)
// Vision sustained runtime: 12.6 minutes (254 frames, zero crashes)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Tesseract OCR (character recognition) | VLM-based OCR (SmolVLM2 via Edge-Veda) | 2025 | VLMs understand document context, reading order, and structure; traditional OCR just recognizes individual characters |
| Cloud-based OCR (Google Vision, Azure) | On-device VLM inference | 2025-2026 | Zero latency from network, complete privacy, works offline |
| Manual llama.cpp FFI bindings | Managed runtime (Edge-Veda) | 2025 | Thermal QoS, memory eviction, persistent workers handled automatically |
| Provider state management | Riverpod 3.x with code generation | Sept 2025 | Compile-time safety, AsyncValue.isFromCache, progress on AsyncLoading |
| Hive/Isar local storage | Drift (SQLite) | 2025 | Hive/Isar abandoned by author; Drift actively maintained on top of SQLite |

**Deprecated/outdated:**
- `google_mlkit_text_recognition`: Traditional OCR, not VLM-based. Cannot do structured extraction.
- `tflite_flutter`: Wrong model format for GGUF models. No llama.cpp Metal GPU support.
- `Provider` package: Deprecated by Riverpod author (same author). BuildContext-dependent.

## Open Questions

1. **Exact ChatTemplateFormat for SmolVLM2 via VisionWorker**
   - What we know: Edge-Veda ChatTemplateFormat enum has `.chatML`, `.llama3Instruct`, `.qwen3`, `.generic`. SmolVLM2 uses SmolLM2 (Llama architecture) with a template resembling ChatML (`<|im_start|>` style). VisionWorker.describeFrame takes a plain prompt string.
   - What's unclear: Does VisionWorker auto-detect and apply the chat template from the GGUF metadata? Or must the template be explicitly specified? If explicit, which ChatTemplateFormat value works for SmolVLM2?
   - Recommendation: Day-one smoke test. Try describeFrame with plain prompt first (VisionWorker may handle it). If output is garbage, create a ChatSession with different ChatTemplateFormat values until output is coherent. Document the working configuration.

2. **SmolVLM2 500M GGUF file names and download URLs**
   - What we know: ggml-org/SmolVLM2-500M-Video-Instruct-GGUF on HuggingFace has Q8_0 (437 MB) and F16 (820 MB). The mmproj file is required but its exact filename needs verification.
   - What's unclear: Exact file names for model + mmproj. Whether Q4_K_M is available from any source. Whether Edge-Veda has a built-in model registry that handles SmolVLM2 download.
   - Recommendation: Check HuggingFace file listing before implementation. Use Q8_0 (437 MB) as primary target -- smaller AND higher quality than originally estimated Q4_K_M. Verify mmproj filename from the same repository.

3. **Edge-Veda ModelAdvisor / built-in model management**
   - What we know: Edge-Veda documentation mentions `ModelAdvisor` for device-aware model recommendations and `EvModel.smolVLM2` as a pre-configured model reference. This might include built-in download URLs.
   - What's unclear: Whether ModelAdvisor or the EvModel enum provides download functionality, or if it's just metadata for model selection.
   - Recommendation: Check Edge-Veda API for any model download helpers before building custom download manager. If EvModel.smolVLM2 includes download URL and size, use that instead of hardcoding HuggingFace URLs.

4. **VisionWorker streaming support**
   - What we know: Edge-Veda's text API has `generateStream()` for token streaming. VisionWorker has `describeFrame()` which returns a `FrameDescription` (seems like a single complete result).
   - What's unclear: Whether VisionWorker supports streaming token output for vision inference, or if it only returns the complete result.
   - Recommendation: Phase 1 can work with non-streaming describeFrame (show spinner, then full result). Streaming is a Phase 3 enhancement for progressive text display. Investigate streaming capability during implementation.

## Sources

### Primary (HIGH confidence)
- [Edge-Veda pub.dev package v2.5.0](https://pub.dev/packages/edge_veda) -- API documentation, VisionWorker API, performance benchmarks, version verification
- [Edge-Veda GitHub repository](https://github.com/ramanujammv1988/edge-veda) -- Architecture, worker system, QoS, thermal management, ChatTemplateFormat options
- [ggml-org/SmolVLM2-500M-Video-Instruct-GGUF](https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF) -- Official GGUF quantizations (Q8_0: 437 MB, F16: 820 MB)
- [HuggingFaceTB/SmolVLM2-500M-Video-Instruct](https://huggingface.co/HuggingFaceTB/SmolVLM2-500M-Video-Instruct) -- Model specifications, usage examples
- [SmolVLM Transformers documentation](https://huggingface.co/docs/transformers/en/model_doc/smolvlm) -- Image processing details: default resize to 4*512=2048px longest edge, 512x512 patches, SigLIP vision encoder
- [Apple: Identifying high-memory use with jetsam event reports](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports) -- iOS memory limits
- [path_provider pub.dev](https://pub.dev/packages/path_provider) -- Documents directory API for iOS
- [Riverpod 3.0 documentation](https://riverpod.dev/docs/whats_new) -- AsyncValue, code generation, AsyncNotifier patterns

### Secondary (MEDIUM confidence)
- [Dart image package](https://pub.dev/packages/image/versions/4.8.0) -- Image decode, resize, RGB conversion APIs
- [background_downloader pub.dev](https://pub.dev/packages/background_downloader) -- iOS background download with pause/resume
- [SmolVLM: Redefining small and efficient multimodal models (arXiv)](https://arxiv.org/html/2504.05299v1) -- Model architecture: SigLIP-B/16 vision encoder, pixel shuffle compression
- [Riverpod Generator patterns (CodeWithAndrea)](https://codewithandrea.com/articles/flutter-riverpod-async-notifier/) -- AsyncNotifier code generation examples
- [Edge-Veda GitHub Releases](https://github.com/ramanujammv1988/edge-veda/releases) -- v2.4.2 latest tagged release (v2.5.0 on pub.dev)

### Tertiary (LOW confidence, needs validation)
- SmolVLM2 ChatTemplateFormat mapping to Edge-Veda enum -- inferred from architecture analysis, not directly verified
- Exact mmproj filename for SmolVLM2-500M -- needs verification from HuggingFace file listing
- Q4_K_M quantization availability -- not found in official ggml-org repository; Q8_0 recommended instead
- VisionWorker streaming support for vision tasks -- unclear from documentation, needs empirical testing

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- Edge-Veda 2.5.0, Riverpod 3.x, path_provider, image package all verified on pub.dev with current versions
- Architecture patterns: HIGH -- Service-mediated inference, lazy init, isolate preprocessing are documented patterns from Edge-Veda design philosophy and Flutter official architecture guide
- VisionWorker API: MEDIUM-HIGH -- Method signatures verified from pub.dev/GitHub docs, but ChatTemplateFormat for SmolVLM2 and streaming capability need empirical validation
- Model download: MEDIUM -- Edge-Veda does not clearly document model download management; custom HTTP download with Range headers is standard but needs integration testing
- Pitfalls: HIGH -- Memory pressure, chat template, and download UX pitfalls verified across multiple authoritative sources (Apple docs, Edge-Veda warnings, Flutter issue tracker)
- Model file details: MEDIUM -- Q8_0 at 437 MB verified from HuggingFace; mmproj filename needs confirmation; Q4_K_M not found in official repo

**Research date:** 2026-03-17
**Valid until:** 2026-04-17 (30 days -- stable domain, Edge-Veda may release patches)
