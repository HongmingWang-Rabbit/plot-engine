# Google Sign-In Setup Guide

This guide explains how to configure Google Sign-In for PlotEngine.

## Prerequisites

You need to create OAuth 2.0 credentials in the Google Cloud Console.

## Step 1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google Sign-In API**

## Step 2: Configure OAuth Consent Screen

1. Navigate to **APIs & Services** > **OAuth consent screen**
2. Select **External** user type
3. Fill in the required information:
   - App name: PlotEngine
   - User support email: Your email
   - Developer contact: Your email
4. Add scopes: `email` and `profile`
5. Save and continue

## Step 3: Create OAuth 2.0 Client ID

1. Navigate to **APIs & Services** > **Credentials**
2. Click **Create Credentials** > **OAuth client ID**
3. Select **macOS** as the application type
4. Enter a name (e.g., "PlotEngine macOS")
5. Add your app's bundle identifier: `com.example.plotEngine`
6. **IMPORTANT**: Under "Authorized redirect URIs", add:
   ```
   com.googleusercontent.apps.YOUR_CLIENT_ID:/
   ```
   Replace `YOUR_CLIENT_ID` with your actual Client ID (e.g., `com.googleusercontent.apps.1049734729172-u4pv0l6ck2shr6okgjujp8um2a4j95p7:/`)

   **Note**: The `:/` at the end is required!

7. Click **Create**
8. Download the client configuration

## Step 4: Configure macOS Info.plist

**IMPORTANT**: The app will crash on launch without this configuration.

Update `macos/Runner/Info.plist` with your OAuth Client ID:

1. Open `macos/Runner/Info.plist`
2. Replace `YOUR_CLIENT_ID` in both locations with your actual Client ID (without the `.apps.googleusercontent.com` suffix):

```xml
<key>GIDClientID</key>
<string>YOUR_CLIENT_ID.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
  </dict>
</array>
```

**Example**:
If your Client ID is `123456789-abcdefg.apps.googleusercontent.com`, then:
- `GIDClientID`: `123456789-abcdefg.apps.googleusercontent.com`
- URL Scheme: `com.googleusercontent.apps.123456789-abcdefg`

**Note**: The Info.plist file already contains placeholder values. You just need to replace `YOUR_CLIENT_ID` with your actual Client ID.

## Step 5: Test the Implementation

1. Run `flutter pub get` to install dependencies
2. Run the app: `flutter run -d macos`
3. Click "Sign in with Google" on the login screen
4. Complete the OAuth flow in your browser
5. You should be redirected back to the app upon successful authentication

## Security Notes

1. **Never commit OAuth credentials to version control**
2. Add `google-services.json` and similar files to `.gitignore`
3. For production, use environment variables or secure configuration management
4. Consider using different OAuth clients for development and production

## Troubleshooting

### "Sign in cancelled by user" error (after completing sign-in)
**Problem**: You complete the OAuth flow in the browser, but the app shows "Sign in cancelled by user".

**Solution**: The redirect URI is missing or incorrect in Google Cloud Console.
1. Go to [Google Cloud Console - Credentials](https://console.cloud.google.com/apis/credentials)
2. Edit your OAuth 2.0 Client ID
3. Add the redirect URI: `com.googleusercontent.apps.YOUR_CLIENT_ID:/` (include the `:/`)
4. Save and wait 1-2 minutes for changes to propagate
5. Try signing in again

### Sign-in fails immediately
- Verify your OAuth client ID is correct
- Ensure the bundle identifier matches your Google Cloud project configuration

### Browser doesn't open
- Check that your app has permission to open URLs
- Verify macOS app sandboxing settings

### "Redirect URI mismatch" error
- Ensure your redirect URIs are properly configured in Google Cloud Console
- For macOS apps, the redirect URI format is: `com.googleusercontent.apps.YOUR_CLIENT_ID:/`

## Future Backend Integration

Once your backend is implemented:

1. The `accessToken` and `idToken` from the AuthUser model can be used for API calls
2. Send these tokens in the `Authorization` header:
   ```dart
   final headers = {
     'Authorization': 'Bearer ${authUser.accessToken}',
   };
   ```
3. Your backend should verify the token with Google's token verification API
4. Store user sessions and implement token refresh logic as needed

## Adding More Authentication Methods

The modular architecture supports adding additional auth providers:

1. Create a new service implementing `AuthService` (e.g., `GitHubAuthService`, `EmailAuthService`)
2. Update the `authServiceProvider` in `lib/state/app_state.dart` to use your new service
3. Update the login screen UI to offer multiple sign-in options

Example:
```dart
// In lib/state/app_state.dart
final authServiceProvider = Provider<AuthService>((ref) {
  // You can use environment variables or settings to switch providers
  return GoogleAuthService(); // or GitHubAuthService(), etc.
});
```
