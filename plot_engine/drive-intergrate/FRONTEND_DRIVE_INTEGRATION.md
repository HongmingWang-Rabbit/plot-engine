# Frontend Integration Guide - File-Based Architecture

## Overview

The PlotEngine backend now uses a **file-first architecture** where all project data is stored in Google Drive as JSON files. This guide shows you how to integrate the new API responses in your frontend.

## 🔄 What Changed

### Before (Database-First)
```javascript
// GET /projects/:id returned minimal data
{
  "project": {
    "id": "uuid",
    "title": "My Novel",
    "description": "...",
    "chapters": []  // Empty! Needed separate /chapters request
  }
}

// Separate request needed for chapters
GET /projects/:projectId/chapters
```

### After (File-First) ✅
```javascript
// GET /projects/:id returns EVERYTHING
{
  "id": "uuid",
  "title": "My Novel",
  "description": "...",
  "genre": "fantasy",
  "created_at": "2025-11-25T12:00:00Z",
  "updated_at": "2025-11-25T12:00:00Z",
  "metadata": {
    "word_count": 50000,
    "chapter_count": 10,
    "character_count": 5,
    "location_count": 3
  },
  "chapters": [           // ✅ Already included!
    {
      "id": "uuid",
      "title": "Chapter 1",
      "content": "...",
      "word_count": 5000,
      "order_index": 0,
      "created_at": "...",
      "updated_at": "...",
      "metadata": {
        "tags": [],
        "notes": ""
      }
    }
  ],
  "characters": [         // ✅ Bonus!
    {
      "id": "uuid",
      "name": "John Smith",
      "description": "...",
      "traits": ["brave"],
      "relationships": []
    }
  ],
  "locations": [...],     // ✅ All locations
  "plot_events": [...],   // ✅ All events
  "consistency_checks": [...] // ✅ All checks
}
```

## 📱 Frontend Implementation

### React/TypeScript Example

#### Types
```typescript
// types.ts
export interface Project {
  id: string;
  title: string;
  description: string;
  genre: string;
  created_at: string;
  updated_at: string;
  metadata: {
    word_count: number;
    chapter_count: number;
    character_count: number;
    location_count: number;
  };
  chapters: Chapter[];
  characters: Character[];
  locations: Location[];
  plot_events: PlotEvent[];
  consistency_checks: ConsistencyCheck[];
}

export interface Chapter {
  id: string;
  title: string;
  content: string;
  word_count: number;
  order_index: number;
  created_at: string;
  updated_at: string;
  metadata: {
    tags: string[];
    notes: string;
  };
}

export interface Character {
  id: string;
  name: string;
  description: string;
  first_appearance_chapter_id?: string;
  traits: string[];
  relationships: Relationship[];
  created_at: string;
  updated_at: string;
}

export interface Relationship {
  character_id: string;
  type: string;
  description: string;
}

export interface Location {
  id: string;
  name: string;
  description: string;
  first_appearance_chapter_id?: string;
  attributes: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface PlotEvent {
  id: string;
  chapter_id: string;
  event_type: string;
  description: string;
  characters_involved: string[];
  locations_involved: string[];
  foreshadowing_references: string[];
  timeline_position?: number;
  metadata: Record<string, any>;
  created_at: string;
  updated_at: string;
}

export interface ConsistencyCheck {
  id: string;
  chapter_id: string;
  check_type: string;
  severity: string;
  description: string;
  suggestion?: string;
  resolved: boolean;
  created_at: string;
  updated_at: string;
}
```

