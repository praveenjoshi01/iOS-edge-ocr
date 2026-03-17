# Roadmap: iOS Edge OCR

## Overview

This roadmap delivers an offline iOS OCR app in three phases, ordered by technical dependency. Phase 1 proves the core technology works (Edge-Veda runtime loading SmolVLM2 and producing text from an image with Metal GPU). Phase 2 connects all image input sources (camera, photo library, Files app) to that proven pipeline. Phase 3 closes the user loop with copy-to-clipboard, loading feedback, error handling, and thermal management for sustained use.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Runtime & Core Pipeline** - Edge-Veda + SmolVLM2 inference working on-device with Metal GPU
- [ ] **Phase 2: Image Acquisition** - Camera, photo library, and Files app feeding the OCR pipeline
- [ ] **Phase 3: Complete User Loop** - Copy output, loading feedback, error handling, and thermal resilience

## Phase Details

### Phase 1: Runtime & Core Pipeline
**Goal**: User can extract text from an image entirely on-device using SmolVLM2 500M with Metal GPU acceleration
**Depends on**: Nothing (first phase)
**Requirements**: OCR-01, OCR-02, OCR-05, RT-01, RT-02
**Success Criteria** (what must be TRUE):
  1. User launches app for the first time, sees model download progress (percentage and MB), and can resume if interrupted
  2. User can provide a test image and receive extracted plain text from on-device SmolVLM2 inference (no network calls)
  3. Inference runs on Metal GPU (useGpu: true) and completes within reasonable time on iPhone 13+
  4. App does not crash or get killed by iOS during inference (memory stays within safe bounds)
**Plans:** 3 plans

Plans:
- [ ] 01-01-PLAN.md -- Scaffold Flutter project, Edge-Veda integration, model download with progress/resume
- [ ] 01-02-PLAN.md -- Image preprocessing, prompt construction, and end-to-end OCR inference pipeline
- [ ] 01-03-PLAN.md -- Diagnostic logging and physical device validation (Metal GPU, memory, ChatTemplateFormat)

### Phase 2: Image Acquisition
**Goal**: User can capture or import images from any source and see a preview before extracting text
**Depends on**: Phase 1
**Requirements**: INPUT-01, INPUT-02, INPUT-03, INPUT-04
**Success Criteria** (what must be TRUE):
  1. User can open camera, see live viewfinder, capture an image, and preview it before extraction
  2. User can select an existing image from their photo library and preview it before extraction
  3. User can import an image or PDF from the iOS Files app and preview it before extraction
  4. All three input paths feed into the OCR pipeline from Phase 1 and produce extracted text
**Plans**: TBD

Plans:
- [ ] 02-01: Camera capture with viewfinder and image preview screen
- [ ] 02-02: Photo library import, Files app import, and unified input flow

### Phase 3: Complete User Loop
**Goal**: User experiences a polished capture-extract-copy workflow with clear feedback at every step
**Depends on**: Phase 2
**Requirements**: OCR-03, OCR-04, OUT-01, RT-03
**Success Criteria** (what must be TRUE):
  1. User sees a loading indicator while text extraction is in progress
  2. User receives a clear, actionable error message when extraction fails or returns empty results
  3. User can copy extracted text to clipboard with one tap and sees visual confirmation that it worked
  4. App handles thermal throttling gracefully during sustained use, surfacing state to user rather than silently degrading
**Plans**: TBD

Plans:
- [ ] 03-01: Loading states, error handling, and copy-to-clipboard with confirmation
- [ ] 03-02: Thermal throttling handling and QoS signal surfacing

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3

| Phase | Plans Complete | Status | Completed |
|-------|---------------|--------|-----------|
| 1. Runtime & Core Pipeline | 0/3 | Planned | - |
| 2. Image Acquisition | 0/2 | Not started | - |
| 3. Complete User Loop | 0/2 | Not started | - |
