import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../models/entity.dart';
import '../models/entity_metadata.dart';

class EntityHighlightedText extends StatefulWidget {
  final String text;
  final List<Entity> entities;
  final TextStyle? baseStyle;
  final Function(Entity)? onEntityClick;

  const EntityHighlightedText({
    super.key,
    required this.text,
    required this.entities,
    this.baseStyle,
    this.onEntityClick,
  });

  @override
  State<EntityHighlightedText> createState() => _EntityHighlightedTextState();
}

class _EntityHighlightedTextState extends State<EntityHighlightedText> {
  Entity? _hoveredEntity;
  Offset? _hoverPosition;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) {
        setState(() {
          _hoverPosition = event.position;
        });
      },
      onExit: (_) {
        setState(() {
          _hoveredEntity = null;
          _hoverPosition = null;
        });
      },
      child: Stack(
        children: [
          Text.rich(
            _buildTextSpan(context),
            style: widget.baseStyle,
          ),
          if (_hoveredEntity != null && _hoverPosition != null)
            Positioned(
              left: _hoverPosition!.dx + 10,
              top: _hoverPosition!.dy + 10,
              child: _buildTooltip(_hoveredEntity!),
            ),
        ],
      ),
    );
  }

  TextSpan _buildTextSpan(BuildContext context) {
    if (widget.entities.isEmpty) {
      return TextSpan(text: widget.text);
    }

    final spans = <InlineSpan>[];
    var lastEnd = 0;

    // Sort entities by start offset
    final sortedEntities = List<Entity>.from(widget.entities)
      ..sort((a, b) => a.startOffset.compareTo(b.startOffset));

    for (final entity in sortedEntities) {
      // Add text before entity
      if (entity.startOffset > lastEnd) {
        spans.add(TextSpan(
          text: widget.text.substring(lastEnd, entity.startOffset),
        ));
      }

      // Add entity span
      spans.add(TextSpan(
        text: entity.name,
        style: TextStyle(
          backgroundColor: entity.recognized ? Colors.green.shade100 : Colors.orange.shade100,
          color: entity.recognized ? Colors.green.shade900 : Colors.orange.shade900,
          fontWeight: FontWeight.w500,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            widget.onEntityClick?.call(entity);
          },
        onEnter: (_) {
          setState(() {
            _hoveredEntity = entity;
          });
        },
        onExit: (_) {
          setState(() {
            _hoveredEntity = null;
          });
        },
      ));

      lastEnd = entity.endOffset;
    }

    // Add remaining text
    if (lastEnd < widget.text.length) {
      spans.add(TextSpan(
        text: widget.text.substring(lastEnd),
      ));
    }

    return TextSpan(children: spans);
  }

  Widget _buildTooltip(Entity entity) {
    if (!entity.recognized || entity.metadata == null) {
      return const SizedBox.shrink();
    }

    final metadata = entity.metadata!;

    return Material(
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
                  backgroundColor: _getTypeColor(metadata),
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
    );
  }

  Color _getTypeColor(EntityMetadata metadata) {
    switch (metadata.type.name) {
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
