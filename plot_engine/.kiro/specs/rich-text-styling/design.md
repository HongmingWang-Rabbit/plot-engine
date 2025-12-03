# Design Document

## Overview

This design document outlines the architecture for adding comprehensive rich text styling capabilities to PlotEngine's writing panel. The implementation will extend the existing super_editor integration to support DOCX-like formatting while maintaining compatibility with the current entity recognition and highlighting system.

The design follows a layered approach:
1. **Attribution Layer**: Extend super_editor's attribution system with new formatting attributions
2. **Toolbar Layer**: Create a comprehensive formatting toolbar with buttons and dropdowns
3. **Styling Layer**: Implement stylesheet rules that render attributions visually
4. **Persistence Layer**: Serialize/deserialize formatted content to/from JSON
5. **Integration Layer**: Ensure formatting works seamlessly with entity highlighting

## Architecture

### High-Level Component Structure

```
EditorPanel (existing)
├── FormattingToolbar (new)
│   ├── InlineStyleButtons (bold, italic, underline, etc.)
│   ├── BlockStyleDropdown (headings, normal, quote)
│   ├── ListButtons (bullet, numbered)
│   ├── AlignmentButtons (left, center, right, justify)
│   ├── ColorPickers (text color, highlight)
│   └── FontSizeSelector
├── SuperEditor (existing, enhanced)
│   ├── Enhanced Stylesheet (new styling rules)
│   ├── Custom Attributions (formatting metadata)
│   └── Enhanced KeyboardActions (shortcuts)
└── AIInputBar (existing)
```

### Data Flow

1. **User Action** → Toolbar button click or keyboard shortcut
2. **Command Execution** → EditorCommandExecutor applies attribution
3. **Document Update** → MutableDocument receives new attributions
4. **Style Application** → Stylesheet renders attributions visually
5. **Auto-save** → Formatted content serialized to storage


## Components and Interfaces

### 1. FormattingToolbar Widget

A new stateful widget that displays formatting controls above the editor.

```dart
class FormattingToolbar extends ConsumerStatefulWidget {
  final Editor editor;
  final DocumentComposer composer;
  
  const FormattingToolbar({
    required this.editor,
    required this.composer,
  });
}
```

**Responsibilities:**
- Display formatting buttons and controls
- React to selection changes to update button states
- Execute formatting commands via editor
- Handle keyboard shortcuts
- Provide tooltips and accessibility labels

**Sub-components:**
- `InlineStyleButtonGroup`: Bold, italic, underline, strikethrough buttons
- `BlockStyleDropdown`: Heading levels and paragraph types
- `ListButtonGroup`: Bullet and numbered list buttons
- `AlignmentButtonGroup`: Text alignment buttons
- `ColorPickerButton`: Text and highlight color selection
- `FontSizeSelector`: Font size dropdown with custom input
- `ClearFormattingButton`: Remove all formatting

### 2. Custom Attributions

New attribution classes extending super_editor's Attribution system:

```dart
// Inline style attributions
class BoldAttribution extends Attribution { }
class ItalicAttribution extends Attribution { }
class UnderlineAttribution extends Attribution { }
class StrikethroughAttribution extends Attribution { }
class TextColorAttribution extends Attribution {
  final Color color;
}
class HighlightColorAttribution extends Attribution {
  final Color color;
}
class FontSizeAttribution extends Attribution {
  final double size;
}

// Block style attributions (stored in node metadata)
enum HeadingLevel { h1, h2, h3 }
enum ListType { unordered, ordered }
enum TextAlignment { left, center, right, justify }
```

### 3. Enhanced Stylesheet

Extension of `EditorStylesheetFactory` to handle new attributions:

