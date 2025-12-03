---
inclusion: always
---

# Flutter Development Guidelines for PlotEngine

## Code Style

- Use `const` constructors wherever possible for performance
- Prefer `final` over `var` for immutable variables
- Use meaningful variable names that describe the data
- Keep widget build methods focused and extract complex UI into separate widgets

## State Management (Riverpod)

- Use `StateNotifier` for complex state logic
- Use `StateProvider` for simple state
- Always use `ref.watch()` in build methods for reactive updates
- Use `ref.read()` for one-time reads or in callbacks
- Dispose controllers and subscriptions properly

## Project Architecture

### Platform-Aware Services
- All project operations go through `BaseProjectService` interface
- `ProjectService` handles desktop (local files)
- `WebProjectService` handles web (cloud API)
- Access via `ref.read(projectServiceProvider)` - auto-selects correct implementation

### Data Flow
1. UI widget calls service method
2. Service updates StateNotifier providers
3. Service persists changes (local or cloud)
4. UI rebuilds automatically via Riverpod

### File Organization
- Models in `lib/models/` with `toJson`/`fromJson`
- Services in `lib/services/` for business logic
- State in `lib/state/` using Riverpod
- UI components in `lib/ui/` organized by feature
- Reusable widgets in `lib/widgets/`

## Performance

- Use `const` widgets to prevent unnecessary rebuilds
- Implement `shouldRepaint` in CustomPainters
- Debounce expensive operations (auto-save uses 5-second debounce)
- Use `ListView.builder` for long lists

## Error Handling

- Use `ErrorHandler.handleAsync()` wrapper for service methods
- Log errors with `AppLogger` (info, warn, error, load)
- Show user-friendly error messages in UI
- Handle both desktop and web error scenarios

## Testing

- Write widget tests for UI components
- Write unit tests for services and state logic
- Mock platform-specific services for cross-platform testing

## Localization

- Use `ref.tr('key')` for all user-facing strings
- Add translations to `lib/l10n/translations/` for each language
- Keep translation keys descriptive and organized by feature

## AI Features

- All AI operations go through `AIService`
- Check credits before expensive AI operations
- Handle API errors gracefully with fallbacks
- Show loading states during AI processing
- Use debouncing for real-time AI features (entity recognition)

## Themes

- Support all three themes: Light, Dark, Halloween
- Use theme colors from `Theme.of(context).colorScheme`
- Test UI in all themes to ensure readability
- Avoid hardcoded colors - use theme values
