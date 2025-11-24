import '../models/project.dart';
import '../models/chapter.dart';
import '../models/knowledge_item.dart';
import '../models/entity_metadata.dart';
import '../models/entity_type.dart';

class TemplateProjectService {
  static Project createTemplateProject() {
    final now = DateTime.now();
    final projectId = 'template_${now.millisecondsSinceEpoch}';

    return Project(
      id: projectId,
      name: 'Welcome to PlotEngine',
      path: '', // Will be set by the caller
      createdAt: now,
      updatedAt: now,
    );
  }

  static List<Chapter> createTemplateChapters() {
    final now = DateTime.now();

    return [
      Chapter(
        id: 'chapter_1_${now.millisecondsSinceEpoch}',
        title: 'Chapter 1: Getting Started',
        content: '''Welcome to PlotEngine! This template project demonstrates the entity recognition features.

Try hovering over the highlighted words below:

Alice is a brave young woman who embarks on an epic journey. She travels through the mystical Shadowvale forest, searching for the legendary Crystal of Light.

Along the way, she meets Bob, a wise old wizard who becomes her trusted companion. Together, they face many challenges in the ancient city of Elderwatch.

Notice how different entities are highlighted:
- Green highlights = Recognized entities (already in your knowledge base)
- Orange highlights = Unrecognized entities (capitalized words not yet added)

Click on a green entity to view its details. Click on an orange entity to add it to your knowledge base!''',
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      Chapter(
        id: 'chapter_2_${now.millisecondsSinceEpoch}',
        title: 'Chapter 2: Entity Features Demo',
        content: '''This chapter demonstrates more entity recognition features.

CHARACTERS:
Alice and Bob continue their adventure. They meet new allies like Sarah, Tom, and mysterious strangers.

LOCATIONS:
They visit Shadowvale, the Whispering Woods, Dragon Peak, and the Sunken City. Each location holds unique challenges.

OBJECTS:
Important items include the Crystal, the Ancient Map, the Sword of Dawn, and magical Potions.

EVENTS:
The Great Battle, the Festival of Lights, and the Dragon's Awakening are pivotal moments.

Try clicking on:
1. Recognized entities (green) - Opens detail screen
2. Unrecognized entities (orange) - Opens creation dialog

You can add new entities by clicking on any orange-highlighted word!''',
        order: 1,
        createdAt: now.add(const Duration(seconds: 1)),
        updatedAt: now.add(const Duration(seconds: 1)),
      ),
      Chapter(
        id: 'chapter_3_${now.millisecondsSinceEpoch}',
        title: 'Chapter 3: Your Story Begins',
        content: '''Now it's your turn! Start writing your own story here.

Create your own characters, locations, and objects. As you type capitalized words, they'll be highlighted automatically.

Tips:
- Capitalize character names, location names, and important objects
- Hover over recognized entities to see their summaries
- Click orange entities to add them to your knowledge base
- Click green entities to view and edit their details
- Use the Knowledge Panel on the right to manage all your entities

Happy writing!''',
        order: 2,
        createdAt: now.add(const Duration(seconds: 2)),
        updatedAt: now.add(const Duration(seconds: 2)),
      ),
    ];
  }

  static List<KnowledgeItem> createTemplateKnowledgeItems() {
    final now = DateTime.now();

    return [
      // Characters (using plural 'characters' to match Knowledge Panel tabs)
      KnowledgeItem(
        id: 'char_alice_${now.millisecondsSinceEpoch}',
        name: 'Alice',
        type: 'characters',
        description: 'Alice is a brave young woman who embarks on a journey to save her village from an ancient curse. She is resourceful, kind-hearted, and determined. Despite her fears, she never backs down from a challenge.',
        appearances: [],
      ),
      KnowledgeItem(
        id: 'char_bob_${now.millisecondsSinceEpoch}',
        name: 'Bob',
        type: 'characters',
        description: 'Bob is a wise old wizard who has lived for centuries. He guides Alice on her quest and teaches her about magic and the ancient ways. His knowledge of history and mystical arts is invaluable.',
        appearances: [],
      ),

      // Locations (using plural 'locations' to match Knowledge Panel tabs)
      KnowledgeItem(
        id: 'loc_shadowvale_${now.millisecondsSinceEpoch}',
        name: 'Shadowvale',
        type: 'locations',
        description: 'Shadowvale is an ancient forest shrouded in mist and legend. The trees are ancient and twisted, and few dare to venture deep into its depths. It is said that the forest itself is alive and watches all who enter.',
        appearances: [],
      ),
      KnowledgeItem(
        id: 'loc_elderwatch_${now.millisecondsSinceEpoch}',
        name: 'Elderwatch',
        type: 'locations',
        description: 'Elderwatch is an ancient city built by a long-forgotten civilization. Its towering spires and intricate architecture speak of a glorious past. Now it lies in ruins, guarded by ancient magic.',
        appearances: [],
      ),

      // Objects (using plural 'objects' to match Knowledge Panel tabs)
      KnowledgeItem(
        id: 'obj_crystal_${now.millisecondsSinceEpoch}',
        name: 'Crystal',
        type: 'objects',
        description: 'The Crystal of Light is a legendary artifact said to have the power to break any curse. It glows with an inner radiance and is warm to the touch. Many have sought it, but few have found it.',
        appearances: [],
      ),

      // Events (note: no default tab for events, but keeping it for completeness)
      KnowledgeItem(
        id: 'event_battle_${now.millisecondsSinceEpoch}',
        name: 'Great Battle',
        type: 'events',
        description: 'The Great Battle was a pivotal moment in history when the forces of light and darkness clashed. It shaped the fate of the realm and left scars that can still be seen today.',
        appearances: [],
      ),
    ];
  }

  static List<EntityMetadata> createTemplateEntities() {
    return [
      // Characters
      EntityMetadata(
        id: '1',
        name: 'Alice',
        type: EntityType.character,
        summary: 'The protagonist of the story',
        description: 'Alice is a brave young woman who embarks on a journey to save her village from an ancient curse. She is resourceful, kind-hearted, and determined.',
      ),
      EntityMetadata(
        id: '2',
        name: 'Bob',
        type: EntityType.character,
        summary: 'Alice\'s loyal companion',
        description: 'Bob is a wise old wizard who guides Alice on her quest. His knowledge of history and mystical arts is invaluable.',
      ),

      // Locations
      EntityMetadata(
        id: '3',
        name: 'Shadowvale',
        type: EntityType.location,
        summary: 'A dark and mysterious forest',
        description: 'Shadowvale is an ancient forest shrouded in mist and legend, where few dare to venture.',
      ),
      EntityMetadata(
        id: '4',
        name: 'Elderwatch',
        type: EntityType.location,
        summary: 'An ancient ruined city',
        description: 'Elderwatch is an ancient city built by a long-forgotten civilization, now lying in ruins.',
      ),

      // Objects
      EntityMetadata(
        id: '5',
        name: 'Crystal',
        type: EntityType.object,
        summary: 'A magical artifact',
        description: 'The Crystal of Light is said to have the power to break any curse.',
      ),
    ];
  }
}
