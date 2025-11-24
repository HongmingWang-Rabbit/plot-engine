import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:super_editor/super_editor.dart';
import '../models/entity.dart';
import '../services/local_entity_recognizer.dart';

class EntityAwareParagraphComponentBuilder implements ComponentBuilder {
  final LocalEntityRecognizer recognizer;
  final Function(Entity)? onEntityClick;

  EntityAwareParagraphComponentBuilder({
    required this.recognizer,
    this.onEntityClick,
  });

  @override
  SingleColumnLayoutComponentViewModel? createViewModel(Document document, DocumentNode node) {
    if (node is! ParagraphNode) {
      return null;
    }

    return ParagraphComponentViewModel(
      nodeId: node.id,
      text: node.text,
      textStyleBuilder: noStyleBuilder,
      selectionColor: const Color(0x00000000),
    );
  }

  @override
  Widget? createComponent(
    SingleColumnDocumentComponentContext componentContext,
    SingleColumnLayoutComponentViewModel componentViewModel,
  ) {
    if (componentViewModel is! ParagraphComponentViewModel) {
      return null;
    }

    return EntityAwareParagraphComponent(
      key: componentContext.componentKey,
      text: componentViewModel.text,
      styleBuilder: componentViewModel.textStyleBuilder,
      recognizer: recognizer,
      onEntityClick: onEntityClick,
    );
  }
}

class EntityAwareParagraphComponent extends StatefulWidget {
  final AttributedText text;
  final AttributionStyleBuilder styleBuilder;
  final LocalEntityRecognizer recognizer;
  final Function(Entity)? onEntityClick;

  const EntityAwareParagraphComponent({
    super.key,
    required this.text,
    required this.styleBuilder,
    required this.recognizer,
    this.onEntityClick,
  });

  @override
  State<EntityAwareParagraphComponent> createState() => _EntityAwareParagraphComponentState();
}

class _EntityAwareParagraphComponentState extends State<EntityAwareParagraphComponent> {
  Entity? _hoveredEntity;
  final _tooltipKey = GlobalKey();
  Offset? _tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final plainText = widget.text.toPlainText();
    final entities = widget.recognizer.recognizeEntities(plainText);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text.rich(
            _buildTextSpan(plainText, entities),
          ),
        ),
        if (_hoveredEntity != null && _hoveredEntity!.recognized && _tooltipPosition != null)
          Positioned(
            left: _tooltipPosition!.dx,
            top: _tooltipPosition!.dy + 25,
            child: _buildTooltip(_hoveredEntity!),
          ),
      ],
    );
  }

  TextSpan _buildTextSpan(String text, List<Entity> entities) {
    if (entities.isEmpty) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontSize: 16, height: 1.6),
      );
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    // Sort entities by start offset
    final sortedEntities = List<Entity>.from(entities)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    for (final entity in sortedEntities) {
      // Add text before entity
      if (entity.startOffset > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, entity.startOffset),
          style: const TextStyle(fontSize: 16, height: 1.6),
        ));
      }

      // Add entity span with hover and click
      spans.add(TextSpan(
        text: entity.name,
        style: TextStyle(
          fontSize: 16,
          height: 1.6,
          backgroundColor: entity.recognized ? Colors.green.shade100 : Colors.orange.shade100,
          color: entity.recognized ? Colors.green.shade900 : Colors.orange.shade900,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            widget.onEntityClick?.call(entity);
          },
        onEnter: (event) {
          if (entity.recognized) {
            setState(() {
              _hoveredEntity = entity;
              _tooltipPosition = Offset(event.localPosition.dx, 0);
            });
          }
        },
        onExit: (_) {
          setState(() {
            if (_hoveredEntity == entity) {
              _hoveredEntity = null;
              _tooltipPosition = null;
            }
          });
        },
      ));

      lastEnd = entity.endOffset;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: const TextStyle(fontSize: 16, height: 1.6),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildTooltip(Entity entity) {
    if (entity.metadata == null) {
      return const SizedBox.shrink();
    }

    final metadata = entity.metadata!;

    return IgnorePointer(
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metadata.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(
                      metadata.type.displayName,
                      style: const TextStyle(fontSize: 11),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: _getTypeColor(metadata.type.toJson()),
                  ),
                ],
              ),
              if (metadata.summary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  metadata.summary,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String typeName) {
    switch (typeName) {
      case 'character':
        return Colors.blue.shade100;
      case 'location':
        return Colors.green.shade100;
      case 'object':
        return Colors.orange.shade100;
      case 'event':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }
}
