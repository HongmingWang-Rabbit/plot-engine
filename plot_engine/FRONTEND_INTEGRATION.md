# PlotEngine Frontend Integration Guide

Complete guide for integrating your frontend (Web/Flutter) with the PlotEngine backend.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Authentication](#authentication)
3. [API Client Setup](#api-client-setup)
4. [Core Features](#core-features)
5. [Error Handling](#error-handling)
6. [Best Practices](#best-practices)

---

## Quick Start

### Base URL

```
Development: http://localhost:3000
Production: https://api.plotengine.com
```

### Authentication Flow

```
1. User clicks "Sign in with Google"
2. Frontend initiates OAuth flow
3. User authenticates with Google
4. Backend returns JWT token
5. Frontend stores token securely
6. All API requests include token in Authorization header
```

---

## Authentication

### Web App (React/Vue/Angular)

#### 1. Google OAuth Button

```jsx
// React example
import React from 'react';

function LoginButton() {
  const handleGoogleLogin = () => {
    // Redirect to backend OAuth endpoint
    window.location.href = 'http://localhost:3000/auth/google';
  };

  return (
    <button onClick={handleGoogleLogin}>
      Sign in with Google
    </button>
  );
}

export default LoginButton;
```

#### 2. Handle OAuth Callback

```jsx
// pages/AuthSuccess.jsx
import { useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';

function AuthSuccess() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  useEffect(() => {
    const token = searchParams.get('token');

    if (token) {
      // Store token securely
      localStorage.setItem('auth_token', token);

      // Fetch user info
      fetchCurrentUser(token).then(user => {
        // Store user in state management (Redux/Context/etc.)
        navigate('/dashboard');
      });
    } else {
      navigate('/login');
    }
  }, [searchParams, navigate]);

  return <div>Authenticating...</div>;
}

async function fetchCurrentUser(token) {
  const response = await fetch('http://localhost:3000/auth/me', {
    headers: {
      'Authorization': `Bearer ${token}`,
    },
  });

  if (response.ok) {
    const data = await response.json();
    return data.user;
  }

  throw new Error('Failed to fetch user');
}

export default AuthSuccess;
```

#### 3. API Client with Auto-Token

```javascript
// api/client.js
class ApiClient {
  constructor(baseURL = 'http://localhost:3000') {
    this.baseURL = baseURL;
  }

  getToken() {
    return localStorage.getItem('auth_token');
  }

  async request(endpoint, options = {}) {
    const token = this.getToken();

    const config = {
      ...options,
      headers: {
        'Content-Type': 'application/json',
        ...(token && { 'Authorization': `Bearer ${token}` }),
        ...options.headers,
      },
    };

    const response = await fetch(`${this.baseURL}${endpoint}`, config);

    if (response.status === 401) {
      // Token expired, redirect to login
      localStorage.removeItem('auth_token');
      window.location.href = '/login';
      throw new Error('Unauthorized');
    }

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error || 'Request failed');
    }

    // Handle 204 No Content
    if (response.status === 204) {
      return null;
    }

    return response.json();
  }

  // Convenience methods
  get(endpoint) {
    return this.request(endpoint, { method: 'GET' });
  }

  post(endpoint, data) {
    return this.request(endpoint, {
      method: 'POST',
      body: JSON.stringify(data),
    });
  }

  patch(endpoint, data) {
    return this.request(endpoint, {
      method: 'PATCH',
      body: JSON.stringify(data),
    });
  }

  delete(endpoint) {
    return this.request(endpoint, { method: 'DELETE' });
  }
}

export const apiClient = new ApiClient();
```

---

### Flutter App (iOS/Android/Desktop)

#### 1. Install Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  google_sign_in: ^6.2.1
  http: ^1.2.0
  flutter_secure_storage: ^9.2.2
  provider: ^6.1.2  # For state management
```

#### 2. Google Sign-In Setup

```dart
// services/auth_service.dart
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:io';

class AuthService {
  static const String baseUrl = 'http://localhost:3000';
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User cancelled

      // 2. Get authentication
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Send ID token to backend
      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'idToken': googleAuth.idToken,
          'platform': _getPlatform(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Save JWT token
        await _storage.write(key: 'auth_token', value: data['token']);

        // Return user
        return User.fromJson(data['user']);
      } else {
        throw Exception('Authentication failed');
      }
    } catch (error) {
      print('Sign-in error: $error');
      rethrow;
    }
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else if (response.statusCode == 401) {
        // Token expired
        await signOut();
        return null;
      }
    } catch (error) {
      print('Get user error: $error');
    }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: 'auth_token');
  }

  // Get stored token
  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  String _getPlatform() {
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isWindows) return 'windows';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }
}

