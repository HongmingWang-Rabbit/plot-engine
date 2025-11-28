# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PlotEngine is a Flutter application for creative writing with AI-assisted features. It provides a rich text editor for writing chapters, a knowledge base for tracking story elements (characters, locations, objects, events), and AI-powered entity recognition.

## Commands

```bash
flutter pub get          # Get dependencies
flutter run -d macos     # Run macOS desktop app
flutter run -d chrome    # Run web version
flutter test             # Run tests
flutter test test/widget_test.dart  # Run single test
flutter analyze          # Static analysis
dart format .            # Format code
flutter build macos      # Build macOS app
flutter clean            # Clean build artifacts
```

## Architecture

### Platform-Aware Services

The app runs on both desktop (macOS) and web, with platform-specific service implementations:

```
BaseProjectService (interface)
├── ProjectService (desktop) - local file storage
└── WebProjectService (web) - cloud backend API
```

The `projectServiceProvider` automatically selects the correct implementation based on `kIsWeb`.

### State Management (Riverpod)

State is organized in `lib/state/`:
- `app_state.dart`: Core providers (project, chapters, knowledge, auth, entities, billing)
- `tab_state.dart`: Multi-tab editor state with preview/permanent tabs
- `settings_state.dart`: Theme and preferences
- `status_state.dart`: Loading/status indicators

Key providers in `app_state.dart`:
- `projectProvider`: Current open project
- `chaptersProvider`: List of chapters
- `currentChapterProvider`: Active chapter in editor
- `knowledgeBaseProvider`: Knowledge items
- `entityStoreProvider`: AI-recognized entities (singleton)
- `authUserProvider`: Authenticated user
- `projectServiceProvider`: Platform-aware service (switches between local/cloud)

### Service Layer

- **ProjectService** / **WebProjectService**: High-level project CRUD via `BaseProjectService` interface
- **BackendProjectService**: REST API client for cloud operations
- **StorageService**: Local file I/O (desktop only)
- **AIService**: Entity extraction, consistency checking, foreshadowing suggestions
- **AIEntityRecognizer**: Debounced AI entity recognition in editor content
- **BillingService**: User credits and usage tracking
- **GoogleAuthService** / **WebAuthService**: Platform-specific OAuth

### Data Flow

1. User interacts with UI widget
2. Widget calls method on `BaseProjectService` (via provider)
3. Service updates StateNotifier providers
4. Service persists changes (local files or cloud API)
5. UI rebuilds automatically (Riverpod reactivity)

## Project Storage

**Desktop (local files)**:
```
{project_path}/
├── project.json      # Project metadata
├── chapters.json     # Chapter metadata only (not content)
├── chapters/
│   └── chapter_{id}.txt   # Individual chapter content
├── knowledge.json    # Knowledge base items
└── entities.json     # AI-recognized entities
```

**Web**: All data stored in cloud backend via REST API.

## Key Models

Located in `lib/models/`:
- **Project**: id, name, path, timestamps
- **Chapter**: id, title, content, order, timestamps
- **EntityMetadata**: id, name, type (character/location/object/event), description, aliases, attributes
- **KnowledgeItem**: Manually created story elements
- **AuthUser**: OAuth user info and tokens
- **BillingModels**: Credits, usage, and billing status

## UI Layout

Three-panel layout in `lib/main.dart`:
1. **Editor Panel** (60%): Multi-tab `super_editor` with entity highlighting
2. **Sidebar Comments** (20%): Entity details and AI comments
3. **Knowledge Panel** (20%): Entity/knowledge management

**Tab System** (`lib/state/tab_state.dart`):
- Preview tabs (italicized) auto-replace when clicking another item
- Tabs become permanent when user starts editing
- Supports both chapter and entity tabs via `TabContentType`

## Localization

Custom i18n system in `lib/l10n/`:
- `app_localizations.dart`: `L10n` class and `localeProvider`
- `translations/en.dart`, `zh.dart`, `fr.dart`: Translation maps

Usage in widgets:
```dart
ref.tr('key_name')  // Via LocalizationExtension
```

## Important Patterns

### Adding Platform-Aware Features

1. Define interface in `BaseProjectService` if it involves project data
2. Implement in both `ProjectService` (desktop) and `WebProjectService` (web)
3. Access via `ref.read(projectServiceProvider)` - correct implementation auto-selected

### Entity Recognition Flow

1. `AIEntityRecognizer` watches editor content with debouncing
2. Calls `AIService.extractEntities()` API
3. Results stored in `EntityStore` (singleton)
4. `entityStoreVersionProvider` triggers UI rebuilds when entities change

### Auto-save

Editor implements 5-second debounce auto-save. Centralized save logic in `SaveService` (`lib/services/save_service.dart`).

### Adding New State

1. Add model in `lib/models/` with `toJson`/`fromJson`
2. Create StateNotifier in `lib/state/app_state.dart`
3. Add service methods for business logic
4. For persistent data, update `StorageService` and/or `BackendProjectService`

## Environment Configuration

`.env` file required with:
- `API_BASE_URL`: Backend API endpoint
- Auth credentials for OAuth

Configuration loaded via `EnvConfig` in `lib/config/env_config.dart`.

## Platform Support

- **macOS**: Primary desktop platform
- **Web**: Cloud-backed version with Google OAuth
- Android/iOS/Windows/Linux: Generated directories exist but untested
