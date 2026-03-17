/// Centralized prompt templates for OCR inference with SmolVLM2.
///
/// Prompts are kept short and direct -- SmolVLM2 500M works best with
/// simple, clear instructions. Complex multi-step prompts degrade output
/// quality on smaller models.
///
/// Phase 1: Plain text extraction only.
/// Phase 3 will add structured, markdown, and key-value prompt strategies.
class OcrPrompts {
  OcrPrompts._();

  /// Plain text extraction prompt.
  ///
  /// Instructs the model to return only extracted text with preserved
  /// line breaks and no additional commentary or formatting.
  static const String plainText =
      'Extract all visible text from this image. '
      'Return only the extracted text, preserving line breaks. '
      'Do not add any commentary.';
}