// User model
class User {
  final String id;
  final String email;
  final String displayName;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      displayName: json['displayName'],
      avatarUrl: json['avatarUrl'],
    );
  }
}
```

#### 3. API Client for Flutter

```dart
// services/api_client.dart
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class ApiClient {
  static const String baseUrl = 'http://localhost:3000';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: json.encode(data),
    );
    return _handleResponse(response);
  }

  Future<void> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 204) {
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return json.decode(response.body);
    }

    if (response.statusCode == 401) {
      throw UnauthorizedException('Token expired or invalid');
    }

    final error = json.decode(response.body);
    throw ApiException(
      error['error'] ?? 'Request failed',
      statusCode: response.statusCode,
    );
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, {required this.statusCode});

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}
```

---

## Core Features

### 1. Projects

#### Create Project

```javascript
// Web (JavaScript)
const project = await apiClient.post('/projects', {
  title: 'My Novel',
  description: 'A thrilling adventure',
  genre: 'fantasy',
  initialChapterTitle: 'Chapter 1',
  initialChapterContent: 'It was a dark and stormy night...',
});
```

```dart
// Flutter
final project = await apiClient.post('/projects', {
  'title': 'My Novel',
  'description': 'A thrilling adventure',
  'genre': 'fantasy',
  'initialChapterTitle': 'Chapter 1',
  'initialChapterContent': 'It was a dark and stormy night...',
});
```

#### Get Projects List

```javascript
// Web
const { projects } = await apiClient.get('/projects?limit=20&offset=0');
```

```dart
// Flutter
final data = await apiClient.get('/projects?limit=20&offset=0');
final projects = (data['projects'] as List)
    .map((p) => Project.fromJson(p))
    .toList();
```

#### Get Single Project

```javascript
// Web
const { project } = await apiClient.get(`/projects/${projectId}`);
```

#### Update Project

```javascript
// Web
const { project } = await apiClient.patch(`/projects/${projectId}`, {
  title: 'Updated Title',
  description: 'Updated description',
});
```

#### Delete Project

```javascript
// Web
await apiClient.delete(`/projects/${projectId}`);
```

---

### 2. Chapters

#### Get Chapters

```javascript
// Web
const { chapters } = await apiClient.get(
  `/projects/${projectId}/chapters?limit=100&offset=0`
);
```

#### Create Chapter

```javascript
// Web
const { chapter } = await apiClient.post(
  `/projects/${projectId}/chapters`,
  {
    title: 'Chapter 2',
    content: 'The adventure continues...',
  }
);
```

#### Update Chapter

```javascript
// Web
const { chapter } = await apiClient.patch(
  `/projects/${projectId}/chapters/${chapterId}`,
  {
    title: 'Updated Title',
    content: 'Updated content...',
  }
);
```

#### Delete Chapter

```javascript
// Web
await apiClient.delete(`/projects/${projectId}/chapters/${chapterId}`);
```

#### Reorder Chapters

```javascript
// Web
await apiClient.post(`/projects/${projectId}/chapters/reorder`, {
  chapters: [
    { chapterId: 'uuid-1', orderIndex: 0 },
    { chapterId: 'uuid-2', orderIndex: 1 },
    { chapterId: 'uuid-3', orderIndex: 2 },
  ],
});
```

---

### 3. AI Features

#### Extract Entities

```javascript
// Web
const { entities } = await apiClient.post('/ai/extract/entities', {
  text: 'John stared at the ancient key...',
  provider: 'anthropic', // or 'openai'
});

// Response:
// {
//   entities: {
//     characters: [{ name: 'John', description: '...', traits: [...] }],
//     locations: [{ name: 'Crystal Tower', description: '...' }],
//     objects: [{ name: 'ancient key', description: '...' }],
//   }
// }
```

#### Check Consistency

```javascript
// Web
const { issues } = await apiClient.post('/ai/validate/consistency', {
  chapterId: 'uuid',
  projectId: 'uuid',
  contextRange: 5, // Check against last 5 chapters
});