#### API Hook
```typescript
// hooks/useProject.ts
import { useState, useEffect } from 'react';
import { Project } from '../types';

export const useProject = (projectId: string) => {
  const [project, setProject] = useState<Project | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    loadProject();
  }, [projectId]);

  const loadProject = async () => {
    try {
      setLoading(true);
      const response = await fetch(
        `http://localhost:3000/projects/${projectId}`,
        {
          headers: {
            'Authorization': `Bearer ${getToken()}`
          }
        }
      );

      if (!response.ok) {
        throw new Error('Failed to load project');
      }

      const data = await response.json();
      setProject(data);  // Entire project with all data!
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  };

  const updateChapter = async (chapterId: string, updates: Partial<Chapter>) => {
    try {
      const response = await fetch(
        `http://localhost:3000/chapters/${chapterId}`,
        {
          method: 'PATCH',
          headers: {
            'Authorization': `Bearer ${getToken()}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(updates)
        }
      );

      if (!response.ok) {
        throw new Error('Failed to update chapter');
      }

      // Reload entire project to get updated data
      await loadProject();
    } catch (err) {
      setError(err as Error);
    }
  };

  const createChapter = async (data: { title: string; content: string; order_index: number }) => {
    try {
      const response = await fetch(
        `http://localhost:3000/projects/${projectId}/chapters`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${getToken()}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(data)
        }
      );

      if (!response.ok) {
        throw new Error('Failed to create chapter');
      }

      // Reload entire project to get new chapter
      await loadProject();
    } catch (err) {
      setError(err as Error);
    }
  };

  return {
    project,
    loading,
    error,
    reloadProject: loadProject,
    updateChapter,
    createChapter
  };
};

function getToken() {
  return localStorage.getItem('token') || '';
}
```

#### Component Example
```typescript
// components/ProjectEditor.tsx
import React from 'react';
import { useProject } from '../hooks/useProject';

export const ProjectEditor: React.FC<{ projectId: string }> = ({ projectId }) => {
  const { project, loading, error, updateChapter } = useProject(projectId);

  if (loading) return <div>Loading project from Google Drive...</div>;
  if (error) return <div>Error: {error.message}</div>;
  if (!project) return <div>Project not found</div>;

  return (
    <div>
      <h1>{project.title}</h1>
      <p>{project.description}</p>

      <div className="stats">
        <span>📝 {project.metadata.chapter_count} chapters</span>
        <span>📖 {project.metadata.word_count.toLocaleString()} words</span>
        <span>👥 {project.metadata.character_count} characters</span>
        <span>📍 {project.metadata.location_count} locations</span>
      </div>

      <div className="chapters">
        <h2>Chapters</h2>
        {project.chapters
          .sort((a, b) => a.order_index - b.order_index)
          .map(chapter => (
            <ChapterCard
              key={chapter.id}
              chapter={chapter}
              onUpdate={(updates) => updateChapter(chapter.id, updates)}
            />
          ))}
      </div>

      <div className="characters">
        <h2>Characters</h2>
        {project.characters.map(character => (
          <CharacterCard key={character.id} character={character} />
        ))}
      </div>

      <div className="locations">
        <h2>Locations</h2>
        {project.locations.map(location => (
          <LocationCard key={location.id} location={location} />
        ))}
      </div>
    </div>
  );
};
```

### Flutter/Dart Example

```dart
// models/project.dart
class Project {
  final String id;
  final String title;
  final String description;
  final String genre;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProjectMetadata metadata;
  final List<Chapter> chapters;
  final List<Character> characters;
  final List<Location> locations;
  final List<PlotEvent> plotEvents;
  final List<ConsistencyCheck> consistencyChecks;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.genre,
    required this.createdAt,
    required this.updatedAt,
    required this.metadata,
    required this.chapters,
    required this.characters,
    required this.locations,
    required this.plotEvents,
    required this.consistencyChecks,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      genre: json['genre'] ?? 'general',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      metadata: ProjectMetadata.fromJson(json['metadata']),
      chapters: (json['chapters'] as List?)
          ?.map((c) => Chapter.fromJson(c))
          .toList() ?? [],
      characters: (json['characters'] as List?)
          ?.map((c) => Character.fromJson(c))
          .toList() ?? [],
      locations: (json['locations'] as List?)
          ?.map((l) => Location.fromJson(l))
          .toList() ?? [],
      plotEvents: (json['plot_events'] as List?)
          ?.map((e) => PlotEvent.fromJson(e))
          .toList() ?? [],
      consistencyChecks: (json['consistency_checks'] as List?)
          ?.map((c) => ConsistencyCheck.fromJson(c))
          .toList() ?? [],
    );
  }
}

