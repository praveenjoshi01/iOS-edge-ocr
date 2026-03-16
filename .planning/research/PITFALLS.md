# Pitfalls Research

**Domain:** On-device OCR with vision-language model inference (Flutter iOS)
**Researched:** 2026-03-16
**Confidence:** MEDIUM-HIGH (verified across multiple sources; Edge-Veda-specific items are MEDIUM due to limited public track record)

## Critical Pitfalls

### Pitfall 1: VLM Hallucination -- The Model Invents Text That Is Not in the Image

**What goes wrong:**
Vision-language models do not perform character-by-character OCR. They generate text by predicting tokens conditioned on visual features and language priors. When the image is noisy, low-contrast, partially obscured, or contains non-semantic strings (serial numbers, URLs, codes), the model confidently outputs plausible-looking but fabricated text. SmolVLM2 500M is especially vulnerable because smaller parameter budgets amplify reliance on language priors over visual evidence. SmolVLM 500M scores only 61.0% on OCRBench -- nearly 4 in 10 characters may be wrong on difficult inputs.

**Why it happens:**
VLMs use an encode-then-decode architecture where the language model generates text from a visual embedding. Language priors learned during training can override what the vision encoder actually sees, producing "OCR hallucination." This is a fundamental property of the architecture, not a bug. The smaller the model, the stronger the language prior dominance because the visual encoder has less capacity to override it.

**How to avoid:**
- Never present VLM output as guaranteed-accurate OCR. Always communicate to the user that output is AI-generated and may contain errors.
- Implement confidence-adjacent UX: let users compare extracted text side-by-side with the source image for verification.
- Use prompt engineering to constrain output: "Extract only the text visible in this image. If text is unclear, indicate [unclear] rather than guessing."
- For structured extraction (tables, key-value), validate output format programmatically (does the JSON parse? does the table have consistent columns?).
- Consider a post-processing step that flags suspiciously long words or strings that deviate from expected patterns.

**Warning signs:**
- Output text is longer than what appears in the image.
- Output contains grammatically perfect sentences where the source image has fragmented text.
- Repeated testing of the same image produces different text each time.
- Non-semantic strings (serial numbers, product codes) are subtly wrong.

**Phase to address:**
Phase 1 (Core inference integration). Set user expectations in the UI from day one. Prompt engineering quality gates should be established during initial model integration, not retrofitted.

---

### Pitfall 2: iOS Memory Pressure Kills the App During Inference

**What goes wrong:**
SmolVLM2 500M consumes approximately 600 MB of memory persistently during inference. iPhones use unified memory shared between the system, GPU, and apps. iPhone 13 has 4 GB total RAM; iPhone 14 Pro has 6 GB. iOS's jetsam daemon kills apps that consume more than roughly half of total physical memory. With 600 MB for the model, the Flutter engine overhead (~80-120 MB), image buffers from the camera or photo library, and normal iOS system processes, you are operating at or near the jetsam threshold on 4 GB devices. A single high-resolution camera image decoded at full size (12 MP = ~48 MB uncompressed RGBA) can push you over the edge.

**Why it happens:**
Developers test on their latest-model iPhones (often 6-8 GB RAM) and never encounter memory pressure. iOS does not provide a hard memory limit API -- you discover the limit when jetsam kills your process. GPU memory and CPU memory are the same pool on Apple Silicon, so the model's GPU allocations compete directly with everything else. The camera plugin's image streaming mode is known to leak memory on iOS (multiple open Flutter issues dating back years, partially addressed but not fully resolved).

**How to avoid:**
- Always resize input images before inference. Cap at the model's input resolution (typically 384x384 or 512x512 for SmolVLM2). Never pass multi-megapixel camera output directly to the model.
- Use `didReceiveMemoryWarning` on the native side to trigger model eviction or graceful degradation. Edge-Veda has built-in memory monitoring with auto-eviction after 60s idle and QoS degradation under pressure -- rely on this rather than ignoring it.
- Profile on the minimum supported device (iPhone 13, 4 GB RAM), not just flagship hardware.
- Avoid holding camera image buffers and model inference results simultaneously. Process images sequentially: capture, resize, release original, run inference, return result.
- Wrap native CoreML/inference calls in @autoreleasepool blocks to ensure intermediate allocations are released promptly, not deferred to the main run loop.

**Warning signs:**
- App crashes without meaningful error logs (jetsam kills produce no standard crash report in the app).
- Memory usage in Instruments climbs steadily during a session without returning to baseline.
- App works fine on newer iPhones but crashes on iPhone 13 or 14.
- Crashes correlate with high-resolution images or rapid sequential captures.

