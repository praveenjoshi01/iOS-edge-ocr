# Project Research Summary

**Project:** iOS Edge OCR
**Domain:** On-device OCR Flutter iOS app with vision-language model inference
**Researched:** 2026-03-16
**Confidence:** MEDIUM-HIGH

## Executive Summary

iOS Edge OCR is an on-device text extraction app for iPhone 13+ built with Flutter, Edge-Veda runtime, and SmolVLM2 500M vision-language model. Unlike traditional OCR engines (Tesseract, ML Kit), this uses a VLM that understands document context and structure, enabling prompt-based output formatting (plain text, structured markdown, key-value extraction). Research confirms this architecture is viable but requires careful attention to mobile constraints: 607 MB model download on first launch, 600 MB persistent memory footprint during inference, thermal throttling after sustained GPU use, and VLM hallucination risk on noisy inputs.

The recommended approach is a phased implementation prioritizing runtime foundation before user-facing features. SmolVLM2 500M (Q4_K_M quantization) fits comfortably on iPhone 13's 4 GB RAM, and Edge-Veda provides managed inference with thermal monitoring, memory eviction, and QoS degradation - all critical for production stability. The core competitive advantage is 100% offline capability with no cloud, no accounts, no subscriptions, and VLM-powered structured extraction that traditional OCR cannot match. This fills the gap left by Microsoft Lens retirement (March 2026) and differentiates from subscription-gated competitors like Adobe Scan and Genius Scan.

Key risks center on memory management (image resizing before inference is non-negotiable), model download UX (607 MB on first launch destroys onboarding if not handled gracefully), and managing user expectations around VLM accuracy (SmolVLM2 500M scores 61% on OCRBench - 4 in 10 characters may be wrong on difficult inputs). Mitigation strategies are well-documented across all research areas and must be built into the architecture from day one, not retrofitted.

## Key Findings

### Recommended Stack

The stack centers on Edge-Veda (Flutter-native managed VLM runtime) with SmolVLM2 500M for inference, Riverpod 3.x for state management, and standard Flutter plugins for camera/gallery/file input. Edge-Veda is the only Flutter SDK providing thermal monitoring, memory eviction, and persistent worker lifecycle for on-device VLM inference - critical features missing from raw llama.cpp bindings. SmolVLM2 500M at Q4_K_M quantization (607 MB on disk) is the sweet spot for iPhone 13's 4 GB RAM, balancing accuracy against memory pressure.

**Core technologies:**
- **Flutter 3.41.x + Dart 3.9.x:** Single-platform iOS with hot-reload DX, isolates for background inference, sound null safety for robust state modeling
- **Edge-Veda 2.5.0:** Managed VLM runtime wrapping llama.cpp b7952 via XCFramework, Metal GPU offload, thermal-aware QoS, automatic model downloads
- **SmolVLM2 500M (Q4_K_M):** 500M parameter VLM, 607 MB GGUF, proven OCR capability, fits iPhone 13 RAM with ~1.8 GB headroom for app/OS
- **flutter_riverpod 3.3.1:** State management with compile-time safety, async state handling via AsyncValue, code-gen support for clean provider definitions
- **camera 0.12.0, image_picker 1.2.1, file_picker 10.3.10:** Official Flutter plugins for camera capture, photo library, and Files app import
- **drift 2.32.0:** SQLite wrapper for OCR history persistence (defer to v2+), actively maintained unlike abandoned Hive/Isar alternatives
- **share_plus 12.0.1:** Native iOS share sheet integration for exporting extracted text

**Critical version requirements:**
- iOS deployment target: 15.0 (iPhone 13 minimum)
- Xcode 16.x for iOS build toolchain
- CocoaPods for Edge-Veda XCFramework auto-download (31 MB)

**OCR prompt strategy (adapted from Ollama-OCR):**
SmolVLM2 inference quality depends heavily on prompt engineering. Three core prompt templates enable format selection:
- Plain text: "Extract all visible text exactly as it appears. Preserve line breaks. Output only text, nothing else."
- Structured/markdown: "Extract text preserving formatting using Markdown: headers for titles, bullet points for lists, tables for tabular data."
- Key-value: "Extract all labeled fields and their values. Output as key: value pairs, one per line."

Temperature must be 0.0 for deterministic OCR output. Higher temperatures introduce hallucinated text. Prompts derived from Ollama-OCR patterns require validation with SmolVLM2 500M specifically during implementation (smaller model may not follow complex multi-step instructions as reliably as 7B+ models).

### Expected Features

