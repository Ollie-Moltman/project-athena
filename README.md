# Project Athena — AI Video Detection

**Scan any video playing on screen. No URL input needed.**

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐
│   Android App       │     │   FastAPI Backend   │
│   (Flutter) │────▶│   (VPS with GPU)    │
│                      │     │                     │
│  • Screen capture    │     │  • ML analysis │
│  • Floating overlay  │     │  • Layer 1-4 checks │
│  • Results display   │     │  • Verdict + score  │
└─────────────────────┘     └─────────────────────┘
```

## Project Structure

```
athena/
├── lib/
│   ├── main.dart # App entry point
│   ├── models/                 # Data models
│   ├── services/              # API service, capture service
│   └── ui/
│       ├── screens/ # 5 main screens
│       └── widgets/           # Reusable widgets
├── android/                   # Android native code
│   └── app/src/main/
│       ├── java/ # MediaProjection service
│       └── res/              # Android resources
└── backend/                   # FastAPI backend
    └── app/
        ├── routes/           # API endpoints
        ├── ml/               # ML models& analysis
        └── services/        # Business logic
```

## Screens

1. **Scan** — Big "Start Scanning" button, no URL input
2. **Scanning** — Live progress with per-layer bars
3. **Results** — Verdict badge + confidence + breakdown
4. **History** — Past scans list
5. **Settings** — Preferences + account

## Detection Layers

| Layer | Name | Method |
|-------|------|--------|
| 1 | Provenance | Metadata, channel signals |
| 2 | Visual Artifacts | Face landmarks, temporal analysis |
| 3 | Deep Learning | UNITE/STALL classifier |
| 4 | Contextual | Upload patterns, metadata |

## Backend API

```
POST /scan/screen
  Body: { frames: [base64...], duration_ms: 3000 }
  Response: { job_id: "..." }

GET /result/{job_id}
  Response: {
    verdict: "ai_generated" | "real" | "uncertain",
    confidence: 87,
    layers: { provenance, visual, deep_learning, contextual }
  }
```

## Tech Stack

- **App:** Flutter (Android), MediaProjection API
- **Backend:** FastAPI + Python, PyTorch, OpenCV
- **ML Models:** UNITE / STALL (CPU-friendly, 100-400MB)
- **Database:** SQLite (MVP), PostgreSQL (production)

## Status

🚧 Under construction — building end-to-end
