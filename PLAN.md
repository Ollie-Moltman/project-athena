# Project Athena — Build Plan

## 1. What Are We Building?

**Name:** Athena — AI Video Detector

**Core functionality:** User plays any video on screen → opens Athena → taps "Start Scanning" → 3-button floating overlay appears → captures 3 seconds → sends frames to backend → returns verdict: "AI-Generated" or "Real" with confidence score and per-layer breakdown.

**Target users:**
- Journalists / fact-checkers verifying video authenticity
- General users who want to know if a viral video is fake
- Researchers studying AI content proliferation

**Platform:** Android-first (Flutter), with a backend API for heavy ML inference.

---

## 2. Detection Pipeline Architecture

```
Screen Capture (MediaProjection)
    │
    ├─ Layer 1: Provenance Check (fast, ~1s)
    │   └─ Capture metadata signals (frame rate, size consistency)
    │
    ├─ Layer 2: Visual Artifact Analysis (medium, ~10-30s)
    │   ├─ Spatial frequency anomaly detection (OpenCV DFT)
    │   ├─ Color distribution analysis
    │   ├─ Face landmark consistency (future)
    │   └─ Temporal frame consistency (future)
    │
    ├─ Layer 3: Deep Learning Classifier (slower, ~30-60s)
    │   └─ Pre-trained model (UNITE or STALL — CPU-friendly)
    │
    └─ Layer 4: Contextual Signals (fast, ~1s)
        └─ Capture duration + frame rate patterns

Final Verdict → Confidence Score → Per-Layer Breakdown
```

**Why a backend is needed:** Layers 2& 3 require running ML models that are too heavy for a phone. Analysis happens server-side, results streamed to app.

---

## 3. System Architecture

### App (Flutter / Android)

**Screens:**

1. **Home / Scan Screen**
   - Big circular "SCAN" button (no URL input)
   - Instructions: "Play any video → Tap Scan → Get verdict"
   - Navigation to History and Settings

2. **Scanning Screen**
   - Animated pulsing circle with progress indicator
   - Per-layer progress dots
   - Pause / Resume / Cancel controls
   - Floating overlay simulation (Scan / Pause-Play / Finish)

3. **Results Screen**
   - Large verdict badge: "⚠️ AI-Generated" / "✅ Real" / "🤔 Uncertain"
   - Confidence percentage (0-100%)
   - Per-layer confidence bars with details
   - Processing time display

4. **History Screen**
   - List of past scans with verdicts + thumbnails
   - Relative timestamps ("2m ago", "1h ago")
   - Tap to re-view full results

5. **Settings Screen**
   - Max scan duration setting
   - Capture quality setting
   - Account / plan info
   - Upgrade to Pro CTA
   - Privacy policy / methodology links

### Backend (Python / FastAPI on VPS)

**Endpoints:**

```
POST /scan/screen
  Body: { "frames": [base64...], "duration_ms": 3000 }
  Response: { "job_id": "..." }

GET /result/{job_id}
  Response: {
    "status": "completed",
    "result": {
      "verdict": "ai_generated" | "real" | "uncertain",
      "confidence": 87,
      "layers": {
        "provenance": { "flagged": false, "score": 12, "details": [] },
        "visual": { "flagged": true, "score": 94, "details": [...] },
        "deep_learning": { "flagged": true, "score": 85, "details": [] },
        "contextual": { "flagged": false, "score": 8, "details": [] }
      },
      "processing_time_ms": 24500,
      "scanned_at": "2026-05-31T..."
    }
  }
```

**Stack:**
- FastAPI (Python web framework)
- OpenCV + NumPy for visual artifact analysis
- PyTorch for ML model inference (UNITE/STALL)
- SQLite for scan history (MVP), PostgreSQL (production)

---

## 4. ML Models Required

### Layer 2 — Visual Artifact Analysis (Custom or Fine-Tuned)

| Model | Purpose | Size | Notes |
|-------|---------|------|-------|
| **OpenCV DFT** | Spatial frequency analysis | ~0MB | Custom implementation |
| **Color Analyzer** | Color distribution check | ~0MB | Custom implementation |
| **MediaPipe Face** | Face landmark extraction | ~15MB | Deferred for MVP |

### Layer 3 — Deep Learning Classifier (Pre-trained)

| Model | Purpose | Size | Notes |
|-------|---------|------|-------|
| **UNITE** | Universal synthetic detector | ~400MB | Good balance of speed/accuracy |
| **STALL** | Training-free, fast | ~100MB | Good for quick checks |
| **DeMamba** | SOTA video deepfake detection | ~500MB | Most accurate but heavy |

