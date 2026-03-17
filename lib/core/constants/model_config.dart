import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Configuration constants for SmolVLM2 500M model files.
///
/// Uses Q8_0 quantization (437 MB) — officially available from ggml-org,
/// smaller than Q4_K_M and higher quality. mmproj f16 bridges the vision
/// encoder to the language model.
///
/// CRITICAL: All files stored in Documents directory, never Caches.
/// iOS evicts Caches under storage pressure, which would force a ~500 MB
/// re-download.
class ModelConfig {
  ModelConfig._();

  // --- File names ---
  static const String modelFileName =
      'SmolVLM2-500M-Video-Instruct-Q8_0.gguf';
  static const String mmprojFileName =
      'mmproj-SmolVLM2-500M-Video-Instruct-f16.gguf';

  // --- HuggingFace download URLs (resolve/main for direct download) ---
  static const String modelUrl =
      'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/$modelFileName';
  static const String mmprojUrl =
      'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/$mmprojFileName';

  // --- Approximate file sizes (bytes) ---
  // Q8_0 model: ~437 MB
  static const int modelSizeBytes = 458227712;
  // mmproj f16: ~50-80 MB (estimate; verify from HuggingFace)
  // TODO: Verify exact mmproj file size from HuggingFace listing
  static const int mmprojSizeBytes = 75497472; // ~72 MB estimate

  /// Combined download size for progress display.
  static int get totalDownloadBytes => modelSizeBytes + mmprojSizeBytes;

  // --- Path management ---

  /// Directory for model files: Documents/models/
  static Future<String> get modelDir async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/models');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Full path to the main GGUF model file.
  static Future<String> get modelPath async =>
      '${await modelDir}/$modelFileName';

  /// Full path to the multimodal projector file.
  static Future<String> get mmprojPath async =>
      '${await modelDir}/$mmprojFileName';

  /// Check if BOTH model files exist and are ready for inference.
  static Future<bool> get isModelReady async {
    final model = File(await modelPath);
    final mmproj = File(await mmprojPath);
    return await model.exists() && await mmproj.exists();
  }
}