// services/project_service.dart
class ProjectService {
  final String baseUrl = 'http://localhost:3000';

  Future<Project> getProject(String projectId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/projects/$projectId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      // Entire project loaded from Google Drive!
      return Project.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load project');
    }
  }

  Future<void> updateChapter(
    String chapterId,
    Map<String, dynamic> updates,
    String token,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/chapters/$chapterId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode(updates),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update chapter');
    }
  }
}
```

## 🎯 Key Integration Points

### 1. Loading Projects
**One request gets everything:**
```javascript
// Before: Multiple requests
const project = await getProject(id);
const chapters = await getChapters(id);
const characters = await getCharacters(id);

// After: Single request
const project = await getProject(id);
// project already contains: chapters, characters, locations, etc.
```

### 2. Real-time Updates
Since data is loaded from Drive, you may want to implement polling or WebSockets for real-time updates:

```typescript
// Polling approach
useEffect(() => {
  const interval = setInterval(() => {
    reloadProject();
  }, 30000); // Reload every 30 seconds

  return () => clearInterval(interval);
}, []);
```

### 3. Optimistic Updates
For better UX, update UI immediately and rollback on error:

```typescript
const updateChapter = async (chapterId: string, updates: Partial<Chapter>) => {
  // Optimistic update
  setProject(prev => ({
    ...prev!,
    chapters: prev!.chapters.map(ch =>
      ch.id === chapterId ? { ...ch, ...updates } : ch
    )
  }));

  try {
    await api.updateChapter(chapterId, updates);
  } catch (error) {
    // Rollback on error
    await loadProject();
    showError('Failed to update chapter');
  }
};
```

### 4. Caching Strategy
Cache loaded projects to avoid repeated Drive API calls:

```typescript
const projectCache = new Map<string, { data: Project; timestamp: number }>();

const loadProject = async (projectId: string) => {
  const cached = projectCache.get(projectId);
  const CACHE_TTL = 5 * 60 * 1000; // 5 minutes

  if (cached && Date.now() - cached.timestamp < CACHE_TTL) {
    return cached.data;
  }

  const data = await fetchProject(projectId);
  projectCache.set(projectId, { data, timestamp: Date.now() });
  return data;
};
```

## ⚠️ Important Notes

### 1. Response Size
Projects now include all data in one response. For large projects:
- Response size will be larger
- Loading time may increase
- Consider showing loading indicators

### 2. Stale Data
Since data is loaded all at once:
- UI might show stale data between reloads
- Implement refresh mechanism
- Show "last updated" timestamp

### 3. Concurrent Edits
Multiple users editing the same project:
- Drive handles file conflicts
- Consider implementing conflict resolution UI
- Show warnings when data has changed

### 4. Offline Support
With Drive storage:
- Can implement offline mode using Drive's offline capabilities
- Sync changes when back online
- Use service workers for caching

## 🚀 Migration Checklist

- [ ] Update API types/interfaces
- [ ] Remove separate chapter/character loading logic
- [ ] Update project loading to expect full data
- [ ] Implement caching for loaded projects
- [ ] Add refresh/reload functionality
- [ ] Update UI to show all project data
- [ ] Add loading indicators for Drive operations
- [ ] Test with large projects (many chapters)
- [ ] Implement error handling for Drive API
- [ ] Add offline support (optional)

## 📚 Additional Resources

- [FILE_BASED_ARCHITECTURE.md](./FILE_BASED_ARCHITECTURE.md) - Architecture overview
- [Test Script](./test-drive-storage.sh) - End-to-end testing
- [API Documentation](./API_DOCUMENTATION.md) - Full API reference

---

**Need help?** Check the [FILE_BASED_ARCHITECTURE.md](./FILE_BASED_ARCHITECTURE.md) for more details about the new architecture.
