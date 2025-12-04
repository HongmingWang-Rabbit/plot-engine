/// Serialization service for formatted document content
/// 
/// This service handles converting super_editor Document objects to/from JSON
/// while preserving all formatting attributions and block metadata.
library;

import 'dart:ui';
import 'package:super_editor/super_editor.dart';
import 'block_metadata.dart';
import 'entity_attribution_service.dart';
import '../models/entity.dart';
import '../models/entity_type.dart';

/// Service for serializing and deserializing formatted document content
class FormattedContentSerializer {
  FormattedContentSerializer._();

  /// Serialize a Document to JSON with all formatting preserved
  static Map<String, dynamic> serializeDocument(Document document) {
    final nodes = <Map<String, dynamic>>[];
    
    for (int i = 0; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node != null) {
        nodes.add(serializeNode(node));
      }
    }
    
    return {
      'version': '1.0',
      'nodes': nodes,
    };
  }

  /// Serialize a list of nodes to JSON (for clipboard operations)
  static Map<String, dynamic> serializeNodes(List<DocumentNode> nodes) {
    final nodesJson = <Map<String, dynamic>>[];
    
    for (final node in nodes) {
      nodesJson.add(serializeNode(node));
    }
    
    return {
      'version': '1.0',
      'nodes': nodesJson,
    };
  }

  /// Deserialize a list of nodes from JSON (for clipboard operations)
  static List<DocumentNode> deserializeNodes(Map<String, dynamic> json) {
    return deserializeDocument(json);
  }

  /// Deserialize JSON to a list of DocumentNode objects
  static List<DocumentNode> deserializeDocument(Map<String, dynamic> json) {
    try {
      final version = json['version'] as String?;
      if (version != '1.0') {
        // Log warning but continue with default handling
        print('[Serializer] Unknown version: $version, attempting to deserialize anyway');
      }
      
      final nodesJson = json['nodes'] as List?;
      if (nodesJson == null || nodesJson.isEmpty) {
        // Return default empty paragraph
        return [
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText(''),
          ),
        ];
      }
      
      final nodes = <DocumentNode>[];
      for (final nodeJson in nodesJson) {
        try {
          final node = deserializeNode(nodeJson as Map<String, dynamic>);
          if (node != null) {
            nodes.add(node);
          }
        } catch (e) {
          print('[Serializer] Error deserializing node: $e, skipping node');
          // Continue with other nodes
        }
      }
      
      // If all nodes failed to deserialize, return default
      if (nodes.isEmpty) {
        return [
          ParagraphNode(
            id: Editor.createNodeId(),
            text: AttributedText(''),
          ),
        ];
      }
      
      return nodes;
    } catch (e) {
      print('[Serializer] Error deserializing document: $e, returning default');
      // Return default empty paragraph on any error
      return [
        ParagraphNode(
          id: Editor.createNodeId(),
          text: AttributedText(''),
        ),
      ];
    }
  }

  /// Serialize a single DocumentNode to JSON
  static Map<String, dynamic> serializeNode(DocumentNode node) {
    final json = <String, dynamic>{
      'id': node.id,
    };
    
    if (node is ParagraphNode) {
      json['type'] = 'paragraph';
      json['text'] = node.text.toPlainText();
      json['attributions'] = _serializeAttributions(node.text);
      
      // Serialize block metadata if present
      final metadata = node.metadata['blockMetadata'];
      if (metadata is BlockMetadata && metadata.hasFormatting) {
        json['metadata'] = metadata.toJson();
      }
    } else if (node is HorizontalRuleNode) {
      json['type'] = 'horizontalRule';
    } else {
      // Unknown node type - serialize as paragraph with plain text if possible
      json['type'] = 'unknown';
      if (node is TextNode) {
        json['text'] = node.text.toPlainText();
      }
    }
    
    return json;
  }

  /// Deserialize a single node from JSON
  static DocumentNode? deserializeNode(Map<String, dynamic> json) {
    try {
      final id = json['id'] as String?;
      final type = json['type'] as String?;
      
      if (id == null || type == null) {
        print('[Serializer] Missing id or type in node JSON');
        return null;
      }
      
      switch (type) {
        case 'paragraph':
          return _deserializeParagraphNode(id, json);
        case 'horizontalRule':
          return HorizontalRuleNode(id: id);
        case 'unknown':
          // Try to recover as paragraph
          final text = json['text'] as String? ?? '';
          return ParagraphNode(
            id: id,
            text: AttributedText(text),
          );
        default:
          print('[Serializer] Unknown node type: $type, treating as paragraph');
          final text = json['text'] as String? ?? '';
          return ParagraphNode(
            id: id,
            text: AttributedText(text),
          );
      }
    } catch (e) {
      print('[Serializer] Error deserializing node: $e');
      return null;
    }
  }

  /// Deserialize a paragraph node with attributions and metadata
  static ParagraphNode _deserializeParagraphNode(
    String id,
    Map<String, dynamic> json,
  ) {
    final text = json['text'] as String? ?? '';
    final attributionsJson = json['attributions'] as List?;
    final metadataJson = json['metadata'] as Map<String, dynamic>?;
    
    // Create attributed text with attributions
    final attributedText = AttributedText(text);
    if (attributionsJson != null) {
      _deserializeAttributions(attributedText, attributionsJson);
    }
    
    // Create node
    final node = ParagraphNode(
      id: id,
      text: attributedText,
    );
    
    // Apply block metadata if present
    if (metadataJson != null) {
      try {
        final metadata = BlockMetadata.fromJson(metadataJson);
        node.metadata['blockMetadata'] = metadata;
      } catch (e) {
        print('[Serializer] Error deserializing metadata: $e, using defaults');
        // Continue without metadata
      }
    }
    
    return node;
  }

  /// Serialize attributions from AttributedText
  static List<Map<String, dynamic>> _serializeAttributions(AttributedText text) {
    final attributions = <Map<String, dynamic>>[];
    final allSpans = text.getAttributionSpansInRange(
      attributionFilter: (_) => true,
      range: SpanRange(0, text.length - 1),
    );
    
    for (final span in allSpans) {
      final attribution = span.attribution;
      final attributionJson = _serializeAttribution(attribution);
      
      if (attributionJson != null) {
        attributions.add({
          'start': span.start,
          'end': span.end,
          ...attributionJson,
        });
      }
    }
    
    return attributions;
  }

  /// Serialize a single attribution
  static Map<String, dynamic>? _serializeAttribution(Attribution attribution) {
    // Bold
    if (attribution == boldAttribution) {
      return {'type': 'bold'};
    }
    // Italic
    else if (attribution == italicsAttribution) {
      return {'type': 'italic'};
    }
    // Underline
    else if (attribution == underlineAttribution) {
      return {'type': 'underline'};
    }
    // Strikethrough
    else if (attribution == strikethroughAttribution) {
      return {'type': 'strikethrough'};
    }
    // Text color
    else if (attribution is ColorAttribution) {
      return {
        'type': 'textColor',
        'color': attribution.color.value,
      };
    }
    // Highlight color (background)
    else if (attribution is BackgroundColorAttribution) {
      return {
        'type': 'highlightColor',
        'color': attribution.color.value,
      };
    }
    // Font size
    else if (attribution is FontSizeAttribution) {
      return {
        'type': 'fontSize',
        'size': attribution.fontSize,
      };
    }
    // Entity attribution - preserve for entity highlighting
    else if (attribution is EntityAttribution) {
      return {
        'type': 'entity',
        'entityName': attribution.entity.name,
        'entityType': attribution.entity.type.name,
        'recognized': attribution.entity.recognized,
      };
    }
    // Unknown attribution type - skip it
    else {
      print('[Serializer] Unknown attribution type: ${attribution.runtimeType}, skipping');
      return null;
    }
  }

  /// Deserialize attributions and apply them to AttributedText
  static void _deserializeAttributions(
    AttributedText text,
    List attributionsJson,
  ) {
    for (final attrJson in attributionsJson) {
      try {
        final attrMap = attrJson as Map<String, dynamic>;
        final start = attrMap['start'] as int?;
        final end = attrMap['end'] as int?;
        final type = attrMap['type'] as String?;
        
        if (start == null || end == null || type == null) {
          print('[Serializer] Invalid attribution JSON, skipping');
          continue;
        }
        
        // Validate range
        if (start < 0 || end >= text.length || start > end) {
          print('[Serializer] Invalid attribution range ($start-$end), skipping');
          continue;
        }
        
        final attribution = _deserializeAttribution(type, attrMap);
        if (attribution != null) {
          text.addAttribution(attribution, SpanRange(start, end));
        }
      } catch (e) {
        print('[Serializer] Error deserializing attribution: $e, skipping');
        // Continue with other attributions
      }
    }
  }

  /// Deserialize a single attribution from JSON
  static Attribution? _deserializeAttribution(
    String type,
    Map<String, dynamic> json,
  ) {
    try {
      switch (type) {
        case 'bold':
          return boldAttribution;
        case 'italic':
          return italicsAttribution;
        case 'underline':
          return underlineAttribution;
        case 'strikethrough':
          return strikethroughAttribution;
        case 'textColor':
          final colorValue = json['color'] as int?;
          if (colorValue == null) return null;
          return ColorAttribution(Color(colorValue));
        case 'highlightColor':
          final colorValue = json['color'] as int?;
          if (colorValue == null) return null;
          return BackgroundColorAttribution(Color(colorValue));
        case 'fontSize':
          final size = json['size'] as num?;
          if (size == null) return null;
          return FontSizeAttribution(size.toDouble());
        case 'entity':
          // Reconstruct entity attribution
          final entityName = json['entityName'] as String?;
          final entityTypeStr = json['entityType'] as String?;
          final recognized = json['recognized'] as bool? ?? false;
          
          if (entityName == null || entityTypeStr == null) return null;
          
          // Parse entity type
          final entityType = EntityType.values.firstWhere(
            (e) => e.name == entityTypeStr,
            orElse: () => EntityType.character, // Default fallback
          );
          
          return EntityAttribution(
            Entity(
              name: entityName,
              type: entityType,
              recognized: recognized,
              startOffset: 0, // Will be set by attribution span
              endOffset: 0, // Will be set by attribution span
            ),
          );
        default:
          print('[Serializer] Unknown attribution type: $type, skipping');
          return null;
      }
    } catch (e) {
      print('[Serializer] Error creating attribution: $e');
      return null;
    }
  }
}
