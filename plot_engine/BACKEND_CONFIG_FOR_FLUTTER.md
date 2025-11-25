# Backend Configuration for Flutter Web

Your Flutter web app is now set up to receive OAuth callbacks. Make sure your backend is configured to redirect to the correct URL.

## Backend Environment Variables

In your backend's `.env` file, set:

```env
# Frontend URL for OAuth redirects
FRONTEND_URL=http://localhost:5173

# Or if you want to support both web and native:
FRONTEND_WEB_URL=http://localhost:5173
FRONTEND_NATIVE_URL=plotengine://auth/callback
```

## Expected Backend Behavior

When OAuth completes, your backend should redirect to:

### Success
```
http://localhost:5173/auth/success?token=<JWT_TOKEN>
```

### Error
```
http://localhost:5173/auth/error?error=<ERROR_CODE>&message=<ERROR_MESSAGE>
```

## Testing the Flow

1. **Run Flutter web on fixed port:**
   ```bash
   ./run_web.sh
   # Or: flutter run -d chrome --web-port=5173
   ```

2. **Make sure backend is running:**
   ```bash
   cd backend
   npm start
   ```

3. **Test OAuth flow:**
   - Open Flutter app: `http://localhost:5173`
   - Click "Sign in with Google"
   - You'll be redirected to: `http://localhost:3000/auth/google`
   - Complete Google sign-in
   - Backend redirects back to: `http://localhost:5173/auth/success?token=...`
   - Flutter saves token and logs you in

## Backend Route Structure

Your backend should have these routes:

```javascript
// Initiate OAuth
GET /auth/google
→ Redirects to Google OAuth

// OAuth callback (from Google)
GET /auth/google/callback
→ Exchanges code for tokens
→ Creates JWT
→ Redirects to: ${FRONTEND_URL}/auth/success?token=${jwt}

// Verify JWT
GET /auth/me
Headers: Authorization: Bearer <token>
→ Returns user info

// For native apps (iOS/Android/macOS)
POST /auth/google/verify
Body: { idToken, platform }
→ Returns { token, user }
```

## Current Setup

- ✅ Flutter web runs on: `http://localhost:5173`
- ✅ Backend runs on: `http://localhost:3000`
- ✅ OAuth callback routes implemented in Flutter
- ✅ Token storage using secure storage
- ⚠️ Make sure backend `FRONTEND_URL` is set correctly

## Google Cloud Console Setup

Make sure your **Web OAuth Client** has:

**Authorized JavaScript origins:**
```
http://localhost:5173
```

**Authorized redirect URIs:**
```
http://localhost:3000/auth/google/callback
```

## Troubleshooting

### "redirect_uri_mismatch"
- Add `http://localhost:3000/auth/google/callback` to Google Cloud Console

### "ERR_TOO_MANY_REDIRECTS"
- Check backend's callback handler implementation
- Make sure it redirects to frontend, not back to itself

### "Token not saved"
- Check browser console for errors
- Verify `/auth/success` route is being hit
- Check that `flutter_secure_storage` is working

### OAuth works but app doesn't log in
- Check that `authUserProvider` is refreshing after token save
- Verify `/auth/me` endpoint returns valid user data
- Check browser's Application → Local Storage/Session Storage

## Testing Without Browser

You can also test the backend directly:

```bash
# 1. Get a token
curl http://localhost:3000/auth/google
# (Complete in browser, copy token from redirected URL)

# 2. Test the token
curl -H "Authorization: Bearer YOUR_TOKEN" \
     http://localhost:3000/auth/me
```
