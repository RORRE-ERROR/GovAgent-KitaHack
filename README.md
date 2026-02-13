# GovAgent

Voice-first AI assistant for navigating Malaysian government portals. Speak naturally and GovAgent will browse government websites on your behalf — filling forms, clicking buttons, and reading pages — all through a conversational voice interface powered by Gemini.

Built for **KitaHack 2026**.

## How It Works

1. You tap the mic and speak (e.g. "Help me renew my driving license")
2. Gemini Live processes your speech and decides what browser actions to take
3. A backend server (separate repo) executes those actions in a real browser
4. You see a live screenshot stream of the browser in the app
5. Before any form submission, GovAgent asks for your explicit confirmation

## What's Built (Flutter Client)

This repo is the **mobile client only** (iOS/Android). It's the front-end half — everything the user sees and touches. The backend (browser automation server) lives in a separate repo.

### Features

- **Voice conversation** — tap the mic, speak naturally in English or Bahasa Malaysia, hear the AI respond out loud. Full duplex audio streaming to Gemini Live API.
- **Live browser view** — the top of the screen shows a real-time screenshot stream of the browser the AI is controlling on the backend. Pinch to zoom on details.
- **Action status** — an overlay label shows what the AI is currently doing (e.g. "Filling IC number...", "Navigating to JPJ portal...")
- **Form submission confirmation** — when the AI wants to submit a form, a dialog pops up asking you to confirm or cancel. Nothing gets submitted without your approval.
- **Transcript** — tap the chat icon to see a scrollable history of the conversation (your speech, AI responses, system messages) as chat bubbles.
- **Audio waveform** — animated bars above the mic button that visualize when you're speaking.
- **Graceful degradation** — if the backend isn't running, the app still works as a voice assistant (you can talk to Gemini, just no browser actions).

### What's NOT Built Yet

- No onboarding or tutorial flow
- No session history (past conversations aren't saved anywhere)
- No login/auth screen (Firebase Auth is a dependency but no UI for it)
- No "reconnect" button if Gemini disconnects (just shows error state)
- No session timeout handling (Gemini sessions expire after ~10 min)
- No settings screen
- Web platform won't work (`flutter_soloud` doesn't support web)

### Screens

| Screen | What it does |
|--------|-------------|
| **Home** | Landing page with the GovAgent logo and a "Start Session" button. Handles connection setup (mic permission, Gemini connect, backend connect). |
| **Session** | The main screen. Browser viewer on top, mic button at bottom, status overlay, waveform indicator, connection dot, transcript sheet. |

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | Flutter (Dart) |
| State Management | Riverpod |
| AI | Gemini Live API via `firebase_ai` |
| Voice Capture | `record` (PCM 16-bit 16kHz) |
| Voice Playback | `flutter_soloud` (PCM 24kHz) |
| Backend Comms | WebSocket (`web_socket_channel`) |

## Prerequisites

- Flutter 3.41.0+ / Dart 3.11.0+
- A Firebase project with Gemini API enabled (via Firebase AI Logic)
- Firebase config files:
  - `android/app/google-services.json`
  - `ios/Runner/GoogleService-Info.plist`
- Backend server running (optional — app works in voice-only mode without it)

## Setup

```bash
# Clone the repo
git clone <repo-url>
cd GovAgent

# Install dependencies
flutter pub get

# Add Firebase config files (not checked in)
# - Place google-services.json in android/app/
# - Place GoogleService-Info.plist in ios/Runner/
```

## Running

```bash
# Run with defaults (backend at localhost:8080)
flutter run

# Run with custom backend URL
flutter run --dart-define=BACKEND_URL=ws://192.168.1.100:8080/ws

# Run on a specific platform
flutter run -d ios
flutter run -d macos
flutter run -d chrome
```

### Configuration

Pass runtime config via `--dart-define`:

| Variable | Default | Description |
|----------|---------|-------------|
| `BACKEND_URL` | `ws://localhost:8080/ws` | Browser automation backend WebSocket URL |
| `GEMINI_MODEL` | `gemini-2.0-flash-live-001` | Gemini model for the live voice session |

## Project Structure

```
lib/
  main.dart                         # Entry point: Firebase init, ProviderScope
  app.dart                          # MaterialApp, dark theme, routing

  config/
    app_config.dart                 # Runtime config from --dart-define
    theme.dart                      # Dark theme definition

  models/
    session_state.dart              # idle | connecting | active | error
    tool_call.dart                  # Parsed Gemini function call
    browser_frame.dart              # Screenshot frame + action label
    transcript_entry.dart           # Speaker + text + timestamp

  services/
    gemini_live_service.dart        # firebase_ai LiveSession wrapper
    audio_capture_service.dart      # Mic → PCM 16kHz stream
    audio_playback_service.dart     # PCM 24kHz → speaker
    backend_websocket_service.dart  # WebSocket to backend
    permission_service.dart         # Mic permission handling

  providers/
    gemini_session_provider.dart    # Session orchestrator (wires all services)
    browser_stream_provider.dart    # Latest screenshot frame
    transcript_provider.dart        # Running transcript list
    tool_call_provider.dart         # Pending confirmation state

  screens/
    home_screen.dart                # Landing screen with "Start Session"
    session_screen.dart             # Voice session UI

  widgets/
    mic_button.dart                 # Animated mic button
    browser_viewer.dart             # Screenshot stream display
    status_overlay.dart             # Current action indicator
    transcript_overlay.dart         # Scrolling transcript
    confirmation_dialog.dart        # Form submission confirmation
    waveform_indicator.dart         # Audio level visualization
```

## Development

```bash
# Static analysis
flutter analyze

# Run tests
flutter test

# Run a specific test
flutter test test/widget_test.dart
```

## Platform Notes

- **Android**: `minSdk` is 24 (required by the `record` package). Mic and internet permissions are declared in the manifest.
- **iOS**: Microphone usage description is set in `Info.plist`. Deployment target 14.0+.
- **Web**: `flutter_soloud` does not support web. Audio playback won't work in the browser.

## Team

Built by the GovAgent team for KitaHack 2026.
