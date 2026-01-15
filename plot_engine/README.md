# PlotEngine

A Flutter-powered creative writing platform with AI entity recognition, multi-tab rich text editing, and intelligent knowledge base management for tracking characters, locations, and story elements.

## Features

### 📝 Rich Text Editor
- Multi-tab editing with preview and permanent tabs
- Auto-save with 5-second debounce
- Entity highlighting and inline tooltips
- Keyboard shortcuts (Cmd+S to save)
- Responsive design (mobile, tablet, desktop)

### 🤖 AI-Powered Writing Assistant
- **Entity Recognition**: Automatically detect characters, locations, objects, and events
- **Ask AI**: Get contextual answers about your project, chapters, or selections
- **Continue Writing**: AI-powered content generation
- **Modify Content**: Transform text based on natural language instructions
- **Consistency Checking**: Detect plot holes and character inconsistencies
- **Timeline Validation**: Ensure chronological accuracy across chapters
- **Foreshadowing Suggestions**: Get recommendations for narrative setup and payoff

### 📚 Knowledge Base
- Track characters, locations, objects, and events
- Custom entity types (factions, timelines, etc.)
- Rich entity descriptions with summaries
- Entity attribution tracking across chapters
- Visual entity relationships

### 🔄 Cross-Platform Storage
- **Desktop (macOS/Windows/Linux)**: Fast local file storage with automatic cloud sync
- **Hybrid Sync**: Local files for speed + cloud sync for AI features (when logged in)
- **Web**: Cloud-backed storage with REST API
- **Auto-sync**: Changes sync to cloud in background with retry on failure
- Platform-aware service architecture automatically selects the right implementation

### 🎨 Modern UI
- Material Design 3 with dark/light themes
- Responsive three-panel layout (editor, AI sidebar, knowledge panel)
- Collapsible panels for focused writing
- Mobile-optimized bottom navigation
- Custom text selection colors (orange for light, cyan for dark)

### 🔐 Authentication
- Google OAuth integration
- Platform-specific auth flows:
  - **macOS**: Native Google Sign-In
  - **Windows/Linux**: Browser-based OAuth with local callback server
  - **Web**: Backend OAuth redirect flow
- Secure token storage

### 💳 Billing & Credits
- Usage-based pricing for AI features
- Stripe integration for credit purchases
- Real-time credit balance tracking
- Detailed usage analytics

### 🌍 Internationalization
- Multi-language support (English, Chinese, French)
- Custom i18n system with `ref.tr()` extension
- Locale-aware AI responses

## Getting Started

### Prerequisites
- Flutter SDK 3.10.1 or higher
- For macOS: Xcode and macOS development environment
- For Windows: Visual Studio with "Desktop development with C++" workload
- For web: Modern web browser

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd plot_engine
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure environment:
```bash
cp .env.example .env
# Edit .env with your API credentials
```

4. Run the app:
```bash
# Desktop (macOS)
flutter run -d macos

# Desktop (Windows)
flutter run -d windows

# Desktop (Linux)
flutter run -d linux

# Web
flutter run -d chrome

# Or use the convenience script (macOS/Linux)
./run_web.sh
```

## Project Structure

```
lib/
├── config/           # Environment configuration
├── core/             # Core utilities and extensions
├── l10n/             # Internationalization
├── models/           # Data models
├── screens/          # Full-screen views
├── services/         # Business logic and API clients
│   ├── auth/         # Authentication services
│   ├── ai_service.dart
│   ├── project_service.dart (desktop)
│   ├── web_project_service.dart (web)
│   └── billing_service.dart
├── state/            # Riverpod state management
├── ui/               # UI components
│   ├── editor/       # Rich text editor
│   ├── sidebar_comments/  # AI assistant panel
│   ├── knowledge_panel/   # Entity management
│   └── toolbar/      # App toolbar
├── utils/            # Helper utilities
└── widgets/          # Reusable widgets
```

## Architecture

### State Management
Uses **Riverpod** for reactive state management:
- `projectProvider`: Current open project
- `chaptersProvider`: List of chapters
- `currentChapterProvider`: Active chapter in editor
- `knowledgeBaseProvider`: Knowledge items
- `entityStoreProvider`: AI-recognized entities (singleton)
- `authUserProvider`: Authenticated user
- `tabStateProvider`: Multi-tab editor state

### Platform-Aware Services

**Project Services:**
```dart
BaseProjectService (interface)
├── ProjectService (desktop) - local file storage
└── WebProjectService (web/cloud) - cloud backend API
```

The `projectServiceProvider` automatically selects the correct implementation based on `kIsWeb`.
Desktop users can also access cloud storage via `cloudProjectServiceProvider` when logged in.

**Auth Services:**
```dart
AuthService (interface)
├── GoogleAuthService (macOS) - native Google Sign-In
├── DesktopAuthService (Windows/Linux) - browser-based OAuth
└── WebAuthService (web) - backend redirect flow
```

### Data Storage

**Desktop (local files)**:
```
{project_path}/
├── project.json          # Project metadata
├── chapters.json         # Chapter metadata
├── chapters/
│   └── chapter_{id}.txt
├── knowledge.json
├── entities.json
└── sync_metadata.json    # Cloud sync state (ID mappings)
```

**Web**: All data stored in cloud backend via REST API.

**Hybrid Sync (Desktop)**: When logged in, projects automatically sync to cloud in the background. Local timestamp IDs are mapped to cloud UUIDs via `sync_metadata.json`. Failed syncs retry with exponential backoff.

## Development

### Commands
```bash
flutter pub get          # Get dependencies
flutter run -d macos     # Run macOS desktop app
flutter run -d chrome    # Run web version
flutter test             # Run tests
flutter analyze          # Static analysis
dart format .            # Format code
flutter build macos      # Build macOS app
flutter clean            # Clean build artifacts
```

### Adding New Features

1. **Define models** in `lib/models/` with `toJson`/`fromJson`
2. **Create StateNotifier** in `lib/state/app_state.dart`
3. **Add service methods** for business logic
4. **Update storage** in `StorageService` and/or `BackendProjectService`
5. **Implement UI** in `lib/ui/`

### Platform-Specific Implementation

To add a platform-aware feature:
1. Define interface in `BaseProjectService`
2. Implement in both `ProjectService` (desktop) and `WebProjectService` (web)
3. Access via `ref.read(projectServiceProvider)` - correct implementation auto-selected

## Key Dependencies

- `super_editor`: Rich text editing
- `flutter_riverpod`: State management
- `web_socket_channel`: Real-time communication
- `http`: REST API client
- `google_sign_in`: OAuth authentication
- `flutter_secure_storage`: Secure token storage
- `sqflite`: Local database (desktop)
- `file_picker`: File system access

## Known Issues

### Windows: OneDrive Folder Restrictions
On Windows, the Documents folder is often synced to OneDrive with "Files On-Demand" enabled. This can prevent creating new folders programmatically. If you encounter "folder creation failed" errors:
- Select a folder outside of Documents (e.g., `C:\Users\YourName\PlotEngine`)
- Or disable OneDrive sync for your Documents folder

The app defaults to `%USERPROFILE%\PlotEngine` on Windows to avoid this issue.

## Contributing

See [CLAUDE.md](CLAUDE.md) for detailed development guidelines and architecture documentation.

## License

[Add your license here]

## Support

For issues and feature requests, please use the GitHub issue tracker.
