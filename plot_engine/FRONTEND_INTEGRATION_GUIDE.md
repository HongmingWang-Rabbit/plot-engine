# Frontend Integration Guide - Complete API Reference

## Overview

The PlotEngine backend uses a **file-first architecture** where all project data is stored in Google Drive. This guide shows you how to integrate with the API endpoints for projects, chapters, and entities.

**Last Updated**: November 25, 2025
**API Base URL**: `http://localhost:3000`

---

## 🔑 Authentication

All endpoints (except `/auth/*`) require JWT authentication.

### Get JWT Token

```bash
# 1. Redirect user to Google OAuth
GET /auth/google

# 2. User signs in, gets redirected with token
```

### Use Token in Requests

```javascript
fetch('http://localhost:3000/projects', {
  headers: {
    'Authorization': `Bearer ${token}`
  }
});
```

---

## 📊 Complete Data Structure

### Project Response (Everything in One Call!)

```json
{
  "id": "uuid",
  "title": "My Novel",
  "description": "A fantasy epic",
  "genre": "fantasy",
  "created_at": "2025-11-25T12:00:00Z",
  "updated_at": "2025-11-25T12:00:00Z",
  "metadata": {
    "word_count": 50000,
    "chapter_count": 10
  },
  "chapters": [
    {
      "id": "uuid",
      "title": "Chapter 1",
      "content": "Once upon a time...",
      "word_count": 5000,
      "order_index": 0,
      "created_at": "2025-11-25T12:00:00Z",
      "updated_at": "2025-11-25T12:00:00Z",
      "metadata": {
        "tags": [],
        "notes": ""
      }
    }
  ],
  "entities": [
    {
      "id": "uuid",
      "name": "Alice",
      "type": "character",
      "summary": "The protagonist",
      "description": "Full detailed description...",
      "customType": null,
      "createdAt": "2025-11-25T12:00:00Z",
      "updatedAt": "2025-11-25T12:00:00Z"
    }
  ]
}
```

---

## 🎯 TypeScript Types

```typescript
interface Project {
  id: string;
  title: string;
  description: string;
  genre: string;
  created_at: string;
  updated_at: string;
  metadata: ProjectMetadata;
  chapters: Chapter[];
  entities: Entity[];  // ← NEW! All entity types unified
}

interface ProjectMetadata {
  word_count: number;
  chapter_count: number;
}

interface Chapter {
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

interface Entity {
  id: string;
  name: string;
  type: EntityType;
  summary: string;
  description: string;
  customType: string | null;
  createdAt: string;
  updatedAt: string;
}

type EntityType = 'character' | 'location' | 'object' | 'event' | 'custom';
```

---

## 📡 API Endpoints

### Projects

#### GET /projects
List all user's projects (lightweight metadata only)

```typescript
Response: {
  "projects": [
    {
      "id": "uuid",
      "title": "My Novel",
      "description": "...",
      "genre": "fantasy",
      "created_at": "...",
      "updated_at": "..."
    }
  ]
}
```

#### GET /projects/:projectId
Get complete project with all chapters and entities

```typescript
Response: Project (see structure above)
```

#### POST /projects
Create new project

```typescript
Body: {
  "title": "My Novel",
  "description": "A fantasy epic",
  "genre": "fantasy",
  "initialChapterTitle": "Chapter 1",  // Optional
  "initialChapterContent": "..."       // Optional
}

Response: 201 Created + Project
```

#### PATCH /projects/:projectId
Update project metadata

```typescript
Body: {
  "title": "Updated Title",       // Optional
  "description": "Updated desc",  // Optional
  "genre": "sci-fi"              // Optional
}

Response: 200 OK + Project
```

#### DELETE /projects/:projectId
Delete project

```typescript
Response: 204 No Content
```

---

### Chapters

#### GET /projects/:projectId/chapters
Get all chapters for a project

```typescript
Response: {
  "chapters": [Chapter, ...]
}
```

#### POST /projects/:projectId/chapters
Create new chapter

```typescript
Body: {
  "title": "Chapter 2",
  "content": "The story continues...",
  "order_index": 1,
  "tags": ["action"],         // Optional
  "notes": "Plot twist here"  // Optional
}

Response: 201 Created + Chapter
```

#### PATCH /chapters/:chapterId
Update chapter

```typescript
Body: {
  "title": "Updated Title",         // Optional
  "content": "Updated content...",  // Optional
  "order_index": 2,                 // Optional
  "tags": ["action", "drama"],      // Optional
  "notes": "Revised ending"         // Optional
}

Response: 200 OK + Chapter
```

#### DELETE /chapters/:chapterId
Delete chapter

