import 'package:flutter/material.dart';

/// Centralized icon mapping utility for knowledge tabs and categories
class IconMapper {
  /// Convert string icon name to IconData
  static IconData fromString(String iconName) {
    switch (iconName) {
      case 'menu_book':
        return Icons.menu_book;
      case 'person':
        return Icons.person;
      case 'place':
        return Icons.place;
      case 'category':
        return Icons.category;
      case 'event':
        return Icons.event;
      case 'inventory':
        return Icons.inventory_2;
      case 'timeline':
        return Icons.timeline;
      case 'groups':
        return Icons.groups;
      case 'auto_awesome':
        return Icons.auto_awesome;
      default:
        return Icons.label;
    }
  }

  /// Available icons with display labels for selection UI
  static const List<IconOption> availableIcons = [
    IconOption(name: 'label', label: 'Default', description: 'General label'),
    IconOption(name: 'person', label: 'Person', description: 'Characters, people'),
    IconOption(name: 'place', label: 'Place', description: 'Locations, settings'),
    IconOption(name: 'category', label: 'Category', description: 'Categories, types'),
    IconOption(name: 'event', label: 'Event', description: 'Events, timeline'),
    IconOption(name: 'inventory', label: 'Items', description: 'Objects, inventory'),
    IconOption(name: 'timeline', label: 'Timeline', description: 'Chronology, sequence'),
    IconOption(name: 'groups', label: 'Groups', description: 'Factions, organizations'),
    IconOption(name: 'auto_awesome', label: 'Magic', description: 'Magic, special abilities'),
    IconOption(name: 'menu_book', label: 'Chapters', description: 'Chapters, sections'),
  ];

  /// Get icon option by name
  static IconOption? getOption(String name) {
    try {
      return availableIcons.firstWhere((option) => option.name == name);
    } catch (e) {
      return null;
    }
  }
}

/// Icon option for UI selection
class IconOption {
  final String name;
  final String label;
  final String description;

  const IconOption({
    required this.name,
    required this.label,
    required this.description,
  });

  IconData get icon => IconMapper.fromString(name);
}
