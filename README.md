# Malaysian Sign Language Translator

A Flutter mobile app to help bridge communication between deaf and hearing users in Malaysia by detecting hand signs using YOLO, translating them to text, and supporting speech input to text.

## Overview
The app captures hand-sign gestures (local or backend detection), converts them into readable text, and offers optional speech output and speech-to-text. Designed to be modular: detector, translator, speech to text (STT) and history modules.

## Features
- Real-time sign detection (detector or backend)
- Gesture → text translation
- Speech-to-text (STT)
- Translation and STT history with persistence
- Simple, mobile-first UI for translating BIM (Bahasa Isyarat Malaysia)

## Screenshots

<img src="https://github.com/user-attachments/assets/12162cc4-4051-4a50-9264-cc82f4943eb5" width=240>
<img src="https://github.com/user-attachments/assets/5f04dfab-82eb-4bbd-a4b0-fece34c79726" width=240>
<img src="https://github.com/user-attachments/assets/fb9e24e6-b3c9-4ed0-81d1-e58915811ca2" width=240>
<img src="https://github.com/user-attachments/assets/f5b7ca32-e63a-448a-a69d-569733ab6981" width=240>
<img src="https://github.com/user-attachments/assets/7eb4c08d-4e7b-46e8-aaa3-7ba2998521f2" width=240>
<img src="https://github.com/user-attachments/assets/857a8fd7-6ad2-4908-ac93-cd2720d2598c" width=240>
<img src="https://github.com/user-attachments/assets/f10d652b-cc28-4e3e-8ef6-071c1a125f49" width=240>

## Technology Used
- Framework: Flutter (Dart)
- Detector model: [**Custom made YOLO model**](https://github.com/EdgyPotato/Yolo-Model)
- Speech recognition model: [**OpenAI Whisper Turbo**](https://huggingface.co/openai/whisper-large-v3-turbo)
- Text translation model: [**Google Gemma**](https://huggingface.co/google/gemma-3-27b-it) with custom instructions

## How it works
1. Camera captures frames.
2. Frames processed by detector.
3. Translator maps detected gestures → text.
4. STT captures spoken input and stores/translates as needed.

## Limitiations
- Model accuracy may vary based on lighting, background, and hand positioning.
- Limited vocabulary based on available training data.
- API URL is disabled and removed, you are required to implement your own API from huggingface.


