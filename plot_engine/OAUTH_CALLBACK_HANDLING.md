# OAuth Callback Handling Guide

## What Happened: The Double-Request Issue

When you tested the OAuth flow, the logs showed:

1. **First request (SUCCESS)**: 
   - Google returned valid tokens
   - User was created/found in database
   - Backend redirected to frontend with JWT token
   - Status: 200 OK ✅

2. **Second request (FAILED)**:
   - Same authorization code was reused
   - Google returned `invalid_grant` error
   - Status: 400 Bad Request ❌

**Why**: OAuth authorization codes can only be used once. After the first successful exchange, Google invalidates the code. When your browser/frontend made a second request with the same code, Google rejected it.

## The Fix Applied

### Backend Changes

1. **Code Deduplication**: Added a memory cache that tracks recently used authorization codes for 1 minute
2. **Graceful Handling**: If a duplicate request comes in, it now:
   - Logs a warning (not an error)
   - Redirects to frontend success page
   - Doesn't try to exchange the code again

3. **Better Error Responses**: Changed from returning 500 errors to redirecting to frontend with error information

### Frontend Routes You Need

Your frontend should handle these redirect URLs:

#### Success Route
```
http://localhost:5173/auth/success?token=<JWT_TOKEN>
```

**What to do**:
```javascript
// React example
import { useEffect } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';

function AuthSuccess() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();

  useEffect(() => {
    const token = searchParams.get('token');
    
    if (token) {
      // Save token
      localStorage.setItem('auth_token', token);
      
      // Clear URL params to prevent token from staying in URL
      window.history.replaceState({}, document.title, '/auth/success');
      
      // Redirect to main app
      setTimeout(() => navigate('/dashboard'), 1000);
    } else {
      // No token - duplicate request, just redirect
      navigate('/dashboard');
    }
  }, [searchParams, navigate]);

  return <div>Authentication successful! Redirecting...</div>;
}
```

#### Error Route
```
http://localhost:5173/auth/error?error=<ERROR_CODE>&message=<ERROR_MESSAGE>
```

**Error codes**:
- `oauth_failed`: User denied permission or OAuth initiation failed
- `no_code`: No authorization code in callback
- `token_exchange_failed`: Failed to exchange code for token

**What to do**:
```javascript
// React example
function AuthError() {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  
  const error = searchParams.get('error');
  const message = searchParams.get('message');
  
  const errorMessages = {
    oauth_failed: 'Google sign-in was cancelled or failed',
    no_code: 'Authentication error: no authorization code received',
    token_exchange_failed: message || 'Failed to complete authentication'
  };

  return (
    <div>
      <h2>Authentication Failed</h2>
      <p>{errorMessages[error] || 'An unknown error occurred'}</p>
      <button onClick={() => navigate('/login')}>Try Again</button>
    </div>
  );
}
```

## Preventing Double Requests

### Common Causes

1. **Browser auto-retry**: Browser automatically retries failed/slow requests
2. **Service Worker**: PWA service workers can intercept and retry requests
3. **React Router**: Double-rendering in development mode
4. **User action**: User refreshes the callback page

### Best Practices

#### 1. Don't Store OAuth Callback in History

```javascript
// When redirecting to OAuth
const handleGoogleLogin = () => {
  // Open in popup instead of redirect (advanced)
  const width = 500;
  const height = 600;
  const left = window.screenX + (window.outerWidth - width) / 2;
  const top = window.screenY + (window.outerHeight - height) / 2;
  
  const popup = window.open(
    'http://localhost:3000/auth/google',
    'Google Sign-In',
    `width=${width},height=${height},left=${left},top=${top}`
  );
  
  // Listen for popup to close or send message
  const checkPopup = setInterval(() => {
    if (popup.closed) {
      clearInterval(checkPopup);
      // Check if token was saved
      if (localStorage.getItem('auth_token')) {
        navigate('/dashboard');
      }
    }
  }, 500);
};
```

#### 2. Clear URL After Processing Token

```javascript
// After saving token, clear the URL
localStorage.setItem('auth_token', token);
window.history.replaceState({}, document.title, window.location.pathname);
```

#### 3. Add Loading State

```javascript
function AuthSuccess() {
  const [isProcessing, setIsProcessing] = useState(false);
  const [searchParams] = useSearchParams();

  useEffect(() => {
    // Prevent double-processing
    if (isProcessing) return;
    
    const token = searchParams.get('token');
    if (!token) return;
    
    setIsProcessing(true);
    
    // Save token
    localStorage.setItem('auth_token', token);
    window.history.replaceState({}, document.title, '/auth/success');
    
    // Navigate after short delay
    setTimeout(() => {
      navigate('/dashboard');
    }, 1000);
  }, []);

  return <div>Processing authentication...</div>;
}
```

## Flutter/Mobile Implementation

For mobile apps using Google Sign-In packages:

```dart
// Use the /auth/google/verify endpoint instead
Future<void> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    final GoogleSignInAuthentication googleAuth = 
        await googleUser!.authentication;
    
    // Send ID token to backend
    final response = await http.post(
      Uri.parse('http://localhost:3000/auth/google/verify'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'idToken': googleAuth.idToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Save JWT token
      await storage.write(key: 'auth_token', value: data['token']);
      // Navigate to main screen
      Navigator.pushReplacementNamed(context, '/home');
    }
  } catch (error) {
    print('Google Sign-In error: $error');
  }
}
```

## Testing Your Implementation

### 1. Test Happy Path

```bash
# Open browser to:
http://localhost:3000/auth/google

# Should redirect through Google and back to:
http://localhost:5173/auth/success?token=eyJ...
```

### 2. Test Duplicate Request Handling

```bash
# After successful auth, try accessing the callback URL again
# (copy the full callback URL from browser history)

# Should redirect to success page without error
```

### 3. Check Server Logs

Look for these messages:

```
✅ SUCCESS:
Google token response (status: 200)
User authenticated successfully via Google OAuth

⚠️ DUPLICATE (expected, not an error):
Authorization code already used, ignoring duplicate request

❌ ERROR (investigate):
Google OAuth error: redirect_uri_mismatch
```

## Security Notes

1. **Don't expose JWT in URL longer than necessary**: Clear it after saving to localStorage
2. **Use HTTPS in production**: OAuth requires HTTPS for callback URLs in production
3. **Set token expiration**: Tokens expire in 7 days by default (configurable in .env)
4. **Implement token refresh**: Use `/auth/refresh` endpoint before token expires

## Summary

The OAuth flow is now working correctly! The "error" you saw was just a duplicate request trying to reuse the same authorization code. The first request succeeded and created a JWT token for you.

Make sure your frontend:
1. Has routes for `/auth/success` and `/auth/error`
2. Extracts and saves the token from URL params
3. Clears the token from the URL after saving
4. Redirects to your main app

The duplicate requests are now handled gracefully without causing user-facing errors.
