import '../models/entity_metadata.dart';
import '../models/entity_type.dart';

class EntityStore {
  final Map<String, EntityMetadata> _entitiesById = {}; // ID -> Entity
  final Map<String, String> _nameToId = {}; // lowercase name -> ID (for quick lookups)

  EntityStore();

  void save(EntityMetadata metadata) {
    _entitiesById[metadata.id] = metadata;
    _nameToId[metadata.name.toLowerCase()] = metadata.id;
  }

  EntityMetadata? get(String name) {
    final id = _nameToId[name.toLowerCase()];
    return id != null ? _entitiesById[id] : null;
  }

  EntityMetadata? getById(String id) {
    return _entitiesById[id];
  }

  bool exists(String name) {
    return _nameToId.containsKey(name.toLowerCase());
  }

  List<EntityMetadata> getAll() {
    return _entitiesById.values.toList();
  }

  List<EntityMetadata> getByType(EntityType type) {
    return _entitiesById.values.where((m) => m.type == type).toList();
  }

  List<EntityMetadata> getByCustomType(String customType) {
    return _entitiesById.values
        .where((m) => m.type == EntityType.custom && m.customType == customType)
        .toList();
  }

  void delete(String name) {
    final id = _nameToId[name.toLowerCase()];
    if (id != null) {
      _entitiesById.remove(id);
      _nameToId.remove(name.toLowerCase());
    }
  }

  void deleteById(String id) {
    final entity = _entitiesById[id];
    if (entity != null) {
      _entitiesById.remove(id);
      _nameToId.remove(entity.name.toLowerCase());
    }
  }

  void clear() {
    _entitiesById.clear();
    _nameToId.clear();
  }

  void setAll(List<EntityMetadata> entities) {
    clear();
    for (final entity in entities) {
      save(entity);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'entities': _entitiesById.values.map((m) => m.toJson()).toList(),
    };
  }

  void fromJson(Map<String, dynamic> json) {
    clear();
    final entities = json['entities'] as List<dynamic>?;
    if (entities != null) {
      for (final entity in entities) {
        final metadata = EntityMetadata.fromJson(entity as Map<String, dynamic>);
        save(metadata);
      }
    }
  }
}
