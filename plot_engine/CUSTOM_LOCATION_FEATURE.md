# Custom Project Location Feature

## Overview
Users can now choose where to save their projects instead of being limited to the default `~/Documents/PlotEngine/` directory.

## Changes Made

### 1. New Project Dialog (`lib/ui/dialogs/new_project_dialog.dart`)
- Added **file picker** for selecting custom project location
- Visual folder display showing selected path or default
- "Choose Location" button to browse file system
- Returns both project name and optional custom path

### 2. Storage Service (`lib/services/storage_service.dart`)
- Updated `createProject()` to accept optional `customPath` parameter
- Creates project directory at custom location if provided
- Falls back to default location if no custom path specified

### 3. Project Service (`lib/services/project_service.dart`)
- Updated `createProject()` to pass custom path through to storage service
- Maintains backward compatibility with default location

### 4. Open Project Dialog (`lib/ui/dialogs/open_project_dialog.dart`)
- Added **"Browse for Project..."** button at the top
- Shows recent projects from default location
- Allows browsing to any project folder on the file system
- Displays project path and last updated time

### 5. Toolbar (`lib/ui/toolbar/app_toolbar.dart`)
- Updated handlers to work with new dialog responses
- Handles Map response from New Project dialog
- Handles String path response from Open Project dialog

## User Experience

### Creating a New Project
1. Click **"New Project"** in toolbar
2. Enter project name
3. (Optional) Click **"Choose Location"** to browse for custom folder
4. Click **"Create"**

**Default**: Project saved to `~/Documents/PlotEngine/ProjectName/`
**Custom**: Project saved to `{CustomPath}/ProjectName/`

### Opening a Project

**Option 1: Browse**
1. Click **"Open Project"** in toolbar
2. Click **"Browse for Project..."**
3. Navigate to any project folder
4. Project opens

**Option 2: Recent Projects**
1. Click **"Open Project"** in toolbar
2. Select from list of recent projects (from default location)
3. Project opens

## Technical Details

### File Picker Dependency
```yaml
file_picker: ^8.1.6
```

### Project Structure
```
Custom Location/
└── MyNovel/
    ├── project.json      # Project metadata
    ├── chapters.json     # All chapters
    └── knowledge.json    # Knowledge base items
```

### Backward Compatibility
- Existing projects in default location still work
- New projects can be created in default location (don't select custom path)
- All existing functionality preserved

## Benefits

1. **Flexibility**: Users can organize projects in their preferred folder structure
2. **Cloud Sync**: Save projects in Dropbox, Google Drive, etc.
3. **Version Control**: Save projects in Git repositories
4. **Collaboration**: Share project folders with others
5. **Backup**: Easy to include in existing backup routines
