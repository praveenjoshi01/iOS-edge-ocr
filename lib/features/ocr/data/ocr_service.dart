import '../../../runtime/edge_veda_runtime.dart';
import '../domain/ocr_result.dart';
import 'image_preprocessor.dart';
import 'prompt_builder.dart';

/// Orchestrates the complete OCR pipeline: preprocess -> prompt -> infer.
///
/// This class enforces the service-mediated inference pattern:
/// UI never calls VisionWorker directly. The pipeline is:
///   1. Preprocess image in background isolate (resize, EXIF, RGB)
///   2. Build prompt (plain text for Phase 1)
///   3. Run inference through Edge-Veda VisionWorker
///   4. Post-process result text
///   5. Return OcrResult with text and metadata
///
/// Requires an initialized [EdgeVedaRuntime] (state must be RuntimeState.ready).
class OcrService {
  final EdgeVedaRuntime _runtime;
  final PromptBuilder _promptBuilder;

  OcrService({
    required EdgeVedaRuntime runtime,
    PromptBuilder? promptBuilder,
  })  : _runtime = runtime,
        _promptBuilder = promptBuilder ?? PromptBuilder();

  /// Extract text from an image file using on-device SmolVLM2 inference.
  ///
  /// [imagePath] must be a valid path to a readable image file (JPEG, PNG, etc.).
  ///
  /// Pipeline:
  ///   1. Preprocess: resize to max 1024px, correct EXIF, convert to RGB (runs in isolate)
  ///   2. Build prompt: plain text extraction
  ///   3. Infer: VisionWorker.describeFrame with interleaved RGB bytes
  ///   4. Post-process: trim whitespace, clean artifacts
  ///
  /// Returns [OcrResult] with extracted text, processing time, and image dimensions.
  /// Throws if VisionWorker is not initialized or if image cannot be decoded.
  Future<OcrResult> extractText(String imagePath) async {
    final stopwatch = Stopwatch()..start();

    // 1. Preprocess image in background isolate
    final processed = await ImagePreprocessor.prepare(imagePath);

    // 2. Build prompt
    final prompt = _promptBuilder.buildPlainText();

    // 3. Run inference through Edge-Veda VisionWorker
    final result = await _runtime.describeFrame(
      processed.rgbBytes,
      processed.width,
      processed.height,
      prompt: prompt,
      maxTokens: 1024,
    );

    stopwatch.stop();

    // 4. Post-process result text
    // VisionResultResponse uses 'description' field, not 'text'
    final cleanText = _postProcess(result.description);

    // 5. Return structured result
    return OcrResult(
      text: cleanText,
      processingTimeMs: stopwatch.elapsedMilliseconds,
      imageWidth: processed.width,
      imageHeight: processed.height,
    );
  }

  /// Post-process model output to clean up common artifacts.
  ///
  /// - Trims leading/trailing whitespace
  /// - Removes common VLM output artifacts (e.g., repeated newlines)
  /// - Preserves intentional line breaks
  String _postProcess(String rawText) {
    var text = rawText.trim();

    // Collapse 3+ consecutive newlines to 2 (preserve paragraph breaks)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text;
  }
}
