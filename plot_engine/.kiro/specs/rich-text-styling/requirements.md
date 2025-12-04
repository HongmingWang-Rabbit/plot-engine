# Requirements Document

## Introduction

This document specifies the requirements for enhancing PlotEngine's writing panel with comprehensive text styling capabilities similar to those found in Microsoft Word (DOCX) documents. The current editor supports basic paragraph text with entity highlighting, but lacks fundamental formatting options that writers expect from a modern word processor. This feature will enable authors to format their manuscripts with proper emphasis, structure, and visual hierarchy while maintaining the existing AI-powered entity recognition capabilities.

## Glossary

- **Writing Panel**: The main text editing area in PlotEngine where users write chapter content
- **Super Editor**: The Flutter package (super_editor) that provides the underlying rich text editing capabilities
- **Text Attribution**: Metadata attached to text spans that defines styling properties (bold, italic, etc.)
- **Toolbar**: The horizontal UI component above the editor that contains formatting controls
- **Keyboard Shortcut**: Key combinations that trigger formatting actions (e.g., Cmd+B for bold)
- **Selection**: The currently highlighted text range in the editor
- **Inline Style**: Character-level formatting applied to text spans (bold, italic, underline, etc.)
- **Block Style**: Paragraph-level formatting applied to entire text blocks (headings, lists, alignment, etc.)
- **Entity Attribution**: Existing system for highlighting recognized story entities (characters, locations, etc.)
- **Serialization**: The process of converting editor content to/from a storable format (JSON)
- **DOCX**: Microsoft Word document format, used as reference for expected styling capabilities

## Requirements

### Requirement 1

**User Story:** As a writer, I want to apply basic inline text formatting (bold, italic, underline, strikethrough), so that I can emphasize important words and phrases in my manuscript.

#### Acceptance Criteria

1. WHEN a user selects text and clicks the bold button, THEN the system SHALL apply bold formatting to the selected text
2. WHEN a user selects text and clicks the italic button, THEN the system SHALL apply italic formatting to the selected text
3. WHEN a user selects text and clicks the underline button, THEN the system SHALL apply underline formatting to the selected text
4. WHEN a user selects text and clicks the strikethrough button, THEN the system SHALL apply strikethrough formatting to the selected text
5. WHEN a user applies multiple inline styles to the same text, THEN the system SHALL render all styles simultaneously (e.g., bold + italic)
6. WHEN a user clicks a formatting button with no text selected, THEN the system SHALL apply that formatting to subsequently typed text until toggled off
7. WHEN a user selects formatted text and clicks the corresponding formatting button, THEN the system SHALL remove that formatting (toggle behavior)

### Requirement 2

**User Story:** As a writer, I want to create different heading levels, so that I can structure my chapters with clear hierarchical organization.

#### Acceptance Criteria

1. WHEN a user places the cursor in a paragraph and selects "Heading 1" from the format dropdown, THEN the system SHALL convert that paragraph to a Heading 1 with larger font size and bold weight
2. WHEN a user places the cursor in a paragraph and selects "Heading 2" from the format dropdown, THEN the system SHALL convert that paragraph to a Heading 2 with medium font size and bold weight
3. WHEN a user places the cursor in a paragraph and selects "Heading 3" from the format dropdown, THEN the system SHALL convert that paragraph to a Heading 3 with slightly larger font size and bold weight
4. WHEN a user places the cursor in a paragraph and selects "Normal" from the format dropdown, THEN the system SHALL convert that paragraph to normal body text
5. WHEN a user presses Enter at the end of a heading, THEN the system SHALL create a new normal paragraph (not another heading)

### Requirement 3

**User Story:** As a writer, I want to create bulleted and numbered lists, so that I can organize information and outline plot points within my chapters.

#### Acceptance Criteria

1. WHEN a user clicks the bullet list button, THEN the system SHALL convert the current paragraph to a bulleted list item
2. WHEN a user clicks the numbered list button, THEN the system SHALL convert the current paragraph to a numbered list item
3. WHEN a user presses Enter at the end of a list item, THEN the system SHALL create a new list item with the same list type
4. WHEN a user presses Enter twice on an empty list item, THEN the system SHALL exit the list and create a normal paragraph
5. WHEN a user presses Tab within a list item, THEN the system SHALL indent the list item to create a nested sub-list
6. WHEN a user presses Shift+Tab within an indented list item, THEN the system SHALL outdent the list item to the previous level
7. WHEN a user creates a numbered list with multiple items, THEN the system SHALL automatically maintain sequential numbering

