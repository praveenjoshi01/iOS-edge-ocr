import '../../../core/constants/ocr_prompts.dart';

/// Constructs prompts for OCR inference with SmolVLM2.
///
/// This abstraction exists so Phase 3 can add structured/markdown/key-value
/// prompt strategies without changing OCRService. The service always calls
/// a PromptBuilder method; the strategy is determined by which method is called.
///
/// Phase 1: Only plain text extraction is supported.
class PromptBuilder {
  /// Build the plain text extraction prompt.
  ///
  /// Returns a prompt that instructs SmolVLM2 to extract all visible text
  /// from an image, preserving line breaks, with no commentary.
  String buildPlainText() => OcrPrompts.plainText;
}