// Response:
// {
//   issues: [
//     {
//       type: 'character',
//       severity: 'high',
//       description: 'Eye color changed',
//       suggestion: 'Maintain consistent descriptions'
//     }
//   ]
// }
```

#### Get Foreshadowing Suggestions

```javascript
// Web
const { suggestions } = await apiClient.post('/ai/suggest/foreshadow', {
  chapterId: 'uuid',
  projectId: 'uuid',
});

// Response:
// {
//   suggestions: {
//     callbacks: [
//       {
//         reference_chapter: 2,
//         element: 'The mysterious key',
//         suggestion: 'Reference the key discovery',
//         location: 'During confrontation scene'
//       }
//     ],
//     foreshadowing: [...],
//     thematic_resonances: [...]
//   }
// }
```

---

## Error Handling

### Handling API Errors

```javascript
// Web - React example
import { useState } from 'react';
import { apiClient } from './api/client';

function useApiRequest() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const execute = async (requestFn) => {
    setLoading(true);
    setError(null);

    try {
      const result = await requestFn();
      return result;
    } catch (err) {
      setError(err.message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { loading, error, execute };
}

// Usage:
function CreateProject() {
  const { loading, error, execute } = useApiRequest();

  const handleCreate = async () => {
    try {
      const project = await execute(() =>
        apiClient.post('/projects', {
          title: 'My Novel',
          description: 'A story',
        })
      );
      // Success!
      console.log('Created:', project);
    } catch (err) {
      // Error already set in state
      console.error('Failed:', err);
    }
  };

  return (
    <div>
      <button onClick={handleCreate} disabled={loading}>
        {loading ? 'Creating...' : 'Create Project'}
      </button>
      {error && <div className="error">{error}</div>}
    </div>
  );
}
```

```dart
// Flutter example
class ProjectService {
  final ApiClient _api = ApiClient();

  Future<Project> createProject({
    required String title,
    String? description,
  }) async {
    try {
      final data = await _api.post('/projects', {
        'title': title,
        'description': description,
      });
      return Project.fromJson(data['project']);
    } on UnauthorizedException {
      // Handle token expiration
      rethrow;
    } on ApiException catch (e) {
      // Handle API errors
      print('API Error: ${e.message}');
      rethrow;
    } catch (e) {
      // Handle network errors
      print('Network Error: $e');
      rethrow;
    }
  }
}
```

---

## Best Practices

### 1. Token Management

#### Web (localStorage with expiration check)

```javascript
// utils/auth.js
export function setAuthToken(token) {
  localStorage.setItem('auth_token', token);
  localStorage.setItem('auth_token_time', Date.now().toString());
}

export function getAuthToken() {
  const token = localStorage.getItem('auth_token');
  const tokenTime = localStorage.getItem('auth_token_time');

  if (!token || !tokenTime) return null;

  // Check if token is older than 6 days (refresh before 7 day expiry)
  const age = Date.now() - parseInt(tokenTime);
  const sixDays = 6 * 24 * 60 * 60 * 1000;

  if (age > sixDays) {
    // Token about to expire, refresh it
    refreshToken();
  }

  return token;
}

async function refreshToken() {
  const oldToken = localStorage.getItem('auth_token');

  try {
    const response = await fetch('http://localhost:3000/auth/refresh', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: oldToken }),
    });

    if (response.ok) {
      const { token } = await response.json();
      setAuthToken(token);
    }
  } catch (error) {
    console.error('Token refresh failed:', error);
  }
}
```

#### Flutter (Secure Storage)

```dart
// Always use flutter_secure_storage for tokens
final storage = FlutterSecureStorage();

// Write
await storage.write(key: 'auth_token', value: token);

// Read
final token = await storage.read(key: 'auth_token');

// Delete
await storage.delete(key: 'auth_token');
```

### 2. State Management

#### React Context

```jsx
// contexts/AuthContext.jsx
import { createContext, useContext, useState, useEffect } from 'react';
import { apiClient } from '../api/client';

