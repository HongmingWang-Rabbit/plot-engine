import 'package:flutter/material.dart';

class AppToolbar extends StatelessWidget {
  const AppToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          // App Title
          Text(
            'PlotEngine',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 32),
          // File Menu
          _ToolbarButton(
            icon: Icons.folder_open,
            label: 'Open Project',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.save,
            label: 'Save',
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          _ToolbarButton(
            icon: Icons.add,
            label: 'New Chapter',
            onPressed: () {},
          ),
          const Spacer(),
          // Chapter Dropdown (placeholder)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).dividerColor,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Chapter 1',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
