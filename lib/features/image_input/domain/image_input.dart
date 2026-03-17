import 'package:freezed_annotation/freezed_annotation.dart';

part 'image_input.freezed.dart';

/// Source of the image input.
enum InputSource { camera, photoLibrary, filesApp }

/// Represents a user-provided image ready for OCR processing.
///
/// All three input sources (camera, photo library, Files app) produce
/// this unified model, decoupling input acquisition from OCR processing.
@freezed
sealed class ImageInput with _$ImageInput {
  const factory ImageInput({
    required String filePath,
    required InputSource source,
    String? originalFileName,
  }) = _ImageInput;
}
