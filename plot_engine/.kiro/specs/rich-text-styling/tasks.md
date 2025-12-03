# Implementation Plan

- [ ] 1. Create custom attribution classes for formatting
  - Define BoldAttribution, ItalicAttribution, UnderlineAttribution, StrikethroughAttribution classes
  - Define TextColorAttribution and HighlightColorAttribution with color properties
  - Define FontSizeAttribution with size property
  - Add equality and hashCode implementations for all attributions
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.1, 5.2, 6.1_

- [ ] 1.1 Write property test for inline style application
  - **Property 1: Inline style application**
  - **Validates: Requirements 1.1, 1.2, 1.3, 1.4**

- [ ] 2. Implement block-level metadata structures
  - Create HeadingLevel enum (h1, h2, h3)
  - Create ListType enum (unordered, ordered)
  - Create TextAlignment enum (left, center, right, justify)
  - Create BlockMetadata class with all block-level properties
  - Implement toJson/fromJson for BlockMetadata
  - _Requirements: 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 7.1_

- [ ] 3. Create formatting command classes
  - Implement ToggleInlineStyleCommand for inline formatting
  - Implement ChangeBlockTypeCommand for headings and block quotes
  - Implement ToggleListCommand for list creation
  - Implement SetTextAlignmentCommand for alignment
  - Implement ClearFormattingCommand for removing all formatting
  - Add command execution logic to integrate with super_editor's Editor
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 3.1, 4.1, 12.1_

- [ ] 3.1 Write property test for style toggle behavior
  - **Property 4: Style toggle behavior**
  - **Validates: Requirements 1.7**

- [ ] 3.2 Write property test for multiple inline styles coexist
  - **Property 2: Multiple inline styles coexist**
  - **Validates: Requirements 1.5**

- [ ] 4. Enhance stylesheet factory with formatting support
  - Extend EditorStylesheetFactory to create enhanced stylesheets
  - Implement heading style rules (H1, H2, H3 with appropriate sizes)
  - Implement list style rules (bullet and numbered with indentation)
  - Implement block quote style rules (border, padding, background)
  - Implement alignment style rules
  - Update inline text styler to handle new attributions (bold, italic, underline, strikethrough, colors, font size)
  - Ensure entity highlighting works alongside formatting
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 6.1, 7.1, 11.1, 11.2, 11.5_

- [ ] 4.1 Write property test for entity and formatting coexistence
  - **Property 21: Entity and formatting coexistence**
  - **Validates: Requirements 11.1, 11.2, 11.5**

- [ ] 5. Create FormattingToolbar widget
  - Create FormattingToolbar stateful widget that accepts Editor and DocumentComposer
  - Implement toolbar layout with proper spacing and grouping
  - Add listener to composer for selection changes
  - Implement FormattingState extraction from current selection
  - Create toolbar state update logic
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

- [ ] 5.1 Write property test for toolbar reflects selection formatting
  - **Property 26: Toolbar reflects selection formatting**
  - **Validates: Requirements 9.1, 9.2, 9.3, 9.4**

- [ ] 6. Implement inline style button group
  - Create InlineStyleButtonGroup widget with bold, italic, underline, strikethrough buttons
  - Implement button press handlers that execute ToggleInlineStyleCommand
  - Add visual highlighting for active styles
  - Add tooltips with keyboard shortcuts
  - Handle indeterminate state for mixed formatting
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.7, 9.1, 9.5_

- [ ] 7. Implement block style dropdown
  - Create BlockStyleDropdown widget with options: Normal, Heading 1, Heading 2, Heading 3, Block Quote
  - Implement dropdown selection handler that executes ChangeBlockTypeCommand
  - Display current block type in dropdown
  - Add keyboard shortcut hints in dropdown items
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 7.1, 9.3_

- [ ] 7.1 Write property test for heading level application
  - **Property 5: Heading level application**
  - **Validates: Requirements 2.1, 2.2, 2.3**

- [ ] 7.2 Write property test for normal paragraph conversion
  - **Property 6: Normal paragraph conversion**
  - **Validates: Requirements 2.4, 12.2, 12.3**

- [ ] 8. Implement list button group
  - Create ListButtonGroup widget with bullet and numbered list buttons
  - Implement button press handlers that execute ToggleListCommand
  - Add visual highlighting for active list type
  - Add tooltips with keyboard shortcuts
  - _Requirements: 3.1, 3.2, 9.4_

- [ ] 8.1 Write property test for list type conversion
  - **Property 8: List type conversion**
  - **Validates: Requirements 3.1, 3.2**

- [ ] 8.2 Write property test for sequential numbering
  - **Property 10: Sequential numbering**
  - **Validates: Requirements 3.7**