```dart
class EnhancedStylesheetFactory {
  static Stylesheet createEnhancedStylesheet({
    required BuildContext context,
    required bool highlightsEnabled,
    String? hoveredEntityName,
  }) {
    return Stylesheet(
      rules: [
        // Heading styles
        _createHeadingRule(HeadingLevel.h1),
        _createHeadingRule(HeadingLevel.h2),
        _createHeadingRule(HeadingLevel.h3),
        // List styles
        _createListRule(ListType.unordered),
        _createListRule(ListType.ordered),
        // Block quote styles
        _createBlockQuoteRule(),
        // Alignment styles
        _createAlignmentRules(),
      ],
      inlineTextStyler: _createInlineStyler(
        highlightsEnabled: highlightsEnabled,
        hoveredEntityName: hoveredEntityName,
      ),
    );
  }
}
```

### 4. Formatting Commands

New editor commands for applying formatting:

```dart
class ToggleInlineStyleCommand implements EditorCommand {
  final Attribution attribution;
  final DocumentSelection selection;
}

class ChangeBlockTypeCommand implements EditorCommand {
  final String nodeId;
  final BlockType blockType;
}

class ToggleListCommand implements EditorCommand {
  final ListType listType;
}

class SetTextAlignmentCommand implements EditorCommand {
  final TextAlignment alignment;
}

class ClearFormattingCommand implements EditorCommand {
  final DocumentSelection selection;
}
```

### 5. Serialization Service

Service for converting formatted content to/from JSON:

```dart
class FormattedContentSerializer {
  /// Serialize document to JSON with formatting
  static Map<String, dynamic> serializeDocument(Document document);
  
  /// Deserialize JSON to document with formatting
  static List<DocumentNode> deserializeDocument(Map<String, dynamic> json);
  
  /// Serialize individual node with attributions
  static Map<String, dynamic> serializeNode(DocumentNode node);
  
  /// Deserialize node with attributions
  static DocumentNode deserializeNode(Map<String, dynamic> json);
}
```


## Data Models

### Attribution Data Structure

```dart
// Inline attribution with span information
class AttributionSpan {
  final int start;
  final int end;
  final Attribution attribution;
  
  AttributionSpan({
    required this.start,
    required this.end,
    required this.attribution,
  });
  
  Map<String, dynamic> toJson() => {
    'start': start,
    'end': end,
    'type': attribution.runtimeType.toString(),
    'data': _serializeAttributionData(attribution),
  };
  
  factory AttributionSpan.fromJson(Map<String, dynamic> json) {
    // Deserialize based on type
  }
}

// Block-level formatting metadata
class BlockMetadata {
  final HeadingLevel? headingLevel;
  final ListType? listType;
  final int? listIndent;
  final TextAlignment? alignment;
  final bool isBlockQuote;
  
  BlockMetadata({
    this.headingLevel,
    this.listType,
    this.listIndent,
    this.alignment,
    this.isBlockQuote = false,
  });
  
  Map<String, dynamic> toJson();
  factory BlockMetadata.fromJson(Map<String, dynamic> json);
}
```

### Serialized Document Format

```json
{
  "version": "1.0",
  "nodes": [
    {
      "id": "node_1",
      "type": "paragraph",
      "text": "This is bold and italic text",
      "attributions": [
        {
          "start": 8,
          "end": 12,
          "type": "bold"
        },
        {
          "start": 17,
          "end": 23,
          "type": "italic"
        }
      ],
      "metadata": {
        "alignment": "left"
      }
    },
    {
      "id": "node_2",
      "type": "paragraph",
      "text": "Chapter Title",
      "metadata": {
        "headingLevel": "h1",
        "alignment": "center"
      }
    },
    {
      "id": "node_3",
      "type": "listItem",
      "text": "First item",
      "metadata": {
        "listType": "unordered",
        "indent": 0
      }
    }
  ]
}
```

### Toolbar State Model

