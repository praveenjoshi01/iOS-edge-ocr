# Feature Research

**Domain:** On-device offline OCR / mobile text extraction (iOS)
**Researched:** 2026-03-16
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Camera capture with viewfinder | Every OCR/scanner app starts with the camera; users expect to point and shoot | LOW | Use Flutter camera plugin; show a live preview so users can frame text before capture |
| Photo library import | Users have existing photos with text they want to extract; every competitor supports this | LOW | Use image_picker or file picker plugin; standard iOS photo permission flow |
| Text extraction (plain text) | The entire point of the app; if OCR output is gibberish, users delete the app immediately | HIGH | Core VLM inference via Edge-Veda + SmolVLM2; quality here determines app viability. Adapt Ollama-OCR "plain text" prompt strategy |
| Copy to clipboard | The most basic output action; 100% of OCR apps support this. The core loop is capture -> extract -> copy | LOW | Standard Flutter clipboard API; single-tap copy with visual confirmation |
| Share via iOS share sheet | Users expect to send extracted text to Messages, Notes, Mail, etc. Standard iOS interaction pattern | LOW | Use Flutter share_plus plugin to invoke native UIActivityViewController |
| Loading / progress indicator | On-device VLM inference takes noticeable time (seconds); without feedback users think the app froze | LOW | Show spinner or progress bar during Edge-Veda inference; consider streaming tokens if generateStream supports it |
| Error handling for poor images | Users will try blurry, dark, and angled photos; the app must tell them why extraction failed rather than returning empty text | MEDIUM | Implement pre-inference quality checks (brightness, blur detection) or post-inference empty-result messaging |
| Image preview before extraction | Users need to confirm they captured the right thing before waiting for inference | LOW | Show captured/selected image with "Extract Text" button; do not auto-process without user intent |

### Differentiators (Competitive Advantage)

