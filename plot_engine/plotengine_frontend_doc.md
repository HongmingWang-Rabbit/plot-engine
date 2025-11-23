# PlotEngine – Frontend (Flutter) Technical Overview

## 1. Overview

PlotEngine frontend is a cross-platform Flutter application targeting Mac, Windows, iOS, and Android. It provides a rich text editor for novelists and storytellers and integrates with the backend AI services to provide real-time narrative comments and story consistency analysis.

## 2. Core Features

- **Rich Text Editor**: Multi-line text, chapter management, undo/redo, custom styling.
- **Sidebar AI Comments**: Real-time feedback from backend AI on character introduction, plot consistency, foreshadowing.
- **Knowledge Base Panel**: Overview of characters, locations, objects, and events.
- **Project & Chapter Management**: Create, open, and save projects and chapters.
- **WebSocket Integration**: Real-time communication with backend AI services.

## 3. Technology Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod / Bloc
- **Rich Text Editing**: SuperEditor package
- **Networking**: WebSocket via `web_socket_channel`, HTTP via `http` package
- **Local Storage**: SharedPreferences / SQLite for offline drafts
- **Cross-platform Target**: MacOS, Windows, iOS, Android

## 4. Architecture Diagram

```
Flutter Frontend
 ├── Editor UI (Rich Text)
 ├── Sidebar Comments
 ├── Knowledge Base Panel
 ├── Project/Chapter Management
 └── WebSocket/HTTP Client
        |
        v
Backend AI Services (Node.js)
```

## 5. Folder Structure (Suggested)

```
lib/
 ├── main.dart
 ├── ui/
 │    ├── editor/
 │    ├── sidebar_comments/
 │    └── knowledge_panel/
 ├── models/
 ├── services/
 │    ├── websocket_service.dart
 │    └── api_service.dart
 ├── state/
 └── utils/
assets/
 └── icons, fonts
pubspec.yaml
```

## 6. Development Notes

- Connect WebSocket client to backend AI streaming endpoint for real-time feedback.
- Implement diffing of text input to send only changed parts to backend.
- Keep editor performance optimized for long-form text.
- Ensure offline draft saving and recovery.
