import 'dart:io';

import 'package:edge_veda/edge_veda.dart';
import 'package:path_provider/path_provider.dart';

/// Configuration constants for SmolVLM2 500M model files.
///
/// Uses Q8_0 quantization (~417 MB) -- officially available from ggml-org,
/// smaller than Q4_K_M and higher quality. mmproj f16 (~190 MB) bridges the
/// vision encoder to the language model.
///
/// Leverages Edge-Veda's ModelRegistry for verified download URLs and sizes.
///
/// CRITICAL: All files stored in Documents directory, never Caches.
/// iOS evicts Caches under storage pressure, which would force a ~600 MB
/// re-download.
class ModelConfig {
  ModelConfig._();

  // --- Edge-Veda ModelRegistry references ---
  /// Pre-configured model info from Edge-Veda's ModelRegistry.
  static const ModelInfo modelInfo = ModelRegistry.smolvlm2_500m;
  static const ModelInfo mmprojInfo = ModelRegistry.smolvlm2_500m_mmproj;

  // --- File names ---
  static const String modelFileName =
      'SmolVLM2-500M-Video-Instruct-Q8_0.gguf';
  static const String mmprojFileName =
      'mmproj-SmolVLM2-500M-Video-Instruct-f16.gguf';

  // --- HuggingFace download URLs (resolve/main for direct download) ---
  // Uses /resolve/main/ format which provides direct file download.
  // Alternative format /blob/main/ returns HTML page (wrong for downloads).
  // Edge-Veda ModelManager uses ModelRegistry URLs, so these are backup references.
  static const String modelUrl =
      'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/$modelFileName';
  static const String mmprojUrl =
      'https://huggingface.co/ggml-org/SmolVLM2-500M-Video-Instruct-GGUF/resolve/main/$mmprojFileName';

  // --- File sizes (bytes, from Edge-Veda ModelRegistry) ---
  // These are the exact expected sizes after successful download.
  // If file size on disk does not match, the download may be corrupt/incomplete.
  //
  // Q8_0 model: 436,808,704 bytes (~416.6 MB)
  static const int modelSizeBytes = 436808704;

  // mmproj f16: 199,470,624 bytes (~190.2 MB)
  // TODO: Verify mmproj file name on device -- if Edge-Veda ModelRegistry
  // uses a different filename than expected, download may succeed but
  // VisionWorker init will fail to find the file.
  static const int mmprojSizeBytes = 199470624;

  /// Combined download size for progress display (~607 MB total).
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
