---
inclusion: always
---

# Common Development Tasks

Quick reference for frequent development tasks in PlotEngine.

## Adding a New Feature

### 1. Define the Model
```dart
// lib/models/my_feature.dart
class MyFeature {
  final String id;
  final String name;
  final DateTime createdAt;

  MyFeature({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  MyFeature copyWith({String? id, String? name, DateTime? createdAt}) {
    return MyFeature(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'createdAt': createdAt.toIso8601String(),
  };

  factory MyFeature.fromJson(Map<String, dynamic> json) => MyFeature(
    id: json['id'] as String,
    name: json['name'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}
```

### 2. Create State Provider
```dart
// lib/state/app_state.dart
class MyFeatureNotifier extends StateNotifier<List<MyFeature>> {
  MyFeatureNotifier() : super([]);

  void addFeature(MyFeature feature) {
    state = [...state, feature];
  }

  void updateFeature(MyFeature feature) {
    state = [
      for (final f in state)
        if (f.id == feature.id) feature else f
    ];
  }

  void deleteFeature(String id) {
    state = state.where((f) => f.id != id).toList();
  }
}

final myFeatureProvider = StateNotifierProvider<MyFeatureNotifier, List<MyFeature>>((ref) {
  return MyFeatureNotifier();
});
```

### 3. Add Service Methods
```dart
// lib/services/base_project_service.dart
abstract class BaseProjectService {
  // ... existing methods
  Future<void> addMyFeature(MyFeature feature);
  Future<void> updateMyFeature(MyFeature feature);
  Future<void> deleteMyFeature(String id);
}

// lib/services/project_service.dart (Desktop)
@override
Future<void> addMyFeature(MyFeature feature) async {
  ref.read(myFeatureProvider.notifier).addFeature(feature);
  await saveProject();
}

// lib/services/web_project_service.dart (Web)
@override
Future<void> addMyFeature(MyFeature feature) async {
  await _backend.createMyFeature(projectId: project.id, feature: feature);
  ref.read(myFeatureProvider.notifier).addFeature(feature);
}
```

### 4. Create UI Component
```dart
// lib/ui/my_feature/my_feature_panel.dart
class MyFeaturePanel extends ConsumerWidget {
  const MyFeaturePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(myFeatureProvider);
    
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                ref.tr('my_feature'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddDialog(context, ref),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: features.length,
            itemBuilder: (context, index) {
              return MyFeatureCard(feature: features[index]);
            },
          ),
        ),
      ],
    );
  }
}
```

### 5. Add Translations
```dart
// lib/l10n/translations/en.dart
'my_feature': 'My Feature',
'add_my_feature': 'Add Feature',
'edit_my_feature': 'Edit Feature',

// lib/l10n/translations/zh.dart
'my_feature': '我的功能',
'add_my_feature': '添加功能',
'edit_my_feature': '编辑功能',
```

## Adding a New Theme

```dart
// lib/config/app_themes.dart
enum AppTheme {
  light,
  dark,
  halloween,
  myNewTheme, // Add here
}

class AppThemes {
  // Add theme getter
  static ThemeData get myNewTheme => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );

  // Update getTheme method
  static ThemeData getTheme(AppTheme theme) {
    switch (theme) {
      case AppTheme.light: return lightTheme;
      case AppTheme.dark: return darkTheme;
      case AppTheme.halloween: return halloweenTheme;
      case AppTheme.myNewTheme: return myNewTheme;
    }
  }

  // Update getThemeName
  static String getThemeName(AppTheme theme) {
    switch (theme) {
      // ... existing cases
      case AppTheme.myNewTheme: return '🎨 My Theme';
    }
  }
}
```

## Adding Platform-Specific Code

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

void myPlatformSpecificFunction() {
  if (kIsWeb) {
    // Web implementation
    _webImplementation();
  } else {
    // Desktop implementation
    _desktopImplementation();
  }
}

// Or use conditional imports
import 'my_feature_web.dart' if (dart.library.io) 'my_feature_desktop.dart';
```

## Adding a New Dialog

```dart
// lib/ui/dialogs/my_dialog.dart
class MyDialog extends ConsumerStatefulWidget {
  const MyDialog({super.key});

  @override
  ConsumerState<MyDialog> createState() => _MyDialogState();
}

class _MyDialogState extends ConsumerState<MyDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ref.tr('my_dialog_title'),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: ref.tr('name'),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ref.tr('required_field');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(ref.tr('cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleSubmit,
                    child: Text(ref.tr('save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      // Handle submission
      Navigator.of(context).pop(_controller.text);
    }
  }
}

// Usage
final result = await showDialog<String>(
  context: context,
  builder: (context) => const MyDialog(),
);
if (result != null) {
  // Use result
}
```

## Adding API Endpoint

```dart
// lib/services/backend_project_service.dart
Future<MyFeatureResponse> createMyFeature({
  required String projectId,
  required MyFeature feature,
}) async {
  final response = await _apiClient.post(
    '/projects/$projectId/my-features',
    feature.toJson(),
  );
  return MyFeatureResponse.fromJson(response);
}

Future<List<MyFeature>> getMyFeatures(String projectId) async {
  final response = await _apiClient.get('/projects/$projectId/my-features');
  final features = response['features'] as List;
  return features.map((f) => MyFeature.fromJson(f)).toList();
}
```

## Debugging Tips

### Print State Changes
```dart
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState.initial()) {
    addListener((state) {
      debugPrint('State changed: $state');
    });
  }
}
```

### Log Provider Reads
```dart
class LoggerProviderObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    debugPrint('Provider ${provider.name ?? provider.runtimeType} updated');
    debugPrint('  Previous: $previousValue');
    debugPrint('  New: $newValue');
  }
}

// In main.dart
runApp(
  ProviderScope(
    observers: [LoggerProviderObserver()],
    child: const PlotEngineApp(),
  ),
);
```

### Check Widget Rebuilds
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  debugPrint('${widget.runtimeType} rebuilding');
  // ... rest of build
}
```

## Performance Optimization

### Use const Constructors
```dart
// Bad
return Container(child: Text('Hello'));

// Good
return const Text('Hello');
```

### Avoid Rebuilding Large Widgets
```dart
// Extract static parts
class MyWidget extends ConsumerWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dynamicData = ref.watch(myProvider);
    
    return Column(
      children: [
        const _StaticHeader(), // Won't rebuild
        _DynamicContent(data: dynamicData), // Only this rebuilds
      ],
    );
  }
}
```

### Use ListView.builder for Long Lists
```dart
// Bad - builds all items at once
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// Good - builds items on demand
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

## Testing

### Widget Test Template
```dart
testWidgets('MyWidget displays correctly', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: const MyWidget(),
      ),
    ),
  );

  expect(find.text('Expected Text'), findsOneWidget);
  
  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
  
  expect(find.byType(MyDialog), findsOneWidget);
});
```

### Service Test Template
```dart
test('MyService creates feature correctly', () async {
  final service = MyService();
  final feature = MyFeature(
    id: '1',
    name: 'Test',
    createdAt: DateTime.now(),
  );

  await service.addFeature(feature);
  
  final features = await service.getFeatures();
  expect(features, contains(feature));
});
```

## Quick Commands

```bash
# Hot reload
r

# Hot restart
R

# Clear console
c

# Quit
q

# Run specific test
flutter test test/my_test.dart

# Run with coverage
flutter test --coverage

# Build for web
flutter build web --release

# Build for macOS
flutter build macos --release

# Analyze code
flutter analyze

# Format code
dart format lib/

# Update dependencies
flutter pub upgrade

# Clean build
flutter clean && flutter pub get
```
