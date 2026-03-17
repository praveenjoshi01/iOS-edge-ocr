import 'package:freezed_annotation/freezed_annotation.dart';

part 'ocr_result.freezed.dart';

/// Immutable model representing the result of an OCR inference run.
///
/// Contains the extracted text and metadata about the processing:
/// - [text]: The raw extracted text from the image
/// - [processingTimeMs]: Total pipeline time (preprocess + inference) in milliseconds
/// - [imageWidth]: Width of the preprocessed image sent to inference (after resize)
/// - [imageHeight]: Height of the preprocessed image sent to inference (after resize)
@freezed
sealed class OcrResult with _$OcrResult {
  const factory OcrResult({
    required String text,
    required int processingTimeMs,
    required int imageWidth,
    required int imageHeight,
  }) = _OcrResult;
}
