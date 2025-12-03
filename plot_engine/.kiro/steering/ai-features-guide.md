---
inclusion: always
---

# AI Features Implementation Guide

## Overview

PlotEngine uses AI to assist writers with entity recognition, consistency checking, and content generation. All AI operations go through the `AIService` and require credits.

## AI Service Architecture

### Core Service
- **Location**: `lib/services/ai_service.dart`
- **Provider**: `aiServiceProvider`
- **API Client**: Uses `ApiClient` for backend communication

### Credit System
- **Service**: `BillingService` in `lib/services/billing_service.dart`
- **Check credits**: `await billingService.hasSufficientCredits()`
- **Get balance**: `await billingService.getCreditsBalance()`
- **Purchase**: Stripe integration via `purchaseCredits(amount)`

## AI Features

### 1. Entity Extraction
Automatically detect characters, locations, objects, and events from text.

```dart
final aiService = ref.read(aiServiceProvider);
final result = await aiService.extractEntities(
  text: chapterContent,
  provider: 'anthropic',
);

// Result contains:
// - characters: List<ExtractedEntity>
// - locations: List<ExtractedEntity>
// - objects: List<ExtractedEntity>
// - events: List<ExtractedEntity>
// - relationships: List<EntityRelationship>
```

**Implementation Notes**:
- Debounce calls (5 seconds) to avoid excessive API usage
- Use `AIEntityRecognizer` service for automatic recognition
- Store results in `EntityStore` singleton
- Update `entityStoreVersionProvider` to trigger UI rebuilds

### 2. Ask AI
Get contextual answers about project, chapters, or selections.

```dart
final response = await aiService.askAI(
  projectId: project.id,
  question: 'What are the main themes in this story?',
  context: AskContext.project, // or .chapter, .selection
  chapterId: chapter.id, // optional
  selection: selectedText, // optional
  locale: ref.read(localeProvider).apiLocaleCode,
);

// response.answer contains the AI's response
```

**Contexts**:
- `AskContext.project` - Entire project context
- `AskContext.chapter` - Single chapter context
- `AskContext.selection` - Selected text only

### 3. Continue Writing
AI-powered content generation from where the chapter left off.

```dart
final response = await aiService.continueWriting(
  projectId: project.id,
  chapterId: chapter.id,
  prompt: 'Continue with more action', // optional
  maxWords: 500,
  locale: ref.read(localeProvider).apiLocaleCode,
);

// response.content contains generated text
```

**Best Practices**:
- Show loading indicator during generation
- Allow user to accept/reject generated content
- Track token usage for billing

### 4. Modify Content
Transform text based on natural language instructions.

```dart
final response = await aiService.modifyChapter(
  projectId: project.id,
  chapterId: chapter.id,
  prompt: 'Make this more suspenseful',
  selection: selectedText, // optional - modify selection only
  locale: ref.read(localeProvider).apiLocaleCode,
);

// response.content contains modified text
```

**Use Cases**:
- Rewrite for tone/style
- Expand or condense text
- Fix grammar/spelling
- Change perspective (1st to 3rd person)

### 5. Consistency Checking
Detect plot holes and character inconsistencies.

```dart
final issues = await aiService.checkConsistency(
  projectId: project.id,
  chapterId: chapter.id,
  contextRange: 5, // Check against previous 5 chapters
  locale: ref.read(localeProvider).apiLocaleCode,
);

// issues: List<ConsistencyIssue>
// Each issue has:
// - type: 'character', 'plot', 'setting', 'timeline'
// - severity: 'low', 'medium', 'high'
// - description: Human-readable explanation
// - suggestion: How to fix it
// - affectedChapters: List of chapter IDs
```

**Display**:
- Show in AI sidebar
- Group by severity
- Allow user to dismiss or fix
- Track resolved issues

### 6. Timeline Validation
Ensure chronological accuracy across the entire project.

```dart
final issues = await aiService.validateTimeline(
  projectId: project.id,
  locale: ref.read(localeProvider).apiLocaleCode,
);

// issues: List<TimelineIssue>
// Each issue has:
// - description: What's wrong
// - affectedChapters: Where the issue occurs
// - suggestion: How to fix
```

### 7. Foreshadowing Suggestions
Get recommendations for narrative setup and payoff.

```dart
// For specific chapter
final suggestions = await aiService.getForeshadowingSuggestions(
  projectId: project.id,
  chapterId: chapter.id,
  locale: ref.read(localeProvider).apiLocaleCode,
);

// suggestions contains:
// - setupOpportunities: Where to plant hints
// - payoffOpportunities: Where to resolve setups
// - existingForeshadowing: What's already there

// For entire project
final opportunities = await aiService.detectForeshadowingOpportunities(
  projectId: project.id,
  locale: ref.read(localeProvider).apiLocaleCode,
);
```

