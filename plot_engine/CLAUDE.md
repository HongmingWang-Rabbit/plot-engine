# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PlotEngine is a Flutter application for creative writing with AI-assisted features. It provides a rich text editor for writing chapters, a knowledge base for tracking story elements (characters, locations, objects, events), and AI-powered entity recognition.

## Commands

```bash
flutter pub get          # Get dependencies
flutter run -d macos     # Run macOS desktop app
flutter run -d windows   # Run Windows desktop app
flutter run -d linux     # Run Linux desktop app
flutter run -d chrome    # Run web version
flutter test             # Run tests
flutter test test/widget_test.dart  # Run single test
flutter analyze          # Static analysis
dart format .            # Format code
flutter build macos      # Build macOS app
flutter build windows    # Build Windows app
flutter clean            # Clean build artifacts
```

## Architecture

### Platform-Aware Services

The app runs on desktop (macOS/Windows/Linux) and web, with platform-specific service implementations:

**Project Services:**
```
BaseProjectService (interface)
├── ProjectService (desktop) - local file storage
└── WebProjectService (web/cloud) - cloud backend API
```

The `projectServiceProvider` automatically selects the correct implementation based on `kIsWeb`.
Desktop users can access cloud storage via `cloudProjectServiceProvider` when logged in.

**Auth Services:**
```
AuthService (interface)
├── GoogleAuthService (macOS) - native Google Sign-In
├── DesktopAuthService (Windows/Linux) - browser-based OAuth with local callback
└── WebAuthService (web) - backend redirect flow
```

Uses conditional imports with stub files to avoid platform-specific code loading errors.

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
- **SyncService**: Background cloud sync for desktop projects (auto-syncs on save when logged in)
- **AIService**: Entity extraction, consistency checking, foreshadowing suggestions
- **AIEntityRecognizer**: Debounced AI entity recognition in editor content
- **BillingService**: User credits and usage tracking
- **GoogleAuthService**: Native OAuth for macOS
- **DesktopAuthService**: Browser-based OAuth for Windows/Linux (uses local HTTP server for callback)
- **WebAuthService**: Backend redirect OAuth for web
- **AuthUtils**: Shared utilities for auth services (user conversion, etc.)

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
├── project.json          # Project metadata
├── chapters.json         # Chapter metadata only (not content)
├── chapters/
│   └── chapter_{id}.txt  # Individual chapter content
├── knowledge.json        # Knowledge base items
├── entities.json         # AI-recognized entities
└── sync_metadata.json    # Cloud sync state and ID mappings
```

**Web**: All data stored in cloud backend via REST API.

### Hybrid Local+Cloud Storage (Desktop)

Desktop projects use fast local file I/O while automatically syncing to cloud for AI features:

1. **Local-first**: Save to local files immediately (fast)
2. **Background sync**: Sync to cloud when logged in (non-blocking)
3. **ID mapping**: `sync_metadata.json` maps local timestamp IDs to cloud UUIDs
4. **Retry logic**: Failed syncs retry with exponential backoff (5s, 15s, 45s, 2min, 5min)

**Key files**:
- `lib/models/sync_metadata.dart`: SyncMetadata, SyncStatus, SyncQueueItem
- `lib/services/sync_service.dart`: Cloud sync logic (desktop only)
- `lib/services/sync_service_stub.dart`: Web stub (web is always cloud-native)
- `lib/core/constants/sync_constants.dart`: Retry delays and operation constants

**Providers**:
- `syncServiceProvider`: SyncService instance
- `syncStatusProvider`: Current sync status (synced/syncing/pending/failed/offline)

The sync status is shown in the footer with cloud icons and localized status text.

## Key Models

Located in `lib/models/`:
- **Project**: id, name, path, timestamps, isCloudStored flag
- **Chapter**: id, title, content, order, timestamps
- **EntityMetadata**: id, name, type (character/location/object/event), description, aliases, attributes
- **KnowledgeItem**: Manually created story elements
- **AuthUser**: OAuth user info and tokens
- **BillingModels**: Credits, usage, and billing status
- **SyncMetadata**: Cloud sync state, ID mappings (local↔cloud), pending queue

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

- **macOS**: Primary desktop platform with native Google Sign-In
- **Windows**: Supported with browser-based OAuth authentication
- **Linux**: Supported with browser-based OAuth authentication
- **Web**: Cloud-backed version with backend OAuth flow
- Android/iOS: Generated directories exist but untested

### Desktop Features (macOS/Windows/Linux)
- Local file storage with configurable default save location
- Cloud storage option when logged in (sync across devices)
- Settings dialog with storage preferences

### Windows-Specific Notes
- Default save location is `%USERPROFILE%\PlotEngine` (avoids OneDrive-synced Documents folder issues)
- Browser-based OAuth via `DesktopAuthService` with local HTTP callback server
- Uses `StorageException` for clear error messaging when folder creation fails
