import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as img;

/// Result of image preprocessing, ready for Edge-Veda VisionWorker inference.
///
/// [rgbBytes] contains interleaved RGB pixels (R0G0B0R1G1B1...), 3 bytes per
/// pixel, NO alpha channel. Length is always width * height * 3.
class ProcessedImage {
  final Uint8List rgbBytes;
  final int width;
  final int height;

  const ProcessedImage({
    required this.rgbBytes,
    required this.width,
    required this.height,
  });
}

/// Preprocesses images for OCR inference in a background isolate.
///
/// Pipeline:
///   1. Read image bytes from file path
///   2. Decode image (handles JPEG, PNG, WebP, BMP, TIFF, GIF)
///   3. Apply EXIF orientation correction (8 rotation variants)
///   4. Resize: cap longest edge at 1024px, maintain aspect ratio
///   5. Convert to interleaved RGB bytes (3 bytes/pixel, no alpha)
///
/// CRITICAL MEMORY CONSTRAINT: Always resizes to max 1024px longest edge.
/// On iPhone 13 (4 GB RAM), full 12 MP images (~48 MB raw) push past iOS
/// jetsam limits when combined with the ~600 MB model in GPU memory.
///
/// CRITICAL FORMAT: Edge-Veda VisionWorker.describeFrame expects interleaved
/// RGB (3 bytes/pixel). The Dart `image` package pixel accessor returns RGBA.
/// We extract R, G, B channels only -- skip alpha.
class ImagePreprocessor {
  ImagePreprocessor._();

  /// Maximum dimension (longest edge) for preprocessed images.
  ///
  /// SmolVLM2's SigLIP vision encoder operates on 512x512 patches.
  /// 1024px allows 2x2 patches while staying within memory budget.
  static const int maxEdge = 1024;

  /// Preprocess an image file for OCR inference.
  ///
  /// Runs entirely in a background isolate via [compute] to avoid
  /// blocking the UI thread. Returns a [ProcessedImage] with interleaved
  /// RGB bytes ready for VisionWorker.describeFrame().
  ///
  /// Throws [ArgumentError] if the image cannot be decoded.
  static Future<ProcessedImage> prepare(String imagePath) async {
    return compute(_processImage, imagePath);
  }

  /// Internal processing function that runs in a background isolate.
  ///
  /// This is a top-level-compatible static method (no closures over
  /// instance state) so it can be sent to an isolate via compute().
  static ProcessedImage _processImage(String imagePath) {
    // 1. Read image bytes from file
    final fileBytes = File(imagePath).readAsBytesSync();

    // 2. Decode image (handles JPEG, PNG, WebP, BMP, TIFF, GIF)
    final decoded = img.decodeImage(fileBytes);
    if (decoded == null) {
      throw ArgumentError(
        'Failed to decode image at path: $imagePath. '
        'Supported formats: JPEG, PNG, WebP, BMP, TIFF, GIF.',
      );
    }

    // 3. Apply EXIF orientation correction
    // bakeOrientation reads EXIF data and rotates/flips the image
    // so it displays correctly regardless of camera orientation.
    var image = img.bakeOrientation(decoded);

    // 4. Resize: cap longest edge at maxEdge (1024px)
    if (image.width > maxEdge || image.height > maxEdge) {
      if (image.width >= image.height) {
        // Landscape or square: constrain width
        image = img.copyResize(
          image,
          width: maxEdge,
          interpolation: img.Interpolation.linear,
        );
      } else {
        // Portrait: constrain height
        image = img.copyResize(
          image,
          height: maxEdge,
          interpolation: img.Interpolation.linear,
        );
      }
    }

    // 5. Convert to interleaved RGB bytes (3 bytes per pixel, no alpha)
    // Edge-Veda VisionWorker.describeFrame expects: R0G0B0R1G1B1...
    final pixelCount = image.width * image.height;
    final rgbBytes = Uint8List(pixelCount * 3);
    int offset = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        rgbBytes[offset++] = pixel.r.toInt();
        rgbBytes[offset++] = pixel.g.toInt();
        rgbBytes[offset++] = pixel.b.toInt();
      }
    }

    // Verify: byte count must equal width * height * 3
    assert(rgbBytes.length == image.width * image.height * 3);

    return ProcessedImage(
      rgbBytes: rgbBytes,
      width: image.width,
      height: image.height,
    );
  }
}