### Requirement 4

**User Story:** As a writer, I want to align text left, center, right, or justify, so that I can format special sections like titles, quotes, or letters within my story.

#### Acceptance Criteria

1. WHEN a user selects a paragraph and clicks the left align button, THEN the system SHALL align the paragraph to the left margin
2. WHEN a user selects a paragraph and clicks the center align button, THEN the system SHALL center the paragraph horizontally
3. WHEN a user selects a paragraph and clicks the right align button, THEN the system SHALL align the paragraph to the right margin
4. WHEN a user selects a paragraph and clicks the justify button, THEN the system SHALL justify the paragraph with even spacing
5. WHEN a user selects multiple paragraphs and applies alignment, THEN the system SHALL apply the alignment to all selected paragraphs

### Requirement 5

**User Story:** As a writer, I want to change text color and highlight color, so that I can mark sections for revision or add visual emphasis to specific passages.

#### Acceptance Criteria

1. WHEN a user selects text and chooses a color from the text color picker, THEN the system SHALL apply that color to the selected text
2. WHEN a user selects text and chooses a color from the highlight color picker, THEN the system SHALL apply a background highlight color to the selected text
3. WHEN a user clicks the text color button with no color selected, THEN the system SHALL display a color picker with common colors and a custom color option
4. WHEN a user clicks the highlight color button with no color selected, THEN the system SHALL display a color picker with common highlight colors and a "no highlight" option
5. WHEN a user applies both text color and highlight color to the same text, THEN the system SHALL render both styles simultaneously

### Requirement 6

**User Story:** As a writer, I want to adjust font size for specific text, so that I can create visual variety and emphasis in my manuscript.

#### Acceptance Criteria

1. WHEN a user selects text and chooses a font size from the size dropdown, THEN the system SHALL apply that font size to the selected text
2. WHEN a user selects text and clicks the increase font size button, THEN the system SHALL increase the font size by 2 points
3. WHEN a user selects text and clicks the decrease font size button, THEN the system SHALL decrease the font size by 2 points
4. WHEN the font size dropdown is opened, THEN the system SHALL display common sizes (8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72)
5. WHEN a user types a custom font size in the dropdown, THEN the system SHALL accept any size between 6 and 200 points

### Requirement 7

**User Story:** As a writer, I want to insert block quotes, so that I can format letters, documents, or quoted passages within my narrative.

#### Acceptance Criteria

1. WHEN a user selects one or more paragraphs and clicks the block quote button, THEN the system SHALL convert those paragraphs to block quotes with left indentation and distinct styling
2. WHEN a user presses Enter at the end of a block quote, THEN the system SHALL create a new block quote paragraph
3. WHEN a user presses Enter twice on an empty block quote paragraph, THEN the system SHALL exit the block quote and create a normal paragraph
4. WHEN a block quote is rendered, THEN the system SHALL display it with a left border, increased left padding, and subtle background color

### Requirement 8

**User Story:** As a writer, I want to insert horizontal rules (dividers), so that I can create visual scene breaks or section separators in my chapters.

#### Acceptance Criteria

1. WHEN a user clicks the horizontal rule button or types "---" followed by Enter, THEN the system SHALL insert a horizontal divider line
2. WHEN a horizontal rule is inserted, THEN the system SHALL create a new paragraph below it for continued writing
3. WHEN a user clicks on a horizontal rule, THEN the system SHALL allow deletion via Backspace or Delete key
4. WHEN a horizontal rule is rendered, THEN the system SHALL display it as a centered line spanning 80% of the editor width

### Requirement 9

**User Story:** As a writer, I want the formatting toolbar to show the current formatting state, so that I can see what styles are applied to my selected text.

#### Acceptance Criteria

1. WHEN a user selects text with bold formatting, THEN the system SHALL highlight the bold button in the toolbar
2. WHEN a user selects text with multiple formatting styles, THEN the system SHALL highlight all corresponding buttons in the toolbar
3. WHEN a user places the cursor in a heading, THEN the system SHALL display the heading level in the format dropdown
4. WHEN a user places the cursor in a list item, THEN the system SHALL highlight the corresponding list button in the toolbar
5. WHEN a user selects text with mixed formatting (some bold, some not), THEN the system SHALL show the bold button in an indeterminate state

