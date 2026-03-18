import 'package:edge_veda/edge_veda.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../runtime/edge_veda_runtime.dart';
import '../../../runtime/thermal_monitor.dart';
import '../data/ocr_service.dart';
import '../domain/ocr_state.dart';

part 'ocr_view_model.g.dart';

/// Manages the OCR pipeline lifecycle as a Riverpod Notifier.
///
/// Orchestrates: pick image -> preprocess -> infer -> display result.
/// UI watches this provider and renders the appropriate state.
///
/// Architecture: OcrTestScreen -> OcrViewModel -> OcrService -> EdgeVedaRuntime
/// The view model never imports edge_veda or calls VisionWorker directly.
@riverpod
class OcrViewModel extends _$OcrViewModel {
  @override
  OcrState build() {
    return const OcrState.idle();
  }

  /// Pick an image from the photo library and extract text via OCR.
  ///
  /// State transitions: idle -> pickingImage -> preprocessing -> inferring -> complete
  /// On error: any state -> error
  /// On cancel (user dismisses picker): pickingImage -> idle
  Future<void> pickAndExtract() async {
    state = const OcrState.pickingImage();

    try {
      // 1. Pick image from gallery
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        // Don't set maxWidth/maxHeight here -- ImagePreprocessor handles resize
        // with proper aspect ratio and RGB conversion for VisionWorker.
      );

      // User cancelled the picker
      if (pickedFile == null) {
        state = const OcrState.idle();
        return;
      }

      // 2. Thermal gate: block inference when device is critically hot
      try {
        final thermalState = await TelemetryService().getThermalState();
        if (shouldBlockInference(thermalState)) {
          state = OcrState.error(thermalMessage(thermalState));
          return;
        }
      } catch (_) {
        // Thermal check failed (simulator, etc.) -- proceed anyway
      }

      // 3. Transition to preprocessing state
      state = const OcrState.preprocessing();

      // 4. Create OCR service with runtime reference
      final runtimeNotifier = ref.read(edgeVedaRuntimeProvider.notifier);
      final ocrService = OcrService(runtime: runtimeNotifier);

      // 5. Transition to inferring state
      state = const OcrState.inferring();

      // 6. Run full pipeline: preprocess -> prompt -> infer
      final result = await ocrService.extractText(pickedFile.path);

      // 7. Display result
      state = OcrState.complete(result);
    } catch (e) {
      state = OcrState.error(e.toString());
    }
  }

  /// Extract text from a pre-selected image path.
  ///
  /// Called from PreviewScreen after user taps "Extract Text".
  /// Unlike [pickAndExtract] which opens the gallery, this skips
  /// the picking step and goes straight to preprocessing + inference.
  ///
  /// State transitions: idle -> preprocessing -> inferring -> complete
  /// On error: any state -> error
  Future<void> extractFromPath(String imagePath) async {
    // Thermal gate: block inference when device is critically hot
    try {
      final thermalState = await TelemetryService().getThermalState();
      if (shouldBlockInference(thermalState)) {
        state = OcrState.error(thermalMessage(thermalState));
        return;
      }
    } catch (_) {
      // Thermal check failed (simulator, etc.) -- proceed anyway
    }

    state = const OcrState.preprocessing();

    try {
      final runtimeNotifier = ref.read(edgeVedaRuntimeProvider.notifier);
      final ocrService = OcrService(runtime: runtimeNotifier);

      state = const OcrState.inferring();

      final result = await ocrService.extractText(imagePath);

      state = OcrState.complete(result);
    } catch (e) {
      state = OcrState.error(e.toString());
    }
  }

  /// Reset to idle state. Called when user taps "Try Another" or "Retry".
  void reset() {
    state = const OcrState.idle();
  }
}
