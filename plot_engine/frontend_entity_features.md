# Frontend Entity Interaction Specification (Flutter)

## Overview
This document defines the required frontend functionality for entity recognition, highlighting, hover summaries, click actions, and entity creation within a Flutter-based novel editor.

## Goals
- Local entity recognition (characters, items, locations)
- Highlighting recognized & unrecognized entities in the text editor
- Hover → show brief summary for recognized entities
- Click recognized → open entity detail page
- Click unrecognized → open entity creation dialog
- Local storage of entity metadata
- Default Flutter project should compile and run these features

---

## 1. Local Entity Recognition
Implement a lightweight local recognizer:

- Words starting with a capital letter → potential entities
- Entities matched against stored lists:
  - characters
  - items
  - locations
- Recognized entities → green highlight
- Unrecognized entity candidates → orange highlight

Data model:

```
class Entity {
  final String name;
  final EntityType type; // character, item, location, unknown
  final bool recognized;
  final EntityMetadata? metadata;
}
```

---

## 2. Highlighting in Text Editor
Use a custom widget builder (e.g., TextSpan or SuperEditor) to show:

- Color-coded entities
- Inline interaction zones

Each entity span must support:

```
- Hover: show tooltip / summary overlay
- Click recognized → open detail screen
- Click unrecognized → open creation dialog
```

---

## 3. Hover Summary
For recognized entities:

- Show a tooltip or overlay (MouseRegion + OverlayEntry)
- Contains:
  - Name
  - Type
  - Brief summary

---

## 4. Click Handling

### 4.1 Recognized Entity
Click → Open `EntityDetailScreen`:

Displays:
- Name
- Type
- Summary
- Full description
- Save button

### 4.2 Unrecognized Entity
Click → Open `EntityCreationDialog`:

Fields:
- Name (pre-filled)
- Type dropdown
- Summary
- Full description

After creating:
- Save metadata locally
- Add to known lists
- Re-render text so highlight changes to recognized

---

## 5. Entity Metadata Storage
Implement `EntityStore`:

```
class EntityStore {
  Map<String, EntityMetadata> metadata = {};

  void save(EntityMetadata data);
  EntityMetadata? get(String name);
}
```

`EntityMetadata`:

```
class EntityMetadata {
  final String name;
  final EntityType type;
  final String summary;
  final String description;
}
```

Can use in-memory map; persistent storage optional.

---

## 6. Editor Integration
Editor must:

- Parse text into tokens
- Recognize entities using local store
- Build spans using interaction-capable widgets
- Rebuild on text changes
- Debounce optional networking calls (but not required yet)

---

## 7. Required Files for Generation (Claude Code)
Claude must generate the following files inside the Flutter project:

```
/lib/services/local_entity_recognizer.dart
/lib/services/entity_store.dart

/lib/models/entity.dart
/lib/models/entity_type.dart
/lib/models/entity_metadata.dart

/lib/widgets/highlighted_text.dart
/lib/widgets/entity_creation_dialog.dart

/lib/screens/entity_detail_screen.dart

/lib/main.dart
/pubspec.yaml (add dependencies)
```

All provided code must compile.
All features must work in isolation.
Mock data may be used for summaries & descriptions.

---

## 8. Default Project Behavior
The generated project must:

- Start with a text editor pre-filled with sample paragraphs
- Highlight entities immediately
- Hover shows summary overlay
- Click shows detail or creation dialog
- All state operations local-only
- No backend required