On-device offline OCR apps have a well-established feature baseline. Users expect camera capture, photo library import, text extraction, copy/share, and loading indicators. Missing any of these makes the product feel incomplete. Differentiators for this app are: 100% offline (no cloud, no account), VLM-based contextual understanding (handles complex layouts better than traditional OCR), prompt-based output formats (plain/structured/key-value via same model), and privacy-first (zero data collection). Anti-features to avoid: document scanning with edge detection (OpenCV complexity), PDF export (layout engine complexity), scan history (database overhead), and real-time live overlay (VLM inference is seconds, not frames).

**Must have (table stakes):**
- Camera capture with viewfinder - primary input method, expected starting point for every OCR app
- Photo library import - secondary input for existing images, trivial to add with image_picker
- Text extraction (plain text) - core VLM inference via Edge-Veda + SmolVLM2; quality determines app viability
- Copy to clipboard - most basic output action, 100% of OCR apps support this
- Share via iOS share sheet - users expect to send text to Messages/Notes/Mail/etc
- Loading indicator during inference - VLM takes 2-5 seconds; without feedback users think app froze
- Error handling for poor images - must tell users why extraction failed vs returning empty text
- Image preview before extraction - confirm captured image before waiting for inference

**Should have (competitive differentiators):**
- Output format selection (Plain/Structured/Key-Value) - adapted from Ollama-OCR, no mobile competitor offers this
- 100% offline operation - architectural decision, post-Microsoft-Lens gap, privacy differentiation
- VLM contextual understanding - SmolVLM2 "sees" whole page, infers reading order, handles complex layouts better than traditional OCR
- No subscription model - subscription fatigue in market (Adobe Scan $9.99/mo, Genius Scan $7.99/mo), free or one-time purchase differentiates
- Privacy-first (zero data collection) - no account, no analytics, no cloud, no tracking; stronger privacy than any competitor

**Defer (v2+):**
- Document edge detection + perspective correction - full document scanning adds OpenCV complexity, VLM can handle moderately angled photos
- PDF export - requires layout engine and font embedding, users can paste to Notes/Pages for PDF creation
- Scan history with local storage - requires SQLite, search indexing, thumbnail generation, contradicts v1 capture-extract-copy simplicity
- Batch/multi-page processing - queue management, progress per page, significant UX complexity
- Translation - requires translation models or internet, scope creep from OCR into NLP
- Handwriting recognition - SmolVLM2 500M likely struggles, do not advertise until validated
- Real-time live overlay - continuous VLM inference measured in seconds not frames, battery drain

### Architecture Approach

The architecture follows Flutter's official feature-first structure with clean separation between presentation (ViewModels + Views), service orchestration (OCRService, ImageAcquisitionService, ExportService), and infrastructure (EdgeVedaRuntime, ImagePreprocessor). The critical pattern is service-mediated inference: UI never talks to Edge-Veda directly, OCRService orchestrates preprocessing, prompt construction, and streaming inference. Edge-Veda's VisionWorker runs in a persistent isolate with lazy initialization (load model once on first use, keep alive for session) to avoid 3-5 second model load overhead on every extraction.

**Major components:**
1. **ImageAcquisitionService** - unified interface for camera, gallery, file picker; returns normalized ImageInput regardless of source
2. **OCRService** - orchestrates image preprocessing (resize, RGB conversion in isolate), prompt selection (format-specific via PromptBuilder), and VisionWorker streaming inference
3. **EdgeVedaRuntime** - manages VisionWorker lifecycle (init, spawn, dispose), model loading (lazy, with download progress), thermal monitoring, and QoS signals
4. **ImagePreprocessor** - runs in Dart isolate to resize images (cap at 1024px), correct EXIF orientation, convert to RGB byte array without blocking UI
5. **ExportService** - copy to clipboard and iOS share sheet integration
6. **PromptBuilder** - centralized prompt templates (Plain/Structured/KeyValue formats), single source of truth for prompt engineering iteration

**Key patterns:**
- Streaming token display: VisionWorker yields tokens incrementally (2-5 second inference), UI updates progressively as text appears
- Lazy runtime initialization: load SmolVLM2 once on first extraction, not at app startup or per-request
- Prompt strategy registry: different output formats achieved by varying prompts, not post-processing
- Minimal platform channel crossings: capture image in native, resize in native, pass to native inference, return only text string to Flutter (avoid serializing megabytes of image data)

**Data flow (happy path):**
User taps capture → ImageAcquisitionService returns ImageInput → ImagePreprocessor (isolate) resizes + converts to RGB → PromptBuilder generates format-specific prompt → EdgeVedaRuntime.describeFrame streams tokens → OcrViewModel accumulates → ResultScreen displays with copy/share

### Critical Pitfalls

Research identified six critical pitfalls with high impact and specific prevention strategies. All must be addressed in Phase 1 (runtime foundation) or Phase 2 (core workflows).

