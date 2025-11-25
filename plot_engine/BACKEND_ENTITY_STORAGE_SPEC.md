# Backend Entity Storage Specification

## Overview

This document specifies how the backend should store entities (characters, locations, objects, events) in Google Drive, following the same pattern as chapter storage.

## Current Pattern (Chapters)

```
Google Drive: project_{id}/
├── project.json          # Project metadata
├── chapters.json         # Chapter metadata (title, order, timestamps)
├── chapters/
│   ├── chapter_{id}.txt  # Individual chapter content
│   └── ...
```

## Requested Pattern (Entities)

```
Google Drive: project_{id}/
├── project.json          # Project metadata
├── chapters.json         # Chapter metadata
├── chapters/
│   ├── chapter_{id}.txt  # Chapter content
│   └── ...
├── entities.json         # Entity metadata (NEW)
└── entities/             # Entity descriptions (NEW)
    ├── entity_{id}.txt   # Individual entity description
    └── ...
```

## Entity Data Structure

### entities.json
Contains metadata for all entities (lightweight, fast to load):

```json
[
  {
    "id": "uuid-string",
    "name": "Alice",
    "type": "character",
    "summary": "The protagonist of the story",
    "customType": null,
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:00:00Z"
  },
  {
    "id": "uuid-string",
    "name": "Shadowvale",
    "type": "location",
    "summary": "A dark and mysterious forest",
    "customType": null,
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:00:00Z"
  },
  {
    "id": "uuid-string",
    "name": "Crystal of Light",
    "type": "object",
    "summary": "A magical artifact",
    "customType": null,
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:00:00Z"
  },
  {
    "id": "uuid-string",
    "name": "The Great Battle",
    "type": "event",
    "summary": "A pivotal moment in history",
    "customType": null,
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:00:00Z"
  },
  {
    "id": "uuid-string",
    "name": "Magic System",
    "type": "custom",
    "summary": "The rules of magic",
    "customType": "world-building",
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:00:00Z"
  }
]
```

### entities/entity_{id}.txt
Contains the full description for each entity (can be large text):

```
Alice is a brave young woman who embarks on a journey to save her village from an ancient curse.

Physical Description:
- Age: 22
- Height: 5'6"
- Hair: Long, dark brown
- Eyes: Emerald green

Personality:
- Brave and determined
- Kind-hearted but fierce when needed
- Quick thinker in dangerous situations
- Has a fear of deep water

Background:
She grew up in the small village of Millbrook...

[Full detailed description continues...]
```

## Entity Types

The `type` field must be one of:
- `"character"` - People, creatures, beings
- `"location"` - Places, buildings, regions
- `"object"` - Items, artifacts, tools
- `"event"` - Historical events, battles, ceremonies
- `"custom"` - User-defined types (requires `customType` field)

## API Endpoints

### 1. Get Project (Include Entities)

**Existing**: `GET /projects/:projectId`

**Update to include**:
```json
{
  "id": "uuid",
  "title": "My Novel",
  "chapters": [...],
  "entities": [              // ← ADD THIS
    {
      "id": "uuid",
      "name": "Alice",
      "type": "character",
      "summary": "The protagonist",
      "description": "Full description...",  // ← Loaded from entity_{id}.txt
      "customType": null,
      "createdAt": "2025-11-25T12:00:00Z",
      "updatedAt": "2025-11-25T12:00:00Z"
    }
  ]
}
```

**Implementation**:
1. Load `entities.json` from Drive
2. For each entity, load `entities/entity_{id}.txt`
3. Combine metadata + description
4. Return in project response

### 2. Create Entity

**New**: `POST /projects/:projectId/entities`

**Request Body**:
```json
{
  "name": "Alice",
  "type": "character",
  "summary": "The protagonist of the story",
  "description": "Alice is a brave young woman who...",
  "customType": null  // Only for type="custom"
}
```