### Requirement 10

**User Story:** As a writer, I want all formatting to be preserved when I save and reopen my chapters, so that my formatting work is not lost between editing sessions.

#### Acceptance Criteria

1. WHEN a user applies formatting to text and saves the chapter, THEN the system SHALL serialize all formatting attributes to the storage format
2. WHEN a user reopens a chapter with formatted content, THEN the system SHALL restore all formatting exactly as it was saved
3. WHEN the system serializes formatted content, THEN the system SHALL use a JSON structure that preserves all inline and block styles
4. WHEN the system deserializes formatted content, THEN the system SHALL handle missing or invalid formatting attributes gracefully by using default values
5. WHEN a user exports or shares chapter content, THEN the system SHALL maintain formatting in the exported format

### Requirement 11

**User Story:** As a writer, I want formatting to work seamlessly with the existing entity highlighting system, so that I can format text without losing entity recognition.

#### Acceptance Criteria

1. WHEN a user applies formatting to text that contains recognized entities, THEN the system SHALL preserve entity highlighting alongside the formatting
2. WHEN a user applies bold formatting to an entity name, THEN the system SHALL display both the bold style and the entity underline
3. WHEN a user hovers over a formatted entity, THEN the system SHALL display the entity tooltip with correct positioning
4. WHEN the entity recognition system updates, THEN the system SHALL preserve all user-applied formatting
5. WHEN a user applies text color to an entity, THEN the system SHALL display the text color while maintaining the entity underline decoration

### Requirement 12

**User Story:** As a writer, I want to clear all formatting from selected text, so that I can quickly remove unwanted styles and return to plain text.

#### Acceptance Criteria

1. WHEN a user selects formatted text and clicks the "Clear Formatting" button, THEN the system SHALL remove all inline formatting while preserving the text content
2. WHEN a user clears formatting from a heading, THEN the system SHALL convert it to a normal paragraph
3. WHEN a user clears formatting from a list item, THEN the system SHALL convert it to a normal paragraph
4. WHEN a user clears formatting from text with entity attributions, THEN the system SHALL preserve the entity attributions
5. WHEN a user clears formatting, THEN the system SHALL preserve paragraph breaks and document structure

### Requirement 13

**User Story:** As a writer, I want to use standard editing keyboard shortcuts, so that I can work efficiently without interrupting my writing flow.

#### Acceptance Criteria

1. WHEN a user presses Cmd+Z (Ctrl+Z on Windows), THEN the system SHALL undo the last formatting change
2. WHEN a user presses Cmd+Shift+Z (Ctrl+Shift+Z on Windows), THEN the system SHALL redo the last undone formatting change
3. WHEN a user presses Cmd+A (Ctrl+A on Windows), THEN the system SHALL select all text in the current chapter
4. WHEN a user presses Cmd+C/X/V (Ctrl+C/X/V on Windows), THEN the system SHALL copy/cut/paste text with formatting preserved

**Note:** Custom formatting keyboard shortcuts (Cmd+B for bold, Cmd+I for italic, etc.) are not currently supported due to API limitations in super_editor 0.3.0-dev.40. The underlying editor command system has changed significantly, making it infeasible to implement custom keyboard actions without extensive workarounds. Users can apply formatting via toolbar buttons.

### Requirement 14

**User Story:** As a writer, I want the formatting toolbar to be responsive and accessible, so that I can use it effectively on different screen sizes and with keyboard navigation.

#### Acceptance Criteria

1. WHEN the editor window is resized to a narrow width, THEN the system SHALL adapt the toolbar layout to fit available space
2. WHEN a user navigates the toolbar with Tab key, THEN the system SHALL move focus between toolbar buttons in logical order
3. WHEN a toolbar button has focus and the user presses Enter or Space, THEN the system SHALL activate that formatting action
4. WHEN a user opens a dropdown menu in the toolbar, THEN the system SHALL allow keyboard navigation with arrow keys
5. WHEN the toolbar is displayed, THEN the system SHALL ensure all buttons have appropriate tooltips describing their function
