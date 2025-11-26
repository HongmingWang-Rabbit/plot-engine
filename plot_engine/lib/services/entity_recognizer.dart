import '../models/entity.dart';

/// Base interface for entity recognizers
/// Both LocalEntityRecognizer and AIEntityRecognizer implement this interface
abstract class EntityRecognizer {
  /// Recognize entities in text
  /// Returns immediately recognized entities (from store or cache)
  List<Entity> recognizeEntities(String text);
}