Features that set this app apart from Adobe Scan, Genius Scan, Apple Live Text, and others.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| **100% offline, zero network** | Most competitors require cloud for OCR or premium features. Apple Live Text is on-device but limited in output options. Post-Microsoft-Lens-retirement (March 2026), there is a real gap for offline-first scanning. Users in secure facilities, flights, low-connectivity areas, and privacy-conscious users all benefit | LOW | This is an architectural decision, not a feature to build. But it must be prominently communicated in UI and App Store listing |
| **VLM-powered contextual understanding** | Traditional OCR (Tesseract, Apple Vision) treats text as character recognition. VLM understands context: it can infer reading order in multi-column layouts, understand table structure, and handle mixed content (text + labels + headings) better than pipeline OCR | HIGH | This is the SmolVLM2 advantage. The model "sees" the whole page and reasons about structure, not just individual characters. Must validate actual accuracy vs Live Text |
| **Multiple output formats via prompts** | Adapted from Ollama-OCR: same image can produce plain text, structured markdown, key-value pairs, or table extraction depending on prompt. No competitor mobile app offers user-selectable output formats | MEDIUM | Implement as output mode selector (Plain / Structured / Key-Value). Each mode uses a different prompt template sent to Edge-Veda. This is a genuine differentiator since no mobile OCR app exposes this |
| **Structured text preserving layout** | Extract text that preserves paragraphs, headings, columns, and table structure as markdown. Most OCR apps dump flat text. VLM-based extraction can maintain document hierarchy | HIGH | Depends on SmolVLM2 500M accuracy for structured output. This is the "Ollama-OCR markdown format" prompt adapted for on-device use. Validate quality before promising this feature |
| **Privacy-first with no data collection** | No account required, no analytics, no cloud, no tracking. Stronger privacy story than any competitor (Adobe Scan requires account, CamScanner had malware history, Genius Scan syncs to cloud) | LOW | Architectural decision. Communicate clearly. Consider privacy policy that says "we collect nothing" |
| **No subscription model** | Most competitors gate OCR behind subscriptions (Genius Scan, Adobe Scan, SwiftScan). A one-time purchase or free app with full OCR is differentiated in a market of $20-50/year subscriptions | LOW | Business model decision, not a code feature. But strongly recommended -- the subscription fatigue in this market is real |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems for an offline-first V1 tool.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| **Document scanning with edge detection and perspective correction** | Every scanner app has it; users expect it | This is a full document-scanning app, not just OCR. Edge detection, perspective correction, and image enhancement require OpenCV or custom ML models, adding significant binary size and complexity. SmolVLM2 can likely handle moderately angled photos without preprocessing | For V1, let the VLM handle imperfect images. Add a simple crop tool if needed. Defer full document scanning to V2 |
| **PDF output / export** | Users expect to create PDFs from scans | PDF generation requires layout engine, font embedding, and significant complexity. The app's value is text extraction, not document creation | Export extracted text as .txt file or copy to clipboard. Users can paste into Notes/Pages for PDF creation. Defer PDF export to V2 |
| **Scan history / document library** | Users want to save and search past scans | Requires local database, search indexing, storage management, thumbnail generation, and a whole second screen. Contradicts V1 "capture-extract-copy" simplicity | V1 is ephemeral: extract and move on. The user's clipboard or share target is the storage. Add history in V2 |
| **Cloud sync / backup** | Users worry about losing scans | Fundamentally contradicts the offline-first, privacy-first value proposition. Adds massive complexity (auth, sync, conflict resolution) | Stay offline. If users want backup, they share to their own cloud storage via share sheet |
| **Translation** | Natural follow-up after text extraction | Requires translation models (additional binary size, memory) or internet access. Scope creep from OCR into NLP | Defer entirely. User can copy text and paste into a translation app. Not V1 scope |
| **Handwriting recognition** | Users see it in Apple Live Text | SmolVLM2 500M at this parameter count likely struggles with arbitrary handwriting. Promising it and delivering poor results is worse than not offering it | Do not advertise handwriting OCR. If VLM happens to handle some handwriting, let users discover it. Do not make it a feature |
| **Real-time live OCR overlay** | Apple Live Text does this; users may expect it | Continuous VLM inference on camera frames is computationally expensive, drains battery, and SmolVLM2 inference is measured in seconds, not frames. Live overlay requires <100ms inference | V1 is capture-then-process. Show camera viewfinder, user taps capture, then inference runs. Do not attempt live overlay |
| **Multi-language support (explicit)** | OCR apps advertise 50+ languages | SmolVLM2 language capabilities are uncertain at 500M parameters. Do not promise languages you have not tested | Test with English first. If other languages work, document them. Do not build language selection UI until capabilities are validated |
| **Batch scanning / multi-page** | Enterprise users want to scan multi-page documents | Requires queue management, progress tracking per page, combined output, and significant UX complexity. V1 is single-image flow | Single image at a time for V1. Batch is a V2 feature after the core loop is proven |
| **Text editing in-app** | Users want to fix OCR errors before sharing | Building a text editor is significant scope. The app extracts text; editing happens in the user's preferred tool | Copy/share the raw extraction. User edits in Notes, Pages, or any text app. If demanded, add minimal editing in V1.x |

## Feature Dependencies

```
[Camera Capture]
    |--requires--> [Camera Permission Flow]
    |--produces--> [Captured Image]
                       |--requires--> [Image Preview Screen]
                       |--feeds-----> [OCR Inference Pipeline]
                                          |--requires--> [Edge-Veda Init + Model Load]
                                          |--requires--> [Prompt Template System]
                                          |--produces--> [Extracted Text]
                                                             |--enables--> [Copy to Clipboard]
                                                             |--enables--> [Share Sheet]
                                                             |--enables--> [Output Format Selection]

[Photo Library Import]
    |--requires--> [Photo Library Permission Flow]
    |--produces--> [Selected Image] --feeds--> [Image Preview Screen]

[File Import]
    |--requires--> [Document Picker]
    |--produces--> [Imported Image] --feeds--> [Image Preview Screen]

[Output Format Selection] --enhances--> [Extracted Text Display]
    |--requires--> [Prompt Template System] (multiple prompt templates)

[Edge-Veda Init + Model Load]
    |--required-by--> ALL inference features
    |--should-be--> App startup / lazy first-use initialization

[Loading Indicator] --enhances--> [OCR Inference Pipeline]
    |--uses--> [generateStream] for token-by-token display if available
```

### Dependency Notes

- **Edge-Veda initialization is the critical path:** Every OCR feature depends on the model being loaded. Cold start time determines first-use experience. Must be handled at app startup or with a loading screen.
- **Prompt Template System enables format selection:** Plain text and structured output share the same inference pipeline; only the prompt changes. Build the prompt system once, and output format selection is just a UI toggle.
- **Camera and Photo Library are independent inputs:** Both feed the same Image Preview -> OCR pipeline. Build the pipeline first, then attach input sources.
- **Copy and Share are independent outputs:** Both consume the same extracted text. Neither depends on the other.

