import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../models/entity_metadata.dart';
import '../services/entity_attribution_service.dart';
import '../state/app_state.dart';
import '../state/tab_state.dart';
import 'entity_creation_dialog.dart';

/// Document overlay that shows tooltips when hovering over entities
class EntityTooltipOverlayBuilder implements SuperEditorLayerBuilder {
  final WidgetRef ref;

  EntityTooltipOverlayBuilder(this.ref);

  @override
  ContentLayerWidget build(BuildContext context, SuperEditorContext editorContext) {
    return ContentLayerProxyWidget(
      child: EntityTooltipOverlay(
        editorContext: editorContext,
        ref: ref,
      ),
    );
  }
}

class EntityTooltipOverlay extends StatefulWidget {
  final SuperEditorContext editorContext;
  final WidgetRef ref;

  const EntityTooltipOverlay({
    super.key,
    required this.editorContext,
    required this.ref,
  });

  @override
  State<EntityTooltipOverlay> createState() => _EntityTooltipOverlayState();
}

class _EntityTooltipOverlayState extends State<EntityTooltipOverlay> {
  EntityMetadata? _hoveredEntity;
  Offset? _tooltipPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onTap,
      child: MouseRegion(
        hitTestBehavior: HitTestBehavior.translucent,
        onHover: _onHover,
        onExit: (_) {
          setState(() {
            _hoveredEntity = null;
            _tooltipPosition = null;
          });
          widget.ref.read(hoveredEntityProvider.notifier).clearHover();
        },
        child: IgnorePointer(
          ignoring: true,
          child: Stack(
            children: [
              if (_hoveredEntity != null && _tooltipPosition != null)
                Positioned(
                  left: _tooltipPosition!.dx,
                  top: _tooltipPosition!.dy + 20,
                  child: _buildTooltip(_hoveredEntity!),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onHover(PointerHoverEvent event) {
    final documentPosition = widget.editorContext.documentLayout
        .getDocumentPositionAtOffset(event.localPosition);

    if (documentPosition == null) {
      setState(() {
        _hoveredEntity = null;
        _tooltipPosition = null;
      });
      return;
    }

    final document = widget.editorContext.document;
    final node = document.getNodeById(documentPosition.nodeId);

    if (node is! ParagraphNode) {
      setState(() {
        _hoveredEntity = null;
        _tooltipPosition = null;
      });
      return;
    }

    final offset = (documentPosition.nodePosition as TextPosition).offset;
    final attributions = node.text.getAllAttributionsAt(offset);

    EntityAttribution? entityAttribution;
    for (final attribution in attributions) {
      if (attribution is EntityAttribution) {
        entityAttribution = attribution;
        break;
      }
    }

    if (entityAttribution != null) {
      final entity = entityAttribution.entity;

      // Always set hover state for animation (both recognized and unrecognized)
      widget.ref.read(hoveredEntityProvider.notifier).setHovered(entity.name);

      // Only show tooltip for recognized entities
      if (entity.recognized && entity.metadata != null) {
        setState(() {
          _hoveredEntity = entity.metadata;
          _tooltipPosition = event.localPosition;
        });
      } else {
        setState(() {
          _hoveredEntity = null;
          _tooltipPosition = null;
        });
      }
    } else {
      setState(() {
        _hoveredEntity = null;
        _tooltipPosition = null;
      });
      widget.ref.read(hoveredEntityProvider.notifier).clearHover();
    }
  }

  Widget _buildTooltip(EntityMetadata metadata) {
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

  void _onTap(PointerDownEvent event) {
    final documentPosition = widget.editorContext.documentLayout
        .getDocumentPositionAtOffset(event.localPosition);

    if (documentPosition == null) return;

    final document = widget.editorContext.document;
    final node = document.getNodeById(documentPosition.nodeId);

    if (node is! ParagraphNode) return;

    final offset = (documentPosition.nodePosition as TextPosition).offset;
    final attributions = node.text.getAllAttributionsAt(offset);

    EntityAttribution? entityAttribution;
    for (final attribution in attributions) {
      if (attribution is EntityAttribution) {
        entityAttribution = attribution;
        break;
      }
    }

    if (entityAttribution != null) {
      final entity = entityAttribution.entity;

      if (entity.recognized && entity.metadata != null) {
        // Open entity in a tab in the writing panel
        widget.ref.read(tabStateProvider.notifier).openEntityPreview(entity.metadata!);
      } else {
        // Open creation dialog for unrecognized entities
        showDialog(
          context: context,
          builder: (context) => EntityCreationDialog(
            entityName: entity.name,
            onSave: (metadata) {
              // Save new entity to store
              widget.ref.read(entityStoreProvider).save(metadata);
              // Open the newly created entity in a tab
              widget.ref.read(tabStateProvider.notifier).openEntityPreview(metadata);
            },
          ),
        );
      }
    }
  }
}
