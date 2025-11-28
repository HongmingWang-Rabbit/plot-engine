import 'dart:async';
import '../models/entity.dart';
import '../models/entity_type.dart';
import '../models/ai_models.dart';
import '../core/utils/logger.dart';
import 'entity_store.dart';
import 'entity_recognizer.dart';
import 'ai_service.dart';

/// AI-powered entity recognizer that extracts entities using the backend AI API
/// with debouncing to avoid excessive API calls during typing.
class AIEntityRecognizer implements EntityRecognizer {
  final EntityStore _store;
  final AIService _aiService;

  // Debounce timer
  Timer? _debounceTimer;

  // Cache for extracted entities (text hash -> entities)
  final Map<int, List<ExtractedEntity>> _cache = {};

  // Currently processing
  bool _isProcessing = false;

  // Callback for when entities are extracted
  void Function(List<Entity>)? onEntitiesExtracted;

  // Last processed text hash (to avoid redundant processing)
  int? _lastTextHash;

  // Current document hash (for document-level extraction)
  int? _currentDocumentHash;

  // Debounce duration (longer for AI to reduce API calls)
  static const Duration _debounceDuration = Duration(milliseconds: 1500);

  AIEntityRecognizer(this._store, this._aiService);

  /// Set the full document text for extraction
  /// This should be called before recognizeEntities to enable document-level caching
  void setDocumentText(String fullText) {
    final newHash = fullText.hashCode;

    // Skip if same document and already cached or being processed
    if (newHash == _currentDocumentHash) {
      return;
    }

    // Skip if already cached
    if (_cache.containsKey(newHash)) {
      _currentDocumentHash = newHash;
      return;
    }

    _currentDocumentHash = newHash;
    // Schedule extraction for the full document
    _scheduleAIExtraction(fullText);
  }

  /// Recognize entities in text using AI extraction with debouncing
  /// Returns immediately with locally known entities + cached AI entities
  @override
  List<Entity> recognizeEntities(String text) {
    // First, get entities from local store (fast)
    final localEntities = _recognizeFromStore(text);

    // Check if we have cached AI entities for this specific text
    final textHash = text.hashCode;
    if (_cache.containsKey(textHash)) {
      // Return local + cached AI entities
      return _combineWithCachedEntities(text, localEntities, _cache[textHash]!);
    }

    // Check if we have document-level cache (for paragraph-level matching)
    if (_currentDocumentHash != null && _cache.containsKey(_currentDocumentHash)) {
      // Use document-level extracted entities to find matches in this paragraph
      final docEntities = _cache[_currentDocumentHash]!;
      final combined = _combineWithCachedEntities(text, localEntities, docEntities);
      return combined;
    }

    // Don't schedule extraction for individual paragraphs
    // Document-level extraction is triggered by setDocumentText
    // Individual paragraphs will use the document cache once it's populated
    return localEntities;
  }

  /// Combine local entities with cached AI-extracted entities
  List<Entity> _combineWithCachedEntities(
    String text,
    List<Entity> localEntities,
    List<ExtractedEntity> cachedExtracted,
  ) {
    final entities = List<Entity>.from(localEntities);

    // Add AI-extracted entities that aren't already in the store
    for (final ext in cachedExtracted) {
      if (_store.get(ext.name) != null) continue; // Already in store

      // Find positions of this entity in text
      final positions = _findAllOccurrences(text, ext.name);

      for (final pos in positions) {
        entities.add(Entity(
          name: ext.name,
          type: _guessEntityType(ext),
          recognized: false,
          metadata: null,
          startOffset: pos.start,
          endOffset: pos.end,
        ));
      }
    }

    return entities;
  }

  /// Recognize entities only from the local entity store (no AI)
  List<Entity> _recognizeFromStore(String text) {
    final entities = <Entity>[];
    final knownEntities = _store.getAll();

    for (final metadata in knownEntities) {
      // Find all occurrences of this entity name in the text
      final positions = _findAllOccurrences(text, metadata.name);

      for (final pos in positions) {
        entities.add(Entity(
          name: metadata.name,
          type: metadata.type,
          recognized: true,
          metadata: metadata,
          startOffset: pos.start,
          endOffset: pos.end,
        ));
      }
    }

    return entities;
  }

  // UI/instructional texts to ignore
  static const Set<String> _ignoredTexts = {
    'Start writing your story here...',
    'Welcome',
    'Getting Started',
    'Introduction',
    'Chapter 1',
    'Untitled',
    '',
  };

  // Common UI phrases to filter out
  static final RegExp _uiPhrasePattern = RegExp(
    r'(click here|getting started|how to|tutorial|example|placeholder|lorem ipsum)',
    caseSensitive: false,
  );


