# AI API Reference

## Overview

PlotEngine provides AI-powered writing assistance through three main services:
- **Entity Extraction** - Extract characters, locations, objects from text
- **Consistency Checking** - Detect plot holes and inconsistencies
- **Foreshadowing** - Suggest narrative callbacks and foreshadowing

**Base URL**: `http://localhost:3000/ai`

**AI Providers**: Anthropic Claude 3.5 Sonnet (default) or OpenAI GPT-4

---

## Authentication

All AI endpoints require JWT authentication:

```dart
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
}
```

---

## Endpoints

### 1. Extract Entities

Extract narrative entities from text (characters, locations, objects, events, relationships).

**POST** `/ai/extract/entities`

#### Request

```json
{
  "text": "Alice walked through the dark forest of Shadowvale, clutching the Crystal of Light...",
  "provider": "anthropic"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `text` | string | Yes | Text to analyze |
| `provider` | string | No | `"anthropic"` (default) or `"openai"` |

#### Response

```json
{
  "entities": {
    "characters": [
      {
        "name": "Alice",
        "description": "A brave young woman on a quest",
        "traits": ["brave", "determined"]
      }
    ],
    "locations": [
      {
        "name": "Shadowvale",
        "description": "A dark, mysterious forest"
      }
    ],
    "objects": [
      {
        "name": "Crystal of Light",
        "description": "A magical artifact with glowing properties"
      }
    ],
    "events": [
      {
        "description": "Alice enters Shadowvale forest",
        "characters_involved": ["Alice"]
      }
    ],
    "relationships": [
      {
        "character1": "Alice",
        "character2": "Bob",
        "type": "ally",
        "description": "Trusted companions on the journey"
      }
    ]
  }
}
```

---

### 2. Check Consistency

Analyze a chapter against previous chapters for inconsistencies.

**POST** `/ai/validate/consistency`

#### Request

```json
{
  "chapterId": "uuid-of-chapter",
  "projectId": "uuid-of-project",
  "contextRange": 5
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `chapterId` | string | Yes | Chapter to analyze |
| `projectId` | string | Yes | Project ID |
| `contextRange` | integer | No | Number of previous chapters to consider (1-10, default: 5) |

#### Response

```json
{
  "issues": [
    {
      "type": "character",
      "severity": "high",
      "description": "Alice's hair color changed from brown to blonde",
      "suggestion": "Update chapter 3 to maintain brown hair, or add a scene explaining the change"
    },
    {
      "type": "timeline",
      "severity": "medium",
      "description": "The journey to Shadowvale took 3 days in chapter 2, but is referenced as 'yesterday' in chapter 4",
      "suggestion": "Adjust the time reference to 'last week' or modify travel duration"
    }
  ]
}
```

**Issue Types:**
- `character` - Personality, appearance, abilities
- `plot` - Events contradicting earlier events
- `timeline` - Temporal inconsistencies
- `location` - Geographic/spatial contradictions
- `object` - Items appearing/disappearing unexpectedly

**Severity Levels:**
- `high` - Major contradiction that breaks the story
- `medium` - Noticeable inconsistency
- `low` - Minor detail mismatch

---

### 3. Validate Timeline

Check entire project for timeline issues.

**POST** `/ai/validate/timeline`

#### Request

```json
{
  "projectId": "uuid-of-project"
}
```

#### Response

```json
{
  "issues": [
    {
      "chapters": [2, 5],
      "description": "Chapter 5 references events from chapter 2 happening 'last month', but the story timeline suggests only a week has passed",
      "suggestion": "Adjust temporal references or add transition scenes to account for time passage"
    }
  ]
}
```

---

### 4. Suggest Foreshadowing

Get foreshadowing suggestions for a specific chapter.

**POST** `/ai/suggest/foreshadow`

#### Request

```json
{
  "chapterId": "uuid-of-chapter",
  "projectId": "uuid-of-project"
}
```

#### Response

```json
{
  "suggestions": {
    "callbacks": [
      {
        "reference_chapter": 2,
        "element": "The mysterious symbol Alice found on the tree",
        "suggestion": "Have Alice notice a similar symbol, triggering a memory",
        "location": "When entering the ancient ruins"
      }
    ],
    "foreshadowing": [
      {
        "type": "plot",
        "suggestion": "Add a subtle mention of strange weather patterns, hinting at the coming storm in later chapters",
        "subtlety": "high"
      },
      {
        "type": "character",
        "suggestion": "Show Bob hesitating before making a decision, foreshadowing his later betrayal",
        "subtlety": "medium"
      }
    ],
    "thematic_resonances": [
      {
        "theme": "trust vs betrayal",
        "earlier_occurrence": "Alice's mentor warning her about false friends in chapter 1",
        "suggested_echo": "Have Alice recall this warning when meeting new characters"
      }
    ]
  }
}
```

**Foreshadowing Types:**
- `plot` - Future plot events
- `character` - Character development/decisions
- `theme` - Thematic elements

**Subtlety Levels:**
- `high` - Very subtle, only noticed on re-read
- `medium` - Noticeable but not obvious
- `low` - Clear setup for later payoff

---

### 5. Detect Foreshadowing Opportunities

Analyze entire project for foreshadowing opportunities.

**POST** `/ai/suggest/foreshadow/detect`

#### Request

```json
{
  "projectId": "uuid-of-project"
}
```

#### Response

```json
{
  "opportunities": [
    {
      "target_chapter": 8,
      "element": "The villain's true identity reveal",
      "could_be_foreshadowed_in": [2, 4, 6],
      "suggestion": "Add subtle clues about the character's suspicious behavior in earlier chapters"
    },
    {
      "target_chapter": 5,
      "element": "Alice's hidden magical ability",
      "could_be_foreshadowed_in": [1, 3],
      "suggestion": "Show unexplained events happening around Alice that she dismisses as coincidence"
    }
  ]
}
```

---

## Dart/Flutter Examples

### Entity Extraction

```dart
Future<Map<String, dynamic>> extractEntities(String text) async {
  final response = await http.post(
    Uri.parse('$baseUrl/ai/extract/entities'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'text': text,
      'provider': 'anthropic',
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['entities'];
  }
  throw Exception('Failed to extract entities');
}
```

### Consistency Check

```dart
Future<List<ConsistencyIssue>> checkConsistency(
  String projectId,
  String chapterId,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/ai/validate/consistency'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'projectId': projectId,
      'chapterId': chapterId,
      'contextRange': 5,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return (data['issues'] as List)
        .map((i) => ConsistencyIssue.fromJson(i))
        .toList();
  }
  throw Exception('Failed to check consistency');
}

class ConsistencyIssue {
  final String type;
  final String severity;
  final String description;
  final String suggestion;

  ConsistencyIssue({
    required this.type,
    required this.severity,
    required this.description,
    required this.suggestion,
  });

  factory ConsistencyIssue.fromJson(Map<String, dynamic> json) {
    return ConsistencyIssue(
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'low',
      description: json['description'] ?? '',
      suggestion: json['suggestion'] ?? '',
    );
  }
}
```

### Foreshadowing Suggestions

```dart
Future<ForeshadowingSuggestions> getForeshadowing(
  String projectId,
  String chapterId,
) async {
  final response = await http.post(
    Uri.parse('$baseUrl/ai/suggest/foreshadow'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'projectId': projectId,
      'chapterId': chapterId,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return ForeshadowingSuggestions.fromJson(data['suggestions']);
  }
  throw Exception('Failed to get foreshadowing suggestions');
}
```

---

## Error Responses

```json
{
  "error": "Error message",
  "statusCode": 400
}
```

| Status | Meaning |
|--------|---------|
| 400 | Bad request / Missing required fields |
| 401 | Unauthorized |
| 403 | Access denied (not project owner) |
| 404 | Chapter/Project not found |
| 500 | AI service error |

---

## Rate Limits & Best Practices

1. **Caching**: Cache AI responses to avoid redundant API calls
2. **Debouncing**: Don't call on every keystroke - wait for user to stop typing
3. **Progressive Loading**: Show partial results while waiting for full analysis
4. **Error Handling**: AI services may timeout - implement retry logic

```dart
// Example: Debounced entity extraction
Timer? _debounceTimer;

void onTextChanged(String text) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(Duration(milliseconds: 500), () {
    extractEntities(text);
  });
}
```

---

## Environment Variables

```bash
# At least one AI provider required
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

---

**Version**: 1.0
**Updated**: November 25, 2025
