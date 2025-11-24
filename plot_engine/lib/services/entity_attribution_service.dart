import 'package:super_editor/super_editor.dart';
import '../models/entity.dart';
import 'local_entity_recognizer.dart';

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
class EntityAttributionService {
  final LocalEntityRecognizer recognizer;

  EntityAttributionService(this.recognizer);

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
    for (var i = 0; i < document.nodeCount; i++) {
      final node = document.getNodeAt(i);
      if (node is ParagraphNode) {
        applyEntityAttributions(node);
      }
    }
  }
}
