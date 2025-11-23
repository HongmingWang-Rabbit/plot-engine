# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

PlotEngine is a Flutter desktop application for creative writing with AI-assisted features. It provides a rich text editor for writing chapters, a knowledge base for tracking story elements (characters, locations, objects, events), and a sidebar for AI-generated comments (planned).

## Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run the app (macOS)
flutter run -d macos

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format .
```

### Building
```bash
# Build for macOS
flutter build macos

# Clean build artifacts
flutter clean
```

## Architecture

### State Management
The app uses **Riverpod** for state management with a clear separation of concerns:
- **Models** (`lib/models/`): Immutable data classes with JSON serialization
- **Services** (`lib/services/`): Business logic and I/O operations
- **State** (`lib/state/app_state.dart`): StateNotifier providers that connect UI to services
- **UI** (`lib/ui/`): Widgets that consume state via providers

### Key State Providers
All providers are defined in `lib/state/app_state.dart`:
- `projectProvider`: Current open project (nullable)
- `chaptersProvider`: List of all chapters in current project
- `currentChapterProvider`: Currently active chapter in the editor
- `knowledgeBaseProvider`: List of all knowledge base items

### Service Layer
- **ProjectService** (`lib/services/project_service.dart`): High-level operations for projects, chapters, and knowledge items. Orchestrates state updates and persistence.
- **StorageService** (`lib/services/storage_service.dart`): Low-level file I/O. Handles reading/writing JSON files.
- **FolderPickerService** (`lib/services/folder_picker_service.dart`): File system browsing for custom project locations.

### Data Flow
1. User interacts with UI widget
2. Widget calls method on ProjectService (via provider)
3. ProjectService updates state (via StateNotifier)
4. ProjectService persists changes (via StorageService)
5. UI rebuilds automatically (Riverpod reactivity)

## Project Storage

Projects use a file-based storage system where content is separated from metadata:

```
{project_path}/
├── project.json      # Project metadata (id, name, timestamps)
├── chapters.json     # Chapter metadata only (id, title, order, timestamps)
├── chapters/         # Chapter content directory
│   ├── chapter_{id}.txt   # Individual chapter content files
│   └── ...
└── knowledge.json    # Array of knowledge base items
```

**Key design decisions**:
- Chapter content is stored in separate `.txt` files to avoid large JSON files
- `chapters.json` contains only metadata (title, order, timestamps), not content
- Each chapter file is named `chapter_{id}.txt` in the `chapters/` subdirectory

**Default location**: `~/Documents/PlotEngine/{project_id}/`

**Custom locations**: Users can save projects anywhere via file picker.

## Key Models

### Chapter
- `id`: Unique identifier (timestamp-based)
- `title`: Chapter title
- `content`: Plain text content from super_editor (stored in separate file)
- `order`: Sort order (integer)
- `createdAt`, `updatedAt`: Timestamps

**Serialization methods**:
- `toMetadataJson()`: Saves metadata only (for chapters.json)
- `fromMetadataJson(json, content)`: Loads metadata and content separately
- `toJson()/fromJson()`: Full serialization (backward compatibility)

### KnowledgeItem
- `id`: Unique identifier
- `name`: Item name
- `type`: One of: 'character', 'location', 'object', 'event'
- `description`: Item description
- `appearances`: List of chapter IDs (for future AI tracking)

### Project
- `id`: Unique identifier (timestamp-based)
- `name`: Project name
- `path`: Absolute file system path to project directory
- `createdAt`, `updatedAt`: Timestamps

## UI Layout

The app has a three-panel layout (defined in `lib/main.dart`):
1. **Editor Panel** (60% width): Rich text editor using `super_editor` package
2. **Sidebar Comments** (20% width): Placeholder for AI comments (not yet implemented)
3. **Knowledge Panel** (20% width): Tab-based interface for managing knowledge items

**Toolbar** (`lib/ui/toolbar/app_toolbar.dart`): Global actions for New Project, Open Project, Save, New Chapter, etc.

## Important Patterns

### Creating New Features with State
When adding features that need state:
1. Add data model in `lib/models/` with `toJson`/`fromJson`
2. Create StateNotifier in `lib/state/app_state.dart`
3. Add methods to ProjectService for business logic
4. Update StorageService if persistence is needed
5. Build UI that consumes the provider

### Service Injection
Services use Riverpod's dependency injection:
```dart
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(ref);
});
```

Access in widgets via:
```dart
final projectService = ref.read(projectServiceProvider);
```

### Auto-save
The editor panel implements auto-save with a 5-second debounce timer. When modifying auto-save behavior, update the timer in `lib/ui/editor/editor_panel.dart`.

## Dependencies

Key packages:
- `super_editor: ^0.3.0-dev.40` - Rich text editing
- `flutter_riverpod: ^2.6.1` - State management
- `web_socket_channel: ^3.0.1` - WebSocket for future AI features
- `http: ^1.2.2` - HTTP client
- `sqflite: ^2.4.1` - Local database (not currently used)
- `file_picker: ^8.1.6` - File/folder picker dialogs

## Platform Support

Currently supports **macOS** only. The `macos/` directory contains macOS-specific configuration. To add other platforms, use `flutter create` to generate platform directories.

## Future AI Integration

The architecture is prepared for AI features:
- WebSocket service (to be implemented in `lib/services/`)
- AI comments sidebar (UI placeholder exists)
- Character tracking via `appearances` field in KnowledgeItem
- Real-time feedback and suggestions

The state management structure supports adding AI-generated data without major refactoring.
