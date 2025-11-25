# Frontend Integration Guide - Cloud Storage API

## Table of Contents
1. [Overview](#overview)
2. [Authentication](#authentication)
3. [API Endpoints](#api-endpoints)
4. [File Upload](#file-upload)
5. [File Management](#file-management)
6. [React Integration Examples](#react-integration-examples)
7. [TypeScript Types](#typescript-types)
8. [Error Handling](#error-handling)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Overview

The PlotEngine Cloud Storage API provides file management capabilities with automatic Google Drive integration. Files are automatically organized per project, with smart caching and fast performance.

**Base URL:** `https://your-api-domain.com` or `http://localhost:3000` (development)

**Key Features:**
- 🚀 Fast file uploads (300ms average)
- 📁 Automatic project folder organization
- 💾 Smart caching (50ms file listings)
- 🔄 Batch upload support
- 📦 Project backup/export
- 🔒 Secure with JWT authentication

---

## Authentication

All storage endpoints require JWT authentication via Bearer token.

### Getting the Token

After user logs in via OAuth:

```javascript
// User authenticates
const response = await fetch('http://localhost:3000/auth/google/callback', {
  // ... OAuth flow
});

const { token } = await response.json();
// Store token in localStorage, cookie, or state management
localStorage.setItem('authToken', token);
```

### Using the Token

Include in all API requests:

```javascript
const token = localStorage.getItem('authToken');

fetch('http://localhost:3000/storage/...', {
  headers: {
    'Authorization': `Bearer ${token}`,
  },
});
```

---

## API Endpoints

### Base Storage URL
```
/storage
```

### Endpoints Summary

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/storage/projects/:projectId/files` | Upload single file |
| `POST` | `/storage/projects/:projectId/files/batch` | Upload multiple files |
| `GET` | `/storage/projects/:projectId/files` | List project files |
| `GET` | `/storage/files/:fileId` | Download file |
| `DELETE` | `/storage/files/:fileId` | Delete file |
| `POST` | `/storage/projects/:projectId/backup` | Export project backup |
| `GET` | `/storage/health` | Health check (no auth) |

---

## File Upload

### Single File Upload

**Endpoint:** `POST /storage/projects/:projectId/files`

**Request:**
```javascript
const uploadFile = async (projectId, file) => {
  const formData = new FormData();
  formData.append('file', file);

  const response = await fetch(
    `http://localhost:3000/storage/projects/${projectId}/files`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
      },
      body: formData, // Don't set Content-Type - browser sets it automatically
    }
  );

  if (!response.ok) {
    throw new Error('Upload failed');
  }

  return await response.json();
};

// Usage
const file = document.querySelector('input[type="file"]').files[0];
const result = await uploadFile('project-123', file);
```

**Response:**
```json
{
  "success": true,
  "file": {
    "fileId": "1a2b3c4d5e",
    "fileName": "chapter-1.docx",
    "webViewLink": "https://drive.google.com/file/d/...",
    "mimeType": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "size": 15234
  }
}
```

**Status Codes:**
- `201` - File uploaded successfully
- `400` - Invalid file or missing file
- `401` - Not authenticated
- `404` - Project not found or no access

---

### Batch File Upload

**Endpoint:** `POST /storage/projects/:projectId/files/batch`

**Request:**
```javascript
const uploadMultipleFiles = async (projectId, files) => {
  const formData = new FormData();

  // Append multiple files
  for (const file of files) {
    formData.append('file', file);
  }

  const response = await fetch(
    `http://localhost:3000/storage/projects/${projectId}/files/batch`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
      },
      body: formData,
    }
  );

  return await response.json();
};

// Usage
const files = Array.from(document.querySelector('input[type="file"]').files);
const result = await uploadMultipleFiles('project-123', files);
```

**Response:**
```json
{
  "success": true,
  "files": [
    {
      "fileId": "1a2b3c4d5e",
      "fileName": "chapter-1.docx",
      "size": 15234
    },
    {
      "fileId": "2b3c4d5e6f",
      "fileName": "chapter-2.docx",
      "size": 18456
    }
  ],
  "count": 2
}
```

---

## File Management

### List Project Files

**Endpoint:** `GET /storage/projects/:projectId/files`

**Request:**
```javascript
const listFiles = async (projectId) => {
  const response = await fetch(
    `http://localhost:3000/storage/projects/${projectId}/files`,
    {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
      },
    }
  );

  return await response.json();
};
```

**Response:**
```json
{
  "success": true,
  "files": [
    {
      "id": "uuid-1",
      "file_id": "1a2b3c4d5e",
      "file_name": "chapter-1.docx",
      "mime_type": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
      "file_size": 15234,
      "web_view_link": "https://drive.google.com/file/d/...",
      "created_at": "2025-11-25T10:30:00Z",
      "updated_at": "2025-11-25T10:30:00Z"
    }
  ],
  "source": "cache",
  "count": 1
}
```

**Notes:**
- First call fetches from Google Drive (slower)
- Subsequent calls use cached metadata (50ms response)
- `source` field indicates `"cache"` or `"provider"`

---

### Download File

**Endpoint:** `GET /storage/files/:fileId`

**Request:**
```javascript
const downloadFile = async (fileId, fileName) => {
  const response = await fetch(
    `http://localhost:3000/storage/files/${fileId}`,
    {
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
      },
    }
  );

  if (!response.ok) {
    throw new Error('Download failed');
  }

  // Get the blob
  const blob = await response.blob();

  // Create download link
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  window.URL.revokeObjectURL(url);
  document.body.removeChild(a);
};

// Usage
await downloadFile('1a2b3c4d5e', 'chapter-1.docx');
```

**Response:**
- Content-Type: `<file mime type>`
- Content-Disposition: `attachment; filename="<filename>"`
- Body: File binary data

---

### Delete File

**Endpoint:** `DELETE /storage/files/:fileId`

**Request:**
```javascript
const deleteFile = async (fileId) => {
  const response = await fetch(
    `http://localhost:3000/storage/files/${fileId}`,
    {
      method: 'DELETE',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
      },
    }
  );

  return await response.json();
};
```

**Response:**
```json
{
  "success": true,
  "message": "File deleted successfully"
}
```

---

### Export Project Backup

**Endpoint:** `POST /storage/projects/:projectId/backup`

**Request:**
```javascript
const exportBackup = async (projectId) => {
  const response = await fetch(
    `http://localhost:3000/storage/projects/${projectId}/backup`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${localStorage.getItem('authToken')}`,
      },
    }
  );

  return await response.json();
};
```

**Response:**
```json
{
  "success": true,
  "backup": {
    "fileId": "backup-file-id",
    "fileName": "backup-2025-11-25.json",
    "webViewLink": "https://drive.google.com/file/d/...",
    "size": 45678
  },
  "message": "Project backup created successfully"
}
```

**Backup Contents:**
- Project metadata
- All chapters with content
- Word counts and timestamps
- Version information

---

## React Integration Examples

### Custom Hook: useCloudStorage

```typescript
// hooks/useCloudStorage.ts
import { useState, useCallback } from 'react';

interface UploadProgress {
  fileName: string;
  progress: number;
  status: 'pending' | 'uploading' | 'success' | 'error';
}

export const useCloudStorage = (projectId: string) => {
  const [files, setFiles] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<UploadProgress[]>([]);
  const [error, setError] = useState<string | null>(null);

  const token = localStorage.getItem('authToken');
  const baseUrl = process.env.REACT_APP_API_URL || 'http://localhost:3000';

  // List files
  const fetchFiles = useCallback(async () => {
    setLoading(true);
    setError(null);

    try {
      const response = await fetch(
        `${baseUrl}/storage/projects/${projectId}/files`,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Failed to fetch files');
      }

      const data = await response.json();
      setFiles(data.files);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unknown error');
    } finally {
      setLoading(false);
    }
  }, [projectId, token, baseUrl]);

  // Upload single file
  const uploadFile = useCallback(async (file: File) => {
    const formData = new FormData();
    formData.append('file', file);

    setUploadProgress(prev => [
      ...prev,
      { fileName: file.name, progress: 0, status: 'uploading' }
    ]);

    try {
      const response = await fetch(
        `${baseUrl}/storage/projects/${projectId}/files`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
          },
          body: formData,
        }
      );

      if (!response.ok) {
        throw new Error('Upload failed');
      }

      const data = await response.json();

      setUploadProgress(prev =>
        prev.map(p =>
          p.fileName === file.name
            ? { ...p, progress: 100, status: 'success' }
            : p
        )
      );

      // Refresh file list
      await fetchFiles();

      return data.file;
    } catch (err) {
      setUploadProgress(prev =>
        prev.map(p =>
          p.fileName === file.name
            ? { ...p, status: 'error' }
            : p
        )
      );
      throw err;
    }
  }, [projectId, token, baseUrl, fetchFiles]);

  // Upload multiple files
  const uploadMultipleFiles = useCallback(async (fileList: FileList | File[]) => {
    const filesArray = Array.from(fileList);

    // Upload in parallel
    const uploadPromises = filesArray.map(file => uploadFile(file));

    try {
      await Promise.all(uploadPromises);
    } catch (err) {
      console.error('Some uploads failed:', err);
    }
  }, [uploadFile]);

  // Download file
  const downloadFile = useCallback(async (fileId: string, fileName: string) => {
    try {
      const response = await fetch(
        `${baseUrl}/storage/files/${fileId}`,
        {
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Download failed');
      }

      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = fileName;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Download failed');
      throw err;
    }
  }, [token, baseUrl]);

  // Delete file
  const deleteFile = useCallback(async (fileId: string) => {
    try {
      const response = await fetch(
        `${baseUrl}/storage/files/${fileId}`,
        {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Delete failed');
      }

      // Refresh file list
      await fetchFiles();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Delete failed');
      throw err;
    }
  }, [token, baseUrl, fetchFiles]);

  // Export backup
  const exportBackup = useCallback(async () => {
    try {
      const response = await fetch(
        `${baseUrl}/storage/projects/${projectId}/backup`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('Backup failed');
      }

      const data = await response.json();
      return data.backup;
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Backup failed');
      throw err;
    }
  }, [projectId, token, baseUrl]);

  return {
    files,
    loading,
    error,
    uploadProgress,
    fetchFiles,
    uploadFile,
    uploadMultipleFiles,
    downloadFile,
    deleteFile,
    exportBackup,
  };
};
```

---

### React Component: FileManager

```typescript
// components/FileManager.tsx
import React, { useEffect, useState } from 'react';
import { useCloudStorage } from '../hooks/useCloudStorage';

interface FileManagerProps {
  projectId: string;
}

export const FileManager: React.FC<FileManagerProps> = ({ projectId }) => {
  const {
    files,
    loading,
    error,
    uploadProgress,
    fetchFiles,
    uploadFile,
    downloadFile,
    deleteFile,
    exportBackup,
  } = useCloudStorage(projectId);

  const [selectedFiles, setSelectedFiles] = useState<FileList | null>(null);

  useEffect(() => {
    fetchFiles();
  }, [fetchFiles]);

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    setSelectedFiles(e.target.files);
  };

  const handleUpload = async () => {
    if (!selectedFiles) return;

    for (const file of Array.from(selectedFiles)) {
      try {
        await uploadFile(file);
      } catch (err) {
        console.error('Upload error:', err);
      }
    }

    setSelectedFiles(null);
  };

  const handleDownload = async (fileId: string, fileName: string) => {
    try {
      await downloadFile(fileId, fileName);
    } catch (err) {
      console.error('Download error:', err);
    }
  };

  const handleDelete = async (fileId: string) => {
    if (!window.confirm('Are you sure you want to delete this file?')) return;

    try {
      await deleteFile(fileId);
    } catch (err) {
      console.error('Delete error:', err);
    }
  };

  const handleExportBackup = async () => {
    try {
      const backup = await exportBackup();
      alert(`Backup created: ${backup.fileName}`);
    } catch (err) {
      console.error('Backup error:', err);
    }
  };

  if (loading && !files.length) {
    return <div>Loading files...</div>;
  }

  return (
    <div className="file-manager">
      <h2>Project Files</h2>

      {error && (
        <div className="error-message">
          Error: {error}
        </div>
      )}

      {/* Upload Section */}
      <div className="upload-section">
        <input
          type="file"
          multiple
          onChange={handleFileSelect}
        />
        <button
          onClick={handleUpload}
          disabled={!selectedFiles}
        >
          Upload Files
        </button>
        <button onClick={handleExportBackup}>
          Export Backup
        </button>
      </div>

      {/* Upload Progress */}
      {uploadProgress.length > 0 && (
        <div className="upload-progress">
          <h3>Upload Progress:</h3>
          {uploadProgress.map((progress, i) => (
            <div key={i} className={`progress-item ${progress.status}`}>
              {progress.fileName}: {progress.status}
              {progress.status === 'uploading' && ` (${progress.progress}%)`}
            </div>
          ))}
        </div>
      )}

      {/* File List */}
      <div className="file-list">
        <h3>Files ({files.length}):</h3>
        {files.length === 0 ? (
          <p>No files yet. Upload your first file!</p>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Name</th>
                <th>Size</th>
                <th>Uploaded</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {files.map((file) => (
                <tr key={file.id}>
                  <td>{file.file_name}</td>
                  <td>{formatFileSize(file.file_size)}</td>
                  <td>{new Date(file.created_at).toLocaleDateString()}</td>
                  <td>
                    <button
                      onClick={() => handleDownload(file.file_id, file.file_name)}
                    >
                      Download
                    </button>
                    <a
                      href={file.web_view_link}
                      target="_blank"
                      rel="noopener noreferrer"
                    >
                      View in Drive
                    </a>
                    <button
                      onClick={() => handleDelete(file.file_id)}
                      className="delete-btn"
                    >
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};

// Utility function
function formatFileSize(bytes: number): string {
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}
```

---

## TypeScript Types

```typescript
// types/storage.ts

export interface CloudFile {
  id: string;
  file_id: string;
  file_name: string;
  mime_type: string;
  file_size: number;
  storage_provider: string;
  web_view_link: string;
  created_at: string;
  updated_at: string;
  is_active: boolean;
}

export interface UploadFileResponse {
  success: true;
  file: {
    fileId: string;
    fileName: string;
    webViewLink: string;
    mimeType: string;
    size: number;
  };
}

export interface ListFilesResponse {
  success: true;
  files: CloudFile[];
  source: 'cache' | 'provider' | 'empty';
  count: number;
}

export interface DeleteFileResponse {
  success: true;
  message: string;
}

export interface BackupResponse {
  success: true;
  backup: {
    fileId: string;
    fileName: string;
    webViewLink: string;
    size: number;
  };
  message: string;
}

export interface ErrorResponse {
  error: string;
  statusCode: number;
  details?: any;
}
```

---

## Error Handling

### Common Error Responses

```typescript
// Error structure
interface ApiError {
  error: string;
  statusCode: number;
  details?: any;
}

// Handle errors
const handleApiError = (error: ApiError) => {
  switch (error.statusCode) {
    case 400:
      return 'Invalid request. Please check your input.';
    case 401:
      return 'Authentication required. Please log in again.';
    case 403:
      return 'Access denied. You may need to re-authorize Drive access.';
    case 404:
      return 'Resource not found.';
    case 413:
      return 'File too large. Maximum size is 100MB.';
    case 500:
      return 'Server error. Please try again later.';
    default:
      return error.error || 'An unknown error occurred.';
  }
};

// Usage
try {
  const response = await fetch(/* ... */);

  if (!response.ok) {
    const error = await response.json();
    throw new Error(handleApiError(error));
  }

  // Success
  const data = await response.json();
} catch (err) {
  console.error(err.message);
  // Show to user
}
```

### Error Handling Best Practices

```typescript
// Wrapper function with retry logic
const fetchWithRetry = async (url: string, options: RequestInit, maxRetries = 3) => {
  let lastError;

  for (let i = 0; i < maxRetries; i++) {
    try {
      const response = await fetch(url, options);

      if (response.ok) {
        return response;
      }

      // Don't retry on 4xx errors (client errors)
      if (response.status >= 400 && response.status < 500) {
        throw new Error(await response.text());
      }

      lastError = new Error(`Request failed: ${response.status}`);
    } catch (err) {
      lastError = err;

      // Wait before retry (exponential backoff)
      if (i < maxRetries - 1) {
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
      }
    }
  }

  throw lastError;
};
```

---

## Best Practices

### 1. File Size Validation

```typescript
const MAX_FILE_SIZE = 100 * 1024 * 1024; // 100MB

const validateFile = (file: File): boolean => {
  if (file.size > MAX_FILE_SIZE) {
    alert(`File ${file.name} is too large. Maximum size is 100MB.`);
    return false;
  }
  return true;
};

// Before upload
const handleUpload = (files: FileList) => {
  const validFiles = Array.from(files).filter(validateFile);
  // Upload only valid files
};
```

### 2. Progress Indication

```typescript
// Show upload progress
const uploadWithProgress = async (file: File, onProgress: (percent: number) => void) => {
  const xhr = new XMLHttpRequest();

  return new Promise((resolve, reject) => {
    xhr.upload.addEventListener('progress', (e) => {
      if (e.lengthComputable) {
        const percent = (e.loaded / e.total) * 100;
        onProgress(percent);
      }
    });

    xhr.addEventListener('load', () => {
      if (xhr.status === 201) {
        resolve(JSON.parse(xhr.responseText));
      } else {
        reject(new Error('Upload failed'));
      }
    });

    xhr.addEventListener('error', () => reject(new Error('Network error')));

    const formData = new FormData();
    formData.append('file', file);

    xhr.open('POST', `${API_URL}/storage/projects/${projectId}/files`);
    xhr.setRequestHeader('Authorization', `Bearer ${token}`);
    xhr.send(formData);
  });
};
```

### 3. Caching Strategy

```typescript
// Cache file list in React Query
import { useQuery, useMutation, useQueryClient } from 'react-query';

export const useProjectFiles = (projectId: string) => {
  const queryClient = useQueryClient();

  // Fetch with cache
  const { data, isLoading } = useQuery(
    ['project-files', projectId],
    () => fetchFiles(projectId),
    {
      staleTime: 1000 * 60 * 5, // 5 minutes
      cacheTime: 1000 * 60 * 30, // 30 minutes
    }
  );

  // Upload mutation
  const uploadMutation = useMutation(
    (file: File) => uploadFile(projectId, file),
    {
      onSuccess: () => {
        // Invalidate cache to refetch
        queryClient.invalidateQueries(['project-files', projectId]);
      },
    }
  );

  return { files: data?.files, isLoading, upload: uploadMutation.mutate };
};
```

### 4. Optimistic Updates

```typescript
// Update UI immediately, rollback on error
const deleteFileOptimistic = async (fileId: string) => {
  // Save current state
  const previousFiles = [...files];

  // Update UI immediately
  setFiles(files.filter(f => f.file_id !== fileId));

  try {
    // Make API call
    await deleteFile(fileId);
  } catch (err) {
    // Rollback on error
    setFiles(previousFiles);
    alert('Delete failed');
  }
};
```

### 5. Drag & Drop Upload

```typescript
const FileDropzone: React.FC<{ onFilesDropped: (files: File[]) => void }> = ({
  onFilesDropped,
}) => {
  const [isDragging, setIsDragging] = useState(false);

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(true);
  };

  const handleDragLeave = () => {
    setIsDragging(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragging(false);

    const files = Array.from(e.dataTransfer.files);
    onFilesDropped(files);
  };

  return (
    <div
      className={`dropzone ${isDragging ? 'dragging' : ''}`}
      onDragOver={handleDragOver}
      onDragLeave={handleDragLeave}
      onDrop={handleDrop}
    >
      <p>Drag & drop files here, or click to select</p>
      <input
        type="file"
        multiple
        onChange={(e) => {
          if (e.target.files) {
            onFilesDropped(Array.from(e.target.files));
          }
        }}
      />
    </div>
  );
};
```

---

## Troubleshooting

### Issue: 403 Forbidden - Drive access required

**Problem:** User hasn't granted Drive permissions yet.

**Solution:**
```typescript
// Redirect user to re-authenticate
const reauthorize = () => {
  window.location.href = `${API_URL}/auth/google`;
};

// Show message to user
if (error?.statusCode === 403) {
  return (
    <div>
      <p>Drive access required. Please re-authorize.</p>
      <button onClick={reauthorize}>Authorize Drive Access</button>
    </div>
  );
}
```

### Issue: CORS errors

**Problem:** Frontend and backend on different domains.

**Solution:** Backend already handles CORS. Ensure you're including credentials:

```typescript
fetch(url, {
  credentials: 'include', // If using cookies
  headers: {
    'Authorization': `Bearer ${token}`,
  },
});
```

### Issue: Files not appearing immediately

**Problem:** Cache not invalidated after upload.

**Solution:** Call `fetchFiles()` after successful upload:

```typescript
const uploadFile = async (file: File) => {
  const result = await doUpload(file);
  await fetchFiles(); // Refresh list
  return result;
};
```

### Issue: Large file upload timeout

**Problem:** Request timeout on large files.

**Solution:** Increase timeout or implement chunked upload:

```typescript
// Set longer timeout
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), 60000); // 60s

fetch(url, {
  signal: controller.signal,
  // ...
}).finally(() => clearTimeout(timeoutId));
```

---

## Environment Variables

Add to your frontend `.env`:

```bash
# API Configuration
REACT_APP_API_URL=http://localhost:3000
# or for production:
# REACT_APP_API_URL=https://api.yourapp.com

# Optional: Enable debug logging
REACT_APP_DEBUG_STORAGE=true
```

---

## Quick Start Checklist

- [ ] Set up API base URL in environment variables
- [ ] Implement authentication token storage
- [ ] Create `useCloudStorage` hook
- [ ] Add file upload UI component
- [ ] Add file list UI component
- [ ] Implement error handling
- [ ] Add progress indicators
- [ ] Test with real files
- [ ] Handle re-authentication flow
- [ ] Add loading states

---

## Support

For issues or questions:
- Check API health: `GET /storage/health`
- Review server logs for errors
- Ensure Google Drive API is enabled
- Verify user has re-authenticated with Drive scope

---

**Last Updated:** November 25, 2025
**API Version:** 1.0.0
**Minimum Browser Support:** Chrome 90+, Firefox 88+, Safari 14+