**Response**:
```json
{
  "entity": {
    "id": "generated-uuid",
    "name": "Alice",
    "type": "character",
    "summary": "The protagonist of the story",
    "description": "Alice is a brave young woman who...",
    "customType": null,
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:00:00Z"
  }
}
```

**Implementation**:
1. Generate new UUID
2. Create entity metadata object
3. Load existing `entities.json` from Drive
4. Append new entity metadata to array
5. Save updated `entities.json` to Drive
6. Save description to `entities/entity_{id}.txt` in Drive
7. Return entity with full data

### 3. Update Entity

**New**: `PATCH /projects/:projectId/entities/:entityId`

**Request Body** (all fields optional):
```json
{
  "name": "Alice Smith",
  "summary": "Updated summary",
  "description": "Updated full description...",
  "type": "character"
}
```

**Response**:
```json
{
  "entity": {
    "id": "uuid",
    "name": "Alice Smith",
    "type": "character",
    "summary": "Updated summary",
    "description": "Updated full description...",
    "customType": null,
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:30:00Z"  // ← Updated
  }
}
```

**Implementation**:
1. Load `entities.json` from Drive
2. Find entity by ID
3. Update metadata fields
4. Update `updatedAt` timestamp
5. Save updated `entities.json` to Drive
6. If description changed, save to `entities/entity_{id}.txt`
7. Return updated entity

### 4. Delete Entity

**New**: `DELETE /projects/:projectId/entities/:entityId`

**Response**: `204 No Content`

**Implementation**:
1. Load `entities.json` from Drive
2. Remove entity from array
3. Save updated `entities.json` to Drive
4. Delete `entities/entity_{id}.txt` from Drive
5. Return 204

### 5. List Entities (Optional)

**New**: `GET /projects/:projectId/entities`

Returns all entities with full descriptions (same as in GET /projects/:projectId response).

**Response**:
```json
{
  "entities": [
    {
      "id": "uuid",
      "name": "Alice",
      "type": "character",
      "summary": "...",
      "description": "...",
      "customType": null,
      "createdAt": "...",
      "updatedAt": "..."
    }
  ]
}
```

## File Management Details

### Creating entities/ Directory

When the first entity is created:
1. Check if `entities/` folder exists in Drive
2. If not, create it
3. Create `entities.json` with empty array `[]`

### File Names

- Metadata file: `entities.json` (at project root)
- Description files: `entities/entity_{uuid}.txt`

### Character Encoding

All `.txt` files should be UTF-8 encoded.

### File Size Limits

- `entities.json`: Should stay under 1MB (metadata only)
- `entity_{id}.txt`: No hard limit, but recommend < 100KB per entity

## Error Handling

### Error Codes

- `400 Bad Request` - Invalid entity type, missing required fields
- `404 Not Found` - Project or entity not found
- `409 Conflict` - Entity name already exists in project
- `500 Internal Server Error` - Drive API failure

### Error Response Format

```json
{
  "error": "Entity not found",
  "code": "ENTITY_NOT_FOUND",
  "details": {
    "entityId": "uuid",
    "projectId": "uuid"
  }
}
```

## Migration Strategy

### For Existing Projects

If a project doesn't have `entities.json`:
1. Return empty array in `GET /projects/:projectId`
2. Create `entities.json` on first entity creation
3. No migration needed (new feature)

## Example Implementation (Pseudocode)

