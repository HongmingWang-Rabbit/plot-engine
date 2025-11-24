import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_editor/super_editor.dart';
import '../services/entity_attribution_service.dart';
import '../state/app_state.dart';
import '../screens/entity_detail_screen.dart';
import 'entity_creation_dialog.dart';

/// Document overlay that handles clicks on entities
class EntityClickOverlayBuilder implements SuperEditorLayerBuilder {
  final WidgetRef ref;

  EntityClickOverlayBuilder(this.ref);

  @override
  ContentLayerWidget build(BuildContext context, SuperEditorContext editorContext) {
    return ContentLayerProxyWidget(
      child: EntityClickOverlay(
        editorContext: editorContext,
        ref: ref,
      ),
    );
  }
}

class EntityClickOverlay extends StatelessWidget {
  final SuperEditorContext editorContext;
  final WidgetRef ref;

  const EntityClickOverlay({
    super.key,
    required this.editorContext,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: Listener(
        onPointerDown: (event) => _onTap(context, event),
        behavior: HitTestBehavior.translucent,
        child: const SizedBox.expand(),
      ),
    );
  }

  void _onTap(BuildContext context, PointerDownEvent event) {
    final documentPosition = editorContext.documentLayout
        .getDocumentPositionAtOffset(event.localPosition);

    if (documentPosition == null) return;

    final document = editorContext.document;
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
        // Clear sidebar selection (don't show in AI Comments panel)
        ref.read(selectedEntityProvider.notifier).clearSelection();

        // Navigate to EntityDetailScreen in the writing panel
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EntityDetailScreen(
              metadata: entity.metadata!,
              onSave: (updatedMetadata) {
                // Update entity in store
                ref.read(entityStoreProvider).save(updatedMetadata);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      } else {
        // Open creation dialog for unrecognized entities
        showDialog(
          context: context,
          builder: (context) => EntityCreationDialog(
            entityName: entity.name,
            onSave: (metadata) {
              // Save new entity to store
              ref.read(entityStoreProvider).save(metadata);
              // Show the newly created entity in sidebar
              ref.read(selectedEntityProvider.notifier).selectEntity(metadata);
            },
          ),
        );
      }
    }
  }
}
