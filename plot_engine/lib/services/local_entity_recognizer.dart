import '../models/entity.dart';
import '../models/entity_type.dart';
import 'entity_store.dart';

class LocalEntityRecognizer {
  final EntityStore _store;

  // Common words to exclude from entity recognition
  static final Set<String> _commonWords = {
    // Pronouns
    'I', 'You', 'He', 'She', 'It', 'We', 'They', 'Me', 'Him', 'Her', 'Us', 'Them',
    'My', 'Your', 'His', 'Her', 'Its', 'Our', 'Their', 'Mine', 'Yours', 'Hers', 'Ours', 'Theirs',
    'This', 'That', 'These', 'Those', 'Who', 'What', 'Which', 'Whom', 'Whose',

    // Common sentence starters
    'The', 'A', 'An', 'And', 'But', 'Or', 'For', 'Nor', 'So', 'Yet',
    'As', 'At', 'By', 'In', 'Of', 'On', 'To', 'Up', 'With', 'From',
    'If', 'When', 'Where', 'Why', 'How', 'While', 'After', 'Before',
    'Since', 'Until', 'Unless', 'Although', 'Though', 'Because',

    // Common verbs that might start sentences
    'Is', 'Are', 'Was', 'Were', 'Be', 'Been', 'Being',
    'Have', 'Has', 'Had', 'Having', 'Do', 'Does', 'Did', 'Done', 'Doing',
    'Will', 'Would', 'Could', 'Should', 'May', 'Might', 'Must', 'Can',
    'Get', 'Got', 'Getting', 'Go', 'Going', 'Went', 'Gone',
    'Make', 'Makes', 'Made', 'Making', 'Take', 'Takes', 'Took', 'Taken', 'Taking',
    'Come', 'Comes', 'Coming', 'Came',

    // Common adjectives/adverbs
    'All', 'Some', 'Many', 'Few', 'Most', 'More', 'Less', 'Each', 'Every', 'Any',
    'No', 'None', 'Nothing', 'Nobody', 'Nowhere', 'Never',
    'Very', 'So', 'Too', 'Quite', 'Rather', 'Just', 'Only', 'Even', 'Also',
    'Still', 'Already', 'Always', 'Often', 'Sometimes', 'Usually', 'Rarely',

    // Common nouns (generic)
    'People', 'Person', 'Man', 'Woman', 'Child', 'Children',
    'Thing', 'Things', 'Place', 'Places', 'Time', 'Times',
    'Day', 'Days', 'Night', 'Nights', 'Year', 'Years', 'Month', 'Months',
    'Way', 'Ways', 'Life', 'Lives', 'Work', 'World',

    // Other common words
    'Other', 'Others', 'Another', 'Such', 'Same', 'Different',
    'Good', 'Bad', 'Great', 'Small', 'Large', 'Big', 'Little',
    'First', 'Last', 'Next', 'New', 'Old', 'Long', 'Short',
    'Try', 'Trying', 'Notice', 'Now', 'Then', 'There', 'Here',
  };

  LocalEntityRecognizer(this._store);

  List<Entity> recognizeEntities(String text) {
    final entities = <Entity>[];
    final words = _tokenize(text);

    for (final word in words) {
      // Skip common words
      if (_commonWords.contains(word.text)) {
        continue;
      }

      // Skip words that are likely sentence starts (check if preceded by period, newline, or start of text)
      if (_isLikelySentenceStart(text, word.start)) {
        // However, if it's in the entity store, still recognize it
        final metadata = _store.get(word.text);
        if (metadata == null) {
          continue;
        }
      }

      if (_isCapitalized(word.text)) {
        final metadata = _store.get(word.text);
        if (metadata != null) {
          // Recognized entity
          entities.add(Entity(
            name: word.text,
            type: metadata.type,
            recognized: true,
            metadata: metadata,
            startOffset: word.start,
            endOffset: word.end,
          ));
        } else {
          // Unrecognized entity candidate (capitalized, not common, not sentence start)
          entities.add(Entity(
            name: word.text,
            type: EntityType.unknown,
            recognized: false,
            metadata: null,
            startOffset: word.start,
            endOffset: word.end,
          ));
        }
      }
    }

    return entities;
  }

  bool _isLikelySentenceStart(String text, int position) {
    if (position == 0) return true;

    // Look back for sentence-ending punctuation
    for (int i = position - 1; i >= 0; i--) {
      final char = text[i];

      // Found sentence ending
      if (char == '.' || char == '!' || char == '?' || char == '\n') {
        return true;
      }

      // Found non-whitespace (not a sentence start)
      if (char != ' ' && char != '\t' && char != '\r') {
        return false;
      }
    }

    return true;
  }

  List<_WordToken> _tokenize(String text) {
    final tokens = <_WordToken>[];
    final regex = RegExp(r'\b[A-Z][a-zA-Z]*\b');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      tokens.add(_WordToken(
        text: match.group(0)!,
        start: match.start,
        end: match.end,
      ));
    }

    return tokens;
  }

  bool _isCapitalized(String word) {
    if (word.isEmpty) return false;
    return word[0] == word[0].toUpperCase();
  }
}

class _WordToken {
  final String text;
  final int start;
  final int end;

  _WordToken({
    required this.text,
    required this.start,
    required this.end,
  });
}
