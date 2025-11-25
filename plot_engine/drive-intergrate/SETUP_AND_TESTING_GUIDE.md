# Setup and Testing Guide - File-Based Architecture

## 🎉 What's Been Implemented

Your PlotEngine backend has been successfully refactored to use a **file-first architecture** where all project data is stored in Google Drive as JSON files!

### ✅ Completed Features

1. **ProjectFileService** - Manages entire project structure in Drive
2. **JSON Schemas** - Defines structure for all entity types
3. **Updated Services** - ProjectService & ChapterService now use Drive
4. **Migration Script** - Exports existing database projects to Drive
5. **Test Suite** - End-to-end testing script
6. **Frontend Documentation** - Integration guide for React/Flutter
7. **Comprehensive Docs** - Architecture and usage guides

## 📁 Project Structure in Google Drive

When you create a project, this structure is automatically created in Drive:

```
PlotEngine/                     # Root folder
  └── My-Novel/                 # Project folder
      ├── project.json          # Project metadata
      ├── chapters/
      │   ├── {uuid}.json       # Each chapter as JSON
      │   └── ...
      ├── characters/
      │   ├── {uuid}.json       # Each character as JSON
      │   └── ...
      ├── locations/
      │   └── ...
      ├── plot_events/
      │   └── ...
      └── consistency_checks/
          └── ...
```

## 🚀 Quick Start

### 1. Server is Already Running ✅

Your server is currently running with the new architecture!

```bash
# Check server status
curl http://localhost:3000/health

# Expected response:
# {"status":"ok","timestamp":"...","uptime":...}
```

### 2. Enable Google Drive API (One-Time Setup)

Before using the new system, enable the Drive API:

1. Go to: https://console.cloud.google.com/apis/library/drive.googleapis.com
2. Click **"Enable"** for Google Drive API
3. Done! (Uses existing OAuth credentials)

### 3. Test the New System

Run the automated test script:

```bash
# Make executable (if not already)
chmod +x test-drive-storage.sh

# Run tests
./test-drive-storage.sh
```

**What the test does:**
1. Checks server status
2. Guides you through authentication
3. Creates a test project
4. Verifies folder structure in Drive
5. Creates and updates chapters
6. Loads project from Drive
7. Verifies all operations

## 📊 Migration Guide

### For Existing Projects in Database

If you have projects already stored in PostgreSQL:

#### Step 1: Run Migration Script

```bash
npm run migrate:to-drive
```

This script will:
- Find all active projects in database
- Create folder structure in Google Drive for each project
- Export chapters, characters, locations as JSON files
- Update database with `storage_folder_id`
- Print summary report

#### Step 2: Check Migration Results

The script prints a summary:

```
========================================
📊 MIGRATION SUMMARY
========================================
Total Projects:    5
✅ Migrated:       4
⏭️  Skipped:        1
❌ Failed:         0
========================================
```

#### Step 3: Verify in Google Drive

1. Go to https://drive.google.com
2. Look for **"PlotEngine"** folder
3. Open it to see your migrated projects
4. Open a project folder to see chapters/, characters/, etc.

### Important Notes

**User Re-Authentication:**
- Users who haven't granted Drive access need to re-authenticate
- They'll see an error prompting them to sign in again
- After re-auth, run migration script again for their projects

**Skipped Projects:**
- Projects without refresh tokens are skipped
- Users need to visit `/auth/google` to re-authenticate
- Then run migration again

## 🧪 Testing Checklist

### Manual Testing

- [ ] **1. Create New Project**
  ```bash
  curl -X POST http://localhost:3000/projects \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title": "Test Novel", "genre": "fantasy"}'
  ```

- [ ] **2. Check Google Drive**
  - Go to drive.google.com
  - Find "PlotEngine/Test Novel" folder
  - Verify subfolders exist
  - Open project.json file

- [ ] **3. Load Project**
  ```bash
  curl http://localhost:3000/projects/{PROJECT_ID} \
    -H "Authorization: Bearer $TOKEN"
  ```
  - Should return entire project
  - Includes chapters, characters, locations arrays

- [ ] **4. Create Chapter**
  ```bash
  curl -X POST http://localhost:3000/projects/{PROJECT_ID}/chapters \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"title": "Chapter 1", "content": "Once upon a time..."}'
  ```

- [ ] **5. Verify in Drive**
  - Go to chapters/ folder
  - Find {uuid}.json file
  - Open and verify content

- [ ] **6. Update Chapter**
  ```bash
  curl -X PATCH http://localhost:3000/chapters/{CHAPTER_ID} \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{"content": "Updated content..."}'
  ```

- [ ] **7. Reload Project**
  - Load project again
  - Verify updated content appears

### Automated Testing

Run the provided test script:

```bash
./test-drive-storage.sh
```

Follow the prompts to test all features interactively.

## 📱 Frontend Integration

### Response Format Changes

**Before:**
```json
{
  "project": {
    "id": "...",
    "title": "...",
    "chapters": []  // Empty
  }
}
```