1. **VLM Hallucination - Model invents text not in image:** SmolVLM2 500M scores 61% on OCRBench (4 in 10 characters wrong on difficult inputs). VLMs generate text from visual embeddings + language priors; smaller models rely more on priors, risking fabrication on noisy/low-contrast/non-semantic input. Prevention: never present output as guaranteed-accurate, show side-by-side image comparison for verification, prompt engineering with "do not guess" instructions, validate structured output format programmatically. Address in Phase 1 (core inference) to set user expectations from day one.

2. **iOS memory pressure kills app during inference:** SmolVLM2 500M consumes 600 MB persistent memory, iPhone 13 has 4 GB total RAM, iOS jetsam kills apps exceeding ~50% of physical memory. With Flutter engine overhead (80-120 MB) and full-resolution camera image (12 MP = 48 MB uncompressed), you approach jetsam threshold. Prevention: always resize input images to model resolution (512-1024px) before inference, profile on iPhone 13 minimum device, use Edge-Veda QoS callbacks for memory warnings, process images sequentially (never hold camera buffer + model result simultaneously). Address in Phase 1 (image pipeline) - memory budgeting must be designed in from start.

3. **607 MB model download on first launch destroys onboarding:** App is "offline OCR" but requires one-time 607 MB download before functional. iOS cellular prompt triggers at 200 MB, blocking many users without Wi-Fi. If download interrupted (backgrounding, network drop), user may have corrupt partial file and broken app. Prevention: dedicated onboarding screen communicating "one-time download, 607 MB, Wi-Fi recommended", show download progress (percentage, MB, ETA), implement robust resume-on-interrupt with checksum validation, store in Documents directory (not Caches). Address in Phase 1 (project scaffold) - this is the first user-facing flow, not an afterthought.

