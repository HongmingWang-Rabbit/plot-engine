---
inclusion: always
---

# Code Review Checklist for PlotEngine

## Before Committing Code

### General Code Quality
- [ ] No hardcoded strings - use `ref.tr()` for user-facing text
- [ ] No hardcoded colors - use `Theme.of(context).colorScheme`
- [ ] All `const` constructors are marked as `const`
- [ ] No unused imports or variables
- [ ] Meaningful variable and function names
- [ ] Complex logic has explanatory comments

### State Management
- [ ] Use `ref.watch()` in build methods for reactive updates
- [ ] Use `ref.read()` for one-time reads or callbacks
- [ ] StateNotifiers properly update state (don't mutate directly)
- [ ] Async operations use `ErrorHandler.handleAsync()`
- [ ] Loading states are shown during async operations

### Platform Compatibility
- [ ] Platform-specific code uses `kIsWeb` check
- [ ] Service methods work on both desktop and web
- [ ] File operations only on desktop (not web)
- [ ] API calls properly handle network errors
- [ ] Test on both platforms before committing

### UI/UX
- [ ] Responsive design works on mobile, tablet, desktop
- [ ] All three themes tested (light, dark, halloween)
- [ ] Loading indicators for async operations
- [ ] Error messages are user-friendly
- [ ] Keyboard shortcuts work as expected
- [ ] Touch targets are at least 44x44 pixels

### Performance
- [ ] Large lists use `ListView.builder`
- [ ] Expensive operations are debounced
- [ ] Images are optimized and cached
- [ ] No unnecessary rebuilds (use `const` widgets)
- [ ] CustomPainters implement `shouldRepaint` correctly

### Security
- [ ] No sensitive data in logs
- [ ] API tokens stored securely (flutter_secure_storage)
- [ ] User input is validated and sanitized
- [ ] No SQL injection vulnerabilities
- [ ] HTTPS for all API calls

### Testing
- [ ] New features have widget tests
- [ ] Service logic has unit tests
- [ ] Edge cases are tested
- [ ] Error scenarios are tested
- [ ] Platform-specific code is mocked in tests

### Documentation
- [ ] Complex logic has inline comments
- [ ] Public APIs have doc comments
- [ ] README updated if needed
- [ ] Breaking changes documented
- [ ] Migration guide for state changes

## Common Pitfalls to Avoid

### State Management
❌ **Don't**: Mutate state directly
```dart
state.chapters.add(newChapter); // Wrong!
```

✅ **Do**: Create new state
```dart
state = [...state, newChapter]; // Correct
```

### Theme Usage
❌ **Don't**: Hardcode colors
```dart
color: Colors.blue // Wrong!
```

✅ **Do**: Use theme colors
```dart
color: Theme.of(context).colorScheme.primary // Correct
```

### Localization
❌ **Don't**: Hardcode strings
```dart
Text('Save') // Wrong!
```

✅ **Do**: Use translations
```dart
Text(ref.tr('save')) // Correct
```

### Platform-Specific Code
❌ **Don't**: Call desktop-only APIs on web
```dart
await FilePicker.platform.pickFiles(); // Crashes on web!
```

✅ **Do**: Check platform first
```dart
if (!kIsWeb) {
  await FilePicker.platform.pickFiles();
}
```

### Error Handling
❌ **Don't**: Silent failures
```dart
try {
  await service.save();
} catch (e) {
  // Nothing - user doesn't know it failed!
}
```

✅ **Do**: Handle and communicate errors
```dart
try {
  await service.save();
} catch (e) {
  AppLogger.error('Save failed', e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ref.tr('save_failed'))),
  );
}
```

## Pre-Commit Commands

```bash
# Format code
dart format .

# Analyze for issues
flutter analyze

# Run tests
flutter test

# Check for unused dependencies
flutter pub deps
```

## Git Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: feat, fix, docs, style, refactor, test, chore

**Examples**:
- `feat(editor): add Halloween theme with animated decorations`
- `fix(web): resolve chapter reordering sync issue`
- `refactor(state): migrate theme system to support custom themes`
- `docs(readme): update feature list and architecture section`
