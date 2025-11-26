import 'package:super_editor/super_editor.dart';
import '../models/entity.dart';
import 'entity_recognizer.dart';
import 'ai_entity_recognizer.dart';

/// Attribution for recognized entities
class EntityAttribution implements Attribution {
  const EntityAttribution(this.entity);

  final Entity entity;

  @override
  String get id => 'entity-${entity.name}-${entity.startOffset}';

  @override
  bool canMergeWith(Attribution other) {
    return false; // Each entity is unique
  }
}

/// Service to apply entity attributions to document nodes
/// Supports both local and AI-powered entity recognition
class EntityAttributionService {
  final EntityRecognizer recognizer;

  // Callback to notify when document needs update after AI extraction
  void Function()? onEntitiesUpdated;

  EntityAttributionService(this.recognizer) {
    // If this is an AI recognizer, set up the callback for async updates
    if (recognizer is AIEntityRecognizer) {
      (recognizer as AIEntityRecognizer).onEntitiesExtracted = (entities) {
        // When AI extracts entities, notify that we need to update
        onEntitiesUpdated?.call();
      };
    }
  }

  /// Apply entity attributions to a paragraph node's text
  void applyEntityAttributions(ParagraphNode node) {
    final plainText = node.text.toPlainText();
    final entities = recognizer.recognizeEntities(plainText);

    // Remove all existing entity attributions
    _removeEntityAttributions(node);

    // Apply new entity attributions
    for (final entity in entities) {
      final attribution = EntityAttribution(entity);
      node.text.addAttribution(
        attribution,
        SpanRange(entity.startOffset, entity.endOffset - 1),
      );
    }
  }

  /// Remove all entity attributions from a node
  void _removeEntityAttributions(ParagraphNode node) {
    final text = node.text.toPlainText();
    if (text.isEmpty) return;

    // Collect all entity attributions to remove
    final attributionsToRemove = <EntityAttribution>{};
    for (var i = 0; i < text.length; i++) {
      final attributions = node.text.getAllAttributionsAt(i);
      for (final attribution in attributions) {
        if (attribution is EntityAttribution) {
          attributionsToRemove.add(attribution);
        }
      }
    }

    // Remove each unique entity attribution across its entire span
    for (final attribution in attributionsToRemove) {
      node.text.removeAttribution(attribution, SpanRange(0, text.length - 1));
    }
  }

  /// Apply attributions to all paragraph nodes in a document
  void applyToDocument(Document document) {
    // First, build full document text for AI extraction
    if (recognizer is AIEntityRecognizer) {
      final buffer = StringBuffer();
      for (var i = 0; i < document.nodeCount; i++) {
        final node = document.getNodeAt(i);
        if (node is ParagraphNode) {
          if (buffer.isNotEmpty) buffer.write('\n');
          buffer.write(node.text.toPlainText());
        }
      }
      final fullText = buffer.toString();
      // Set full document text for document-level AI extraction
      (recognizer as AIEntityRecognizer).setDocumentText(fullText);
    }

    // Then apply attributions to each paragraph
    for (var i = 0; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node is ParagraphNode) {
        applyEntityAttributions(node);
      }
    }
  }

  /// Dispose resources (cancel AI extraction timer if needed)
  void dispose() {
    if (recognizer is AIEntityRecognizer) {
      (recognizer as AIEntityRecognizer).dispose();
    }
  }
}