4. **Thermal throttling degrades inference to unusability:** VLM with Metal GPU generates significant heat; after 3-5 continuous inference passes, iPhone thermal management reduces GPU clock, latency degrades from 2-5 seconds to 15-30+ seconds. Prevention: Edge-Veda includes thermal-aware QoS with hysteresis (don't bypass these signals), surface thermal state to user ("Device warm, processing may be slower"), insert cooldown pauses between sequential passes, test multi-page scenario on physical hardware. Address in Phase 2 (multi-image workflows) - not critical for single-image demo but essential for batch operations.

5. **Wrong chat template format produces garbage output:** Edge-Veda documentation warns "wrong ChatTemplateFormat produces garbage output." SmolVLM2 requires specific prompt template; wrong template yields incoherent text, random tokens, or repeated patterns indistinguishable from "broken model". Prevention: verify exact ChatTemplateFormat from Edge-Veda docs (don't guess), build smoke test with known image ("Hello World") validating expected output substring, log raw model output during development. Address in Phase 1 (day-one integration validation) - if template is wrong, nothing else works.

6. **Platform channel bottleneck passing images Flutter-to-native:** MethodChannel serializes all data crossing Flutter-native boundary; for camera images (megabytes), serialization adds 50-200ms latency per transfer. Passing images back and forth multiple times compounds overhead. Prevention: minimize boundary crossings (ideal: capture in native, resize in native, inference in native, return only text string to Flutter), pass file paths instead of raw bytes if image display needed, use BinaryCodec for unavoidable large transfers. Address in Phase 1 (architecture design) - data flow must minimize crossings from start, retrofitting is painful.

## Implications for Roadmap

Based on combined research, the roadmap should follow a bottom-up dependency sequence: runtime foundation first (if Edge-Veda cannot load SmolVLM2 and produce text, nothing else matters), then core OCR pipeline (proof that inference works), then image acquisition inputs (camera, gallery, file), then result display and export, and finally additional formats and polish. This ordering isolates critical risks early (memory, thermal, model download UX) and enables iterative validation before building user-facing features.

### Phase 1: Runtime Foundation & Model Integration
**Rationale:** Everything depends on Edge-Veda successfully loading SmolVLM2 and producing text from an image. If this core capability fails, no amount of UI polish matters. This phase isolates the three highest-risk items from PITFALLS.md: model download UX (607 MB), memory management (600 MB footprint), and chat template validation (garbage output if wrong). Addressing these first prevents cascading failures in later phases.

**Delivers:**
- EdgeVedaRuntime wrapper with VisionWorker lifecycle management
- Model download with progress UI, resume-on-interrupt, checksum validation
- ImagePreprocessor running in isolate (resize to max 1024px, EXIF correction, RGB conversion)
- PromptBuilder with plain text prompt template (temperature=0.0)
- Smoke test: hardcoded test image → OCR → validate expected output substring
- Memory profiling on iPhone 13 confirming <1.5 GB peak usage

**Addresses features:**
- Text extraction (plain text) - table stakes from FEATURES.md
- Loading indicator - table stakes, showing model download and inference progress

**Avoids pitfalls:**
- Pitfall 3: 607 MB model download UX (dedicated onboarding, progress, resume)
- Pitfall 2: iOS memory pressure (image resizing before inference, profiling on 4 GB device)
- Pitfall 5: Wrong chat template (smoke test validation, verified against Edge-Veda docs)
- Pitfall 6: Platform channel bottleneck (architecture minimizes boundary crossings)

**Uses stack:**
- Edge-Veda 2.5.0 with SmolVLM2 500M (Q4_K_M)
- path_provider for model file storage in Documents directory
- Dart isolates for preprocessing (via compute or long-lived worker)

**Research flag:** Phase 1 does NOT need additional research. Edge-Veda API, SmolVLM2 capabilities, and model download patterns are well-documented in STACK.md and PITFALLS.md. This is standard integration work with known APIs.

---

### Phase 2: Core OCR Pipeline & Streaming Display
**Rationale:** With the runtime proven (Phase 1 smoke test passes), Phase 2 builds the full OCR service orchestration and streaming token display. This establishes the processing pipeline (preprocess → prompt → infer → accumulate tokens) and validates end-to-end latency before adding multiple input sources. Streaming display is critical for perceived performance - 2-5 second inference feels fast if text appears progressively, feels broken if UI is blank.

**Delivers:**
- OCRService orchestrating ImagePreprocessor → PromptBuilder → EdgeVedaRuntime
- OcrViewModel with AsyncValue state modeling (idle/processing/complete/error)
- OcrScreen with StreamBuilder consuming token stream, progressive text accumulation
- Basic ResultScreen (text display, no copy/share yet)
- End-to-end latency measurement (capture to text output)

**Addresses features:**
- Text result display - table stakes from FEATURES.md
- Loading/progress indicator - show "Extracting text..." with animated indicator during inference

**Avoids pitfalls:**
- Pitfall 1: VLM hallucination (UI shows "AI-generated text, verify accuracy" disclaimer)
- Anti-pattern 4: Blocking on full result (stream tokens to UI as they arrive)
- Anti-pattern 5: Hardcoded prompts scattered (PromptBuilder centralizes all prompts)

**Uses stack:**
- flutter_riverpod 3.3.1 for state management (AsyncValue for loading/data/error states)
- freezed 3.2.3 for immutable OCR result models (sealed unions for state variants)

**Research flag:** Phase 2 does NOT need additional research. Riverpod async state handling and StreamBuilder patterns are standard Flutter (well-documented in STACK.md and ARCHITECTURE.md).

---

### Phase 3: Image Acquisition (Camera, Gallery, File)
**Rationale:** With the OCR pipeline validated (Phase 2), Phase 3 adds the three input sources: camera capture (primary input), photo library (secondary input for existing images), and file import (Files app). All three converge to a unified ImageInput model before entering the OCR pipeline. Camera integration has known memory leak risks (Flutter issue #29586, #97941) - test with 20+ consecutive captures on physical device and verify memory returns to baseline.

**Delivers:**
- ImageAcquisitionService with unified ImageInput model (path, source, metadata)
- CameraScreen with live preview (camera plugin), capture button, flash/focus controls
- GalleryPickerScreen (image_picker with ImageSource.gallery)
- FileImportScreen (file_picker for images, defer PDF to Phase 5)
- Permission handling (permission_handler for camera and photo library access)
- All three sources feed existing OCR pipeline from Phase 2

**Addresses features:**
- Camera capture with viewfinder - table stakes from FEATURES.md
- Photo library import - table stakes from FEATURES.md
- Image preview before extraction - table stakes, show captured/selected image with "Extract Text" button

**Avoids pitfalls:**
- Pitfall 6: Platform channel bottleneck (pass file paths to Flutter, not raw bytes; image never crosses to Dart if avoidable)
- Integration gotcha: Flutter camera plugin memory leak (dispose camera controller properly, test 20+ consecutive captures in Instruments)
- "Looks done but isn't": no EXIF orientation correction, no temp file cleanup (both must be in ImagePreprocessor)

**Uses stack:**
- camera 0.12.0 for live preview and capture
- image_picker 1.2.1 for photo library
- file_picker 10.3.10 for Files app import
- permission_handler 12.0.1 for runtime permissions

**Research flag:** Phase 3 does NOT need additional research. Camera, image_picker, and file_picker are official Flutter plugins with established patterns (documented in STACK.md, integration gotchas in PITFALLS.md).

---

### Phase 4: Result Export & Copy/Share
**Rationale:** With images flowing in (Phase 3) and OCR producing text (Phase 2), Phase 4 completes the core capture-extract-export loop by adding clipboard copy and iOS share sheet. This delivers the MVP: user can capture an image, extract text, and copy/share it. Copy must show visual confirmation (SnackBar, checkmark animation) so user knows it succeeded. Share sheet invokes native UIActivityViewController for sending to Messages/Notes/Mail.

**Delivers:**
- ExportService with copyToClipboard and share methods
- ResultScreen updated with copy and share buttons
- Visual confirmation on copy (SnackBar or checkmark animation)
- Share sheet integration (share_plus plugin)
- Error handling for empty text state (disable copy/share if no text extracted)

**Addresses features:**
- Copy to clipboard - table stakes from FEATURES.md
- Share via iOS share sheet - table stakes from FEATURES.md

**Avoids pitfalls:**
- "Looks done but isn't": no user feedback on copy success, no handling of empty text
- UX pitfall: no indication of OCR accuracy limitations (add disclaimer in ResultScreen)

**Uses stack:**
- share_plus 12.0.1 for native share sheet
- Flutter Clipboard API (built-in, flutter/services.dart)

**Research flag:** Phase 4 does NOT need additional research. Clipboard and share_plus are standard Flutter patterns (documented in STACK.md).

---

### Phase 5: Output Formats & PDF Support
**Rationale:** With the MVP complete (Phases 1-4), Phase 5 adds differentiating features: prompt-based output format selection (Plain/Structured/Key-Value) and PDF page rendering for document import. Output formats are the core Ollama-OCR adaptation - same model, different prompts produce structured markdown or key-value extraction. PDF support requires rendering pages to images (pdfrx_coregraphics on iOS to avoid bundling PDFium).

**Delivers:**
- PromptBuilder expanded with Structured and Key-Value prompt templates
- Format selector UI in OcrScreen (Plain/Structured/Key-Value toggle)
- PdfRendererService using pdfrx to render PDF pages to images
- File import updated to support PDFs with page selection
- Post-processing to strip prompt artifacts and normalize whitespace
- Validation testing: 50+ diverse images across all three formats

**Addresses features:**
- Output format selection - differentiator from FEATURES.md (no mobile competitor offers this)
- Structured text preserving layout - differentiator (VLM-based extraction maintains document hierarchy)

**Avoids pitfalls:**
- Pitfall 1: VLM hallucination on structured output (validate format programmatically, flag malformed JSON/markdown)
- Integration gotcha: Ollama-OCR prompt adaptation (simplify prompts for 500M model capacity, don't assume 7B model instruction-following)
- "Looks done but isn't": Structured output breaks on single-line text, 500M model cannot reliably produce complex formats

**Uses stack:**
- pdfrx (or pdfrx_coregraphics) for PDF page rendering
- Expanded PromptBuilder with three format templates

**Research flag:** Phase 5 MAY need targeted research. Ollama-OCR prompts are documented in STACK.md, but adapting them for SmolVLM2 500M's capacity (vs 7B+ models) may require iteration. Consider `/gsd:research-phase` if prompt quality is poor during testing. PDF rendering with pdfrx is standard (skip research).

---

### Phase 6: Thermal Management & Multi-Image Workflows
**Rationale:** Phases 1-5 deliver a functional single-image OCR app. Phase 6 addresses sustained use: batch processing multiple images sequentially and handling thermal throttling gracefully. Edge-Veda's thermal-aware QoS must surface to the user ("Device warm, processing may be slower") and cooldown pauses inserted between sequential passes. Test scenario: import 10 images, process sequentially on physical device, monitor thermal state and latency degradation.

**Delivers:**
- Batch processing UI (select multiple images, queue for sequential extraction)
- Per-image progress display ("Processing image 3 of 10...")
- Thermal state monitoring (ProcessInfo.thermalState on native side, communicated to Flutter)
- Cooldown pauses between inference passes (2-3 seconds)
- QoS signal surfacing ("Device warm" warning banner)
- Runtime state display (model loaded, thermal level, memory pressure)

**Addresses features:**
- Batch/multi-page processing - defer to v2+ from FEATURES.md (now implementing as Phase 6)

**Avoids pitfalls:**
- Pitfall 4: Thermal throttling (Edge-Veda QoS signals surfaced, cooldown pauses, user expectations set)
- UX pitfall: Batch processing with no individual progress (show per-image progress)
- Performance trap: Sequential synchronous inference (run in background isolate, allow cancellation)

**Uses stack:**
- Edge-Veda QoS callbacks (thermal state, memory pressure)
- Native ProcessInfo.thermalState integration

**Research flag:** Phase 6 does NOT need additional research. Edge-Veda QoS and thermal management are documented in STACK.md and PITFALLS.md. This is standard implementation of existing APIs.

---

### Phase 7: Polish, Error Handling & Edge Cases
**Rationale:** Final phase addresses production readiness: comprehensive error states (model load failure, permission denial, corrupt image, empty extraction), recovery paths for common failures, camera viewfinder guidance ("Move closer", "Better lighting"), and post-processing to strip prompt artifacts. This phase also includes accessibility (VoiceOver hints) and final UX polish (empty states, loading skeletons).

**Delivers:**
- Comprehensive error handling (model load failure, Metal GPU unavailable, insufficient disk space, corrupt GGUF, permission denied)
- Recovery paths ("Text could not be extracted. Try a clearer image." with retry button)
- Camera guidance overlay (subtle hints for optimal distance/angle/lighting)
- Post-processing for model output (strip prompt remnants, normalize whitespace, handle empty/error tokens)
- Inference timeout handling (model could hang on adversarial input)
- Cleanup of temporary image files (delete after extraction, cleanup on backgrounding)
- VoiceOver support (semantic labels for buttons, extracted text readability)
- Empty states (no text extracted, model not yet downloaded)

**Addresses features:**
- Error handling for poor images - table stakes from FEATURES.md
- Basic error states - table stakes from FEATURES.md

**Avoids pitfalls:**
- "Looks done but isn't" checklist (error handling, temp file cleanup, EXIF correction, timeout handling, empty states)
- UX pitfall: "Processing failed" with no recovery path (provide actionable feedback)
- UX pitfall: Camera viewfinder without guidance (add overlay hints)
- Security mistake: Storing extracted text in logs (never log extracted text in production builds)

**Uses stack:**
- All previously integrated components
- Flutter kReleaseMode flag to gate debug output

**Research flag:** Phase 7 does NOT need additional research. Error handling and UX polish patterns are standard Flutter development.

---

### Phase Ordering Rationale

**Bottom-up dependency sequence:**
- Phase 1 must come first because everything depends on the runtime working. If Edge-Veda cannot load SmolVLM2 and produce text, nothing else matters.
- Phase 2 before Phase 3 because you can test OCR with a hardcoded image before building camera/gallery UI. This isolates "does inference work?" from "does image capture work?"
- Phase 3 before Phase 4 because you need images flowing in before export makes sense.
- Phase 4 completes the MVP (capture-extract-copy loop).
- Phase 5 adds differentiators (format selection, PDF) after core loop is proven.
- Phase 6 addresses sustained use (batch, thermal) after single-image workflows are validated.
- Phase 7 is polish and error handling after all features are implemented.

**Critical risk isolation:**
The three highest-risk items (model download UX, memory management, chat template validation) are all in Phase 1. This front-loads risk and prevents cascading failures. If Phase 1 smoke test fails, you know immediately (before building any UI) that the core approach needs adjustment.

**Dependency graph alignment:**
ARCHITECTURE.md recommends this exact ordering in its "Build Order" section. The research-derived phase structure matches the technical dependency graph perfectly.

### Research Flags

**Phases likely needing deeper research during planning:**
- **Phase 5 (Output Formats):** Ollama-OCR prompts documented in STACK.md are designed for 7B+ models (Llama 3.2 Vision, MiniCPM-V). Adapting them for SmolVLM2 500M's smaller capacity may require prompt engineering iteration. Consider `/gsd:research-phase` if initial prompt quality testing shows poor structured output or key-value extraction. Plain text extraction is well-validated, but structured/key-value formats need empirical testing.

**Phases with standard patterns (skip research-phase):**
- **Phase 1 (Runtime Foundation):** Edge-Veda API, model download, and memory profiling are fully documented in STACK.md and PITFALLS.md. Standard integration work.
- **Phase 2 (OCR Pipeline):** Riverpod async state, StreamBuilder, and service orchestration are standard Flutter patterns documented in STACK.md and ARCHITECTURE.md.
- **Phase 3 (Image Acquisition):** Camera, image_picker, file_picker are official Flutter plugins with established patterns. Integration gotchas documented in PITFALLS.md.
- **Phase 4 (Export):** Clipboard and share_plus are standard Flutter APIs documented in STACK.md.
- **Phase 6 (Thermal Management):** Edge-Veda QoS and thermal state monitoring fully documented in STACK.md and PITFALLS.md.
- **Phase 7 (Polish):** Error handling and UX patterns are standard Flutter development.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Edge-Veda 2.5.0 and SmolVLM2 500M capabilities verified via pub.dev, GitHub, and HuggingFace. Flutter plugin versions (camera, image_picker, etc.) verified via pub.dev. OCR prompt strategies adapted from Ollama-OCR (MEDIUM confidence - needs validation with 500M model). |
| Features | HIGH | Table stakes features and competitive differentiators derived from comprehensive competitor analysis (Apple Live Text, Adobe Scan, Genius Scan) and Microsoft Lens retirement gap. Feature prioritization matrix validated against Zapier, SecureScan, and GetApp research on user expectations. |
| Architecture | MEDIUM-HIGH | Service-mediated inference, lazy runtime initialization, and streaming token display patterns validated against Edge-Veda documentation and Flutter official architecture guide. Feature-first project structure recommended by official Flutter docs and community consensus. Specific Edge-Veda API shapes (describeFrame, generateStream) need verification against 2.5.0 docs during implementation. |
| Pitfalls | MEDIUM-HIGH | Critical pitfalls (VLM hallucination, memory pressure, thermal throttling) verified across multiple HIGH confidence sources (Apple docs, CoreML issue tracker, Flutter issue tracker, peer-reviewed papers). Edge-Veda-specific QoS behavior documented in GitHub README but has limited public production track record (MEDIUM confidence - assume documentation is accurate, validate during testing). |

**Overall confidence:** MEDIUM-HIGH

Research is comprehensive and cross-verified across multiple sources. The stack, architecture, and feature landscape are well-understood. Primary uncertainty centers on SmolVLM2 500M's actual OCR quality with adapted Ollama-OCR prompts (500M parameter budget vs 7B+ models those prompts were designed for) and Edge-Veda's runtime behavior under sustained production load (thermal throttling recovery, QoS hysteresis timing). Both require empirical validation during implementation but do not block architectural decisions.

### Gaps to Address

**Gap 1: SmolVLM2 500M OCR quality with Ollama-OCR prompts**
- **Nature:** Ollama-OCR prompt strategies documented in STACK.md are derived from usage with larger models (Llama 3.2 Vision 7B, MiniCPM-V 8B). SmolVLM2 500M has significantly smaller parameter budget and may not follow complex multi-step instructions reliably. SmolVLM2 scores 61% on OCRBench (vs 80%+ for larger VLMs).
- **Impact:** Structured output and key-value extraction (Phase 5) may require simplified prompts or deliver lower quality than expected.
- **Mitigation:** Phase 1 smoke test validates plain text extraction quality early. Phase 5 includes explicit validation testing with 50+ diverse images across all formats. If quality is poor, consider `/gsd:research-phase` to find SmolVLM2-specific prompt patterns or fall back to plain text only for v1.
- **When to address:** Phase 1 (plain text validation), Phase 5 (structured format validation)

**Gap 2: Edge-Veda production stability under sustained load**
- **Nature:** Edge-Veda 2.5.0 has limited public production track record. QoS thermal management, memory eviction timing, and hysteresis recovery are documented but not empirically validated in multi-hour sessions or batch processing of 50+ images.
- **Impact:** Thermal throttling recovery may be slower than documented, memory eviction may be more aggressive than expected, or QoS "Paused" state may not resume gracefully.
- **Mitigation:** Phase 6 includes explicit multi-image testing (10 images sequentially) on physical device with thermal state monitoring. Build escape hatches: allow manual model reload if stuck in degraded state, surface QoS level to user for debugging.
- **When to address:** Phase 6 (batch processing and thermal management testing)

**Gap 3: Flutter camera plugin memory leak status (iOS)**
- **Nature:** Flutter issues #29586 and #97941 document camera plugin memory leaks on iOS, partially addressed but not fully resolved as of camera 0.12.0. Leak severity varies by iOS version and device.
- **Impact:** Consecutive captures (20+ images) may accumulate leaked buffers, pushing app toward jetsam threshold.
- **Mitigation:** Phase 3 includes explicit memory testing (20+ consecutive captures in Instruments, verify memory returns to baseline). If leak persists, implement manual buffer disposal or fall back to image_picker for capture (simpler, no streaming, no known leaks).
- **When to address:** Phase 3 (camera integration testing)

**Gap 4: HEIC format handling in simulator vs device**
- **Nature:** PHPicker (used by image_picker since 0.8.1) cannot pick HEIC images in iOS simulator, only on physical devices. HEIC is default capture format for recent iPhones.
- **Impact:** Simulator testing may give false negatives (images work) that fail on device (HEIC decode issues).
- **Mitigation:** Always test photo library import on physical device, not just simulator. Explicitly test HEIC images (capture with iPhone camera, import via library). ImagePreprocessor may need explicit HEIC-to-JPEG conversion if Edge-Veda cannot handle HEIC.
- **When to address:** Phase 3 (photo library import testing on device)

## Sources

### Primary (HIGH confidence)
- [Edge-Veda pub.dev package v2.5.0](https://pub.dev/packages/edge_veda) - API documentation, version verification
- [Edge-Veda GitHub repository](https://github.com/ramanujammv1988/edge-veda) - Architecture, worker system, QoS, thermal management
- [SmolVLM2 HuggingFace blog](https://huggingface.co/blog/smolvlm2) - Model capabilities, sizes, benchmarks
- [SmolVLM2-500M-Video-Instruct model card](https://huggingface.co/HuggingFaceTB/SmolVLM2-500M-Video-Instruct) - 500M specifications
- [Flutter SDK 3.41.x release notes](https://docs.flutter.dev/release/release-notes) - SDK version verification
- [Flutter Official Architecture Guide](https://docs.flutter.dev/app-architecture/guide) - MVVM, feature-first structure
- [Riverpod 3.0 documentation](https://riverpod.dev/docs/whats_new) - State management patterns
- [Apple: Identifying high-memory use with jetsam reports](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports) - iOS memory limits
- [Apple: Live Text Support](https://support.apple.com/en-us/120004) - Competitor capabilities
- [Microsoft Lens Retirement](https://support.microsoft.com/en-us/topic/retirement-of-microsoft-lens-fc965de7-499d-4d38-aeae-f6e48271652d) - Market gap
- [Flutter camera plugin issue #29586](https://github.com/flutter/flutter/issues/29586) - Memory leak documentation
- [Flutter camera plugin issue #97941](https://github.com/flutter/flutter/issues/97941) - iOS memory crash documentation

### Secondary (MEDIUM confidence)
- [Ollama-OCR GitHub](https://github.com/imanoop7/Ollama-OCR) - Prompt-based OCR patterns
- [GGUF Quantization Guide for iPhone/Mac](https://enclaveai.app/blog/2025/11/12/practical-quantization-guide-iphone-mac-gguf/) - Q4_K_M recommendation
- [VLM OCR best practices (Ubicloud)](https://www.ubicloud.com/blog/end-to-end-ocr-with-vision-language-models) - Temperature=0.0, prompt structure
- [HuggingFace: OCR with open models](https://huggingface.co/blog/ocr-open-models) - VLM OCR state of the art
- [Zapier: Best mobile scanning and OCR software](https://zapier.com/blog/best-mobile-scanning-ocr-apps/) - Competitor feature overview
- [SecureScan: Top 10 Free Mobile Scanning Apps 2026](https://www.securescan.com/articles/records-management/the-best-mobile-scanning-apps-rated/) - Competitor accuracy testing
- [GetApp: Best OCR Software with Offline Access 2026](https://www.getapp.com/emerging-technology-software/ocr/f/offline-access/) - User expectations research
- [Flutter Project Structure: Feature-first or Layer-first?](https://codewithandrea.com/articles/flutter-project-structure/) - Architecture recommendation
- [Roboflow: Base vs Fine-Tuned SmolVLM2 for OCR](https://blog.roboflow.com/base-vs-fine-tuned-smolvlm2-ocr/) - SmolVLM2 OCR performance
- [On-Device LLMs: State of the Union 2026 (Vikas Chandra)](https://v-chandra.github.io/on-device-llms/) - Mobile LLM constraints
- [Avoiding Hidden Hazards: ML on iOS (Kirill Semianov)](https://ksemianov.github.io/articles/ios-ml/) - CoreML memory, GPU issues
- [HalluText: Benchmarking OCR Hallucination (OpenReview)](https://openreview.net/forum?id=LRnt6foJ3q) - VLM hallucination research
- [iOS Memory Pressure Signals (Ravi Kumar)](https://ravi6997.medium.com/memory-pressure-signals-in-ios-how-the-system-decides-to-terminate-your-app-c1b174c50214) - Jetsam behavior
- [Improving Platform Channel Performance in Flutter](https://medium.com/flutter/improving-platform-channel-performance-in-flutter-e5b4e5df04af) - Channel optimization

### Tertiary (LOW confidence, needs validation)
- [Building AI-Powered Mobile Apps: On-Device LLMs in Flutter](https://medium.com/@stepan_plotytsia/building-ai-powered-mobile-apps-running-on-device-llms-in-android-and-flutter-2025-guide-0b440c0ae08b) - General patterns
- [Deploying LLMs On-Device with Flutter Method Channels](https://medium.com/@debasishkumardas5/deploying-llms-on-device-in-android-and-ios-gemma-2b-model-with-flutter-method-channels-32c698c63c31) - Different runtime, general guidance

---
*Research completed: 2026-03-16*
*Ready for roadmap: yes*