- [ ] 9. Implement list indentation logic
  - Add Tab key handler for list indentation
  - Add Shift+Tab key handler for list outdentation
  - Update list item metadata with indent level
  - Update stylesheet to render indentation visually
  - _Requirements: 3.5, 3.6_

- [ ] 9.1 Write property test for list indentation
  - **Property 9: List indentation**
  - **Validates: Requirements 3.5, 3.6**

- [ ] 10. Implement alignment button group
  - Create AlignmentButtonGroup widget with left, center, right, justify buttons
  - Implement button press handlers that execute SetTextAlignmentCommand
  - Add visual highlighting for active alignment
  - Add tooltips with keyboard shortcuts
  - Handle multi-paragraph selections
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 9.3_

- [ ] 10.1 Write property test for text alignment application
  - **Property 11: Text alignment application**
  - **Validates: Requirements 4.1, 4.2, 4.3, 4.4**

- [ ] 10.2 Write property test for multi-paragraph alignment
  - **Property 12: Multi-paragraph alignment**
  - **Validates: Requirements 4.5**

- [ ] 11. Implement color picker components
  - Create ColorPickerButton widget for text color
  - Create ColorPickerButton widget for highlight color
  - Implement color palette with common colors
  - Add custom color input option
  - Implement color application via ToggleInlineStyleCommand
  - Add color preview in button
  - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 11.1 Write property test for color application
  - **Property 13: Color application**
  - **Validates: Requirements 5.1, 5.2**

- [ ] 11.2 Write property test for multiple color attributions
  - **Property 14: Multiple color attributions**
  - **Validates: Requirements 5.5**

- [ ] 12. Implement font size selector
  - Create FontSizeSelector dropdown widget
  - Add common font sizes (8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48, 72)
  - Add custom size input with validation (6-200 range)
  - Implement increase/decrease font size buttons
  - Implement font size application via ToggleInlineStyleCommand
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 12.1 Write property test for font size application
  - **Property 15: Font size application**
  - **Validates: Requirements 6.1, 6.5**

- [ ] 12.2 Write property test for relative font size adjustment
  - **Property 16: Relative font size adjustment**
  - **Validates: Requirements 6.2, 6.3**

- [ ] 13. Implement clear formatting button
  - Create ClearFormattingButton widget
  - Implement button press handler that executes ClearFormattingCommand
  - Ensure entity attributions are preserved
  - Ensure document structure is preserved
  - Add tooltip with keyboard shortcut
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5_

- [ ] 13.1 Write property test for clear formatting removes styles
  - **Property 23: Clear formatting removes styles**
  - **Validates: Requirements 12.1**

- [ ] 13.2 Write property test for clear formatting preserves entities
  - **Property 24: Clear formatting preserves entities**
  - **Validates: Requirements 12.4**

- [ ] 13.3 Write property test for clear formatting preserves structure
  - **Property 25: Clear formatting preserves structure**
  - **Validates: Requirements 12.5**

- [ ] 14. Implement keyboard shortcuts
  - Add keyboard action for Cmd+B / Ctrl+B (bold)
  - Add keyboard action for Cmd+I / Ctrl+I (italic)
  - Add keyboard action for Cmd+U / Ctrl+U (underline)
  - Add keyboard action for Cmd+Alt+1/2/3 (headings)
  - Add keyboard action for Cmd+Shift+8 (bullet list)
  - Add keyboard action for Cmd+Shift+7 (numbered list)
  - Add keyboard action for Cmd+Shift+L/E/R/J (alignment)
  - Add keyboard action for Cmd+\\ (clear formatting)
  - Integrate keyboard actions with super_editor's keyboardActions
  - _Requirements: 1.1, 1.2, 1.3, 2.6, 3.1, 3.2, 4.1, 4.2, 4.3, 4.4, 12.1, 13.1_

- [ ] 14.1 Write property test for keyboard shortcut mapping
  - **Property 7: Keyboard shortcut mapping**
  - **Validates: Requirements 2.6, 13.1**

- [ ] 15. Implement horizontal rule support
  - Create HorizontalRuleNode class extending DocumentNode
  - Add horizontal rule insertion command
  - Add "---" + Enter autoformat detection
  - Implement horizontal rule rendering in stylesheet
  - Add deletion support for horizontal rules
  - _Requirements: 8.1, 8.2, 8.3, 8.4_

- [ ] 16. Implement special Enter key behaviors
  - Add Enter key handler for headings (creates normal paragraph)
  - Add Enter key handler for lists (creates new list item)
  - Add double Enter handler for lists (exits list)
  - Add Enter key handler for block quotes (creates new block quote paragraph)
  - Add double Enter handler for block quotes (exits block quote)
  - _Requirements: 2.5, 3.3, 3.4, 7.2, 7.3_