```dart
class FormattingState {
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final Color? textColor;
  final Color? highlightColor;
  final double? fontSize;
  final HeadingLevel? headingLevel;
  final ListType? listType;
  final TextAlignment alignment;
  final bool hasSelection;
  
  FormattingState({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.textColor,
    this.highlightColor,
    this.fontSize,
    this.headingLevel,
    this.listType,
    this.alignment = TextAlignment.left,
    this.hasSelection = false,
  });
  
  /// Extract formatting state from current selection
  factory FormattingState.fromSelection(
    Document document,
    DocumentSelection? selection,
  );
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property Reflection

After analyzing all acceptance criteria, several properties can be consolidated:
- Properties 1.1-1.4 (bold, italic, underline, strikethrough) follow the same pattern and can be generalized
- Properties 2.1-2.3 (heading levels) follow the same pattern
- Properties 4.1-4.4 (alignment types) follow the same pattern
- Properties 9.1-9.4 (toolbar state reflection) follow the same pattern

### Inline Formatting Properties

**Property 1: Inline style application**
*For any* text selection and any inline style (bold, italic, underline, strikethrough), applying that style should add the corresponding attribution to all characters in the selection
**Validates: Requirements 1.1, 1.2, 1.3, 1.4**

**Property 2: Multiple inline styles coexist**
*For any* text selection, applying multiple inline styles should result in all style attributions being present simultaneously on the selected text
**Validates: Requirements 1.5**

**Property 3: Pending style application**
*For any* inline style, when applied with no selection, subsequently typed characters should receive that style attribution until the style is toggled off
**Validates: Requirements 1.6**

**Property 4: Style toggle behavior**
*For any* text with a specific inline style applied, applying the same style again should remove that style attribution (toggle off)
**Validates: Requirements 1.7**

### Block Formatting Properties

**Property 5: Heading level application**
*For any* paragraph and any heading level (H1, H2, H3), applying that heading level should set the paragraph's block metadata to that heading type
**Validates: Requirements 2.1, 2.2, 2.3**

**Property 6: Normal paragraph conversion**
*For any* paragraph with heading or list formatting, converting to normal should remove all block-level formatting metadata
**Validates: Requirements 2.4, 12.2, 12.3**

**Property 7: Keyboard shortcut mapping**
*For any* formatting keyboard shortcut, executing that shortcut should produce the same result as clicking the corresponding toolbar button
**Validates: Requirements 2.6, 13.1**

### List Properties

**Property 8: List type conversion**
*For any* paragraph, converting to a list type (bullet or numbered) should set the paragraph's block metadata to that list type with indent level 0
**Validates: Requirements 3.1, 3.2**

**Property 9: List indentation**
*For any* list item at indent level N, pressing Tab should increase the indent to N+1, and pressing Shift+Tab should decrease to N-1 (minimum 0)
**Validates: Requirements 3.5, 3.6**

**Property 10: Sequential numbering**
*For any* numbered list with multiple items at the same indent level, the items should be numbered sequentially starting from 1
**Validates: Requirements 3.7**

### Alignment Properties

**Property 11: Text alignment application**
*For any* paragraph and any alignment type (left, center, right, justify), applying that alignment should set the paragraph's alignment metadata to that type
**Validates: Requirements 4.1, 4.2, 4.3, 4.4**

**Property 12: Multi-paragraph alignment**
*For any* selection spanning multiple paragraphs, applying an alignment should set that alignment on all paragraphs in the selection
**Validates: Requirements 4.5**

### Color and Font Properties

**Property 13: Color application**
*For any* text selection and any color, applying text color or highlight color should add the corresponding color attribution to the selected text
**Validates: Requirements 5.1, 5.2**

**Property 14: Multiple color attributions**
*For any* text selection, applying both text color and highlight color should result in both color attributions being present simultaneously
**Validates: Requirements 5.5**

**Property 15: Font size application**
*For any* text selection and any valid font size (6-200 points), applying that size should add the font size attribution to the selected text
**Validates: Requirements 6.1, 6.5**

**Property 16: Relative font size adjustment**
*For any* text with font size S, increasing size should result in size S+2, and decreasing should result in size S-2 (minimum 6)
**Validates: Requirements 6.2, 6.3**

### Block Quote Properties

**Property 17: Block quote conversion**
*For any* paragraph or set of paragraphs, converting to block quote should set the block quote flag in metadata and apply appropriate styling
**Validates: Requirements 7.1, 7.4**

### Persistence Properties

**Property 18: Formatting serialization completeness**
*For any* document with formatting, serializing to JSON should preserve all inline attributions and block metadata
**Validates: Requirements 10.1, 10.3**

**Property 19: Formatting round-trip preservation**
*For any* formatted document, serializing then deserializing should produce a document with identical formatting
**Validates: Requirements 10.2**

**Property 20: Graceful deserialization**
*For any* JSON with missing or invalid formatting attributes, deserialization should succeed by applying default values without throwing errors
**Validates: Requirements 10.4**

### Entity Integration Properties

**Property 21: Entity and formatting coexistence**
*For any* text with entity attributions, applying formatting should preserve the entity attributions alongside the formatting attributions
**Validates: Requirements 11.1, 11.2, 11.5**

**Property 22: Entity update preserves formatting**
*For any* formatted text, when the entity recognition system updates entity attributions, all user-applied formatting should remain unchanged
**Validates: Requirements 11.4**

### Clear Formatting Properties

**Property 23: Clear formatting removes styles**
*For any* text with inline formatting, clearing formatting should remove all inline style attributions (bold, italic, underline, strikethrough, colors, font size) while preserving text content
**Validates: Requirements 12.1**

**Property 24: Clear formatting preserves entities**
*For any* text with both formatting and entity attributions, clearing formatting should remove only formatting attributions while preserving entity attributions
**Validates: Requirements 12.4**

**Property 25: Clear formatting preserves structure**
*For any* document, clearing formatting should not merge paragraphs or alter the document node structure
**Validates: Requirements 12.5**

### Toolbar State Properties

**Property 26: Toolbar reflects selection formatting**
*For any* text selection with specific formatting, the toolbar state should indicate all active formatting styles on that selection
**Validates: Requirements 9.1, 9.2, 9.3, 9.4**

**Property 27: Toolbar shows indeterminate for mixed formatting**
*For any* selection where a style is applied to some but not all characters, the toolbar should indicate an indeterminate state for that style
**Validates: Requirements 9.5**

### Clipboard Properties

**Property 28: Clipboard preserves formatting**
*For any* formatted text, copying and pasting should preserve all formatting attributions in the pasted text
**Validates: Requirements 13.5**


## Error Handling

### Input Validation

1. **Font Size Validation**
   - Reject font sizes < 6 or > 200 points
   - Show error message: "Font size must be between 6 and 200 points"
   - Fallback to nearest valid size

2. **Color Validation**
   - Accept any valid Color object
   - Handle null colors as "no color" (use default)
   - Validate hex color strings in custom color picker

3. **Selection Validation**
   - Handle null selections gracefully (no-op)
   - Handle collapsed selections (cursor position) for block formatting
   - Handle selections spanning multiple node types

### Serialization Error Handling

1. **Unknown Attribution Types**
   - Log warning for unknown attribution types during deserialization
   - Skip unknown attributions rather than failing
   - Continue processing remaining attributions

2. **Malformed JSON**
   - Catch JSON parsing exceptions
   - Return empty document with single paragraph on failure
   - Log error with details for debugging

3. **Missing Required Fields**
   - Use default values for missing fields
   - Log warning about missing fields
   - Continue processing with defaults

### Editor State Errors

1. **Invalid Node Operations**
   - Validate node exists before operations
   - Handle deleted nodes gracefully
   - Refresh editor state on structural changes

2. **Attribution Conflicts**
   - Allow multiple attributions of different types
   - Last-applied wins for conflicting attributions of same type
   - Preserve entity attributions during formatting operations

### UI Error Handling

1. **Toolbar State Errors**
   - Handle null document/selection gracefully
   - Show disabled state when no valid selection
   - Recover from state calculation errors

2. **Color Picker Errors**
   - Validate color input before applying
   - Show error for invalid hex codes
   - Provide color preview before applying


## Testing Strategy

### Unit Testing

Unit tests will verify specific examples and edge cases:

**Inline Formatting Tests:**
- Apply bold to empty string (should handle gracefully)
- Apply multiple styles to single character
- Toggle style on/off multiple times
- Apply style to text with existing entity attributions

**Block Formatting Tests:**
- Convert empty paragraph to heading
- Convert heading back to normal
- Apply alignment to paragraph with inline formatting
- Convert list item to block quote

**Serialization Tests:**
- Serialize empty document
- Serialize document with all formatting types
- Deserialize malformed JSON
- Deserialize JSON with unknown attribution types

**Edge Cases:**
- Font size at boundaries (6, 200)
- Very long text with many attributions
- Rapid style toggling
- Undo/redo with formatting changes

### Property-Based Testing

Property-based tests will verify universal properties across random inputs using the **test** package with **test_api** for property testing in Dart/Flutter.

**Configuration:**
- Minimum 100 iterations per property test
- Use random text generators (1-1000 characters)
- Use random selection generators (valid ranges within text)
- Use random style combinations

**Test Tagging:**
Each property-based test must include a comment with this format:
```dart
// Feature: rich-text-styling, Property N: [property description]
```

**Property Test Examples:**

```dart
// Feature: rich-text-styling, Property 1: Inline style application
test('inline style application property', () {
  for (int i = 0; i < 100; i++) {
    final text = generateRandomText();
    final selection = generateRandomSelection(text);
    final style = generateRandomInlineStyle();
    
    final result = applyInlineStyle(text, selection, style);
    
    expect(hasAttribution(result, selection, style), isTrue);
  }
});