**Phase to address:**
Phase 1 (Core inference). Memory budgeting and image resizing must be designed into the data pipeline from the start. Retrofitting memory management into a working pipeline is painful.

---

### Pitfall 3: 607 MB Model Download on First Launch Destroys Onboarding

**What goes wrong:**
SmolVLM2 500M is a 607 MB GGUF file that must be downloaded before the app can do anything useful. The app is "offline OCR" but requires a one-time 607 MB download before it becomes offline-capable. If this is not handled gracefully, users launch the app, see nothing works, and delete it. The iOS cellular download prompt triggers at 200 MB, so many users will be blocked without Wi-Fi. If the download is interrupted (backgrounding, network drop, phone call), the user may end up with a corrupt partial file and a broken app with no clear recovery path.

**Why it happens:**
The model cannot ship inside the app bundle (it would make the IPA ~640 MB+ before App Thinning). Edge-Veda downloads models from pre-configured URLs in its ModelRegistry. Developers focus on the inference experience and treat the download as a trivial prerequisite, but for users it is the very first interaction with the app.

**How to avoid:**
- Design a dedicated first-launch onboarding screen that clearly communicates: "One-time download of 607 MB required for offline AI. Wi-Fi recommended."
- Show download progress with percentage, MB downloaded/total, and estimated time remaining.
- Implement robust resume-on-interrupt: if the download is interrupted, detect the partial file and resume from where it left off on next launch. Validate the downloaded file with the checksum from Edge-Veda's ModelRegistry before declaring success.
- Test the full onboarding flow: fresh install, start download, kill app mid-download, relaunch, verify resume works. Test on cellular with the 200 MB prompt.
- Consider showing a demo or explanation of the app's capabilities during the download to reduce perceived wait time.
- Store the downloaded model in the app's Documents directory (not tmp or caches) so iOS does not evict it during storage pressure.

**Warning signs:**
- App reviews mentioning "doesn't work" or "nothing happens" or "needs internet for offline app."
- High uninstall rates within the first 5 minutes of install.
- Support requests about "stuck on loading screen."

**Phase to address:**
Phase 1 (Project scaffolding and model integration). This must be the first user-facing flow built and tested, not an afterthought.

---

### Pitfall 4: Thermal Throttling Degrades Inference to Unusability During Sustained Use

**What goes wrong:**
Running a 500M-parameter VLM with Metal GPU acceleration generates significant heat. After 3-5 continuous inference passes, the iPhone's thermal management reduces GPU clock speed, and inference latency degrades from acceptable (2-5 seconds) to painful (15-30+ seconds). If the user is processing multiple pages of a document, the experience degrades rapidly. Without thermal-aware scheduling, the app can also trigger iOS's thermal state warnings, which may cause the system to reduce display brightness, disable the camera flash, or further throttle the CPU.

**Why it happens:**
Mobile phones have minimal thermal dissipation. Sustained GPU compute raises the SoC temperature rapidly. iOS thermal management is aggressive and non-negotiable -- the OS will protect the hardware by throttling regardless of what the app wants. Developers building on desktops or simulators never experience this. Even testing on-device may miss it if only running single inference passes.

**How to avoid:**
- Edge-Veda includes thermal-aware QoS with hysteresis (escalation is immediate, restoration requires 60s cooldown per level). Do not bypass or ignore these QoS signals. Surface them to the user: "Device is warm. Processing may be slower."
- Insert deliberate cooldown pauses between sequential inference passes (e.g., 2-3 seconds between processing consecutive pages).
- Test the multi-page document scenario: import 10 pages and process them sequentially. Monitor thermal state and inference latency on physical hardware.
- Consider batch processing UI that sets user expectations: "Processing 8 pages... estimated 2 minutes" rather than appearing to hang.
- Monitor `ProcessInfo.thermalState` on the native side and communicate state changes to Flutter.

**Warning signs:**
- First inference is fast, but subsequent ones get progressively slower.
- Device becomes noticeably warm to the touch during use.
- Edge-Veda QoS drops to "Minimal" or "Paused" during batch operations.
- Users report "app slows down after a few uses."

**Phase to address:**
Phase 2 (after basic inference works). Thermal management is not critical for single-image demo but becomes critical once multi-image and batch workflows are introduced.

---

### Pitfall 5: Wrong Chat Template Format Produces Garbage Output