**After:**
```json
{
  "id": "...",
  "title": "...",
  "chapters": [...],      // ✅ Included!
  "characters": [...],    // ✅ Included!
  "locations": [...],     // ✅ Included!
  "plot_events": [...],   // ✅ Included!
  "consistency_checks": [...] // ✅ Included!
}
```

### Update Your Frontend

See [FRONTEND_DRIVE_INTEGRATION.md](./FRONTEND_DRIVE_INTEGRATION.md) for:
- TypeScript type definitions
- React hooks examples
- Flutter/Dart examples
- Caching strategies
- Migration checklist

## 🔧 Troubleshooting

### Issue: "User needs to re-authenticate"

**Solution:**
```bash
# User must visit:
http://localhost:3000/auth/google

# This grants Drive access and gets refresh token
# Then retry the operation
```

### Issue: "Project not found in Drive"

**Solution:**
```bash
# Check if project has storage_folder_id:
SELECT id, title, storage_folder_id FROM projects WHERE id = 'PROJECT_ID';

# If NULL, project hasn't been migrated yet
# Run migration:
npm run migrate:to-drive
```

### Issue: "Failed to load project"

**Possible causes:**
1. Drive API not enabled → Enable it in Google Console
2. User's refresh token expired → User needs to re-authenticate
3. Network issues → Check internet connection

**Debug:**
```bash
# Check server logs:
tail -f /tmp/server.log | grep ERROR

# Check Drive API status:
curl https://www.googleapis.com/drive/v3/about \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Issue: "Empty response from Drive"

**Solution:**
```bash
# Verify files exist in Drive:
1. Go to drive.google.com
2. Find PlotEngine/{Project Name}
3. Check if project.json exists
4. Check if chapters/ folder has files

# If files missing, re-create project or run migration
```

## 📚 Documentation Index

1. **[FILE_BASED_ARCHITECTURE.md](./FILE_BASED_ARCHITECTURE.md)**
   - Architecture overview
   - JSON schemas
   - Benefits and trade-offs
   - Migration strategy

2. **[FRONTEND_DRIVE_INTEGRATION.md](./FRONTEND_DRIVE_INTEGRATION.md)**
   - Frontend integration guide
   - React/TypeScript examples
   - Flutter/Dart examples
   - Caching strategies

3. **[test-drive-storage.sh](./test-drive-storage.sh)**
   - Automated test script
   - Interactive testing
   - Verification steps

4. **[src/database/migrate-to-drive.js](./src/database/migrate-to-drive.js)**
   - Migration script
   - Exports DB data to Drive
   - Progress reporting

## 🎯 Next Steps

### Immediate (Do Now)

1. **Enable Drive API** ✅
   - https://console.cloud.google.com/apis/library/drive.googleapis.com

2. **Run Test Script** ✅
   ```bash
   ./test-drive-storage.sh
   ```

3. **Migrate Existing Data** (if you have any)
   ```bash
   npm run migrate:to-drive
   ```

### Short Term (This Week)

1. **Update Frontend**
   - Implement new response format
   - Remove separate chapter loading
   - Add caching

2. **Test with Real Users**
   - Have users create new projects
   - Monitor Drive API usage
   - Gather feedback

3. **Monitor Performance**
   - Check response times
   - Monitor Drive API quotas
   - Optimize if needed

### Long Term (Next Month)

1. **Advanced Features**
   - Real-time collaboration
   - Conflict resolution
   - Version history

2. **Optimization**
   - Implement caching layers
   - Add background sync
   - Compress large projects

3. **Additional Providers**
   - Add S3 provider (optional)
   - Add Azure Blob (optional)
   - Support multiple storage backends

## 🎊 Success Metrics

Your file-based architecture is working if:

- ✅ New projects appear in Google Drive
- ✅ Chapters are saved as JSON files
- ✅ Loading project returns full data
- ✅ Updates reflect in Drive immediately
- ✅ Users can see their files in Drive
- ✅ Existing projects migrated successfully

## 💡 Tips

1. **Monitor Drive Quotas**
   - Check: https://console.cloud.google.com/apis/api/drive.googleapis.com/quotas
   - Default: 1000 requests per 100 seconds per user
   - Adjust if needed

2. **Cache Aggressively**
   - Load project once, cache in memory
   - Only reload on explicit user action
   - Reduces Drive API calls

3. **Show Loading States**
   - Drive operations take longer than DB
   - Show "Loading from Google Drive..."
   - Use skeleton screens

4. **Handle Offline**
   - Cache last loaded data
   - Show stale data with warning
   - Queue updates for when online

## 🆘 Need Help?

If you encounter issues:

1. Check server logs: `tail -f /tmp/server.log`
2. Run test script: `./test-drive-storage.sh`
3. Check Google Drive manually
4. Review [FILE_BASED_ARCHITECTURE.md](./FILE_BASED_ARCHITECTURE.md)

---

**🎉 Congratulations!** Your PlotEngine backend is now using Google Drive as primary storage, giving your users full ownership and transparency of their data!