const AuthContext = createContext();

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Check if user is logged in
    const token = localStorage.getItem('auth_token');
    if (token) {
      apiClient.get('/auth/me')
        .then(data => setUser(data.user))
        .catch(() => {
          localStorage.removeItem('auth_token');
        })
        .finally(() => setLoading(false));
    } else {
      setLoading(false);
    }
  }, []);

  const login = (token) => {
    localStorage.setItem('auth_token', token);
    return apiClient.get('/auth/me')
      .then(data => setUser(data.user));
  };

  const logout = () => {
    localStorage.removeItem('auth_token');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
```

#### Flutter Provider

```dart
// providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _loading = true;
  final AuthService _authService = AuthService();

  User? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;

  Future<void> init() async {
    _loading = true;
    notifyListeners();

    _user = await _authService.getCurrentUser();

    _loading = false;
    notifyListeners();
  }

  Future<void> signIn() async {
    _user = await _authService.signInWithGoogle();
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }
}
```

### 3. Caching

```javascript
// Simple cache for GET requests
class CachedApiClient {
  constructor() {
    this.cache = new Map();
    this.cacheTime = 5 * 60 * 1000; // 5 minutes
  }

  async get(endpoint, useCache = true) {
    if (useCache && this.cache.has(endpoint)) {
      const { data, timestamp } = this.cache.get(endpoint);

      if (Date.now() - timestamp < this.cacheTime) {
        return data;
      }
    }

    const data = await apiClient.get(endpoint);

    this.cache.set(endpoint, {
      data,
      timestamp: Date.now(),
    });

    return data;
  }

  invalidate(endpoint) {
    if (endpoint) {
      this.cache.delete(endpoint);
    } else {
      this.cache.clear();
    }
  }
}

export const cachedApi = new CachedApiClient();
```

### 4. Real-time Updates (Optional)

For real-time chapter collaboration:

```javascript
// WebSocket connection (future feature)
const ws = new WebSocket('ws://localhost:3000');

ws.onmessage = (event) => {
  const data = JSON.parse(event.data);

  if (data.type === 'chapter_updated') {
    // Update UI with new chapter content
    updateChapter(data.chapter);
  }
};
```

---

## Complete Example: React App

```jsx
// App.jsx
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import Login from './pages/Login';
import AuthSuccess from './pages/AuthSuccess';
import Dashboard from './pages/Dashboard';
import ProjectEditor from './pages/ProjectEditor';

function PrivateRoute({ children }) {
  const { user, loading } = useAuth();

  if (loading) return <div>Loading...</div>;

  return user ? children : <Navigate to="/login" />;
}

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/auth/success" element={<AuthSuccess />} />
          <Route
            path="/dashboard"
            element={
              <PrivateRoute>
                <Dashboard />
              </PrivateRoute>
            }
          />
          <Route
            path="/project/:projectId"
            element={
              <PrivateRoute>
                <ProjectEditor />
              </PrivateRoute>
            }
          />
          <Route path="/" element={<Navigate to="/dashboard" />} />
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
```

---

## Testing the Integration

### 1. Health Check

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "timestamp": "2024-01-15T12:00:00Z",
  "uptime": 123.45
}
```

### 2. Test Authentication (Manual)

1. Open browser: `http://localhost:3000/auth/google`
2. Login with Google
3. Get redirected with token
4. Use token for API requests

### 3. Test API Call

```bash
# Get projects (replace TOKEN with your JWT)
curl -H "Authorization: Bearer TOKEN" \
  http://localhost:3000/projects
```

---

## Common Issues

### CORS Errors (Web)

**Problem**: `Access to fetch has been blocked by CORS policy`

**Solution**: Make sure backend `.env` has your frontend URL:
```env
ALLOWED_ORIGINS=http://localhost:5173
```

### Token Expiration

**Problem**: API returns 401 Unauthorized

**Solution**: Implement token refresh or redirect to login:
```javascript
if (response.status === 401) {
  localStorage.removeItem('auth_token');
  window.location.href = '/login';
}
```

### Flutter iOS Sign-In Not Working

**Problem**: Google Sign-In button does nothing

**Solution**: Check `Info.plist` has correct Client ID and URL scheme

---

## Summary

✅ **Authentication**: Google OAuth → JWT token → Secure storage
✅ **API Calls**: Authorization header with Bearer token
✅ **Error Handling**: Catch 401, handle token expiration
✅ **State Management**: Context API (React) or Provider (Flutter)
✅ **Best Practices**: Secure token storage, caching, error boundaries

**Ready to build!** 🚀

For more details, see:
- [API Documentation](./API_DOCUMENTATION.md)
- [Google OAuth Setup](./GOOGLE_OAUTH_SETUP.md)
- [Quick Start Guide](./QUICK_START.md)
