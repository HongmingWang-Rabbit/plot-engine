---
inclusion: always
---

# PlotEngine Project Context

## Project Overview

PlotEngine is a cross-platform creative writing application built with Flutter that helps authors write novels with AI assistance. The app runs on both desktop (macOS) and web with a unified codebase.

## Core Features

### 1. Rich Text Editor
- Multi-tab editing system with preview and permanent tabs
- Built on `super_editor` package for rich text capabilities
- Real-time entity highlighting (characters, locations, objects, events)
- Auto-save with 5-second debounce
- Keyboard shortcuts (Cmd+S for save)

### 2. AI Writing Assistant
- Entity extraction from chapter content
- Consistency checking across chapters
- Timeline validation
- Foreshadowing suggestions
- Ask AI questions about project/chapters
- Continue writing with AI
- Modify content with natural language instructions

### 3. Knowledge Base
- Track story entities (characters, locations, objects, events)
- Custom entity types support
- Entity attribution tracking (which chapters mention which entities)
- Rich descriptions with summaries
- Visual entity relationships

### 4. Cross-Platform Architecture
- **Desktop**: Local file-based storage with native folder picker
- **Web**: Cloud-backed REST API storage
- Platform-aware service layer automatically selects implementation
- Shared UI codebase with responsive design

## Technology Stack

- **Framework**: Flutter 3.10.1+
- **State Management**: Riverpod 2.6.1
- **Rich Text**: super_editor 0.3.0
- **Authentication**: Google OAuth (google_sign_in 6.2.2)
- **Storage**: 
  - Desktop: sqflite, file_picker, path_provider
  - Web: http, web_socket_channel
- **Security**: flutter_secure_storage 9.2.2

## Project Structure

```
lib/
├── config/          # Environment and theme configuration
├── core/            # Core utilities, extensions, base classes
├── l10n/            # Internationalization (en, zh, fr)
├── models/          # Data models with JSON serialization
├── screens/         # Full-screen views
├── services/        # Business logic and API clients
│   ├── auth/        # Platform-specific authentication
│   ├── *_service.dart
├── state/           # Riverpod state management
├── ui/              # UI components organized by feature
│   ├── auth/
│   ├── dialogs/
│   ├── editor/
│   ├── footer/
│   ├── knowledge_panel/
│   ├── sidebar_comments/
│   ├── toolbar/
│   └── widgets/
├── utils/           # Helper utilities
└── widgets/         # Reusable widgets
```

## Key Architectural Patterns

### Platform-Aware Services
```dart
BaseProjectService (interface)
├── ProjectService (desktop) - local file storage
└── WebProjectService (web) - cloud backend API
```

Access via: `ref.read(projectServiceProvider)` - automatically selects correct implementation

### State Management Flow
1. UI widget calls service method
2. Service updates StateNotifier providers
3. Service persists changes (local files or cloud API)
4. UI rebuilds automatically via Riverpod reactivity

### Data Storage

**Desktop**:
```
{project_path}/
├── project.json      # Project metadata
├── chapters.json     # Chapter metadata (content separate)
├── chapters/
│   └── chapter_{id}.txt
├── knowledge.json
└── entities.json
```

**Web**: All data in cloud via REST API endpoints

## Important Providers

- `projectProvider` - Current open project
- `chaptersProvider` - List of chapters
- `currentChapterProvider` - Active chapter in editor
- `knowledgeBaseProvider` - Knowledge items
- `entityStoreProvider` - AI-recognized entities (singleton)
- `authUserProvider` - Authenticated user
- `tabStateProvider` - Multi-tab editor state
- `appThemeProvider` - Current theme (light/dark/halloween)

## Development Workflow

1. Models define data structure with `toJson`/`fromJson`
2. Services implement business logic
3. StateNotifiers manage reactive state
4. UI components consume state via `ref.watch()`
5. User actions trigger service methods via `ref.read()`

## Testing Strategy

- Widget tests for UI components
- Unit tests for services and state logic
- Mock platform-specific services for cross-platform testing
- Test all three themes for visual consistency

## Deployment

- **Desktop**: `flutter build macos`
- **Web**: `flutter build web` → Deploy to Vercel
- Environment variables via `.env` file
