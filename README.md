# Malaysian Sign Language Translator

A Flutter mobile app to help bridge communication between deaf and hearing users in Malaysia by detecting hand signs using YOLO, translating them to text, and supporting speech input to text.

---

## Overview
The app captures hand-sign gestures (local or backend detection), converts them into readable text, and offers optional speech output and speech-to-text. Designed to be modular: detector, translator, speech to text (STT) and history modules.

---

## Features
- Real-time sign detection (detector or backend)
- Gesture → text translation
- Speech-to-text (STT)
- Translation and STT history with persistence
- Simple, mobile-first UI for translating BIM (Bahasa Isyarat Malaysia)

---

## Screenshots

Home / Main Screen
<!-- screenshot: add home screen image here -->
![Home Screen](#){width=640}

Real-Time Detection / Camera View
<!-- screenshot: add camera detection image here -->
![Camera View](#){width=640}

Speech-to-Text / STT Screen
<!-- screenshot: add STT screen image here -->
![STT Screen](#){width=640}

Translation History
<!-- screenshot: add history screen image here -->
![History Screen](#){width=640}

Settings / Model Selection
<!-- screenshot: add settings screen image here -->
![Settings Screen](#){width=640}

---

## Technology
- Framework: Flutter (Dart)
- Detector model: Custom made YOLO model
- Speech recognition model: OpenAI Whisper
- Text translation model: Google Gemma with custom instructions

---

## How it works
1. Camera captures frames.
2. Frames processed by detector.
3. Translator maps detected gestures → text.
4. STT captures spoken input and stores/translates as needed.

---

## Limitiations
- Model accuracy may vary based on lighting, background, and hand positioning.
- Limited vocabulary based on available training data.
- API URL is disabled and removed, you are required to implement your own API from huggingface.
