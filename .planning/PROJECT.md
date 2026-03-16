# iOS Edge OCR

## What This Is

A standalone Flutter iOS app that performs optical character recognition entirely on-device. Users point their camera at text (documents, signs, labels — anything), capture or import an image, and get extracted text they can copy or share. No internet required, no data leaves the device.

## Core Value

Instant, private text extraction from any image — entirely offline on the user's iPhone.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] On-device OCR via SmolVLM2 500M through Edge-Veda runtime
- [ ] Camera capture for real-time image acquisition
- [ ] Photo library import for existing images
- [ ] File import (images/PDFs from Files app)
- [ ] Plain text output with copy-to-clipboard
- [ ] Structured text output preserving layout (paragraphs, columns)
- [ ] Metal GPU acceleration on iPhone 13+

### Out of Scope

- Cloud/server-based OCR — contradicts offline-first principle
- Scan history or searchable library — v2 feature, v1 is capture-extract-copy
- Translation or summarization — v1 is extraction only
- Android support — iOS-first, Android is scaffolded in Edge-Veda but not target
- App Store polish (onboarding, settings, themes) — v1 is core loop only

## Context

**Edge-Veda (v2.5.0):** Managed on-device AI runtime for Flutter. Provides vision inference with Metal GPU support on iOS. SmolVLM2 500M is its recommended model for camera/image analysis. Native engine is a ~31 MB XCFramework auto-downloaded via CocoaPods. Minimum iOS 13.0. Key API: `EdgeVeda()` → `init(config)` → `generateStream(prompt)`.

**Ollama-OCR (github.com/imanoop7/Ollama-OCR):** Python-based OCR using vision-language models. Not used directly — we adapt its text extraction strategies: prompt engineering for different output formats (plain text, markdown/structured, JSON, key-value pairs, tabular), image preprocessing (resize, normalize), and custom prompt overrides for language-specific extraction.

**SmolVLM2 500M:** Compact vision-language model. Runs on-device via Edge-Veda with Metal GPU acceleration. Suitable for real-time image analysis on iPhone 13+ hardware.

**Architecture approach:** Flutter app → Edge-Veda SDK → SmolVLM2 500M model → Metal GPU. Image input via camera plugin or file picker → preprocessing → vision inference with OCR-tuned prompts (adapted from Ollama-OCR strategies) → text output.

## Constraints

- **Runtime:** Edge-Veda 2.5.0 (pub.dev/packages/edge_veda) — sole AI runtime, no cloud fallback
- **Model:** SmolVLM2 500M — fixed model choice per Edge-Veda recommendation
- **Platform:** iOS 13.0+ minimum, targeting iPhone 13+ for Metal GPU performance
- **Framework:** Flutter with Dart
- **Offline:** All inference on-device, zero network calls for OCR functionality
- **Binary size:** ~31 MB XCFramework for Edge-Veda native engine

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Edge-Veda as runtime | Managed on-device AI for Flutter with Metal GPU support, handles model lifecycle | — Pending |
| SmolVLM2 500M as model | Edge-Veda's recommended vision model for camera/image analysis, 500M params fits on-device | — Pending |
| Ollama-OCR prompt strategies | Proven extraction techniques (plain text, structured, key-value) adapted for on-device use | — Pending |
| Flutter over native Swift | Cross-platform potential, Edge-Veda is Flutter-native | — Pending |

---
*Last updated: 2026-03-16 after initialization*
