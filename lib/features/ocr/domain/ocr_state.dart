import 'package:freezed_annotation/freezed_annotation.dart';

import 'ocr_result.dart';

part 'ocr_state.freezed.dart';

/// Sealed union representing all possible states of the OCR pipeline.
///
/// State transitions:
///   idle -> pickingImage -> preprocessing -> inferring -> complete
///                                                     -> error
///   complete -> idle (reset)
///   error -> idle (reset)
@freezed
sealed class OcrState with _$OcrState {
  /// No OCR operation in progress. Ready for user to pick an image.
  const factory OcrState.idle() = OcrStateIdle;

  /// User is selecting an image from the gallery.
  const factory OcrState.pickingImage() = OcrStatePickingImage;

  /// Image selected, preprocessing in background isolate (resize, EXIF, RGB).
  const factory OcrState.preprocessing() = OcrStatePreprocessing;

  /// Preprocessing complete, running Edge-Veda VisionWorker inference.
  const factory OcrState.inferring() = OcrStateInferring;

  /// Inference complete, extracted text available.
  const factory OcrState.complete(OcrResult result) = OcrStateComplete;

  /// Error occurred during any pipeline stage.
  const factory OcrState.error(String message) = OcrStateError;
}