**What goes wrong:**
Edge-Veda documentation explicitly warns: "Using the wrong ChatTemplateFormat produces garbage output." SmolVLM2 requires a specific prompt template format. If the template is wrong, the model generates incoherent text, random tokens, or repeated patterns that look nothing like OCR output. This is indistinguishable from a "broken model" to a developer who does not know to check the template.

**Why it happens:**
GGUF models are trained with specific prompt formats (system/user/assistant markers, special tokens). The model weights encode responses to these specific patterns. A model trained with `<|user|>...<|assistant|>` will not respond correctly to `[INST]...[/INST]` format. Edge-Veda's API abstracts this with ChatTemplateFormat enum values, but selecting the wrong one silently produces bad output rather than throwing an error.

**How to avoid:**
- Verify the exact ChatTemplateFormat for SmolVLM2 from Edge-Veda documentation or source. Do not guess.
- Build a smoke test that runs a known image (e.g., a photo of the text "Hello World") through inference and validates the output contains expected substrings. Run this test in CI and on every model or SDK version update.
- If using custom prompts adapted from Ollama-OCR, ensure the prompt content is placed correctly within Edge-Veda's template structure. The prompts from Ollama-OCR assume Ollama's template formatting, which may differ.
- Log raw model output during development to catch template issues early.

**Warning signs:**
- Model output is random characters, repeated tokens, or empty strings.
- Output is coherent English but completely unrelated to the image content.
- Changing the prompt text has no effect on output quality.

**Phase to address:**
Phase 1 (Core inference). This is a day-one integration validation item. If the template is wrong, nothing else works.

---

### Pitfall 6: Platform Channel Bottleneck When Passing Images Between Flutter and Native

**What goes wrong:**
Flutter's MethodChannel serializes all data crossing the Flutter-to-native boundary. For a camera image or photo library import, this means serializing megabytes of image data through the StandardMessageCodec. On iOS, this serialization has documented performance issues with large byte arrays (~1 MB+), adding 50-200ms of latency per image transfer. If images are passed back and forth multiple times (capture in native, send to Flutter for display, send back to native for inference), the overhead compounds. With the camera streaming API, frequent MethodChannel calls can also block the UI thread.

**Why it happens:**
Flutter's platform channels are designed for command/response patterns, not bulk data transfer. Data is copied (not shared by reference), and only standard types are supported. Developers build the "happy path" where a single image works fine, but the serialization cost becomes apparent only when measuring end-to-end latency or processing sequential images.

**How to avoid:**
- Minimize boundary crossings. Ideal flow: capture image in native, resize in native, pass to native inference engine, return only the text result (small string) to Flutter. The image bytes should never cross to the Dart side if avoidable.
- If image display in Flutter is required, pass a file path (string) rather than raw bytes. Flutter can load the image from disk asynchronously.
- Use BinaryCodec instead of StandardMessageCodec for any unavoidable large data transfers.
- Consider using Dart FFI for zero-copy data sharing if Edge-Veda's architecture supports it (Edge-Veda uses background isolates which may already optimize this).
- Batch results rather than streaming intermediate data across the channel.

**Warning signs:**
- Noticeable delay between "image captured" and "inference starts."
- UI jank or dropped frames during image capture or processing.
- Profiling shows significant time spent in message codec serialization.
- Memory spikes when images cross the platform boundary (two copies exist temporarily).

**Phase to address:**
Phase 1 (Image input pipeline). The data flow architecture must be designed to minimize channel crossings from the start. Changing the data flow later requires significant refactoring.

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Pass full-resolution images to model | "Works" on test device | Crashes on 4 GB devices, wastes inference compute on irrelevant pixels | Never -- always resize to model input resolution |
| Skip model download resume logic | Faster initial development | Users with interrupted downloads have broken app, no recovery | Never for a 607 MB download |
| Hardcode prompts without abstraction | Quick iteration on OCR quality | Cannot support multiple output formats, language-specific extraction, or prompt A/B testing | Only in earliest prototype (first week) |
| Use MethodChannel for image bytes | Simple, works with Flutter camera plugin defaults | Serialization overhead compounds; memory doubles during transfer | Only for prototyping; replace before shipping |
| Test only on latest iPhone | Faster development cycle | Memory crashes and thermal throttling on target minimum devices are invisible | Never -- always include iPhone 13 in test matrix |
| Ignore Edge-Veda QoS callbacks | "App works fine in short tests" | App crashes or becomes unusable in sustained use; iOS kills it | Never -- these exist for a reason |
| Store model in Caches directory | iOS manages storage automatically | iOS can evict cached files under storage pressure, forcing 607 MB re-download | Never for a model this large |

