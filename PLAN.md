# Project Athena — Build Plan

## 1. What Are We Building?

**Name:** Athena — AI Video Detector

**Core functionality:** User pastes a YouTube video URL → app analyzes it → returns a verdict: "AI-Generated" or "Real" with a confidence score and breakdown of which detection methods fired.

**Target users:**
- Journalists / fact-checkers verifying video authenticity
- General users who want to know if a viral video is fake
- Researchers studying AI content proliferation

**Platform:** Android-first (Flutter), with a backend API for heavy ML inference.

---

## 2. Detection Pipeline Architecture

```
YouTube URL
    │
    ├─ Layer 1: Provenance Check (fast, ~1s)
    │   ├─ YouTube AI label API (does platform say it's AI?)
    │   ├─ Video metadata extraction (upload date, channel age)
    │   └─ C2PA metadata check (if video file has embedded provenance)
    │
    ├─ Layer 2: Visual Artifact Analysis (medium, ~10-30s)
    │   ├─ Face landmark consistency (blinking, mouth sync)
    │   ├─ Temporal motion analysis (frame-to-frame consistency)
    │   ├─ Spatial frequency anomaly detection
    │   └─ Stitching artifact detection (clip boundaries ~8s)
    │
    ├─ Layer 3: Deep Learning Classifier (slower, ~30-60s)
    │   └─ Pre-trained model (e.g., DeMamba or BusterX)
    │
    └─ Layer 4: Contextual Signals (fast, ~1s)
        ├─ Channel behavior patterns
        └─ Video metadata analysis

Final Verdict → Confidence Score → Breakdown
```

**Why a backend is needed:** Layers 2 & 3 require running ML models that are too heavy for a phone. Analysis happens server-side, results streamed to app.

---

## 3. System Architecture

### App (Flutter / Android)

**Screens:**

1. **Home / Scan Screen**
   - YouTube URL input field
   - Paste button
   - Scan button
   - Animated scanning indicator

2. **Results Screen**
   - Large verdict badge: "✅ Real" / "⚠️ AI-Generated" / "🤔 Uncertain"
   - Confidence percentage (0-100%)
   - Detection breakdown (which layers flagged it)
   - Per-layer confidence bars

3. **History Screen**
   - List of past scans with verdicts
   - Filter by verdict type
   - Tap to re-view full results

4. **Settings Screen**
   - Account / subscription status
   - Daily scan limit counter
   - About / methodology explainer

### Backend (Python / FastAPI on VPS with GPU)

**Endpoints:**

```
POST /scan
  Body: { "youtube_url": "..." }
  Response: { "job_id": "..." }

GET /result/{job_id}
  Response: {
    "verdict": "ai_generated" | "real" | "uncertain",
    "confidence": 87,
    "layers": {
      "provenance": { "flagged": false, "score": 5 },
      "visual": { "flagged": true, "score": 92, "details": [...] },
      "deep_learning": { "flagged": true, "score": 85 },
      "contextual": { "flagged": false, "score": 10 }
    },
    "processing_time_ms": 24500
  }
```

**Stack:**
- FastAPI (Python web framework)
- CUDA GPU for ML inference (if available) — CPU fallback OK for MVP
- Celery + Redis for job queuing (background processing)
- PostgreSQL for scan history
- YouTube Data API v3 for metadata

---

## 4. ML Models Required

### Layer 2 — Visual Artifact Analysis (Custom or Fine-Tuned)

| Model | Purpose | Size | Notes |
|-------|---------|------|-------|
| **MediaPipe Face Detection** | Face landmark extraction | ~15MB | Lightweight, runs on CPU |
| **BlazeFace** | Fast face detector | ~1MB | Alternative to MediaPipe |
| **LSTM/Transformer** | Temporal anomaly modeling | ~50-200MB | Detects frame inconsistencies |
| **Frequency Analyzer** | Spatial frequency fingerprints | ~10MB | Custom implementation |

### Layer 3 — Deep Learning Classifier (Pre-trained)

| Model | Purpose | Size | Notes |
|-------|---------|------|-------|
| **DeMamba** | SOTA video deepfake detection | ~500MB | Most accurate but heavy |
| **BusterX++** | MLLM-based with reasoning | ~1-2GB | Best explanation capability |
| **UNITE** | Universal synthetic detector | ~400MB | Good balance of speed/accuracy |
| **STALL** | Training-free, fast | ~100MB | Good for quick checks |

**MVP choice:** Use **UNITE** or **STALL** for MVP — good accuracy with reasonable model size. Upgrade to DeMamba later.

### YouTube Data API v3 (Free, 10k units/day)
- Fetch video metadata (title, channel, upload date, duration)
- Check if YouTube has flagged the video as AI-generated
- Rate limit: handle gracefully

---

## 5. Video Processing Flow

```
1. Receive YouTube URL
2. Extract video ID → call YouTube Data API
3. Download video (pytube / yt-dlp) — DASH manifest handling
4. Extract frames at intervals (1 frame per second, or key frames)
5. Run Layer 1 — metadata check (YouTube API response)
6. For each frame:
   - Run face detection
   - Extract facial landmarks
   - Compute spatial frequency features
7. Run temporal analysis across frame sequence
8. Feed features to deep learning classifier
9. Aggregate layer scores → final verdict
10. Store result in DB → return to app
```