```javascript
// services/entityService.js

class EntityService {
  async createEntity(projectId, entityData) {
    // 1. Generate ID
    const entityId = generateUUID();
    const now = new Date().toISOString();

    // 2. Create metadata object
    const metadata = {
      id: entityId,
      name: entityData.name,
      type: entityData.type,
      summary: entityData.summary,
      customType: entityData.customType || null,
      createdAt: now,
      updatedAt: now
    };

    // 3. Load existing entities.json
    let entities = [];
    try {
      const entitiesFile = await driveService.getFile(projectId, 'entities.json');
      entities = JSON.parse(entitiesFile.content);
    } catch (error) {
      // File doesn't exist yet, use empty array
    }

    // 4. Add new entity
    entities.push(metadata);

    // 5. Save entities.json
    await driveService.saveFile(
      projectId,
      'entities.json',
      JSON.stringify(entities, null, 2)
    );

    // 6. Save description
    await driveService.saveFile(
      projectId,
      `entities/entity_${entityId}.txt`,
      entityData.description
    );

    // 7. Return full entity
    return {
      ...metadata,
      description: entityData.description
    };
  }

  async getEntities(projectId) {
    // 1. Load entities.json
    const entitiesFile = await driveService.getFile(projectId, 'entities.json');
    const entities = JSON.parse(entitiesFile.content);

    // 2. Load description for each entity
    const fullEntities = await Promise.all(
      entities.map(async (entity) => {
        const descFile = await driveService.getFile(
          projectId,
          `entities/entity_${entity.id}.txt`
        );
        return {
          ...entity,
          description: descFile.content
        };
      })
    );

    return fullEntities;
  }

  async updateEntity(projectId, entityId, updates) {
    // 1. Load entities.json
    const entitiesFile = await driveService.getFile(projectId, 'entities.json');
    let entities = JSON.parse(entitiesFile.content);

    // 2. Find and update entity
    const index = entities.findIndex(e => e.id === entityId);
    if (index === -1) {
      throw new Error('Entity not found');
    }

    entities[index] = {
      ...entities[index],
      ...updates,
      updatedAt: new Date().toISOString()
    };

    // 3. Save entities.json
    await driveService.saveFile(
      projectId,
      'entities.json',
      JSON.stringify(entities, null, 2)
    );

    // 4. Update description if provided
    if (updates.description) {
      await driveService.saveFile(
        projectId,
        `entities/entity_${entityId}.txt`,
        updates.description
      );
    }

    // 5. Load full entity
    const descFile = await driveService.getFile(
      projectId,
      `entities/entity_${entityId}.txt`
    );

    return {
      ...entities[index],
      description: descFile.content
    };
  }

  async deleteEntity(projectId, entityId) {
    // 1. Load entities.json
    const entitiesFile = await driveService.getFile(projectId, 'entities.json');
    let entities = JSON.parse(entitiesFile.content);

    // 2. Remove entity
    entities = entities.filter(e => e.id !== entityId);

    // 3. Save entities.json
    await driveService.saveFile(
      projectId,
      'entities.json',
      JSON.stringify(entities, null, 2)
    );

    // 4. Delete description file
    await driveService.deleteFile(
      projectId,
      `entities/entity_${entityId}.txt`
    );
  }
}
```

## Testing Checklist

- [ ] Create first entity in new project (creates entities.json)
- [ ] Create multiple entities of different types
- [ ] Load project with entities (included in response)
- [ ] Update entity name and description
- [ ] Delete entity (removes from json and deletes file)
- [ ] Handle entity with large description (>10KB)
- [ ] Handle entity with special characters in description
- [ ] Handle entity with empty description
- [ ] Handle custom entity types
- [ ] Concurrent entity updates (race conditions)
- [ ] Error: Create entity in non-existent project
- [ ] Error: Update non-existent entity
- [ ] Error: Delete non-existent entity

## Performance Considerations

### Optimization Tips

1. **Lazy Loading**: For projects with many entities, consider loading descriptions on-demand
2. **Caching**: Cache `entities.json` in memory, reload when modified
3. **Batch Operations**: Support creating/updating multiple entities in one request
4. **Indexing**: Add entity count to project metadata for quick stats

### Monitoring

Track these metrics:
- Average entity description size
- Number of entities per project
- API response time for projects with many entities

## Questions?

Contact: [Your Team]

---

**Document Version**: 1.0
**Date**: November 25, 2025
**Status**: Ready for Implementation
