/// Block-level metadata structures for rich text formatting
/// 
/// This file defines enums and classes for block-level formatting properties
/// such as headings, lists, alignment, and block quotes.
library;

/// Heading levels for hierarchical document structure
enum HeadingLevel {
  h1,
  h2,
  h3;

  /// Convert heading level to JSON string
  String toJson() => name;

  /// Create heading level from JSON string
  static HeadingLevel? fromJson(String? json) {
    if (json == null) return null;
    try {
      return HeadingLevel.values.firstWhere((e) => e.name == json);
    } catch (e) {
      return null;
    }
  }
}

/// List types for bulleted and numbered lists
enum ListType {
  unordered,
  ordered;

  /// Convert list type to JSON string
  String toJson() => name;

  /// Create list type from JSON string
  static ListType? fromJson(String? json) {
    if (json == null) return null;
    try {
      return ListType.values.firstWhere((e) => e.name == json);
    } catch (e) {
      return null;
    }
  }
}

/// Text alignment options for paragraphs
enum TextAlignment {
  left,
  center,
  right,
  justify;

  /// Convert text alignment to JSON string
  String toJson() => name;

  /// Create text alignment from JSON string
  static TextAlignment? fromJson(String? json) {
    if (json == null) return null;
    try {
      return TextAlignment.values.firstWhere((e) => e.name == json);
    } catch (e) {
      return null;
    }
  }
}

/// Block-level metadata for document nodes
/// 
/// This class encapsulates all block-level formatting properties that can be
/// applied to paragraphs and other document nodes.
class BlockMetadata {
  /// Heading level (h1, h2, h3) if this block is a heading
  final HeadingLevel? headingLevel;

  /// List type (unordered, ordered) if this block is a list item
  final ListType? listType;

  /// Indentation level for nested lists (0 = no indent)
  final int? listIndent;

  /// Text alignment for this block
  final TextAlignment? alignment;

  /// Whether this block is a block quote
  final bool isBlockQuote;

  const BlockMetadata({
    this.headingLevel,
    this.listType,
    this.listIndent,
    this.alignment,
    this.isBlockQuote = false,
  });

  /// Create an empty BlockMetadata with default values
  const BlockMetadata.empty()
      : headingLevel = null,
        listType = null,
        listIndent = null,
        alignment = null,
        isBlockQuote = false;

  /// Create a copy with modified properties
  /// 
  /// To explicitly clear a nullable field, pass null directly.
  /// The method uses a sentinel value to distinguish between "not provided" and "explicitly null".
  BlockMetadata copyWith({
    Object? headingLevel = _undefined,
    Object? listType = _undefined,
    Object? listIndent = _undefined,
    Object? alignment = _undefined,
    Object? isBlockQuote = _undefined,
  }) {
    return BlockMetadata(
      headingLevel: headingLevel == _undefined 
          ? this.headingLevel 
          : headingLevel as HeadingLevel?,
      listType: listType == _undefined 
          ? this.listType 
          : listType as ListType?,
      listIndent: listIndent == _undefined 
          ? this.listIndent 
          : listIndent as int?,
      alignment: alignment == _undefined 
          ? this.alignment 
          : alignment as TextAlignment?,
      isBlockQuote: isBlockQuote == _undefined 
          ? this.isBlockQuote 
          : isBlockQuote as bool? ?? false,
    );
  }

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    
    if (headingLevel != null) {
      json['headingLevel'] = headingLevel!.toJson();
    }
    
    if (listType != null) {
      json['listType'] = listType!.toJson();
    }
    
    if (listIndent != null) {
      json['listIndent'] = listIndent;
    }
    
    if (alignment != null) {
      json['alignment'] = alignment!.toJson();
    }
    
    if (isBlockQuote) {
      json['isBlockQuote'] = isBlockQuote;
    }
    
    return json;
  }

  /// Deserialize from JSON
  factory BlockMetadata.fromJson(Map<String, dynamic> json) {
    return BlockMetadata(
      headingLevel: HeadingLevel.fromJson(json['headingLevel'] as String?),
      listType: ListType.fromJson(json['listType'] as String?),
      listIndent: json['listIndent'] as int?,
      alignment: TextAlignment.fromJson(json['alignment'] as String?),
      isBlockQuote: json['isBlockQuote'] as bool? ?? false,
    );
  }

  /// Check if this metadata has any formatting applied
  bool get hasFormatting {
    return headingLevel != null ||
        listType != null ||
        listIndent != null ||
        alignment != null ||
        isBlockQuote;
  }

  /// Check if this is a heading block
  bool get isHeading => headingLevel != null;

  /// Check if this is a list item
  bool get isList => listType != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlockMetadata &&
        other.headingLevel == headingLevel &&
        other.listType == listType &&
        other.listIndent == listIndent &&
        other.alignment == alignment &&
        other.isBlockQuote == isBlockQuote;
  }

  @override
  int get hashCode {
    return Object.hash(
      headingLevel,
      listType,
      listIndent,
      alignment,
      isBlockQuote,
    );
  }

  @override
  String toString() {
    return 'BlockMetadata('
        'headingLevel: $headingLevel, '
        'listType: $listType, '
        'listIndent: $listIndent, '
        'alignment: $alignment, '
        'isBlockQuote: $isBlockQuote)';
  }
}

/// Sentinel value for undefined parameters in copyWith
const _undefined = Object();
