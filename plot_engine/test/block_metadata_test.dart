import 'package:flutter_test/flutter_test.dart';
import 'package:plot_engine/services/block_metadata.dart';

void main() {
  group('HeadingLevel', () {
    test('toJson returns correct string', () {
      expect(HeadingLevel.h1.toJson(), 'h1');
      expect(HeadingLevel.h2.toJson(), 'h2');
      expect(HeadingLevel.h3.toJson(), 'h3');
    });

    test('fromJson returns correct enum value', () {
      expect(HeadingLevel.fromJson('h1'), HeadingLevel.h1);
      expect(HeadingLevel.fromJson('h2'), HeadingLevel.h2);
      expect(HeadingLevel.fromJson('h3'), HeadingLevel.h3);
    });

    test('fromJson returns null for invalid input', () {
      expect(HeadingLevel.fromJson('invalid'), isNull);
      expect(HeadingLevel.fromJson(null), isNull);
    });
  });

  group('ListType', () {
    test('toJson returns correct string', () {
      expect(ListType.unordered.toJson(), 'unordered');
      expect(ListType.ordered.toJson(), 'ordered');
    });

    test('fromJson returns correct enum value', () {
      expect(ListType.fromJson('unordered'), ListType.unordered);
      expect(ListType.fromJson('ordered'), ListType.ordered);
    });

    test('fromJson returns null for invalid input', () {
      expect(ListType.fromJson('invalid'), isNull);
      expect(ListType.fromJson(null), isNull);
    });
  });

  group('TextAlignment', () {
    test('toJson returns correct string', () {
      expect(TextAlignment.left.toJson(), 'left');
      expect(TextAlignment.center.toJson(), 'center');
      expect(TextAlignment.right.toJson(), 'right');
      expect(TextAlignment.justify.toJson(), 'justify');
    });

    test('fromJson returns correct enum value', () {
      expect(TextAlignment.fromJson('left'), TextAlignment.left);
      expect(TextAlignment.fromJson('center'), TextAlignment.center);
      expect(TextAlignment.fromJson('right'), TextAlignment.right);
      expect(TextAlignment.fromJson('justify'), TextAlignment.justify);
    });

    test('fromJson returns null for invalid input', () {
      expect(TextAlignment.fromJson('invalid'), isNull);
      expect(TextAlignment.fromJson(null), isNull);
    });
  });

  group('BlockMetadata', () {
    test('empty constructor creates metadata with no formatting', () {
      const metadata = BlockMetadata.empty();
      expect(metadata.headingLevel, isNull);
      expect(metadata.listType, isNull);
      expect(metadata.listIndent, isNull);
      expect(metadata.alignment, isNull);
      expect(metadata.isBlockQuote, false);
      expect(metadata.hasFormatting, false);
    });

    test('constructor sets all properties correctly', () {
      const metadata = BlockMetadata(
        headingLevel: HeadingLevel.h1,
        listType: ListType.ordered,
        listIndent: 2,
        alignment: TextAlignment.center,
        isBlockQuote: true,
      );

      expect(metadata.headingLevel, HeadingLevel.h1);
      expect(metadata.listType, ListType.ordered);
      expect(metadata.listIndent, 2);
      expect(metadata.alignment, TextAlignment.center);
      expect(metadata.isBlockQuote, true);
      expect(metadata.hasFormatting, true);
    });

    test('copyWith creates new instance with modified properties', () {
      const original = BlockMetadata(
        headingLevel: HeadingLevel.h1,
        alignment: TextAlignment.left,
      );

      final modified = original.copyWith(
        headingLevel: HeadingLevel.h2,
        isBlockQuote: true,
      );

      expect(modified.headingLevel, HeadingLevel.h2);
      expect(modified.alignment, TextAlignment.left);
      expect(modified.isBlockQuote, true);
    });

    test('toJson serializes all properties', () {
      const metadata = BlockMetadata(
        headingLevel: HeadingLevel.h2,
        listType: ListType.unordered,
        listIndent: 1,
        alignment: TextAlignment.right,
        isBlockQuote: true,
      );

      final json = metadata.toJson();

      expect(json['headingLevel'], 'h2');
      expect(json['listType'], 'unordered');
      expect(json['listIndent'], 1);
      expect(json['alignment'], 'right');
      expect(json['isBlockQuote'], true);
    });

    test('toJson omits null properties', () {
      const metadata = BlockMetadata(
        headingLevel: HeadingLevel.h1,
      );

      final json = metadata.toJson();

      expect(json.containsKey('headingLevel'), true);
      expect(json.containsKey('listType'), false);
      expect(json.containsKey('listIndent'), false);
      expect(json.containsKey('alignment'), false);
      expect(json.containsKey('isBlockQuote'), false);
    });

    test('fromJson deserializes all properties', () {
      final json = {
        'headingLevel': 'h3',
        'listType': 'ordered',
        'listIndent': 3,
        'alignment': 'justify',
        'isBlockQuote': true,
      };

      final metadata = BlockMetadata.fromJson(json);

      expect(metadata.headingLevel, HeadingLevel.h3);
      expect(metadata.listType, ListType.ordered);
      expect(metadata.listIndent, 3);
      expect(metadata.alignment, TextAlignment.justify);
      expect(metadata.isBlockQuote, true);
    });

    test('fromJson handles missing properties gracefully', () {
      final json = <String, dynamic>{};
      final metadata = BlockMetadata.fromJson(json);

      expect(metadata.headingLevel, isNull);
      expect(metadata.listType, isNull);
      expect(metadata.listIndent, isNull);
      expect(metadata.alignment, isNull);
      expect(metadata.isBlockQuote, false);
    });

    test('fromJson handles invalid enum values gracefully', () {
      final json = {
        'headingLevel': 'invalid',
        'listType': 'invalid',
        'alignment': 'invalid',
      };

      final metadata = BlockMetadata.fromJson(json);

      expect(metadata.headingLevel, isNull);
      expect(metadata.listType, isNull);
      expect(metadata.alignment, isNull);
    });

    test('round-trip serialization preserves data', () {
      const original = BlockMetadata(
        headingLevel: HeadingLevel.h2,
        listType: ListType.unordered,
        listIndent: 2,
        alignment: TextAlignment.center,
        isBlockQuote: true,
      );

      final json = original.toJson();
      final restored = BlockMetadata.fromJson(json);

      expect(restored, equals(original));
    });

    test('equality works correctly', () {
      const metadata1 = BlockMetadata(
        headingLevel: HeadingLevel.h1,
        alignment: TextAlignment.left,
      );

      const metadata2 = BlockMetadata(
        headingLevel: HeadingLevel.h1,
        alignment: TextAlignment.left,
      );

      const metadata3 = BlockMetadata(
        headingLevel: HeadingLevel.h2,
        alignment: TextAlignment.left,
      );

      expect(metadata1, equals(metadata2));
      expect(metadata1, isNot(equals(metadata3)));
    });

    test('hashCode is consistent with equality', () {
      const metadata1 = BlockMetadata(
        headingLevel: HeadingLevel.h1,
        alignment: TextAlignment.left,
      );

      const metadata2 = BlockMetadata(
        headingLevel: HeadingLevel.h1,
        alignment: TextAlignment.left,
      );

      expect(metadata1.hashCode, equals(metadata2.hashCode));
    });

    test('isHeading returns true when headingLevel is set', () {
      const metadata = BlockMetadata(headingLevel: HeadingLevel.h1);
      expect(metadata.isHeading, true);
    });

    test('isHeading returns false when headingLevel is null', () {
      const metadata = BlockMetadata();
      expect(metadata.isHeading, false);
    });

    test('isList returns true when listType is set', () {
      const metadata = BlockMetadata(listType: ListType.ordered);
      expect(metadata.isList, true);
    });

    test('isList returns false when listType is null', () {
      const metadata = BlockMetadata();
      expect(metadata.isList, false);
    });

    test('hasFormatting returns true when any property is set', () {
      expect(
        const BlockMetadata(headingLevel: HeadingLevel.h1).hasFormatting,
        true,
      );
      expect(
        const BlockMetadata(listType: ListType.ordered).hasFormatting,
        true,
      );
      expect(
        const BlockMetadata(listIndent: 1).hasFormatting,
        true,
      );
      expect(
        const BlockMetadata(alignment: TextAlignment.center).hasFormatting,
        true,
      );
      expect(
        const BlockMetadata(isBlockQuote: true).hasFormatting,
        true,
      );
    });

    test('hasFormatting returns false when no properties are set', () {
      const metadata = BlockMetadata();
      expect(metadata.hasFormatting, false);
    });

    test('toString returns readable representation', () {
      const metadata = BlockMetadata(
        headingLevel: HeadingLevel.h1,
        alignment: TextAlignment.center,
      );

      final str = metadata.toString();
      expect(str, contains('BlockMetadata'));
      expect(str, contains('h1'));
      expect(str, contains('center'));
    });
  });
}
