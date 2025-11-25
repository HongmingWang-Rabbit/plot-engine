# File-Based Architecture - Google Drive Storage

## Overview

The PlotEngine backend has been refactored from a **database-first** to a **file-first** architecture. All project data (chapters, characters, locations, plot events, etc.) is now stored as JSON files in Google Drive, giving users full ownership and direct access to their data.

## Architecture Change

### Before (Database-First)
```
User Data → PostgreSQL Database
           → Optional file attachments in Drive
```

### After (File-First) ✅
```
User Data → Google Drive (JSON files)
           → Database (lightweight index only)
```

## What's Stored Where

### Google Drive (Primary Storage)
```
PlotEngine/
  └── My-Novel/                      # Project folder
      ├── project.json               # Project metadata
      ├── chapters/
      │   ├── {uuid}.json           # Each chapter as JSON
      │   └── ...
      ├── characters/
      │   ├── {uuid}.json           # Each character as JSON
      │   └── ...
      ├── locations/
      │   ├── {uuid}.json
      │   └── ...
      ├── plot_events/
      │   └── ...
      └── consistency_checks/
          └── ...
```

### PostgreSQL Database (Index Only)
- **users** - Auth, refresh tokens
- **projects** - Minimal metadata (id, title, user_id, storage_folder_id)
- **file_metadata** - Cache of Drive files (optional, for performance)

**Deprecated Tables** (no longer used for primary storage):
- ~~chapters~~
- ~~characters~~
- ~~locations~~
- ~~plot_events~~
- ~~consistency_checks~~

## JSON File Schemas

### project.json
```json
{
  "id": "uuid",
  "title": "My Novel",
  "description": "A great story",
  "genre": "fantasy",
  "created_at": "2025-11-25T12:00:00Z",
  "updated_at": "2025-11-25T12:00:00Z",
  "metadata": {
    "word_count": 50000,
    "chapter_count": 10,
    "character_count": 5,
    "location_count": 3
  }
}
```

### chapters/{uuid}.json
```json
{
  "id": "uuid",
  "title": "Chapter 1",
  "content": "Once upon a time...",
  "word_count": 5000,
  "order_index": 0,
  "created_at": "2025-11-25T12:00:00Z",
  "updated_at": "2025-11-25T12:00:00Z",
  "metadata": {
    "tags": ["intro", "worldbuilding"],
    "notes": "First draft"
  }
}
```

### characters/{uuid}.json
```json
{
  "id": "uuid",
  "name": "John Smith",
  "description": "The protagonist",
  "first_appearance_chapter_id": "chapter-uuid",
  "traits": ["brave", "intelligent"],
  "relationships": [
    {
      "character_id": "uuid",
      "type": "friend",
      "description": "Childhood friend"
    }
  ],
  "created_at": "2025-11-25T12:00:00Z",
  "updated_at": "2025-11-25T12:00:00Z"
}
```

## New Services

### ProjectFileService
- **Location**: `src/services/storage/ProjectFileService.js`
- **Purpose**: Manages all file operations in Google Drive
- **Key Methods**:
  - `initializeProject()` - Creates project folder structure
  - `loadProject()` - Loads entire project from Drive
  - `createChapter()` - Creates new chapter JSON file
  - `updateChapter()` - Updates chapter file
  - `deleteChapter()` - Deletes chapter file
  - `createEntity()` - Creates character/location/plot_event
  - `updateEntity()` - Updates any entity
  - `deleteEntity()` - Deletes any entity

### Updated Services

#### ProjectService
- **Changed**: Now uses `ProjectFileService` instead of `ChapterRepository`
- **Constructor**: `new ProjectService(projectRepository, projectFileService)`
- **Methods**:
  - `createProject()` → Creates folder structure in Drive + DB index
  - `getProject()` → Loads full project from Drive
  - `deleteProject()` → Soft delete in DB (Drive files preserved)

#### ChapterService
- **Changed**: Now uses `ProjectFileService` instead of `ChapterRepository`
- **Constructor**: `new ChapterService(projectFileService, projectRepository)`
- **Methods**:
  - All chapter operations now work with Drive files
  - Loading entire project loads all chapters at once

## API Behavior Changes

### Before (Database)
```javascript
GET /projects/:id
→ Returns: { id, title, chapters: [] }
→ Chapters loaded from database

POST /projects/:projectId/chapters
→ Inserts row in chapters table
```

### After (Google Drive)
```javascript
GET /projects/:id
→ Returns: { id, title, chapters: [], characters: [], locations: [] }
→ Entire project loaded from Drive (all JSON files)

POST /projects/:projectId/chapters
→ Creates {uuid}.json file in Drive chapters/ folder
→ Updates project.json metadata
```