## State Management for AI Features

### Loading States
```dart
final aiLoadingProvider = StateProvider<bool>((ref) => false);
final aiErrorProvider = StateProvider<String?>((ref) => null);
```

### Results Storage
```dart
final consistencyIssuesProvider = StateProvider<List<ConsistencyIssue>>((ref) => []);
final foreshadowingSuggestionsProvider = StateProvider<ForeshadowingSuggestions?>((ref) => null);
final extractedEntitiesProvider = StateProvider<ExtractedEntities?>((ref) => null);
```

### AI Writing State
```dart
final aiWritingProvider = StateNotifierProvider<AIWritingNotifier, AIWritingState>((ref) {
  return AIWritingNotifier(ref.read(aiServiceProvider), ref);
});
```

## Error Handling

### Check Credits Before Operation
```dart
final billingService = ref.read(billingServiceProvider);
final hasCredits = await billingService.hasSufficientCredits(minimumRequired: 0.01);

if (!hasCredits) {
  // Show purchase dialog
  showDialog(
    context: context,
    builder: (context) => const BillingDashboardDialog(),
  );
  return;
}
```

### Handle API Errors
```dart
try {
  ref.read(aiLoadingProvider.notifier).state = true;
  final result = await aiService.extractEntities(text: content);
  // Process result
} catch (e) {
  ref.read(aiErrorProvider.notifier).state = e.toString();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ref.tr('ai_error'))),
  );
} finally {
  ref.read(aiLoadingProvider.notifier).state = false;
}
```

## Performance Optimization

### Debouncing
For real-time features like entity recognition:

```dart
Timer? _debounceTimer;

void onContentChanged(String content) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(seconds: 5), () {
    _extractEntities(content);
  });
}
```

### Caching
Cache AI results to avoid redundant API calls:

```dart
final _cache = <String, ExtractedEntities>{};

Future<ExtractedEntities> extractEntitiesWithCache(String text) async {
  final hash = text.hashCode.toString();
  if (_cache.containsKey(hash)) {
    return _cache[hash]!;
  }
  
  final result = await aiService.extractEntities(text: text);
  _cache[hash] = result;
  return result;
}
```

## UI Integration

### Show Loading State
```dart
if (ref.watch(aiLoadingProvider)) {
  return const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('AI is analyzing...'),
      ],
    ),
  );
}
```

### Display Results
```dart
final issues = ref.watch(consistencyIssuesProvider);
if (issues.isNotEmpty) {
  return ListView.builder(
    itemCount: issues.length,
    itemBuilder: (context, index) {
      final issue = issues[index];
      return ConsistencyIssueCard(issue: issue);
    },
  );
}
```

## Localization

AI responses respect the user's locale:

```dart
final locale = ref.read(localeProvider).apiLocaleCode;
// Returns: 'en', 'zh', 'fr', etc.

final response = await aiService.askAI(
  projectId: project.id,
  question: question,
  locale: locale, // AI responds in user's language
);
```

## Testing AI Features

### Mock AI Service
```dart
class MockAIService implements AIService {
  @override
  Future<ExtractedEntities> extractEntities({required String text}) async {
    return ExtractedEntities(
      characters: [
        ExtractedEntity(name: 'Test Character', type: 'character'),
      ],
      locations: [],
      objects: [],
      events: [],
      relationships: [],
    );
  }
}
```

### Test with Provider Override
```dart
testWidgets('AI extraction works', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiServiceProvider.overrideWithValue(MockAIService()),
      ],
      child: const MyApp(),
    ),
  );
  
  // Test AI features
});
```

## Cost Management

### Track Usage
```dart
final usageSummary = await billingService.getUsageSummary(days: 30);
// Shows token usage, costs, and trends
```

### Set Limits
```dart
// Check before expensive operations
if (await billingService.isLowBalance(threshold: 1.0)) {
  // Warn user about low credits
  showLowCreditsWarning(context);
}
```

## Best Practices

1. **Always check credits** before AI operations
2. **Show loading indicators** during API calls
3. **Handle errors gracefully** with user-friendly messages
4. **Debounce real-time features** to reduce API calls
5. **Cache results** when appropriate
6. **Respect user locale** for AI responses
7. **Track usage** for billing transparency
8. **Test with mocks** to avoid API costs during development
