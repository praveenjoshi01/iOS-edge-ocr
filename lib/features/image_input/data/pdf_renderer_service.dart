import 'dart:io';

import 'package:flutter/material.dart' show Colors;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_image_renderer/pdf_image_renderer.dart';

/// Service that renders the first page of a PDF to a temporary JPEG file.
///
/// Used when the user imports a PDF via the Files app. The rendered image
/// is then passed to the OCR pipeline like any other image input.
class PdfRendererService {
  /// Render the first page of a PDF to a temporary JPEG file.
  /// Returns the absolute file path to the rendered image.
  ///
  /// Scale is capped at 3x to avoid excessive memory use.
  /// Renders at up to 2048px wide for good OCR readability.
  Future<String> renderFirstPage(String pdfPath) async {
    final renderer = PdfImageRenderer(path: pdfPath);
    await renderer.open();
    await renderer.openPage(pageIndex: 0);

    final size = await renderer.getPageSize(pageIndex: 0);
    final scale = (2048 / size.width).clamp(0.5, 3.0);

    final imageBytes = await renderer.renderPage(
      pageIndex: 0,
      x: 0,
      y: 0,
      width: size.width.toInt(),
      height: size.height.toInt(),
      scale: scale,
      background: Colors.white,
    );

    await renderer.closePage(pageIndex: 0);
    await renderer.close();

    if (imageBytes == null) {
      throw StateError('PDF rendering returned null for: $pdfPath');
    }

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/pdf_page_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(imageBytes);

    return tempFile.path;
  }
}