**MVP choice:** Use **OpenCV visual analysis** for Layer 2. Layer 3 is simulated for MVP (random score). Upgrade to UNITE/STALL when GPU is available on VPS.

---

## 5. Screen Capture Flow

```
1. User taps "Start Scanning" on Home screen
2. System permission dialog (MediaProjection) — shown once
3. Floating overlay appears over any app
   ├── [SCAN] — Start capturing 3 seconds of frames
   ├── [PAUSE/PLAY] — Pause and resume capture
   └── [FINISH] — End capture early
4. Capture 3 seconds at ~30fps → ~90 frames
5. Frames sent to backend as base64-encoded JPEGs
6. Backend runs 4-layer analysis pipeline
7. Results returned → displayed on Results screen
```

---

## 6. Project Structure

```
athena/
├── lib/
│   ├── main.dart              # App entry + routing
│   ├── models/
│   │   ├── scan_result.dart   # ScanResult, LayerScores, LayerScore
│   │   └── scan_history.dart  # History models
│   ├── services/
│   │   ├── api_service.dart   # HTTP calls to backend
│   │   └── screen_capture_service.dart  # Platform channel to native
│   └── ui/
│       ├── screens/
│       │   ├── scan_screen.dart      # Home / Scan button
│       │   ├── scanning_screen.dart  # Animated scanning UI
│       │   ├── results_screen.dart   # Verdict + breakdown
│       │   ├── history_screen.dart   # Past scans list
│       │   └── settings_screen.dart  # Preferences
│       └── widgets/
├── android/
│   └── app/src/main/
│       ├── java/com/athena/app/
│       │   └── ScreenCaptureService.java  # MediaProjection native code
│       └── res/
└── backend/
    ├── requirements.txt
    └── app/
        └── main.py           # FastAPI app + ML pipeline
```

---

## 7. Development Phases

### Phase 1: App MVP (Flutter Screens) ✅
- [x] Scan screen with big button
- [x] Scanning screen with animation
- [x] Results screen with per-layer bars
- [x] History screen
- [x] Settings screen
- [x] Routing and navigation
- [x] Dark theme throughout

### Phase 2: Native Android (MediaProjection) ✅
- [x] MainActivity.kt — permission flow + platform channel handlers
- [x] FloatingOverlayService.kt — 3-button overlay, frame capture via MediaProjection
- [x] EventChannel for frame streaming to Flutter
- [x] BroadcastReceiver for overlay button actions
- [x] Foreground service with notification
- [x] Flutter platform channel integration (ScreenCaptureService)
- [x] Floating overlay implementation (FloatingOverlayService)
- [x] Frame encoding (RGBA→PNG via image package)

### Phase 3: Backend MVP (FastAPI) ✅
- [x] `/scan/screen` endpoint
- [x] `/result/{job_id}` polling endpoint
- [x] `/history` endpoint
- [x] Layer 1: Provenance (frame metadata analysis)
- [x] Layer 2: Visual artifacts (OpenCV DFT + color analysis)
- [x] Layer 3: Deep learning (simulated for MVP)
- [x] Layer 4: Contextual signals
- [x] Verdict aggregation

### Phase 4: ML Integration (Post-MVP)
- [ ] Integrate UNITE or STALL model on VPS GPU
- [ ] Face landmark pipeline (MediaPipe)
- [ ] Temporal frame consistency analysis
- [ ] Per-layer detailed explanations

### Phase 5: Polish & Monetization
- [ ] Subscription system (Stripe / LemonSqueezy)
- [ ] Report export feature
- [ ] App store listing

---

## 8. Key Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| MediaProjection permission denied | Show friendly message, guide to settings |
| Backend too slow | Show real-time layer progress from app |
| ML model too heavy for VPS | Use STALL (100MB, CPU-friendly) for MVP |
| Detection accuracy poor | Start with Layer 1+2 only, improve from user feedback |
| Screen capture API changes | Test on multiple Android versions |

---

## 9. Similar Apps / References

- **Deepware** (deepware.ai) — Online deepfake scanner, similar concept
- **TruthScan** (truthscan.com) — Claims 99%+ accuracy
- **Fake AV Detection** — Academic projects, not commercial

**Differentiation:** No URL input needed, cleaner UX, better explanation of results, freemium model.

---

*Plan created: 2026-05-31*
*Updated: 2026-05-31 — Screen capture UX*