## Integration Gotchas

Common mistakes when connecting components in this architecture.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Edge-Veda model init | Calling `generateStream()` before model finishes loading; init is async and model download may still be in progress | Always await init completion. Check model download status before enabling inference UI. Show loading state until model is ready. |
| Flutter camera plugin on iOS | Using `startImageStream()` with high ResolutionPreset on physical device causes memory leaks (multiple open Flutter issues) | Use medium or low resolution for streaming preview. Capture single frames at higher resolution only when needed. Dispose camera controller properly. |
| Ollama-OCR prompt adaptation | Copy-pasting prompts designed for 7B+ models (Llama 3.2 Vision, MiniCPM-V) into a 500M model | Simplify prompts for 500M capacity. Shorter, more direct instructions. Reduce expected output complexity. A 500M model cannot follow multi-step reasoning chains reliably. |
| XCFramework + CocoaPods | Missing `pod install` after adding Edge-Veda, or mixing XCFramework locations from different directories | Always run `pod install` from ios/ directory after adding the dependency. Verify XCFramework downloaded successfully (~31 MB). Check Xcode build settings for framework search paths. |
| Image preprocessing | Applying preprocessing on the Dart side before sending to native, causing double serialization | Preprocess (resize, normalize) on the native side, before inference. Keep the Dart side for UI only. |
| PHPicker on iOS 14+ | Expecting HEIC image format support in simulator | PHPicker (used by image_picker since 0.8.1) cannot pick HEIC on iOS simulator. Test image import on physical devices. |

## Performance Traps

Patterns that work at small scale but fail as usage grows.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| No image resizing before inference | Works on simple test images | Cap input to model resolution (384-512px). SmolVLM2 does not benefit from higher resolution input; it downscales internally. | Immediately with 12 MP camera photos (48 MB uncompressed RGBA) |
| Sequential synchronous inference | Fine for one image | Run inference in background isolate (Edge-Veda already does this). Show progress UI. Allow cancellation. | User processes 3+ images and UI freezes |
| Camera preview + inference simultaneously | Preview works, inference works separately | Pause camera preview during inference or use separate buffers. Both compete for GPU and memory. | On any device -- GPU contention causes both to degrade |
| No model warm-up | First inference is slow, subsequent ones are fine | Trigger a lightweight warm-up inference during app startup (after model loads) to initialize GPU pipelines and caches. | Every cold start of the app; first user interaction feels sluggish |
| Loading full image into Flutter Image widget for preview | Small images display fine | Use ResizeImage or specify cacheWidth/cacheHeight. A 12 MP image decoded at full resolution in Flutter consumes ~48 MB of Dart heap. | Any high-resolution camera capture or photo library import |

## Security Mistakes

Domain-specific security issues for an offline OCR app.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Storing extracted text in plaintext logs or debug output | OCR may capture sensitive documents (IDs, medical records, financial statements). Debug logs persist and may be accessible. | Never log extracted text in production builds. Use Flutter's kReleaseMode flag to gate debug output. Clear any temporary files after use. |
| Model file stored without iOS Data Protection | Model file (607 MB) sits unencrypted in filesystem. Less of a direct risk but poor practice. | Store in app's Documents directory with default iOS Data Protection (encrypted at rest when device is locked). |
| Not clearing image files after processing | Temporary image copies accumulate, containing potentially sensitive document photos. | Delete source images from temp directories after inference completes. Implement cleanup on app backgrounding. |
| Clipboard data persists indefinitely | User copies extracted text (including sensitive content) to clipboard; other apps can read it. | iOS 14+ shows clipboard access notification, but consider implementing clipboard clearing after a timeout or providing a "clear clipboard" action. |

## UX Pitfalls

