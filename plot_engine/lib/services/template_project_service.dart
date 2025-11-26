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
        title: 'Chapter 1: The Journey Begins',
        content: '''The morning sun cast long shadows across the cobblestone streets of Millbrook Village as Alice gathered her belongings. She had spent twenty-three years in this quiet hamlet, but today marked the beginning of something extraordinary. The ancient prophecy had spoken of a chosen one, and the village elders had confirmed what she always suspected deep in her heart.

"You must find the Crystal of Light," her grandmother had whispered on her deathbed, pressing a worn leather map into Alice's trembling hands. "It lies hidden in the heart of Shadowvale, guarded by forces older than time itself. Only you can break the curse that plagues our land."

Alice adjusted the strap of her traveling pack and took one last look at the cottage where she had grown up. The thatched roof needed repair, and the garden her mother had tended so lovingly had grown wild since the sickness took her. There was nothing left here now but memories and sorrow.

The road to Shadowvale wound through the Whispering Woods, a forest so ancient that the trees themselves were said to possess consciousness. Travelers spoke in hushed tones of voices carried on the wind, of warnings whispered by unseen watchers. Most avoided the woods entirely, preferring the longer but safer route through the Northern Pass.

But Alice had no time for the safer path. The curse grew stronger with each passing day, and already three more villagers had fallen to the mysterious sleeping sickness. Their bodies lay in the village hall, breathing but unresponsive, their minds trapped in an endless nightmare from which they could not wake.

As she reached the edge of the village, a figure emerged from the shadow of the old mill. It was Bob, the wandering scholar who had arrived in Millbrook just three months ago. His long grey beard and weathered robes marked him as one who had traveled far, and the strange symbols embroidered on his sleeves spoke of knowledge forbidden to most.

"I wondered when you would set out," Bob said, his voice carrying the weight of centuries. "I have been waiting for this day longer than you can imagine, young Alice. The stars aligned at your birth, and I have watched over you from afar, ensuring this moment would come to pass."

Alice studied the old man with new eyes. She had always thought him merely an eccentric scholar, collecting herbs and muttering over ancient texts by candlelight. Now she saw the subtle glow behind his eyes, the way reality seemed to bend ever so slightly in his presence.

"You're a wizard," she breathed.

Bob smiled, revealing teeth that were perhaps too perfect for a man of his apparent age. "Among other things. I am Bob the Wanderer, last of the Council of Seven, keeper of secrets that could reshape the world. And I have been waiting a very long time to guide the chosen one on her quest."''',
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      Chapter(
        id: 'chapter_2_${now.millisecondsSinceEpoch}',
        title: 'Chapter 2: Into Shadowvale',
        content: '''The entrance to Shadowvale loomed before them like the maw of some great beast. Ancient oaks twisted together overhead, their branches so thick and intertwined that barely any sunlight penetrated to the forest floor. A perpetual twilight reigned beneath those primordial boughs, broken only by the occasional shaft of golden light that filtered through gaps in the canopy.

Alice felt a chill run down her spine as she stepped across the invisible threshold that marked the forest's boundary. The air itself seemed to change, growing thick and heavy with the scent of moss and decay. Behind her, the cheerful sounds of birdsong and rustling leaves fell silent, replaced by an oppressive quiet that pressed against her ears.

"Stay close," Bob warned, his staff beginning to emit a soft blue glow. "Shadowvale does not welcome outsiders. The forest will test us, probe for weaknesses. You must guard your thoughts carefully, for there are things here that feed on fear and doubt."

They walked for what felt like hours, though time moved strangely in this place. The path twisted and turned, sometimes doubling back on itself in ways that defied logic. More than once, Alice was certain they had passed the same gnarled oak or moss-covered boulder, yet Bob pressed forward without hesitation.

It was near what Alice assumed was midday when they encountered their first real obstacle. A figure stood in the center of the path, tall and impossibly thin, wrapped in robes that seemed woven from shadow itself. Its face was hidden beneath a deep hood, but Alice could feel its gaze upon her like the weight of a mountain.

"Who dares trespass in the domain of the Shadow Court?" the figure demanded, its voice echoing from everywhere and nowhere at once. "Speak your names and purpose, or be consumed by the eternal darkness."

Bob stepped forward, planting his staff firmly in the soft earth. "I am Bob the Wanderer, bearer of the Seventh Seal, and I invoke the ancient compact between your Court and the Council of Seven. We seek passage to the Crystal Chamber, as is our right under the old laws."

The shadow figure seemed to consider this for a long moment. Then, slowly, it stepped aside, revealing a path that Alice was certain had not existed moments before. "The compact holds," it intoned. "But be warned, Wanderer. The Crystal's guardian does not honor such agreements. What lies ahead, you must face alone."

As they passed the shadow guardian, Alice caught a glimpse beneath its hood—or rather, the absence of anything beneath it. Where a face should have been, there was only void, a darkness so complete that it seemed to swallow light itself. She hurried past, fighting the urge to run.

The path beyond led deeper into the forest, to places where even the twilight faded to near-total darkness. Strange sounds echoed through the trees: whispers in languages long forgotten, the distant sound of bells, the occasional crash of something massive moving through the undergrowth.

"We're being followed," Alice whispered, her hand instinctively moving to the dagger at her belt.

Bob nodded grimly. "The forest sends its servants to observe us. As long as we follow the path and take nothing from this place, they will not attack. But make no mistake—we are not welcome here. Shadowvale tolerates our presence, nothing more."''',
        order: 1,
        createdAt: now.add(const Duration(seconds: 1)),
        updatedAt: now.add(const Duration(seconds: 1)),
      ),
      Chapter(
        id: 'chapter_3_${now.millisecondsSinceEpoch}',
        title: 'Chapter 3: The Crystal Chamber',
        content: '''They emerged from the forest into a clearing that defied all natural laws. The sky above was not the grey overcast of Shadowvale but a brilliant tapestry of stars, despite the fact that it should have been midday. In the center of the clearing stood a structure of impossible beauty: the Crystal Chamber, carved from a single massive gemstone that pulsed with inner light.

Alice approached the chamber slowly, her breath catching in her throat. The crystal walls were transparent, revealing a labyrinth of corridors within, each one glowing with a different color of light. At the very center, visible through countless layers of crystalline walls, she could see her objective: the Crystal of Light, floating on a pedestal of pure energy.

"This is as far as I can guide you," Bob said, his voice heavy with regret. "The chamber's magic will not permit my entry. Only one of pure heart and true purpose may walk its halls. But take heed, Alice—the chamber is a living thing. It will show you visions, test your resolve. Everything you see within may be illusion, or it may be the deepest truth. You must find the wisdom to know the difference."

Alice turned to face her mentor, seeing for the first time the full weight of years upon his shoulders. "Will I see you again?"

"That depends entirely on what you find within," Bob replied. "Go now. The curse grows stronger with each passing hour, and your village needs its champion."

With a deep breath, Alice stepped through the entrance to the Crystal Chamber. The moment she crossed the threshold, the world around her shifted. The starlit sky vanished, replaced by swirling colors that seemed to move with purpose. The air hummed with energy, and she could feel the chamber's attention focusing on her like a great eye opening.

"Welcome, seeker," a voice resonated through the crystal walls. "I am the Guardian of the Crystal, keeper of the light that banishes shadow. You seek the power to break an ancient curse. But power always comes with a price. Are you prepared to pay it?"

Alice straightened her shoulders. "I am prepared to do whatever is necessary to save my people."

"Then let the trials begin."

The floor beneath her feet dissolved into light, and Alice found herself falling through an endless void of color and sound. When she finally landed, she stood in a place she recognized all too well: her childhood home, on the night her mother died. And there, sitting by the cold fireplace, was a figure she had never expected to see again.

"Hello, daughter," her mother said, her eyes filled with tears. "We have much to discuss about your destiny, and the choices that lie before you."''',
        order: 2,
        createdAt: now.add(const Duration(seconds: 2)),
        updatedAt: now.add(const Duration(seconds: 2)),
      ),
    ];
  }

  static List<KnowledgeItem> createTemplateKnowledgeItems() {
    final now = DateTime.now();

    return [
      // Characters
      KnowledgeItem(
        id: 'char_alice_${now.millisecondsSinceEpoch}',
        name: 'Alice',
        type: 'characters',
        description:
            'Alice is a brave young woman from Millbrook Village who embarks on a journey to save her people from an ancient curse. She is twenty-three years old, resourceful, kind-hearted, and determined. Despite her fears, she never backs down from a challenge. Her grandmother entrusted her with the task of finding the Crystal of Light.',
        appearances: [],
      ),
      KnowledgeItem(
        id: 'char_bob_${now.millisecondsSinceEpoch}',
        name: 'Bob',
        type: 'characters',
        description:
            'Bob the Wanderer is the last surviving member of the Council of Seven, an ancient order of wizards. He has lived for centuries, watching over Alice from afar since her birth. His long grey beard and weathered robes mark him as a traveler, while the strange symbols on his sleeves hint at forbidden knowledge. He serves as Alice\'s mentor and guide on her quest.',
        appearances: [],
      ),

      // Locations
      KnowledgeItem(
        id: 'loc_millbrook_${now.millisecondsSinceEpoch}',
        name: 'Millbrook Village',
        type: 'locations',
        description:
            'Millbrook Village is a quiet hamlet where Alice grew up. It has cobblestone streets and thatched-roof cottages. The village has been afflicted by a mysterious sleeping sickness that traps victims in endless nightmares. The village elders recognized Alice as the chosen one from an ancient prophecy.',
        appearances: [],
      ),
      KnowledgeItem(
        id: 'loc_shadowvale_${now.millisecondsSinceEpoch}',
        name: 'Shadowvale',
        type: 'locations',
        description:
            'Shadowvale is an ancient, primordial forest shrouded in perpetual twilight. The trees are so old and intertwined that barely any sunlight reaches the forest floor. Time moves strangely within its borders, and the forest itself seems alive and hostile to outsiders. It is controlled by the Shadow Court and contains the Crystal Chamber at its heart.',
        appearances: [],
      ),
      KnowledgeItem(
        id: 'loc_whispering_${now.millisecondsSinceEpoch}',
        name: 'Whispering Woods',
        type: 'locations',
        description:
            'The Whispering Woods is an ancient forest on the road to Shadowvale. The trees are said to possess consciousness, and travelers report hearing voices carried on the wind—warnings whispered by unseen watchers. Most people avoid the woods entirely, preferring the longer route through the Northern Pass.',
        appearances: [],
      ),
      KnowledgeItem(
        id: 'loc_crystal_chamber_${now.millisecondsSinceEpoch}',
        name: 'Crystal Chamber',
        type: 'locations',
        description:
            'The Crystal Chamber is a structure of impossible beauty at the heart of Shadowvale, carved from a single massive gemstone that pulses with inner light. Its transparent walls reveal a labyrinth of corridors, each glowing with different colors. Only those of pure heart may enter. The chamber is a living thing that tests visitors with visions and trials.',
        appearances: [],
      ),

      // Objects
      KnowledgeItem(
        id: 'obj_crystal_${now.millisecondsSinceEpoch}',
        name: 'Crystal of Light',
        type: 'objects',
        description:
            'The Crystal of Light is a legendary artifact with the power to break any curse. It floats on a pedestal of pure energy at the center of the Crystal Chamber, visible through countless layers of crystalline walls. Many have sought it, but few have survived the trials required to obtain it.',
        appearances: [],
      ),

      // Events/Organizations
      KnowledgeItem(
        id: 'org_council_${now.millisecondsSinceEpoch}',
        name: 'Council of Seven',
        type: 'events',
        description:
            'The Council of Seven was an ancient order of powerful wizards who made compacts with the Shadow Court and other mystical entities. Bob the Wanderer is the last surviving member. They were keepers of secrets that could reshape the world.',
        appearances: [],
      ),
      KnowledgeItem(
        id: 'org_shadow_court_${now.millisecondsSinceEpoch}',
        name: 'Shadow Court',
        type: 'events',
        description:
            'The Shadow Court rules over Shadowvale forest. Their servants are tall, impossibly thin figures wrapped in robes woven from shadow, with only void where their faces should be. They honor ancient compacts with the Council of Seven but warn that the Crystal\'s guardian follows no such agreements.',
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
        summary: 'The chosen one destined to break the curse',
        description:
            'Alice is a brave twenty-three-year-old woman from Millbrook Village. She embarks on a journey to find the Crystal of Light and save her people from an ancient curse.',
      ),
      EntityMetadata(
        id: '2',
        name: 'Bob',
        type: EntityType.character,
        summary: 'Last wizard of the Council of Seven',
        description:
            'Bob the Wanderer is an ancient wizard who has watched over Alice since her birth. He is the last surviving member of the Council of Seven and serves as her mentor.',
      ),

      // Locations
      EntityMetadata(
        id: '3',
        name: 'Millbrook Village',
        type: EntityType.location,
        summary: 'Alice\'s home village afflicted by a curse',
        description:
            'A quiet hamlet with cobblestone streets and thatched cottages. The village suffers from a mysterious sleeping sickness.',
      ),
      EntityMetadata(
        id: '4',
        name: 'Shadowvale',
        type: EntityType.location,
        summary: 'An ancient forest ruled by the Shadow Court',
        description:
            'A primordial forest shrouded in perpetual twilight where time moves strangely. It contains the Crystal Chamber at its heart.',
      ),
      EntityMetadata(
        id: '5',
        name: 'Whispering Woods',
        type: EntityType.location,
        summary: 'A forest where the trees are conscious',
        description:
            'An ancient forest on the road to Shadowvale where travelers hear voices on the wind.',
      ),
      EntityMetadata(
        id: '6',
        name: 'Crystal Chamber',
        type: EntityType.location,
        summary: 'The sanctuary of the Crystal of Light',
        description:
            'A structure carved from a single gemstone at the heart of Shadowvale. Only those of pure heart may enter.',
      ),

      // Objects
      EntityMetadata(
        id: '7',
        name: 'Crystal of Light',
        type: EntityType.object,
        summary: 'A legendary artifact that can break any curse',
        description:
            'The Crystal of Light floats on a pedestal of pure energy at the center of the Crystal Chamber.',
      ),

      // Organizations
      EntityMetadata(
        id: '8',
        name: 'Council of Seven',
        type: EntityType.object,
        summary: 'An ancient order of wizards',
        description:
            'A once-powerful order that made compacts with mystical entities. Bob is the last surviving member.',
      ),
      EntityMetadata(
        id: '9',
        name: 'Shadow Court',
        type: EntityType.object,
        summary: 'The rulers of Shadowvale forest',
        description:
            'Mysterious entities that control Shadowvale. Their servants are shadow-robed figures with void for faces.',
      ),
    ];
  }
}
