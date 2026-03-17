# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

iOS Edge OCR — a standalone Flutter iOS app for offline OCR using on-device vision-language model inference. Users capture/import images and extract text entirely on-device via SmolVLM2 500M running through Edge-Veda runtime with Metal GPU acceleration. Targets iPhone 13+. Zero cloud, zero network for OCR.

## Tech Stack

- **Framework:** Flutter 3.41.x / Dart 3.9.x
- **AI Runtime:** Edge-Veda ^2.5.0 (managed on-device inference, XCFramework ~31 MB via CocoaPods)
- **Model:** SmolVLM2 500M (GGUF Q4_K_M, ~607 MB, downloads on first launch)
- **State:** Riverpod 3.x with code generation (riverpod_annotation + riverpod_generator)
- **Navigation:** go_router
- **Image Input:** camera, image_picker, file_picker
- **Output:** Flutter Clipboard API, share_plus (v2)
- **Data Models:** freezed for immutable classes with code generation

## Build & Run

```bash
# Install dependencies
flutter pub get

# Run code generation (Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# Run on iOS device (requires physical device for Metal GPU)
flutter run --release

# iOS pod install (after adding dependencies)
cd ios && pod install && cd ..
```

## Architecture

Feature-first structure under `lib/features/`. Three features map to the user journey:

- **`features/image_input/`** — Camera capture, photo library, file import. All sources produce unified `ImageInput` model.
- **`features/ocr/`** — OCR pipeline: preprocessing → prompt construction → Edge-Veda inference → token stream. `OCRService` orchestrates, UI never calls runtime directly.
- **`features/result/`** — Text display, copy-to-clipboard, share.
- **`runtime/`** — Edge-Veda SDK integration (separate from features). Manages VisionWorker lifecycle, model init, thermal/QoS state. Only OCRService accesses this.
- **`core/constants/ocr_prompts.dart`** — Centralized prompt templates adapted from Ollama-OCR strategies.

**Key patterns:**
- Service-mediated inference: UI → ViewModel → OCRService → EdgeVedaRuntime (never skip layers)
- Lazy runtime init: Model loads once on first use, VisionWorker persists for app session
- Image preprocessing runs in Dart isolate (never on main thread)
- Prompt strategy registry: output format changes = prompt changes, not model changes
- Temperature = 0.0 for deterministic OCR output

## Critical Constraints

- **Memory:** SmolVLM2 uses ~600 MB persistently. On iPhone 13 (4 GB RAM), always resize images before inference (max 1024px longer edge). Never pass full 12 MP images.
- **Chat template:** Wrong `ChatTemplateFormat` in Edge-Veda produces garbage output. Verify the exact format for SmolVLM2.
- **Platform channels:** Minimize Flutter↔native boundary crossings for image data. Pass file paths (strings), not raw bytes.
- **Model storage:** Store in Documents directory (not Caches) — iOS can evict Caches under storage pressure, forcing 607 MB re-download.
- **iOS deployment target:** 15.0 (iPhone 13 ships with iOS 15)

## Planning

Project planning docs live in `.planning/`:
- `PROJECT.md` — Project context and requirements
- `REQUIREMENTS.md` — v1 requirements with REQ-IDs and traceability
- `ROADMAP.md` — 3-phase roadmap (Runtime → Image Acquisition → User Loop)
- `STATE.md` — Current project state
- `research/` — Domain research (stack, features, architecture, pitfalls)
- `config.json` — GSD workflow preferences
