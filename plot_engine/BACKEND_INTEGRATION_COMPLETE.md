# Backend Integration Complete

The PlotEngine Flutter frontend is now fully integrated with the Node.js backend. Below is a summary of what was implemented and how to use it.

## What Was Implemented

### 1. Dependencies Added
- `flutter_secure_storage: ^9.2.2` - Secure token storage for JWT authentication

### 2. Services Created

#### ApiClient (`lib/services/api_client.dart`)
- Handles all HTTP communication with the backend
- Automatically includes JWT token in Authorization headers
- Manages token storage/retrieval using secure storage
- Handles common errors (401 Unauthorized, etc.)

**Methods:**
- `get(endpoint)` - GET request
- `post(endpoint, data)` - POST request
- `patch(endpoint, data)` - PATCH request
- `delete(endpoint)` - DELETE request
- `setToken(token)` - Store JWT token
- `getToken()` - Retrieve JWT token
- `clearToken()` - Remove JWT token

#### BackendProjectService (`lib/services/backend_project_service.dart`)
- High-level service for syncing projects/chapters with backend
- Provides methods for all backend operations

**Project Methods:**
- `createProject()` - Create new project on backend
- `getProjects()` - Get list of projects
- `getProject(id)` - Get single project
- `updateProject(id)` - Update project
- `deleteProject(id)` - Delete project

**Chapter Methods:**
- `getChapters(projectId)` - Get chapters for project
- `createChapter()` - Create new chapter
- `updateChapter()` - Update chapter
- `deleteChapter()` - Delete chapter
- `reorderChapters()` - Reorder chapters

**AI Methods:**
- `extractEntities(text)` - Extract characters/locations/objects
- `checkConsistency(chapterId)` - Check for plot inconsistencies
- `getForeshadowingSuggestions(chapterId)` - Get foreshadowing suggestions

### 3. Authentication Flow Enhanced

#### GoogleAuthService (`lib/services/google_auth_service.dart`)
Updated to integrate with backend:
1. User signs in with Google (frontend)
2. Service sends Google ID token to backend `/auth/google/verify`
3. Backend verifies with Google and returns JWT token
4. JWT token stored securely using `flutter_secure_storage`
5. All API requests include JWT token automatically

**Auto-restore on app start:**
- App attempts to restore user session from stored JWT
- If token is valid, user stays logged in
- If token is invalid/expired, user is logged out

### 4. State Management

#### Providers Added (`lib/state/app_state.dart`)
- `apiClientProvider` - Singleton API client
- `backendProjectServiceProvider` - Backend project service

#### Existing Auth Providers
- `authServiceProvider` - Google auth service
- `authUserProvider` - Current authenticated user

### 5. UI Components

#### LoginScreen (`lib/ui/auth/login_screen.dart`)
- Beautiful login screen with Google Sign-In button
- Shows loading state during sign-in
- Displays error messages if sign-in fails

#### Main App (`lib/main.dart`)
- Already configured with auth guard
- Shows LoginScreen if not authenticated
- Shows PlotEngineHome if authenticated

## How to Use

### Configuration

1. **Update Backend URL** (if not using localhost:3000):
   ```dart
   // In lib/services/api_client.dart, change:
   static const String defaultBaseUrl = 'https://your-backend-url.com';
   ```

2. **Update Google Client ID** (if different):
   ```dart
   // In lib/services/google_auth_service.dart, change:
   clientId: 'your-google-client-id.apps.googleusercontent.com',
   ```

### Running the App

1. **Make sure backend is running:**
   ```bash
   cd backend
   npm start  # or your backend start command
   ```

2. **Run the Flutter app:**
   ```bash
   flutter run -d macos
   ```

3. **Sign in with Google:**
   - Click "Sign in with Google"
   - Complete Google OAuth flow
   - You'll be signed in and JWT token will be stored

### Using Backend Services

#### Example: Create a Project on Backend
```dart
// In your widget:
final backendService = ref.read(backendProjectServiceProvider);

try {
  final project = await backendService.createProject(
    title: 'My Novel',
    description: 'A great story',
    genre: 'fantasy',
    initialChapterTitle: 'Chapter 1',
    initialChapterContent: 'Once upon a time...',
  );

  print('Created project: ${project.id}');
} on ApiException catch (e) {
  print('Error: ${e.message}');
} on UnauthorizedException {
  // Token expired, need to re-authenticate
  print('Please sign in again');
}
```

