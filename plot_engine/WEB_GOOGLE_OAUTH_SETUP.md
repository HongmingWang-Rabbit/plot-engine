# Google OAuth Setup for Web

The error "Storagerelay URI is not allowed for 'NATIVE_IOS' client type" means you need a separate OAuth Client ID for web applications.

## Step 1: Create Web OAuth Client ID

1. **Go to Google Cloud Console:**
   - Visit: https://console.cloud.google.com/apis/credentials
   - Select your project (or create one)

2. **Create OAuth 2.0 Client ID:**
   - Click "+ CREATE CREDENTIALS"
   - Select "OAuth client ID"
   - Application type: **Web application**
   - Name: "PlotEngine Web"

3. **Configure Authorized Origins:**
   Add these URLs (for local development):
   ```
   http://localhost
   http://localhost:3000
   http://localhost:5173
   ```

4. **Configure Authorized Redirect URIs:**
   Add these URLs:
   ```
   http://localhost:3000/auth/google/callback
   http://localhost/auth/google/callback
   ```

5. **Click "CREATE"**
   - Copy the Client ID (it will look like: `xxxxx.apps.googleusercontent.com`)

## Step 2: Update Flutter Web Configuration

Update the `web/index.html` file with your Web Client ID:

```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

## Step 3: Update GoogleAuthService for Web

For web, Google Sign-In works differently. You'll need to update the service or use a web-specific implementation.

## Alternative: Test with Backend's Web OAuth

If your backend already handles Google OAuth for web, you can test directly through the backend:

1. **Start your backend:**
   ```bash
   cd backend
   npm start
   ```

2. **Open browser and go to:**
   ```
   http://localhost:3000/auth/google
   ```

3. **Sign in with Google**
   - You'll be redirected to Google
   - After signing in, you'll be redirected back with a token
   - Copy the token from the URL

4. **Test the token:**
   ```bash
   curl -H "Authorization: Bearer YOUR_TOKEN" \
        http://localhost:3000/auth/me
   ```

## For Flutter Web Testing

Run the Flutter app on web:

```bash
flutter run -d chrome --web-port=3000
```

**Note:** Flutter's `google_sign_in` package has limited web support. For production web apps, consider:
- Using the backend OAuth flow (redirect to `/auth/google`)
- Or implementing a JavaScript-based Google Sign-In button
- Or using a different auth package like `firebase_auth`

## Current Setup

Your current Client ID (`1049734729172-53ujfb8mlkkir19scv0v29ubrtubmfpu`) is configured for:
- ✅ iOS/macOS/Android
- ❌ Web

You need a separate Web Client ID for web applications.