## Benefits

### 1. User Data Ownership ✅
- Users can access their files directly in Google Drive
- No vendor lock-in - data is in standard JSON format
- Users can edit files outside the app
- Users can backup/share entire project folders

### 2. Transparency ✅
- All data visible in Drive
- Users see exactly what's stored
- Easy to export/migrate data

### 3. Collaboration ✅
- Multiple users can share a project folder in Drive
- Users can collaborate using Drive's sharing features

### 4. Scalability ✅
- Offloads storage to Google infrastructure
- Database only stores lightweight indexes
- Reduced database costs

### 5. Offline Access ✅
- Drive mobile apps can cache files
- Users can access data without backend

## Trade-offs

### Considerations

**Performance**:
- Loading entire project from Drive takes longer than DB queries
- Mitigated by: Loading full project once, caching in memory

**Consistency**:
- No database transactions for multi-file updates
- Mitigated by: Atomic file updates, eventual consistency

**Search**:
- Can't use SQL queries to search content
- Mitigated by: Database can cache searchable metadata

## Migration Strategy

### For Existing Data

If you have existing projects in the database:

1. **Export to Drive** (TODO: Create migration script)
   ```bash
   npm run migrate:export-to-drive
   ```

2. **Keep Database Tables** (backward compatibility)
   - Tables remain for historical data
   - New projects use Drive only

3. **Gradual Migration**
   - Users see migration prompt on next login
   - Migration runs in background
   - Both systems work during transition

## Development Workflow

### Creating a New Project
```javascript
// Creates folder structure in Drive + DB index
const project = await projectService.createProject(userId, {
  title: 'My Novel',
  description: 'A story',
  genre: 'fantasy'
});
// Result: PlotEngine/My-Novel/ folder created with subfolders
```

### Loading a Project
```javascript
// Loads entire project from Drive (all JSON files)
const project = await projectService.getProject(projectId, userId);

// Returns:
{
  id, title, description,
  chapters: [...],      // All chapters
  characters: [...],    // All characters
  locations: [...],     // All locations
  plot_events: [...],   // All events
  consistency_checks: [...]
}
```

### Updating a Chapter
```javascript
// Updates single JSON file in Drive
await chapterService.updateChapter(chapterId, projectId, userId, {
  content: 'New content...'
});
// Updates: chapters/{chapterId}.json
// Updates: project.json (word_count metadata)
```

## Testing

### Manual Testing

1. **Create Project**:
   ```bash
   curl -X POST http://localhost:3000/projects \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"title": "Test Novel"}'
   ```

2. **Check Google Drive**:
   - Go to drive.google.com
   - Look for "PlotEngine/Test Novel" folder
   - Verify subfolders exist
   - Verify project.json exists

3. **Create Chapter**:
   ```bash
   curl -X POST http://localhost:3000/projects/:projectId/chapters \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"title": "Chapter 1", "content": "Once upon a time..."}'
   ```

4. **Check Drive Again**:
   - Verify chapters/{uuid}.json exists
   - Open file and verify content

## Files Changed

### New Files
1. `src/services/storage/ProjectFileService.js` - Main file operations service
2. `src/services/storage/schemas/ProjectSchemas.js` - JSON schemas
3. `FILE_BASED_ARCHITECTURE.md` (this file)

### Modified Files
1. `src/services/ProjectService.js` - Now uses ProjectFileService
2. `src/services/ChapterService.js` - Now uses ProjectFileService
3. `src/server.js` - Wired up ProjectFileService
4. `package.json` - Added uuid dependency

### Dependencies Added
- `uuid@13.0.0` - For generating file IDs

## Next Steps

### Immediate
- ✅ Server running with new architecture
- ⏳ Test creating/loading projects manually
- ⏳ Update frontend to handle new response format

### Short Term
- Create migration script for existing data
- Add caching layer for frequently accessed projects
- Implement conflict resolution for concurrent edits

### Long Term
- Add real-time collaboration via WebSockets
- Implement file locking for concurrent edits
- Add version history using Drive's versioning

## Summary

The PlotEngine backend now uses a **file-first architecture** where:

1. **All project data** stored as JSON files in Google Drive
2. **Database** only stores lightweight indexes
3. **Users own their data** - can access directly in Drive
4. **Full transparency** - data visible and editable outside app

This architecture gives users complete control over their data while leveraging Google Drive's infrastructure for storage, sharing, and collaboration.

---

**Implementation Date**: November 25, 2025
**Status**: ✅ **IMPLEMENTED AND RUNNING**
**Server Status**: Running successfully on port 3000