Common user experience mistakes in mobile OCR apps.

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No feedback during inference (2-5 second wait) | User thinks app is frozen, taps repeatedly, or force-quits | Show animated processing indicator with "Extracting text..." label. Disable the capture button during processing. |
| Showing raw model output without formatting | VLM output may include prompt artifacts, markdown syntax, or inconsistent whitespace | Post-process output: strip prompt template remnants, normalize whitespace, handle edge cases (empty output, error tokens). |
| Camera viewfinder without guidance | User doesn't know optimal distance, angle, or lighting for OCR | Add subtle overlay hints: "Hold steady", "Move closer for small text", "Ensure good lighting." Not a full tutorial -- just contextual nudges. |
| "Processing failed" with no recovery path | User captured an image, waited 5 seconds, and got an unhelpful error | Provide actionable feedback: "Text could not be extracted. Try a clearer image with better lighting." Offer to retry or pick a different image. |
| No indication of OCR accuracy limitations | User trusts extracted text for legal/medical/financial purposes | Add a subtle but persistent disclaimer: "AI-generated text. Verify accuracy for important uses." |
| Long initial download with no skip option | User cannot use the app at all until 607 MB downloads | Show what the app does during download (screenshots, animation). Show progress. Allow backgrounding the download. |
| Batch processing with no individual progress | User imports 5 images and sees one spinner for all | Show per-image progress: "Processing image 3 of 5..." with individual results appearing as they complete. |

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Model loading:** Appears to work but no error handling for: download interruption, corrupt GGUF file, insufficient disk space (need 607 MB free + temp), model version mismatch with Edge-Veda SDK.
- [ ] **Camera capture:** Takes photo and displays it but: no image resizing before inference, no EXIF orientation correction (image may be rotated), no cleanup of temporary image files.
- [ ] **Text extraction:** Returns text but: no post-processing to strip prompt artifacts, no handling of empty/failed extraction, no timeout for inference that takes too long (model could hang on adversarial input).
- [ ] **Copy to clipboard:** Works but: no user feedback confirming copy succeeded, no handling of empty text state (copying nothing), clipboard contents persist with potentially sensitive data.
- [ ] **Structured output:** Markdown/table format looks correct on test images but: breaks on single-line text, breaks on handwritten input, 500M model cannot reliably produce complex structured formats.
- [ ] **Offline capability:** Inference works offline but: first launch requires internet for model download, no detection/messaging for "model not yet downloaded" state, no handling of model file corruption or deletion by iOS storage management.
- [ ] **File import:** Picker opens and selects files but: PDF support requires rendering pages to images first (not just passing the file), large files (8+ MP images) cause memory spikes, HEIC format may need conversion.
- [ ] **Error states:** App handles happy path but: no handling for Metal GPU unavailable (older devices), no handling for Edge-Veda init failure, no handling for thermal pause state, no handling for insufficient memory.

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| VLM hallucination in production | LOW | Add post-processing validation. Improve prompts. Add user-facing accuracy disclaimer. No architectural change needed. |
| Memory crash on low-RAM devices | MEDIUM | Requires adding image resizing pipeline, reviewing all image handling code, and potentially restructuring data flow to minimize concurrent allocations. |
| Corrupt/missing model file | LOW | Implement model integrity check (checksum validation) on app launch. If corrupt, delete and re-trigger download with resume support. |
| Thermal throttling in batch processing | LOW-MEDIUM | Add cooldown delays between inference passes. Surface thermal state to user. Requires testing to calibrate delay timing. |
| Wrong chat template | LOW | Single configuration change. But debugging the root cause (why output is garbage) can waste days if the developer doesn't know to check the template. |
| Platform channel bottleneck | HIGH | Requires restructuring the image data flow to minimize boundary crossings. May require native-side image handling pipeline that doesn't exist yet. Best prevented, not fixed. |
| 607 MB download with no resume | MEDIUM | Implement download manager with resume support. If partially downloaded file exists, validate and resume. Requires testing network interruption scenarios. |
| Camera memory leak | MEDIUM | Update to latest camera plugin version. Implement manual buffer management. May require dropping to native camera API if Flutter plugin issues persist. |

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| VLM hallucination | Phase 1: Core inference | Run OCRBench-style test suite. Verify prompt includes "do not guess" instructions. Verify UI shows accuracy disclaimer. |
| iOS memory pressure | Phase 1: Image pipeline | Profile on iPhone 13 (4 GB). Verify peak memory stays under 1.5 GB. Verify image resizing is in place before inference. |
| 607 MB model download UX | Phase 1: Project scaffold | Test fresh install flow. Test download interruption and resume. Verify model stored in Documents (not Caches). |
| Thermal throttling | Phase 2: Multi-image workflow | Process 10 images sequentially on physical device. Monitor thermal state. Verify Edge-Veda QoS signals are surfaced. |
| Wrong chat template | Phase 1: Day-one integration | Smoke test: known image -> expected output substring match. Automated, runs on every build. |
| Platform channel bottleneck | Phase 1: Architecture design | Measure end-to-end latency from capture to text output. Verify image bytes do not cross Flutter-native boundary unnecessarily. |
| Camera memory leak | Phase 1: Camera integration | Run 20 consecutive captures in Instruments. Verify memory returns to baseline between captures. |
| Model file corruption | Phase 1: Model management | Verify checksum validation on launch. Test recovery from deleted model file. |
| Prompt adaptation from Ollama-OCR | Phase 2: OCR quality tuning | Test with 50+ diverse images. Compare simplified prompts vs direct Ollama-OCR prompt ports. Verify 500M model can follow the prompt. |
| Structured output reliability | Phase 2-3: Output formats | Test structured extraction (JSON, markdown, tables) on 20+ documents. Verify post-processing handles malformed model output gracefully. |

