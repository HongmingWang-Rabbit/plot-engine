# Xcode Code Signing Setup for macOS

Your app needs code signing configured to use Google Sign-In. Here's how to fix it:

## Option 1: Quick Fix (Recommended for Development)

1. **Open the project in Xcode:**
   ```bash
   open macos/Runner.xcworkspace
   ```

2. **Select the Runner target:**
   - In the left sidebar, click on "Runner" (the blue icon at the top)
   - Make sure "Runner" target is selected (not the project)

3. **Go to "Signing & Capabilities" tab:**
   - Click the "Signing & Capabilities" tab at the top

4. **Enable Automatic Signing:**
   - Check the box "Automatically manage signing"
   - Select your Team (Apple ID)
     - If you don't have a team, click "Add Account" and sign in with your Apple ID
     - Personal teams are free and work for development

5. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter run -d macos
   ```

## Option 2: Disable Signing (For Testing Only)

If you don't want to use an Apple ID:

1. Open `macos/Runner.xcodeproj/project.pbxproj` in a text editor

2. Find all occurrences of:
   ```
   CODE_SIGN_STYLE = Automatic;
   ```

3. Replace with:
   ```
   CODE_SIGN_STYLE = Manual;
   ```

4. Find all occurrences of:
   ```
   CODE_SIGN_IDENTITY = "-";
   ```

   Make sure they exist for Debug configuration

5. Save and try building again

## What's Happening?

Google Sign-In requires keychain access on macOS. Even though we disabled the app sandbox in Debug mode, Xcode still requires the app to be code-signed when using any entitlements.

The easiest solution is Option 1 - it only takes 2 minutes and works perfectly for development.

## After Signing is Configured

Once signing is set up, Google Sign-In will work and you can:
- Sign in with your Google account
- The backend will verify and return a JWT token
- Token will be stored securely
- You'll be logged into PlotEngine!

## Troubleshooting

### "No signing certificate"
- Solution: Use Option 1 and add your Apple ID

### "Failed to create provisioning profile"
- Solution: Change the Bundle Identifier in Xcode to something unique
  - Go to "Signing & Capabilities"
  - Change "Bundle Identifier" to `com.yourname.plotengine`

### Still having issues?
- Try `flutter clean` and rebuild
- Make sure Xcode Command Line Tools are installed:
  ```bash
  xcode-select --install
  ```