- [ ] 17. Create serialization service
  - Implement FormattedContentSerializer class
  - Implement serializeDocument method that converts Document to JSON
  - Implement deserializeDocument method that converts JSON to Document nodes
  - Implement serializeNode method for individual nodes with attributions
  - Implement deserializeNode method with error handling
  - Handle all attribution types in serialization
  - Handle all block metadata in serialization
  - _Requirements: 10.1, 10.3_

- [ ] 17.1 Write property test for formatting serialization completeness
  - **Property 18: Formatting serialization completeness**
  - **Validates: Requirements 10.1, 10.3**

- [ ] 17.2 Write property test for formatting round-trip preservation
  - **Property 19: Formatting round-trip preservation**
  - **Validates: Requirements 10.2**

- [ ] 17.3 Write property test for graceful deserialization
  - **Property 20: Graceful deserialization**
  - **Validates: Requirements 10.4**

- [ ] 18. Integrate serialization with save/load
  - Update EditorPanel to use FormattedContentSerializer for saving
  - Update EditorPanel to use FormattedContentSerializer for loading
  - Update _parseContentToNodes to use deserializeDocument
  - Update _getDocumentContent to use serializeDocument
  - Ensure auto-save preserves formatting
  - _Requirements: 10.1, 10.2_

- [ ] 19. Integrate FormattingToolbar into EditorPanel
  - Add FormattingToolbar widget above SuperEditor in EditorPanel
  - Pass editor and composer to FormattingToolbar
  - Update EditorPanel layout to accommodate toolbar
  - Ensure toolbar only shows for chapter tabs (not entity tabs)
  - _Requirements: All formatting requirements_

- [ ] 20. Add pending style support
  - Implement pending style state in composer
  - Update inline style commands to set pending styles when no selection
  - Update text input to apply pending styles to new characters
  - Clear pending styles when cursor moves
  - _Requirements: 1.6_

- [ ] 20.1 Write property test for pending style application
  - **Property 3: Pending style application**
  - **Validates: Requirements 1.6**

- [ ] 21. Implement clipboard formatting preservation
  - Ensure copy operation includes formatting attributions
  - Ensure paste operation restores formatting attributions
  - Handle paste from external sources (plain text fallback)
  - _Requirements: 13.5_

- [ ] 21.1 Write property test for clipboard preserves formatting
  - **Property 28: Clipboard preserves formatting**
  - **Validates: Requirements 13.5**

- [ ] 22. Add entity update preservation
  - Ensure entity recognition updates don't remove formatting
  - Update EntityAttributionService to preserve formatting attributions
  - Test formatting + entity highlighting rendering
  - _Requirements: 11.4_

- [ ] 22.1 Write property test for entity update preserves formatting
  - **Property 22: Entity update preserves formatting**
  - **Validates: Requirements 11.4**

- [ ] 23. Implement responsive toolbar layout
  - Add responsive breakpoints for toolbar
  - Implement toolbar overflow menu for narrow widths
  - Test toolbar on mobile, tablet, and desktop sizes
  - _Requirements: 14.1_

- [ ] 24. Add keyboard navigation to toolbar
  - Implement Tab navigation between toolbar buttons
  - Implement Enter/Space activation for focused buttons
  - Implement arrow key navigation in dropdowns
  - Add focus indicators for keyboard navigation
  - _Requirements: 14.2, 14.3, 14.4_

- [ ] 25. Add tooltips and accessibility
  - Add tooltips to all toolbar buttons with descriptions
  - Add keyboard shortcut hints to tooltips
  - Add ARIA labels for screen readers
  - Test with screen reader
  - _Requirements: 14.5_

- [ ] 26. Add translations for formatting UI
  - Add translation keys for all toolbar button labels
  - Add translation keys for tooltips
  - Add translation keys for dropdown options
  - Add translation keys for error messages
  - Add translations for all supported languages (en, zh, fr, etc.)
  - _Requirements: All requirements (UI text)_

- [ ] 27. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 28. Write unit tests for edge cases
  - Test empty document formatting
  - Test single character formatting
  - Test very long text with many attributions
  - Test rapid style toggling
  - Test font size boundaries (6, 200)
  - Test malformed JSON deserialization
  - Test unknown attribution types
  - Test null selection handling

- [ ] 29. Write integration tests for workflows
  - Test complete formatting workflow: create → format → save → reload → verify
  - Test toolbar integration: click button → verify command → verify UI
  - Test keyboard shortcuts: press shortcut → verify formatting → verify toolbar
  - Test entity integration: format entity → verify both attributions → verify rendering

- [ ] 30. Write widget tests for UI components
  - Test FormattingToolbar renders correctly
  - Test toolbar updates on selection change
  - Test color picker displays and applies colors
  - Test font size selector validates input
  - Test all buttons execute correct commands
