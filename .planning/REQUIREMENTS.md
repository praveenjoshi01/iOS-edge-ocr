# Requirements: iOS Edge OCR

**Defined:** 2026-03-16
**Core Value:** Instant, private text extraction from any image — entirely offline on the user's iPhone.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Image Input

- [ ] **INPUT-01**: User can capture images using live camera viewfinder
- [ ] **INPUT-02**: User can import images from photo library
- [ ] **INPUT-03**: User can import images and PDFs from iOS Files app
- [ ] **INPUT-04**: User sees image preview before triggering text extraction

### OCR Inference

- [ ] **OCR-01**: User can extract plain text from any image using SmolVLM2 500M on-device
- [ ] **OCR-02**: AI inference runs on Metal GPU for accelerated processing on iPhone 13+
- [ ] **OCR-03**: User sees loading indicator during text extraction
- [ ] **OCR-04**: User receives clear error message when extraction fails or produces empty results
- [ ] **OCR-05**: Model downloads on first launch with progress indicator and resume-on-interrupt

### Output

- [ ] **OUT-01**: User can copy extracted text to clipboard with one tap and visual confirmation

### Runtime

- [ ] **RT-01**: All OCR processing runs entirely on-device with zero network calls
- [ ] **RT-02**: Edge-Veda runtime uses Metal GPU acceleration (useGpu: true)
- [ ] **RT-03**: App handles iOS thermal throttling gracefully via Edge-Veda QoS signals

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Output Formats

- **FMT-01**: User can select output format (Plain Text / Structured Markdown / Key-Value)
- **FMT-02**: Structured output preserves document layout (headings, paragraphs, tables)

### Export

- **EXP-01**: User can share extracted text via iOS share sheet
- **EXP-02**: User can export extracted text as .txt file

### Streaming

- **STR-01**: User sees text appearing progressively as model generates tokens

### Model Selection

- **MDL-01**: App detects device capability (RAM, GPU) and recommends appropriate model size
- **MDL-02**: User can upgrade to higher-end model (e.g., SmolVLM2 2.2B) on capable devices (iPhone 15 Pro+, 8 GB RAM)

### History

- **HIST-01**: User can view history of past extractions
- **HIST-02**: User can search through past extraction results

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Cloud/server OCR | Contradicts offline-first principle |
| Real-time live OCR overlay | VLM inference too slow for live frames (~2-5s per image) |
| Document edge detection & perspective correction | Significant complexity; VLM handles moderately angled photos |
| Translation/summarization | Scope creep beyond OCR; user can paste into translation app |
| Android support | iOS-first; Edge-Veda Android validation pending |
| Handwriting recognition | SmolVLM2 500M unreliable for arbitrary handwriting |
| Batch/multi-page scanning | UX complexity; v1 is single-image flow |
| User accounts or cloud sync | Contradicts privacy-first architecture |
| In-app text editing | User edits in their preferred app after copying |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INPUT-01 | — | Pending |
| INPUT-02 | — | Pending |
| INPUT-03 | — | Pending |
| INPUT-04 | — | Pending |
| OCR-01 | — | Pending |
| OCR-02 | — | Pending |
| OCR-03 | — | Pending |
| OCR-04 | — | Pending |
| OCR-05 | — | Pending |
| OUT-01 | — | Pending |
| RT-01 | — | Pending |
| RT-02 | — | Pending |
| RT-03 | — | Pending |

**Coverage:**
- v1 requirements: 13 total
- Mapped to phases: 0
- Unmapped: 13 ⚠️

---
*Requirements defined: 2026-03-16*
*Last updated: 2026-03-16 after initial definition*
