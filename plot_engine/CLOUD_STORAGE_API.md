# Cloud Storage API Reference

## Overview

PlotEngine uses Google Drive as the primary data storage. The database only stores a reference (`storage_folder_id`) to the Drive folder.

---

## Storage Structure

```
Google Drive
└── PlotEngine/
    └── {Project Title}/
        ├── project.json          # Project metadata
        ├── chapters/
        │   └── {uuid}.json       # Chapter data
        ├── entities.json         # All entity metadata
        └── entities/
            └── entity_{uuid}.txt # Entity descriptions
```

---

## API Response Formats

### GET /projects

```json
{
  "projects": [
    {
      "id": "uuid",
      "user_id": "uuid",
      "title": "My Novel",
      "description": "A story about...",
      "genre": "fantasy",
      "storage_folder_id": "drive-folder-id",
      "storage_provider": "google_drive",
      "is_active": true,
      "deleted_at": null,
      "created_at": "2025-11-25T12:00:00Z",
      "updated_at": "2025-11-25T12:00:00Z"
    }
  ]
}
```

### GET /projects/:id

```json
{
  "project": {
    "id": "uuid",
    "user_id": "uuid",
    "folder_id": "drive-folder-id",
    "storage_folder_id": "drive-folder-id",
    "storage_provider": "google_drive",
    "title": "My Novel",
    "description": "A story about...",
    "genre": "fantasy",
    "is_active": true,
    "created_at": "2025-11-25T12:00:00Z",
    "updated_at": "2025-11-25T12:00:00Z",
    "metadata": {
      "word_count": 5000,
      "chapter_count": 3,
      "character_count": 2,
      "location_count": 1
    },
    "chapters": [
      {
        "id": "uuid",
        "title": "Chapter 1",
        "content": "Once upon a time...",
        "word_count": 1500,
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
        "customType": "",
        "createdAt": "2025-11-25T12:00:00Z",
        "updatedAt": "2025-11-25T12:00:00Z",
        "description": "Full character description..."
      }
    ]
  }
}
```

### POST /projects/:id/chapters

**Request:**
```json
{
  "title": "Chapter 2",
  "content": "The adventure continues...",
  "order_index": 1
}
```

**Response:**
```json
{
  "id": "uuid",
  "title": "Chapter 2",
  "content": "The adventure continues...",
  "word_count": 50,
  "order_index": 1,
  "created_at": "2025-11-25T12:00:00Z",
  "updated_at": "2025-11-25T12:00:00Z",
  "metadata": {
    "tags": [],
    "notes": ""
  }
}
```

### POST /projects/:id/entities

**Request:**
```json
{
  "name": "Alice",
  "type": "character",
  "summary": "The protagonist",
  "description": "Full description here..."
}
```

**Response:**
```json
{
  "entity": {
    "id": "uuid",
    "name": "Alice",
    "type": "character",
    "summary": "The protagonist",
    "customType": "",
    "createdAt": "2025-11-25T12:00:00Z",
    "updatedAt": "2025-11-25T12:00:00Z",
    "description": "Full description here..."
  }
}
```

---

## Entity Types

| Type | Description |
|------|-------------|
| `character` | People, creatures, beings |
| `location` | Places, buildings, regions |
| `object` | Items, artifacts, tools |
| `event` | Historical events, battles |
| `custom` | User-defined (requires `customType`) |

---

## Field Naming

| Context | Convention | Examples |
|---------|------------|----------|
| Project | snake_case | `user_id`, `created_at`, `storage_folder_id` |
| Chapter | snake_case | `word_count`, `order_index`, `created_at` |
| Entity | camelCase | `customType`, `createdAt`, `updatedAt` |

---

## Nullable Fields

| Field | Nullable | Default |
|-------|----------|---------|
| `deleted_at` | Yes | `null` |
| All other strings | No | `""` |
| All numbers | No | `0` |
| All booleans | No | `true/false` |
| All arrays | No | `[]` |

---

## Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/projects` | List projects |
| GET | `/projects/:id` | Get full project |
| POST | `/projects` | Create project |
| PATCH | `/projects/:id` | Update project |
| DELETE | `/projects/:id` | Delete project |
| GET | `/projects/:id/chapters` | List chapters |
| POST | `/projects/:id/chapters` | Create chapter |
| PATCH | `/projects/:id/chapters/:chapterId` | Update chapter |
| DELETE | `/projects/:id/chapters/:chapterId` | Delete chapter |
| GET | `/projects/:id/entities` | List entities |
| POST | `/projects/:id/entities` | Create entity |
| PATCH | `/projects/:id/entities/:entityId` | Update entity |
| DELETE | `/projects/:id/entities/:entityId` | Delete entity |

---

**Version**: 2.1
**Updated**: November 25, 2025