## MVP Definition

### Launch With (v1)

Minimum viable product -- the core capture-extract-copy loop.

- [ ] **Camera capture** -- primary input method; the "point at text" use case
- [ ] **Photo library import** -- secondary input for existing images; trivial to add
- [ ] **Edge-Veda + SmolVLM2 inference** -- the actual OCR; plain text output with Ollama-OCR adapted prompts
- [ ] **Text result display** -- show extracted text clearly in a scrollable view
- [ ] **Copy to clipboard** -- one-tap copy with visual confirmation (checkmark/toast)
- [ ] **Share via share sheet** -- standard iOS share for sending text anywhere
- [ ] **Loading state during inference** -- spinner/progress during model inference
- [ ] **Basic error states** -- handle empty results, model load failure, permission denial

### Add After Validation (v1.x)

Features to add once the core loop works and OCR quality is validated.

- [ ] **Output format selection** (Plain / Structured / Key-Value) -- once plain text quality is confirmed, add prompt-based format switching. Trigger: users requesting better formatting
- [ ] **File import from Files app** -- image and potentially PDF page import. Trigger: users asking "can I use an existing file?"
- [ ] **Image crop tool** -- simple pre-inference crop to help users isolate text regions. Trigger: users complaining about irrelevant text in output
- [ ] **Streaming text display** -- show tokens appearing as VLM generates them (if Edge-Veda generateStream supports incremental output). Trigger: inference feels slow, users want feedback
- [ ] **Minimal text editing** -- allow users to tap and edit extracted text before copying. Trigger: consistent OCR errors users want to fix before sharing
- [ ] **Flashlight/torch toggle** -- for scanning in low light. Trigger: user feedback about dark environments

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **Scan history with local storage** -- save past extractions with thumbnails. Defer: requires database, storage management, search
- [ ] **Batch/multi-page processing** -- queue multiple images for sequential extraction. Defer: UX complexity, memory management
- [ ] **Document edge detection + perspective correction** -- auto-crop and straighten. Defer: requires additional ML model or OpenCV, significant binary size
- [ ] **PDF export** -- generate PDF from extracted text. Defer: layout engine complexity
- [ ] **Table extraction to CSV** -- structured table output exportable as CSV. Defer: validate VLM table extraction quality first
- [ ] **Accessibility (VoiceOver + TTS)** -- read extracted text aloud. Defer: important but V2 polish
- [ ] **Widget / Shortcuts integration** -- iOS home screen widget or Siri Shortcuts for quick scanning. Defer: platform integration polish

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Camera capture | HIGH | LOW | P1 |
| Photo library import | HIGH | LOW | P1 |
| Plain text OCR inference | HIGH | HIGH | P1 |
| Copy to clipboard | HIGH | LOW | P1 |
| Share sheet | HIGH | LOW | P1 |
| Loading indicator | MEDIUM | LOW | P1 |
| Error handling | MEDIUM | MEDIUM | P1 |
| Image preview | MEDIUM | LOW | P1 |
| Output format selection | HIGH | MEDIUM | P2 |
| File import (Files app) | MEDIUM | LOW | P2 |
| Streaming text display | MEDIUM | MEDIUM | P2 |
| Image crop tool | MEDIUM | MEDIUM | P2 |
| Flashlight toggle | LOW | LOW | P2 |
| Minimal text editing | MEDIUM | MEDIUM | P2 |
| Scan history | MEDIUM | HIGH | P3 |
| Batch processing | MEDIUM | HIGH | P3 |
| Edge detection / correction | LOW | HIGH | P3 |
| PDF export | MEDIUM | HIGH | P3 |
| Table to CSV | MEDIUM | HIGH | P3 |
| VoiceOver / TTS | MEDIUM | MEDIUM | P3 |

**Priority key:**
- P1: Must have for launch (the capture-extract-copy loop)
- P2: Should have, add when core loop is validated
- P3: Nice to have, future consideration after product-market fit

## Competitor Feature Analysis

