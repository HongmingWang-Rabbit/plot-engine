import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../state/tab_state.dart';

class EditorTabBar extends ConsumerWidget {
  const EditorTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabStateProvider);

    if (tabState.tabs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: tabState.tabs.map((tab) {
            final isActive = tab.id == tabState.activeTabId;
            return _EditorTab(
              tab: tab,
              isActive: isActive,
              onTap: () {
                ref.read(tabStateProvider.notifier).activateTab(tab.id);
              },
              onClose: () {
                ref.read(tabStateProvider.notifier).closeTab(tab.id);
              },
            );
          }).toList(),
          ),
        ),
      ),
    );
  }
}

class _EditorTab extends StatefulWidget {
  final EditorTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _EditorTab({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<_EditorTab> createState() => _EditorTabState();
}

class _EditorTabState extends State<_EditorTab> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 120,
            maxWidth: 200,
          ),
          decoration: BoxDecoration(
            color: widget.isActive
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            border: Border(
              right: BorderSide(
                color: Theme.of(context).dividerColor,
              ),
              top: widget.isActive
                  ? BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : BorderSide.none,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Modified indicator (white dot)
              if (widget.tab.isModified) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onSurface,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              // Tab title
              Flexible(
                child: Text(
                  widget.tab.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: widget.tab.isPreview
                            ? FontStyle.italic
                            : FontStyle.normal,
                        color: widget.isActive
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 6),
              // Close button
              if (_isHovered || widget.isActive)
                InkWell(
                  onTap: widget.onClose,
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                )
              else
                const SizedBox(width: 14), // Reserve space for close button
            ],
          ),
        ),
      ),
    );
  }
}