## Sources

- [On-Device LLMs: State of the Union, 2026 -- Vikas Chandra](https://v-chandra.github.io/on-device-llms/) -- HIGH confidence: comprehensive technical analysis of on-device LLM constraints (memory bandwidth, thermal, quantization)
- [Avoiding the Hidden Hazards: Navigating Non-Obvious Pitfalls in ML on iOS](https://ksemianov.github.io/articles/ios-ml/) -- HIGH confidence: first-hand account of CoreML memory, precision, and GPU issues
- [Memory leak for CoreML inference on iOS device (GitHub issue)](https://github.com/apple/coremltools/issues/1312) -- HIGH confidence: official coremltools issue tracker
- [Camera plugin causing memory leak on iOS (Flutter issue #29586)](https://github.com/flutter/flutter/issues/29586) -- HIGH confidence: official Flutter issue tracker, multiple related issues
- [startImageStream memory crash on iOS (Flutter issue #97941)](https://github.com/flutter/flutter/issues/97941) -- HIGH confidence: official Flutter issue tracker
- [Edge-Veda GitHub repository](https://github.com/ramanujammv1988/edge-veda) -- MEDIUM confidence: primary documentation source for Edge-Veda SDK
- [Edge-Veda pub.dev package](https://pub.dev/packages/edge_veda) -- MEDIUM confidence: package documentation, version 2.5.0
- [SmolVLM: Redefining small and efficient multimodal models](https://arxiv.org/html/2504.05299v1) -- HIGH confidence: peer-reviewed paper with benchmark scores
- [HalluText: Benchmarking OCR Hallucination for LVLMs (OpenReview)](https://openreview.net/forum?id=LRnt6foJ3q) -- HIGH confidence: peer-reviewed benchmark for OCR hallucination
- [OCR vs VLM-OCR: Accuracy Benchmark for Scanned Documents](https://www.dataunboxed.io/blog/ocr-vs-vlm-ocr-naive-benchmarking-accuracy-for-scanned-documents) -- MEDIUM confidence: independent benchmark with methodology
- [iOS Memory Pressure Signals Explained](https://ravi6997.medium.com/memory-pressure-signals-in-ios-how-the-system-decides-to-terminate-your-app-c1b174c50214) -- MEDIUM confidence: community article, cross-verified with Apple documentation
- [Identifying high-memory use with jetsam event reports (Apple docs)](https://developer.apple.com/documentation/xcode/identifying-high-memory-use-with-jetsam-event-reports) -- HIGH confidence: official Apple documentation
- [Improving Platform Channel Performance in Flutter](https://medium.com/flutter/improving-platform-channel-performance-in-flutter-e5b4e5df04af) -- HIGH confidence: official Flutter team publication
- [Camera plugin poor performance serializing large byte array on iOS (Flutter issue #29006)](https://github.com/flutter/flutter/issues/29006) -- HIGH confidence: official Flutter issue tracker
- [SmolVLM2 deployment notes (Roboflow)](https://blog.roboflow.com/smolvlm2/) -- MEDIUM confidence: reputable ML engineering source
- [Fine-Tuning SmolVLM for Receipt OCR](https://debuggercafe.com/fine-tuning-smolvlm-for-receipt-ocr/) -- MEDIUM confidence: practical implementation guide
- [XCFramework Flutter iOS integration issues (Flutter issue #149168)](https://github.com/flutter/flutter/issues/149168) -- HIGH confidence: official Flutter issue tracker
- [App Store rejection for Flutter.xcframework in extensions (Flutter issue #155221)](https://github.com/flutter/flutter/issues/155221) -- HIGH confidence: official Flutter issue tracker

---
*Pitfalls research for: On-device OCR with VLM inference (Flutter iOS)*
*Researched: 2026-03-16*
