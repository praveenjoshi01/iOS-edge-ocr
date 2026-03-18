# iOS Edge OCR

**Fully offline OCR for iOS** — extract text from any image entirely on-device using a vision-language model. No cloud, no network, no data leaves your phone.

Built with Flutter, powered by [SmolVLM2 500M](https://huggingface.co/HuggingFaceTB/SmolVLM2-500M-Video-Instruct) running through [Edge-Veda](https://pub.dev/packages/edge_veda) runtime with Metal GPU acceleration.

## Features

- **On-device inference** — SmolVLM2 500M runs locally via Metal GPU. Zero network calls for OCR.
- **Camera capture** — Live viewfinder with tap-to-capture for documents, signs, labels, receipts.
- **Photo library import** — Select existing photos for text extraction.
- **File import** — Import images and PDFs directly from the iOS Files app.
- **Image preview** — Review your image before running extraction.
- **One-tap copy** — Copy extracted text to clipboard with visual confirmation.
- **Thermal awareness** — Monitors device thermal state during inference; warns before throttling impacts performance.
- **Smart preprocessing** — Images auto-resized and optimized before inference to stay within memory budget.

## Requirements

- **iPhone 13 or newer** (A15 Bionic+, 4 GB RAM minimum)
- iOS 15.0+
- ~700 MB free storage (607 MB model + app)
- Model downloads on first launch (~607 MB, resumable)

## Architecture

```
User → Image Input → Preview → OCR Pipeline → Result Screen
         │                        │
    ┌────┴────┐          ┌───────┴────────┐
    │ Camera  │          │ Preprocessing  │
    │ Photos  │          │ Prompt Builder │
    │ Files   │          │ Edge-Veda SDK  │
    └─────────┘          │ SmolVLM2 500M  │
                         │ Metal GPU      │
                         └────────────────┘
```

**Feature-first structure** under `lib/features/`:

| Layer | Path | Responsibility |
|-------|------|----------------|
| Image Input | `features/image_input/` | Camera, photo library, file/PDF import |
| OCR | `features/ocr/` | Preprocessing, prompt construction, inference orchestration |
| Result | `features/result/` | Text display, copy-to-clipboard |
| Onboarding | `features/onboarding/` | Model download with progress/resume |
| Runtime | `runtime/` | Edge-Veda lifecycle, thermal monitoring, QoS |

**Key design decisions:**
- Service-mediated inference — UI never calls the runtime directly (UI → ViewModel → OCRService → EdgeVedaRuntime)
- Lazy model init — loads once on first use, VisionWorker persists for app session
- Image preprocessing in Dart isolate — never blocks the main thread
- Temperature 0.0 — deterministic OCR output
- Prompt strategy registry — output format changes via prompts, not model swaps

## Tech Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.41 / Dart 3.9 |
| AI Runtime | [Edge-Veda](https://pub.dev/packages/edge_veda) ^2.5.0 (~31 MB XCFramework) |
| Model | SmolVLM2 500M (GGUF Q4_K_M, ~607 MB) |
| State | Riverpod 3.x with code generation |
| Navigation | go_router |
| Image Capture | camera, image_picker, file_picker |
| Data Models | freezed (immutable classes with codegen) |

## Getting Started

### Prerequisites

- macOS with Xcode 15+
- Flutter 3.41+ installed
- Physical iOS device (Metal GPU required — simulator won't work for inference)

### Build & Run

```bash
# Install dependencies
flutter pub get

# Run code generation (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Install iOS pods
cd ios && pod install && cd ..

# Run on device (release mode for Metal performance)
flutter run --release
```

### First Launch

1. App opens to model download screen (~607 MB, shows progress)
2. Download is resumable — interrupt and resume anytime
3. Once complete, you're taken to the home screen
4. Capture or import an image → preview → extract text → copy

## Memory & Performance Notes

- SmolVLM2 holds ~600 MB in memory during inference
- Images auto-resized to max 1024px on longer edge before inference (prevents OOM on 4 GB devices)
- Model stored in Documents directory (not Caches) to avoid iOS eviction
- Inference takes ~2-5 seconds per image on iPhone 13+

## Project Status

All three development phases are complete:

| Phase | Description | Status |
|-------|-------------|--------|
| 1. Runtime & Core Pipeline | Edge-Veda + SmolVLM2 on-device inference with Metal GPU | Done |
| 2. Image Acquisition | Camera, photo library, and Files app integration | Done |
| 3. Complete User Loop | Copy output, loading feedback, error handling, thermal resilience | Done |

## License

This project is for personal/educational use.
