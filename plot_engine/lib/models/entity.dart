import 'entity_type.dart';
import 'entity_metadata.dart';

class Entity {
  final String name;
  final EntityType type;
  final bool recognized;
  final EntityMetadata? metadata;
  final int startOffset;
  final int endOffset;

  Entity({
    required this.name,
    required this.type,
    required this.recognized,
    this.metadata,
    required this.startOffset,
    required this.endOffset,
  });

  Entity copyWith({
    String? name,
    EntityType? type,
    bool? recognized,
    EntityMetadata? metadata,
    int? startOffset,
    int? endOffset,
  }) {
    return Entity(
      name: name ?? this.name,
      type: type ?? this.type,
      recognized: recognized ?? this.recognized,
      metadata: metadata ?? this.metadata,
      startOffset: startOffset ?? this.startOffset,
      endOffset: endOffset ?? this.endOffset,
    );
  }
}
