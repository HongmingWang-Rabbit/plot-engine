import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/entity_update_suggestion.dart';
import '../models/entity_metadata.dart';
import '../models/entity_type.dart';
import '../state/app_state.dart';
import '../l10n/app_localizations.dart';
import '../core/utils/logger.dart';
import 'backend_project_service.dart';

/// Service for managing entity update suggestions and merges
class EntityUpdateService {
  final Ref ref;
  final BackendProjectService _backend;

  EntityUpdateService(this.ref)
      : _backend = ref.read(backendProjectServiceProvider);

  /// Get the current locale from settings
  String get _locale => ref.read(localeProvider).apiLocaleCode;

  /// Check for entity updates based on chapter content
  /// Returns list of suggestions for entities that can be updated
  Future<List<EntityUpdateSuggestion>> checkForUpdates({
    required String chapterContent,
    String? provider,
  }) async {
    final project = ref.read(projectProvider);
    if (project == null) {
      throw Exception('No project is open');
    }

    if (chapterContent.trim().isEmpty) {
      return [];
    }

    try {
      final response = await _backend.suggestEntityUpdates(
        projectId: project.id,
        chapterContent: chapterContent,
        provider: provider,
        locale: _locale,
      );

      AppLogger.info(
        'Entity update suggestions',
        '${response.suggestions.length} suggestions found',
      );

      return response.suggestions;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get entity update suggestions', e, stackTrace);
      rethrow;
    }
  }

  /// Accept a suggestion and merge the new information into the entity
  /// Returns the updated entity metadata
  Future<EntityMetadata> acceptSuggestion({
    required EntityUpdateSuggestion suggestion,
    String? provider,
  }) async {
    final project = ref.read(projectProvider);
    if (project == null) {
      throw Exception('No project is open');
    }

    try {
      // Step 1: Merge the new information using AI
      final mergeResponse = await _backend.mergeEntityUpdate(
        projectId: project.id,
        entityId: suggestion.entityId,
        newInformation: suggestion.suggestedAppendText,
        provider: provider,
        locale: _locale,
      );

      // Step 2: Update the entity with merged content
      await _backend.updateEntity(
        projectId: project.id,
        entityId: suggestion.entityId,
        description: mergeResponse.description,
        summary: mergeResponse.summary,
      );

      // Step 3: Update local entity store
      final entityStore = ref.read(entityStoreProvider);
      final existingEntity = entityStore.getById(suggestion.entityId);

      if (existingEntity != null) {
        final updatedEntity = existingEntity.copyWith(
          description: mergeResponse.description,
          summary: mergeResponse.summary,
        );
        entityStore.save(updatedEntity);
        ref.read(entityStoreVersionProvider.notifier).increment();

        AppLogger.info(
          'Entity updated',
          '${suggestion.entityName}: merged new information',
        );

        return updatedEntity;
      } else {
        // Entity not in local store, create from merge response
        final newEntity = EntityMetadata(
          id: mergeResponse.entityId,
          name: mergeResponse.entityName,
          type: _parseEntityType(suggestion.entityType),
          summary: mergeResponse.summary,
          description: mergeResponse.description,
        );
        entityStore.save(newEntity);
        ref.read(entityStoreVersionProvider.notifier).increment();
        return newEntity;
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to accept entity update', e, stackTrace);
      rethrow;
    }
  }

  /// Accept a suggestion with custom edited text instead of AI merge
  Future<EntityMetadata> acceptWithCustomText({
    required EntityUpdateSuggestion suggestion,
    required String customDescription,
    required String customSummary,
  }) async {
    final project = ref.read(projectProvider);
    if (project == null) {
      throw Exception('No project is open');
    }

    try {
      // Update the entity directly with custom text
      await _backend.updateEntity(
        projectId: project.id,
        entityId: suggestion.entityId,
        description: customDescription,
        summary: customSummary,
      );

      // Update local entity store
      final entityStore = ref.read(entityStoreProvider);
      final existingEntity = entityStore.getById(suggestion.entityId);

      final updatedEntity = (existingEntity ?? EntityMetadata(
        id: suggestion.entityId,
        name: suggestion.entityName,
        type: _parseEntityType(suggestion.entityType),
        summary: '',
        description: '',
      )).copyWith(
        description: customDescription,
        summary: customSummary,
      );

      entityStore.save(updatedEntity);
      ref.read(entityStoreVersionProvider.notifier).increment();

      AppLogger.info(
        'Entity updated with custom text',
        suggestion.entityName,
      );

      return updatedEntity;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update entity with custom text', e, stackTrace);
      rethrow;
    }
  }

  /// Preview what the merged content would look like without saving
  Future<MergeEntityResponse> previewMerge({
    required EntityUpdateSuggestion suggestion,
    String? provider,
  }) async {
    final project = ref.read(projectProvider);
    if (project == null) {
      throw Exception('No project is open');
    }

    return await _backend.mergeEntityUpdate(
      projectId: project.id,
      entityId: suggestion.entityId,
      newInformation: suggestion.suggestedAppendText,
      provider: provider,
      locale: _locale,
    );
  }

  EntityType _parseEntityType(String typeString) {
    switch (typeString.toLowerCase()) {
      case 'character':
        return EntityType.character;
      case 'location':
        return EntityType.location;
      case 'object':
        return EntityType.object;
      case 'event':
        return EntityType.event;
      default:
        return EntityType.custom;
    }
  }
}

/// Provider for EntityUpdateService
final entityUpdateServiceProvider = Provider<EntityUpdateService>((ref) {
  return EntityUpdateService(ref);
});