// Feature: rich-text-styling, Property 19: Formatting round-trip preservation
test('formatting round-trip preservation property', () {
  for (int i = 0; i < 100; i++) {
    final document = generateRandomFormattedDocument();
    
    final json = serializeDocument(document);
    final restored = deserializeDocument(json);
    
    expect(formattingEquals(document, restored), isTrue);
  }
});
```

**Generators:**
- `generateRandomText()`: Creates text of random length with random content
- `generateRandomSelection()`: Creates valid selection within text bounds
- `generateRandomInlineStyle()`: Returns random inline style type
- `generateRandomFormattedDocument()`: Creates document with random formatting
- `generateRandomColor()`: Returns random Color object
- `generateRandomFontSize()`: Returns size between 6-200

**Comparison Functions:**
- `hasAttribution()`: Checks if attribution exists on selection
- `formattingEquals()`: Deep comparison of formatting between documents
- `attributionsEqual()`: Compares attribution sets

### Integration Testing

Integration tests will verify end-to-end workflows:

1. **Complete Formatting Workflow**
   - Create document → Apply formatting → Save → Reload → Verify formatting

2. **Toolbar Integration**
   - Click toolbar button → Verify command executed → Verify UI updated

3. **Keyboard Shortcuts**
   - Press shortcut → Verify formatting applied → Verify toolbar updated

4. **Entity Integration**
   - Apply formatting to entity → Verify both attributions present → Verify rendering

### Widget Testing

Widget tests will verify UI components:

1. **FormattingToolbar Widget**
   - Renders all buttons correctly
   - Updates state based on selection
   - Executes commands on button click
   - Shows tooltips on hover

2. **Color Picker Widget**
   - Displays color palette
   - Accepts custom colors
   - Applies selected color
   - Handles cancellation

3. **Font Size Selector**
   - Displays size options
   - Accepts custom input
   - Validates input range
   - Updates on selection

### Test Coverage Goals

- **Unit Tests**: 80% code coverage
- **Property Tests**: All 28 correctness properties
- **Integration Tests**: All major user workflows
- **Widget Tests**: All UI components

### Testing Tools

- **test**: Dart testing framework
- **flutter_test**: Flutter widget testing
- **mockito**: Mocking for unit tests
- **golden_toolkit**: Visual regression testing for toolbar

