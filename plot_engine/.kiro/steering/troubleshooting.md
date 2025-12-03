---
inclusion: always
---

# Troubleshooting Guide

Common issues and their solutions in PlotEngine development.

## Build Issues

### "Waiting for another flutter command to release the startup lock"
```bash
# Kill the lock file
rm -rf /path/to/flutter/bin/cache/lockfile

# Or restart your machine
```

### "CocoaPods not installed" (macOS)
```bash
sudo gem install cocoapods
cd ios && pod install
cd macos && pod install
```

### Web build fails with "Failed to load network image"
- Check CORS settings on your API server
- Ensure images are served over HTTPS
- Add proper headers in web/index.html

### "MissingPluginException" on web
- Run `flutter clean`
- Delete `build/` folder
- Run `flutter pub get`
- Restart the app

## State Management Issues

### Provider not updating UI
```dart
// ❌ Wrong - mutating state directly
state.items.add(newItem);

// ✅ Correct - creating new state
state = [...state.items, newItem];
```

### "Provider was disposed" error
- Don't call `ref.read()` in build method for reactive updates
- Use `ref.watch()` instead
- Only use `ref.read()` in callbacks/event handlers

### State resets unexpectedly
- Check if provider is being recreated
- Use `StateNotifierProvider` instead of `Provider` for mutable state
- Ensure provider is defined at the correct scope

## Platform-Specific Issues

### Desktop: File picker not working
```dart
// Check platform before calling
if (!kIsWeb) {
  final result = await FilePicker.platform.pickFiles();
}
```

### Web: Local storage not persisting
- Check browser privacy settings
- Ensure cookies are enabled
- Test in incognito mode to rule out extensions

### Web: CORS errors
```dart
// Backend needs proper CORS headers
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH
Access-Control-Allow-Headers: Content-Type, Authorization
```

### Desktop: SQLite errors
```bash
# Reinstall sqflite
flutter pub remove sqflite
flutter pub add sqflite
flutter clean && flutter pub get
```

## Performance Issues

### App is slow/laggy
1. Check for unnecessary rebuilds:
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  debugPrint('${widget.runtimeType} rebuilding');
  // If this prints too often, optimize
}
```

2. Use `const` constructors:
```dart
// Before
Text('Hello')

// After
const Text('Hello')
```

3. Use `ListView.builder` for long lists:
```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### Memory leaks
- Dispose controllers in `dispose()` method
- Cancel timers and subscriptions
- Remove listeners when done

```dart
@override
void dispose() {
  _controller.dispose();
  _timer?.cancel();
  _subscription?.cancel();
  super.dispose();
}
```

## API/Network Issues

### "Connection refused" errors
- Check API_BASE_URL in .env file
- Ensure backend server is running
- Verify network connectivity
- Check firewall settings

### Authentication fails
- Clear secure storage: `await storage.deleteAll()`
- Check token expiration
- Verify OAuth credentials in .env
- Test with fresh login

### API returns 401 Unauthorized
```dart
// Refresh token or re-authenticate
final authService = ref.read(authServiceProvider);
await authService.refreshToken();
```

### API returns 500 Internal Server Error
- Check backend logs
- Verify request payload format
- Test endpoint with Postman/curl
- Check for missing required fields

## Theme Issues

### Theme not applying
```dart
// Ensure you're using theme colors
color: Theme.of(context).colorScheme.primary

// Not hardcoded colors
color: Colors.blue // ❌
```

### Halloween theme not showing decorations
- Check if `appThemeProvider` is set to `AppTheme.halloween`
- Verify `HalloweenDecorations` widget is wrapping content
- Check browser console for rendering errors

### Text not visible in dark theme
- Use `onSurface` or `onPrimary` colors
- Avoid hardcoded black/white text colors
- Test all themes before committing

## Localization Issues

### Translations not loading
```dart
// Check locale provider
final locale = ref.watch(localeProvider);
debugPrint('Current locale: $locale');

// Verify translation key exists
final text = ref.tr('my_key');
if (text == 'my_key') {
  // Translation missing!
}
```