| Feature | Apple Live Text | Adobe Scan | Genius Scan | Our Approach |
|---------|----------------|------------|-------------|--------------|
| OCR engine | Apple Vision framework (on-device) | Adobe cloud OCR (requires account) | Cloud OCR (paid tier) | SmolVLM2 500M via Edge-Veda (on-device, no account) |
| Offline capability | Yes (built into iOS) | Partial (capture offline, OCR needs cloud) | Partial (basic scanning offline, OCR needs paid) | Full offline (all processing on-device) |
| Cost | Free (built into iOS) | Free tier + subscription ($9.99/mo for premium) | Free tier + subscription ($7.99/mo for OCR) | Free or one-time purchase (no subscription) |
| Output formats | Copy text only | PDF, Word (paid) | PDF, JPEG (OCR paid) | Plain text, structured markdown, key-value pairs (all free) |
| Privacy | On-device, Apple privacy | Cloud processing, Adobe account required | Cloud processing for OCR | Zero data collection, zero network, zero accounts |
| Document scanning | No (text overlay only) | Yes (edge detection, filters) | Yes (edge detection, perspective correction) | No (V1 is text extraction, not document scanning) |
| Structured output | No (flat text only) | No (OCR produces flat text) | No | Yes (VLM understands document structure via prompt engineering) |
| Platform | iOS only (built in) | iOS + Android | iOS + Android | iOS only (Flutter, Android possible later) |
| Handwriting | Partial (varies by quality) | Good (cloud ML) | Poor | Not advertised (VLM may handle some) |
| Batch scanning | No | Yes | Yes (paid) | No (V1 single image) |

### Key Competitive Observations

1. **Microsoft Lens retirement (March 2026) creates a gap.** Microsoft Lens was the best free OCR scanner with no subscription. Its retirement leaves users looking for alternatives, especially those who valued offline capability and free OCR.

2. **Apple Live Text is the primary "competition" for on-device OCR on iOS.** It is built into the OS, requires no app install, and works well for simple text copying. Our app must offer something Live Text cannot: structured output, multiple formats, and explicit text extraction workflow.

3. **Subscription fatigue is real.** Adobe Scan, Genius Scan, SwiftScan, and CamScanner all gate OCR behind subscriptions ($7-20/year). A free or one-time-purchase app with full OCR is immediately differentiated.

4. **Privacy differentiation is credible.** CamScanner has had malware incidents. Adobe requires an account. Most apps upload data to cloud for OCR. Truly offline, truly private is a real selling point, especially for sensitive documents (medical, legal, financial).

5. **VLM-based OCR is the technical moat.** No other mobile app uses a vision-language model for OCR. Traditional OCR pipelines (detect -> segment -> recognize) cannot match VLM contextual understanding of document layout, and our prompt-based format selection is unique in the mobile space.

## Sources

- [Zapier: Best mobile scanning and OCR software](https://zapier.com/blog/best-mobile-scanning-ocr-apps/) -- competitor features overview
- [SecureScan: Top 10 Free Mobile Scanning Apps 2026](https://www.securescan.com/articles/records-management/the-best-mobile-scanning-apps-rated/) -- detailed competitor accuracy testing and feature comparison
- [Scanbot SDK: 7 Essential Document Scanner Features](https://scanbot.io/blog/essential-document-scanner-features/) -- industry standard feature expectations
- [GetApp: Best OCR Software with Offline Access 2026](https://www.getapp.com/emerging-technology-software/ocr/f/offline-access/) -- 74% of users rate offline access as important or highly important
- [Microsoft Lens Retirement](https://support.microsoft.com/en-us/topic/retirement-of-microsoft-lens-fc965de7-499d-4d38-aeae-f6e48271652d) -- confirmed retirement timeline, gap analysis
- [Textora: Microsoft Lens Replacements](https://textora.app/blog/microsoft-lens-alternatives/) -- post-Lens market gap and feature needs
- [E2E Networks: Open-Source OCR Models 2025](https://www.e2enetworks.com/blog/complete-guide-open-source-ocr-models-2025) -- VLM vs traditional OCR comparison
- [HuggingFace: SmolVLM Blog](https://huggingface.co/blog/smolvlm) -- SmolVLM capabilities and mobile deployment
- [Ollama-OCR GitHub](https://github.com/imanoop7/Ollama-OCR) -- prompt strategies for text extraction formats
- [Apple: Live Text Support](https://support.apple.com/en-us/120004) -- Live Text capabilities and limitations
- [DocuClipper: OCR Limitations](https://www.docuclipper.com/blog/ocr-limitations/) -- common OCR failure modes
- [Docsumo: OCR Limitations](https://www.docsumo.com/blog/ocr-limitations) -- formatting preservation challenges

---
*Feature research for: On-device offline OCR (iOS)*
*Researched: 2026-03-16*