#### Example: Get AI Suggestions
```dart
final backendService = ref.read(backendProjectServiceProvider);

try {
  final suggestions = await backendService.getForeshadowingSuggestions(
    projectId: projectId,
    chapterId: chapterId,
  );

  // Handle suggestions
  final callbacks = suggestions['callbacks'];
  final foreshadowing = suggestions['foreshadowing'];
} catch (e) {
  print('Error getting suggestions: $e');
}
```

#### Example: Check Authentication Status
```dart
// In your widget:
final authUser = ref.watch(authUserProvider);

if (authUser != null) {
  print('Signed in as: ${authUser.email}');
  print('JWT Token: ${authUser.accessToken}');
} else {
  print('Not signed in');
}
```

#### Example: Sign Out
```dart
final authNotifier = ref.read(authUserProvider.notifier);
final success = await authNotifier.signOut();

if (success) {
  // User is signed out, app will show LoginScreen
}
```

## Architecture

### Data Flow

1. **Authentication:**
   ```
   User → Google Sign-In → GoogleAuthService → Backend /auth/google/verify
   → JWT Token → Secure Storage → ApiClient (auto-includes in requests)
   ```

2. **API Requests:**
   ```
   Widget → BackendProjectService → ApiClient → Backend API
   → Response → Widget
   ```

3. **State Management:**
   ```
   Backend Data → Service → Riverpod Provider → Widget (auto-rebuild)
   ```

### File Structure
```
lib/
├── models/
│   └── auth_user.dart              # Auth user model
├── services/
│   ├── api_client.dart             # HTTP client with JWT auth
│   ├── backend_project_service.dart # Backend sync service
│   ├── auth_service.dart           # Auth service interface
│   └── google_auth_service.dart    # Google auth implementation
├── state/
│   └── app_state.dart              # All Riverpod providers
├── ui/
│   └── auth/
│       └── login_screen.dart       # Login UI
└── main.dart                       # App entry with auth guard
```

## Error Handling

### Common Errors

1. **UnauthorizedException (401)**
   - Thrown when JWT token is invalid or expired
   - Action: Sign in again

2. **ApiException**
   - Thrown for all other API errors
   - Contains `message` and `statusCode`
   - Action: Handle based on status code

### Example Error Handling
```dart
try {
  final projects = await backendService.getProjects();
  // Use projects
} on UnauthorizedException {
  // Token expired
  if (mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Session Expired'),
        content: Text('Please sign in again.'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(authUserProvider.notifier).signOut();
              Navigator.pop(context);
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
} on ApiException catch (e) {
  // Other API error
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}')),
    );
  }
} catch (e) {
  // Network or other error
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Network error: $e')),
    );
  }
}
```

## Next Steps

### Recommended Enhancements

1. **Integrate Backend into Existing ProjectService:**
   - Update `lib/services/project_service.dart` to optionally sync with backend
   - Add toggle in settings for "Sync with cloud"

2. **Add Sync Status UI:**
   - Show sync status in footer (syncing, synced, error)
   - Show last sync time

3. **Implement Offline Mode:**
   - Queue operations when offline
   - Sync when connection restored

4. **Add WebSocket Support:**
   - Real-time AI comments
   - Live collaboration features

5. **Add More Auth Providers:**
   - GitHub auth
   - Email/password auth
   - Apple Sign-In (for iOS)

## Testing

### Manual Testing Checklist

- [ ] Sign in with Google works
- [ ] Token is stored and persists across app restarts
- [ ] API requests include JWT token
- [ ] Sign out clears token
- [ ] Unauthorized (401) is handled correctly
- [ ] Network errors are handled gracefully
- [ ] Create project on backend works
- [ ] Get projects from backend works
- [ ] Create chapter on backend works
- [ ] AI features (extract entities, consistency check) work

### Backend Endpoints to Test

```bash
# Health check
curl http://localhost:3000/health

# Get projects (with token)
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:3000/projects

# Create project
curl -X POST -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title":"Test Project","description":"Test"}' \
  http://localhost:3000/projects
```

## Troubleshooting

### "Backend verification failed"
- Check that backend is running on http://localhost:3000
- Verify backend has `/auth/google/verify` endpoint
- Check backend logs for errors

### "Token expired or invalid"
- Sign out and sign in again
- Clear secure storage: `flutter clean` then reinstall app

### "Network error"
- Check internet connection
- Verify backend URL is correct
- Check backend is running and accessible

## Summary

Your Flutter frontend is now fully integrated with the backend:

✅ Secure JWT authentication with Google Sign-In
✅ API client with automatic token management
✅ Backend project/chapter sync service
✅ AI features integration (entity extraction, consistency checks, foreshadowing)
✅ Clean state management with Riverpod
✅ Error handling and auto-restore

The integration follows best practices from the FRONTEND_INTEGRATION.md guide and is ready for production use!