  /// Schedule AI extraction with debouncing
  void _scheduleAIExtraction(String text) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Skip placeholder/empty text
    final trimmedText = text.trim();
    if (_ignoredTexts.contains(trimmedText)) {
      return;
    }

    // Skip if text is too short (minimum 200 chars for meaningful extraction)
    if (text.length < 200) {
      return;
    }

    // Skip UI/instructional text
    if (_uiPhrasePattern.hasMatch(text)) {
      return;
    }

    // Skip capitalization check - it doesn't work for non-Latin languages
    // like Chinese, Japanese, Korean, etc.

    final textHash = text.hashCode;

    // Skip if already cached (don't notify - just use cache silently)
    if (_cache.containsKey(textHash)) {
      return;
    }

    // Skip if same text already being processed
    if (textHash == _lastTextHash && _isProcessing) {
      return;
    }
    // Schedule new extraction
    _debounceTimer = Timer(_debounceDuration, () {
      _runAIExtraction(text, textHash);
    });
  }

  /// Run AI extraction
  Future<void> _runAIExtraction(String text, int textHash) async {
    if (_isProcessing) {
      return;
    }

    _isProcessing = true;
    _lastTextHash = textHash;

    try {
      final extracted = await _aiService.extractEntities(text: text);

      // Combine all extracted entities
      final allExtracted = <ExtractedEntity>[
        ...extracted.characters,
        ...extracted.locations,
        ...extracted.objects,
      ];

      // Cache the result
      _cache[textHash] = allExtracted;

      // Limit cache size
      if (_cache.length > 20) {
        _cache.remove(_cache.keys.first);
      }

      // Notify with results
      _notifyWithAIEntities(text, allExtracted);

    } catch (e, stackTrace) {
      AppLogger.error('AI extraction failed', e, stackTrace);
    } finally {
      _isProcessing = false;
    }
  }

  /// Notify callback with AI-extracted entities
  void _notifyWithAIEntities(String text, List<ExtractedEntity> extracted) {
    if (onEntitiesExtracted == null) return;

    final entities = <Entity>[];

    // First add known entities from store
    entities.addAll(_recognizeFromStore(text));

    // Then add AI-extracted entities that aren't already in the store
    for (final ext in extracted) {
      if (_store.get(ext.name) != null) continue; // Already in store

      // Find positions of this entity in text
      final positions = _findAllOccurrences(text, ext.name);

      for (final pos in positions) {
        entities.add(Entity(
          name: ext.name,
          type: _guessEntityType(ext),
          recognized: false, // Not in store yet
          metadata: null,
          startOffset: pos.start,
          endOffset: pos.end,
        ));
      }
    }

    onEntitiesExtracted!(entities);
  }

  /// Guess entity type from extracted entity
  EntityType _guessEntityType(ExtractedEntity entity) {
    // The AI categorizes entities into characters, locations, objects
    // We determine type based on which list it came from (stored in description hints)
    final desc = entity.description.toLowerCase();

    if (desc.contains('person') || desc.contains('character') ||
        desc.contains('human') || desc.contains('protagonist') ||
        desc.contains('antagonist') || entity.traits != null) {
      return EntityType.character;
    }
    if (desc.contains('place') || desc.contains('location') ||
        desc.contains('city') || desc.contains('forest') ||
        desc.contains('building') || desc.contains('region')) {
      return EntityType.location;
    }
    if (desc.contains('object') || desc.contains('item') ||
        desc.contains('artifact') || desc.contains('tool') ||
        desc.contains('weapon')) {
      return EntityType.object;
    }

    return EntityType.unknown;
  }

  /// Find all occurrences of a name in text
  List<_TextPosition> _findAllOccurrences(String text, String name) {
    final positions = <_TextPosition>[];

    // Check if text contains non-ASCII characters (Chinese, Japanese, Korean, etc.)
    final hasNonAscii = text.runes.any((r) => r > 127) || name.runes.any((r) => r > 127);

    if (hasNonAscii) {
      // For non-Latin text, use simple substring matching
      int start = 0;
      while (true) {
        final index = text.indexOf(name, start);
        if (index == -1) break;
        positions.add(_TextPosition(index, index + name.length));
        start = index + 1;
      }
    } else {
      // For Latin text, use word boundary matching to avoid partial matches
      final pattern = RegExp(r'\b' + RegExp.escape(name) + r'\b', caseSensitive: true);
      final matches = pattern.allMatches(text);

      for (final match in matches) {
        positions.add(_TextPosition(match.start, match.end));
      }
    }

    return positions;
  }

  /// Cancel any pending operations
  void dispose() {
    _debounceTimer?.cancel();
  }

  /// Clear cache (call when project changes)
  void clearCache() {
    _cache.clear();
    _lastTextHash = null;
    _currentDocumentHash = null;
  }
}

class _TextPosition {
  final int start;
  final int end;
  _TextPosition(this.start, this.end);
}