**Important:** YouTube re-encodes videos → some metadata (C2PA) gets stripped. Visual artifacts may be degraded by compression. Layer 1 (provenance) will often be inconclusive → rely more on Layers 2 & 3.

---

## 6. App Screens (Basic Wireframes)

### Screen 0 — Home/Scan
```
┌─────────────────────────┐
│  🔍 Athena              │
│                         │
│  Paste YouTube URL      │
│  ┌─────────────────────┐ │
│  │ https://youtube...  │ │
│  └─────────────────────┘ │
│                         │
│  [ ▶ Analyze Video ]    │
│                         │
│  ── Recent Scans ──      │
│  • Video title  ✅ Real  │
│  • Video title  ⚠️ AI    │
└─────────────────────────┘
```

### Screen 1 — Results
```
┌─────────────────────────┐
│  ← Back                 │
│                         │
│  ┌─────────────────┐   │
│  │  ⚠️ AI-GENERATED │   │
│  │      87%         │   │
│  └─────────────────┘   │
│                         │
│  Detection Breakdown:   │
│  ▓▓▓▓▓▓▓▓░░ Provenance │
│  ▓▓▓▓▓▓▓▓▓▓ Visual     │
│  ▓▓▓▓▓▓▓▓▓░ Deep Learning│
│  ▓░░░░░░░░░ Contextual  │
│                         │
│  Key findings:          │
│  • Facial artifacts: YES │
│  • Temporal anomalies    │
│  • Low compression flag │
└─────────────────────────┘
```

---

## 7. Monetization

### Freemium Model

| Feature | Free | Pro ($4.99/mo) |
|---------|------|---------------|
| Daily scans | 5 | Unlimited |
| Verdict only | ✅ | ✅ |
| Per-layer breakdown | ❌ | ✅ |
| History | Last 10 | Unlimited |
| Batch scanning | ❌ | ✅ |
| Export report | ❌ | ✅ |

### Why this works:
- Casual users get enough value (5 scans/day)
- Power users (journalists, researchers) pay for full access
- Low friction: no credit card needed for free tier

---

## 8. MVP Scope

**To ship in 2-3 weeks:**

1. **Backend (Priority)**
   - YouTube URL → video metadata (YouTube API)
   - Basic frame extraction (ffmpeg)
   - Layer 1 (provenance check via YouTube API label)
   - Simple visual analysis (face detection + basic artifact check)
   - Results endpoint returning verdict + confidence

2. **App (Priority)**
   - URL input screen
   - Basic results screen with verdict + confidence
   - Simple history list

**Deferred (Post-MVP):**
- Deep learning classifier (Layer 3) — requires GPU, model fine-tuning
- Per-layer detailed breakdown
- Subscription management
- Full visual artifact analysis pipeline

---

## 9. Tech Stack Summary

```
Flutter (Android)
  │
  └── FastAPI (Python backend on VPS)
        │
        ├── YouTube Data API v3
        ├── MediaPipe (face detection)
        ├── OpenCV + ffmpeg (frame extraction)
        ├── PyTorch (deep learning model)
        ├── PostgreSQL (scan history)
        └── Redis + Celery (job queue)
```

---

## 10. Development Phases

### Phase 1: Backend MVP (3-5 days)
- [ ] Set up FastAPI project on VPS
- [ ] YouTube URL → metadata extraction
- [ ] Video download (yt-dlp)
- [ ] Frame extraction (ffmpeg)
- [ ] Layer 1: YouTube AI label check
- [ ] Basic face detection (MediaPipe)
- [ ] Results endpoint
- [ ] Basic scan history DB

### Phase 2: App MVP (5-7 days)
- [ ] Flutter project setup
- [ ] Home screen with URL input
- [ ] Call backend API → show loading
- [ ] Results screen (verdict + confidence)
- [ ] Basic history screen
- [ ] Connect to backend (production URL)

### Phase 3: Visual Analysis (5-7 days)
- [ ] Facial landmark extraction pipeline
- [ ] Blinking detection
- [ ] Mouth sync analysis (if audio available)
- [ ] Temporal frame consistency check
- [ ] Spatial frequency analysis
- [ ] Stitching artifact detection

### Phase 4: Deep Learning (7-10 days)
- [ ] Model selection (UNITE or STALL)
- [ ] Model deployment on GPU VPS
- [ ] Integrate into pipeline
- [ ] Ensemble voting with visual analysis

### Phase 5: Polish & Monetization (5-7 days)
- [ ] Per-layer breakdown UI
- [ ] Subscription system (Stripe or LemonSqueezy)
- [ ] Report export feature
- [ ] App store listing

---

## 11. Key Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| YouTube API rate limits | Cache results, exponential backoff |
| Detection accuracy poor | Start with Layer 1 only (YouTube's own labels), improve from user feedback |
| Video download fails (DASH manifests) | Use yt-dlp (most robust), fallback to direct stream |
| GPU cost too high for VPS | Start with CPU models (STALL is training-free, CPU-friendly), upgrade later |
| AI improves faster than detection | Build retraining pipeline from day 1 |
| YouTube re-encodes → strips metadata | Don't rely on metadata-only detection, use visual analysis |

---

## 12. Similar Apps / References

- **Deepware** (deepware.ai) — Online deepfake scanner, similar concept
- **TruthScan** (truthscan.com) — Claims 99%+ accuracy
- **Fake AV Detection** — Academic projects, not commercial

**Differentiation:** Cleaner UX, better explanation of results, freemium model.

---

*Plan created: 2026-05-31*