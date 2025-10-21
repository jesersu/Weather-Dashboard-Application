# Setting Up WeDaApp in Xcode

Since we have all the source code but not the Xcode project files yet, here's how to create them:

## Quick Setup (Manual Creation in Xcode)

### Step 1: Create New iOS App Project

1. Open Xcode
2. Select **File → New → Project...**
3. Choose **iOS → App**
4. Click **Next**

5. Configure your project:
   - **Product Name**: `WeDaApp`
   - **Team**: Select your team
   - **Organization Identifier**: `com.dollargeneral` (or your preference)
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: **None** (we'll handle persistence ourselves)
   - **Include Tests**: ✅ Check this
   - Click **Next**

6. **Important**: Save it to `/Users/jesesu/Documents/Swift/iOSFueled/WeatherDashboardApp/`
   - Navigate to the WeatherDashboardApp folder
   - **UNCHECK** "Create Git repository" (we already have our structure)
   - Click **Create**

### Step 2: Close the Project and Create Workspace

1. **Close** the WeDaApp.xcodeproj you just created
2. In Xcode, select **File → New → Workspace...**
3. Name it `WeDaApp`
4. Save it in `/Users/jesesu/Documents/Swift/iOSFueled/WeatherDashboardApp/`

### Step 3: Add Project and Packages to Workspace

1. In the workspace (left sidebar), right-click in the empty area
2. Select **Add Files to "WeDaApp"...**
3. Navigate to `/Users/jesesu/Documents/Swift/iOSFueled/WeatherDashboardApp/`
4. Select `WeDaApp.xcodeproj` and click **Add**

5. Now add each Swift package:
   - Right-click in workspace → **Add Files to "WeDaApp"...**
   - Add `NetworkingKit/Package.swift`
   - Add `DollarGeneralPersist/Package.swift`
   - Add `DollarGeneralTemplateHelpers/Package.swift`
   - Add `ArkanaKeys/ArkanaKeys/Package.swift`
   - Add `ArkanaKeys/ArkanaKeysInterfaces/Package.swift`

### Step 4: Link Swift Packages to App Target

1. Select the **WeDaApp project** in the navigator
2. Select the **WeDaApp target**
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click the **+** button
6. Add these packages:
   - NetworkingKit
   - DollarGeneralPersist
   - DollarGeneralTemplateHelpers
   - ArkanaKeys

### Step 5: Move Source Files

Now we need to move our source files into the Xcode project:

1. **Delete** the auto-generated files:
   - Delete `WeDaApp/WeDaAppApp.swift`
   - Delete `WeDaApp/ContentView.swift`

2. **Add our existing code**:
   - In Xcode, right-click on the `WeDaApp` folder
   - Select **Add Files to "WeDaApp"...**
   - Navigate to `WeatherDashboardApp/WeDaApp/Code/`
   - Select the **Code** folder
   - ✅ Check **Create groups**
   - ✅ Check **Copy items if needed**
   - Click **Add**

### Step 6: Configure Build Settings

1. Select the **WeDaApp target**
2. Go to **Build Settings**
3. Search for "iOS Deployment Target"
4. Set to **iOS 15.0**

### Step 7: Install Arkana and Generate Keys

```bash
cd /Users/jesesu/Documents/Swift/iOSFueled/WeatherDashboardApp

# Install Arkana
bundle install

# Add your OpenWeatherMap API key to .env
echo "OpenWeatherMapAPIKey=YOUR_API_KEY_HERE" > .env
echo "OpenWeatherMapBaseUrl=https://api.openweathermap.org" >> .env

# Generate encrypted keys
bundle exec arkana
```

### Step 8: Add External Dependencies

We need Quick, Nimble, and potentially Nuke:

1. Select the **WeDaApp project**
2. Select the **WeDaApp target**
3. Go to **General** tab → **Frameworks, Libraries, and Embedded Content**
4. Click **+** → **Add Other...** → **Add Package Dependency...**

Add these packages:
- **Quick**: `https://github.com/Quick/Quick`
- **Nimble**: `https://github.com/Quick/Nimble`
- **Nuke** (optional for images): `https://github.com/kean/Nuke`

### Step 9: Build and Run

1. Select a simulator (e.g., iPhone 15)
2. Press **Cmd + B** to build
3. Press **Cmd + R** to run

---

## Common Issues

### Issue: "Cannot find 'ArkanaKeys' in scope"

**Solution**: Make sure you ran `bundle exec arkana` to generate the keys.

### Issue: Module not found

**Solution**:
1. Clean build folder: **Product → Clean Build Folder** (Cmd + Shift + K)
2. Rebuild: **Product → Build** (Cmd + B)

### Issue: Packages not linking

**Solution**:
1. Go to **File → Packages → Reset Package Caches**
2. Rebuild the project

---

## Alternative: Let Claude Create the Project Files

If this seems too complex, I can create the Xcode project files programmatically. Just let me know!
