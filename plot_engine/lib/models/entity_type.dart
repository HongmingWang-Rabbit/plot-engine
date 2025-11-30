enum EntityType {
  character,
  location,
  object,
  event,
  setting,
  timeline,
  custom,
  unknown;

  String get displayName {
    switch (this) {
      case EntityType.character:
        return 'Character';
      case EntityType.location:
        return 'Location';
      case EntityType.object:
        return 'Object';
      case EntityType.event:
        return 'Event';
      case EntityType.setting:
        return 'Setting';
      case EntityType.timeline:
        return 'Timeline';
      case EntityType.custom:
        return 'Custom';
      case EntityType.unknown:
        return 'Unknown';
    }
  }

  static EntityType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'character':
        return EntityType.character;
      case 'location':
        return EntityType.location;
      case 'object':
        return EntityType.object;
      case 'event':
        return EntityType.event;
      case 'setting':
        return EntityType.setting;
      case 'timeline':
        return EntityType.timeline;
      case 'custom':
        return EntityType.custom;
      default:
        return EntityType.unknown;
    }
  }

  String toJson() => name;
}