```typescript
Response: 204 No Content
```

---

### Entities (NEW! ⭐)

All entity types unified under these endpoints:

#### GET /projects/:projectId/entities
Get all entities for a project

```typescript
Response: {
  "entities": [
    {
      "id": "uuid",
      "name": "Alice",
      "type": "character",
      "summary": "The protagonist",
      "description": "Full description...",
      "customType": null,
      "createdAt": "...",
      "updatedAt": "..."
    }
  ]
}
```

#### POST /projects/:projectId/entities
Create new entity

```typescript
Body: {
  "name": "Alice Blackwood",
  "type": "character",  // character | location | object | event | custom
  "summary": "A brave detective",
  "description": "Full detailed bio...",
  "customType": null  // Required if type is "custom"
}

Response: 201 Created + { "entity": Entity }
```

**Entity Types**:
- `character` - People, creatures, beings
- `location` - Places, buildings, regions
- `object` - Items, artifacts, tools
- `event` - Historical events, battles
- `custom` - User-defined (requires `customType`)

#### PATCH /projects/:projectId/entities/:entityId
Update entity

```typescript
Body: {
  "name": "Alice Smith",         // Optional
  "summary": "Updated summary",  // Optional
  "description": "Updated bio",  // Optional
  "type": "character"           // Optional
}

Response: 200 OK + { "entity": Entity }
```

#### DELETE /projects/:projectId/entities/:entityId
Delete entity

```typescript
Response: 204 No Content
```

---

## 💻 React/TypeScript Implementation

### API Client