### Missing translation keys
1. Add to all language files:
```dart
// lib/l10n/translations/en.dart
'my_key': 'My Text',

// lib/l10n/translations/zh.dart
'my_key': '我的文本',

// lib/l10n/translations/fr.dart
'my_key': 'Mon texte',
```

## AI Features Issues

### "Insufficient credits" error
```dart
// Check balance before operation
final billingService = ref.read(billingServiceProvider);
final balance = await billingService.getCreditsBalance();
if (balance < 0.01) {
  // Show purchase dialog
}
```

### Entity extraction not working
- Check if AI analysis is enabled in settings
- Verify API key is valid
- Check network connectivity
- Look for errors in console

### AI responses in wrong language
```dart
// Ensure locale is passed correctly
final locale = ref.read(localeProvider).apiLocaleCode;
await aiService.askAI(
  projectId: project.id,
  question: question,
  locale: locale, // Must pass this!
);
```

## Testing Issues

### Tests failing with "No MediaQuery widget found"
```dart
// Wrap with MaterialApp
await tester.pumpWidget(
  MaterialApp(
    home: MyWidget(),
  ),
);
```

### Tests failing with "No ProviderScope found"
```dart
// Wrap with ProviderScope
await tester.pumpWidget(
  ProviderScope(
    child: MaterialApp(
      home: MyWidget(),
    ),
  ),
);
```

### Mock not working
```dart
// Use provider overrides
await tester.pumpWidget(
  ProviderScope(
    overrides: [
      myServiceProvider.overrideWithValue(MockMyService()),
    ],
    child: MaterialApp(home: MyWidget()),
  ),
);
```

## Debugging Techniques

### Enable verbose logging
```dart
// In main.dart
FlutterError.onError = (details) {
  FlutterError.presentError(details);
  debugPrint('Error: ${details.exception}');
  debugPrint('Stack: ${details.stack}');
};
```

### Log all provider changes
```dart
class DebugProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('[Provider] ${provider.name ?? provider.runtimeType}');
    debugPrint('  Old: $previousValue');
    debugPrint('  New: $newValue');
  }
}

// Add to main.dart
runApp(
  ProviderScope(
    observers: [DebugProviderObserver()],
    child: const PlotEngineApp(),
  ),
);
```

### Debug network requests
```dart
// In ApiClient
Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
  debugPrint('[API] POST $endpoint');
  debugPrint('[API] Body: $body');
  
  final response = await http.post(uri, body: jsonEncode(body));
  
  debugPrint('[API] Status: ${response.statusCode}');
  debugPrint('[API] Response: ${response.body}');
  
  return jsonDecode(response.body);
}
```

### Check widget tree
```dart
// In widget test
debugDumpApp(); // Prints entire widget tree
```

## Emergency Fixes

### App won't start at all
```bash
# Nuclear option - clean everything
flutter clean
rm -rf build/
rm -rf .dart_tool/
rm pubspec.lock
flutter pub get
flutter run
```

### Corrupted project state
```bash
# Desktop: Delete project files
rm -rf ~/PlotEngineProjects/MyProject

# Web: Clear browser storage
# Open DevTools → Application → Clear storage
```

### Git merge conflicts in generated files
```bash
# Regenerate files
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

## Getting Help

### Check logs
- **Desktop**: Console output
- **Web**: Browser DevTools console (F12)
- **Backend**: Server logs

### Useful commands
```bash
# Show Flutter doctor
flutter doctor -v

# Show dependencies
flutter pub deps

# Show outdated packages
flutter pub outdated

# Analyze code
flutter analyze

# Run with verbose logging
flutter run -v
```

### Report issues
Include:
1. Flutter version (`flutter --version`)
2. Platform (web/macOS/etc)
3. Error message and stack trace
4. Steps to reproduce
5. Expected vs actual behavior
6. Screenshots if relevant

### Resources
- Flutter docs: https://docs.flutter.dev
- Riverpod docs: https://riverpod.dev
- PlotEngine backend API docs: [Your API docs URL]
- Project CLAUDE.md for architecture details
