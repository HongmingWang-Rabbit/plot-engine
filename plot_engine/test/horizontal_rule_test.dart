import 'package:flutter_test/flutter_test.dart';
import 'package:super_editor/super_editor.dart';

void main() {
  group('Horizontal Rule', () {
    test('HorizontalRuleNode can be created', () {
      final node = HorizontalRuleNode(id: 'hr1');
      expect(node.id, 'hr1');
    });

    test('HorizontalRuleNode equality works correctly', () {
      final node1 = HorizontalRuleNode(id: 'hr1');
      final node2 = HorizontalRuleNode(id: 'hr1');
      final node3 = HorizontalRuleNode(id: 'hr2');

      expect(node1, equals(node2));
      expect(node1, isNot(equals(node3)));
    });

    test('HorizontalRuleNode hasEquivalentContent returns true for all horizontal rules', () {
      final node1 = HorizontalRuleNode(id: 'hr1');
      final node2 = HorizontalRuleNode(id: 'hr2');

      expect(node1.hasEquivalentContent(node2), isTrue);
    });

    test('HorizontalRuleNode can be part of a document', () {
      // Create a document with horizontal rule
      final hrNode = HorizontalRuleNode(id: 'hr1');
      final document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'p1',
            text: AttributedText('Before'),
          ),
          hrNode,
          ParagraphNode(
            id: 'p2',
            text: AttributedText('After'),
          ),
        ],
      );

      // Verify the document structure
      expect(document.nodeCount, 3);
      expect(document.getNodeAt(0), isA<ParagraphNode>());
      expect(document.getNodeAt(1), isA<HorizontalRuleNode>());
      expect(document.getNodeAt(2), isA<ParagraphNode>());
    });

    test('HorizontalRuleNode can be deleted from document', () {
      // Create a document with a horizontal rule
      final hrNode = HorizontalRuleNode(id: 'hr1');
      final document = MutableDocument(
        nodes: [
          ParagraphNode(
            id: 'p1',
            text: AttributedText('Before'),
          ),
          hrNode,
          ParagraphNode(
            id: 'p2',
            text: AttributedText('After'),
          ),
        ],
      );

      // Delete the horizontal rule
      final nodeIndex = document.getNodeIndexById('hr1');
      document.deleteNodeAt(nodeIndex);

      // Verify the horizontal rule was deleted
      expect(document.nodeCount, 2);
      expect(document.getNodeAt(0), isA<ParagraphNode>());
      expect(document.getNodeAt(1), isA<ParagraphNode>());
      expect(document.getNodeById('hr1'), isNull);
    });
  });
}