```typescript
// api/client.ts
const API_BASE = 'http://localhost:3000';

export class PlotEngineAPI {
  constructor(private token: string) {}

  private async request<T>(endpoint: string, options?: RequestInit): Promise<T> {
    const response = await fetch(`${API_BASE}${endpoint}`, {
      ...options,
      headers: {
        'Authorization': `Bearer ${this.token}`,
        'Content-Type': 'application/json',
        ...options?.headers,
      },
    });

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.message || 'API request failed');
    }

    if (response.status === 204) return null as T;
    return response.json();
  }

  // Projects
  async getProject(id: string) {
    return this.request<Project>(`/projects/${id}`);
  }

  async createProject(data: CreateProjectRequest) {
    return this.request<Project>('/projects', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  // Chapters
  async createChapter(projectId: string, data: CreateChapterRequest) {
    return this.request<Chapter>(`/projects/${projectId}/chapters`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateChapter(chapterId: string, data: UpdateChapterRequest) {
    return this.request<Chapter>(`/chapters/${chapterId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteChapter(chapterId: string) {
    return this.request<void>(`/chapters/${chapterId}`, {
      method: 'DELETE',
    });
  }

  // Entities
  async createEntity(projectId: string, data: CreateEntityRequest) {
    return this.request<{ entity: Entity }>(`/projects/${projectId}/entities`, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  async updateEntity(projectId: string, entityId: string, data: UpdateEntityRequest) {
    return this.request<{ entity: Entity }>(`/projects/${projectId}/entities/${entityId}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  async deleteEntity(projectId: string, entityId: string) {
    return this.request<void>(`/projects/${projectId}/entities/${entityId}`, {
      method: 'DELETE',
    });
  }
}
```

### React Hook

```typescript
// hooks/useProject.ts
import { useState, useEffect, useCallback } from 'react';
import { PlotEngineAPI } from '../api/client';

export function useProject(projectId: string | null) {
  const [project, setProject] = useState<Project | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);

  const api = new PlotEngineAPI(localStorage.getItem('token') || '');

  const loadProject = useCallback(async () => {
    if (!projectId) return;

    try {
      setLoading(true);
      const data = await api.getProject(projectId);
      setProject(data);
    } catch (err) {
      setError(err as Error);
    } finally {
      setLoading(false);
    }
  }, [projectId]);

  useEffect(() => {
    loadProject();
  }, [loadProject]);

  const createEntity = useCallback(async (data: CreateEntityRequest) => {
    if (!projectId) return;
    await api.createEntity(projectId, data);
    await loadProject();
  }, [projectId]);

  const updateEntity = useCallback(async (entityId: string, data: UpdateEntityRequest) => {
    if (!projectId) return;
    await api.updateEntity(projectId, entityId, data);
    await loadProject();
  }, [projectId]);

  const deleteEntity = useCallback(async (entityId: string) => {
    if (!projectId) return;
    await api.deleteEntity(projectId, entityId);
    await loadProject();
  }, [projectId]);

  return {
    project,
    loading,
    error,
    reload: loadProject,
    createEntity,
    updateEntity,
    deleteEntity,
  };
}
```

### Entity Manager Component

```tsx
// components/EntityManager.tsx
export function EntityManager({ projectId }: { projectId: string }) {
  const { project, createEntity, updateEntity, deleteEntity } = useProject(projectId);
  const [filter, setFilter] = useState<EntityType | 'all'>('all');

  if (!project) return null;

  const filteredEntities = filter === 'all'
    ? project.entities
    : project.entities.filter(e => e.type === filter);

  const counts = {
    character: project.entities.filter(e => e.type === 'character').length,
    location: project.entities.filter(e => e.type === 'location').length,
    object: project.entities.filter(e => e.type === 'object').length,
    event: project.entities.filter(e => e.type === 'event').length,
    custom: project.entities.filter(e => e.type === 'custom').length,
  };

  return (
    <div>
      <div className="filters">
        <button onClick={() => setFilter('all')}>All ({project.entities.length})</button>
        <button onClick={() => setFilter('character')}>Characters ({counts.character})</button>
        <button onClick={() => setFilter('location')}>Locations ({counts.location})</button>
        <button onClick={() => setFilter('object')}>Objects ({counts.object})</button>
        <button onClick={() => setFilter('event')}>Events ({counts.event})</button>
        <button onClick={() => setFilter('custom')}>Custom ({counts.custom})</button>
      </div>

      <button onClick={() => /* open create form */}>+ New Entity</button>

      {filteredEntities.map(entity => (
        <EntityCard
          key={entity.id}
          entity={entity}
          onUpdate={(data) => updateEntity(entity.id, data)}
          onDelete={() => deleteEntity(entity.id)}
        />
      ))}
    </div>
  );
}
```

---

## 🔄 Key Changes

### Before (Database-First)

```javascript
// Multiple requests needed
const project = await getProject(id);
const chapters = await getChapters(id);
const characters = await getCharacters(id);
const locations = await getLocations(id);

// Different endpoints per type
POST /projects/:id/characters
POST /projects/:id/locations
```

### After (File-First) ✅

```javascript
// Single request!
const project = await getProject(id);
// project.chapters ✅
// project.entities ✅ (all types)

// Unified endpoints
POST /projects/:id/entities  // All types
```

---

## 💡 Best Practices

### 1. Caching

```typescript
const cache = new Map<string, { data: Project; time: number }>();
const CACHE_TTL = 5 * 60 * 1000; // 5 min

async function loadProject(id: string) {
  const cached = cache.get(id);
  if (cached && Date.now() - cached.time < CACHE_TTL) {
    return cached.data;
  }

  const data = await api.getProject(id);
  cache.set(id, { data, time: Date.now() });
  return data;
}
```

### 2. Optimistic Updates

```typescript
async function updateEntity(id: string, updates: UpdateEntityRequest) {
  const original = { ...project };

  // Update UI immediately
  setProject({
    ...project,
    entities: project.entities.map(e =>
      e.id === id ? { ...e, ...updates } : e
    ),
  });

  try {
    await api.updateEntity(projectId, id, updates);
  } catch (error) {
    setProject(original); // Rollback on error
    showError('Update failed');
  }
}
```

### 3. Entity Filtering

```typescript
const characters = project.entities.filter(e => e.type === 'character');
const locations = project.entities.filter(e => e.type === 'location');
const objects = project.entities.filter(e => e.type === 'object');
const events = project.entities.filter(e => e.type === 'event');
```

---

## 🐛 Troubleshooting

### "Entity name already exists"
Entity names must be unique per project. Use a different name or update the existing entity.

### "Unauthorized"
Token expired. Re-authenticate:
```typescript
window.location.href = '/auth/google';
```

### Slow loading
Implement caching and show loading indicators for Google Drive operations.

---

## ✅ Migration Checklist

- [ ] Update API client with entity endpoints
- [ ] Add Entity type definitions
- [ ] Update project loading (expects entities array)
- [ ] Implement entity filtering by type
- [ ] Add entity CRUD operations
- [ ] Implement caching
- [ ] Add loading indicators
- [ ] Handle entity name conflicts
- [ ] Test with large projects

---

## 📚 Documentation

- **Specification**: `BACKEND_ENTITY_STORAGE_SPEC.md`
- **Implementation**: `ENTITY_STORAGE_IMPLEMENTATION.md`
- **Test Script**: `test-entity-storage.sh`
- **Database Cleanup**: `DATABASE_CLEANUP_GUIDE.md`

---

**Version**: 2.0 (File-First)
**Status**: ✅ Production Ready
**Last Updated**: November 25, 2025
