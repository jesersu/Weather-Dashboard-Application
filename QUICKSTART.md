# Quick Start Guide - Get Running in 5 Minutes

## Fastest Method: Create in Xcode

### Step 1: Create New iOS Project (2 minutes)

1. **Open Xcode**
2. **File → New → Project**
3. Choose **iOS → App**
4. Settings:
   - Product Name: `WeDaApp`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - ✅ Include Tests
5. Save to: `/Users/jesesu/Documents/Swift/iOSFueled/WeatherDashboardApp/`
   - ⚠️ **UNCHECK** "Create Git repository"

### Step 2: Create Workspace (1 minute)

1. **Close the project** (Cmd + Q or close the window)
2. **File → New → Workspace**
3. Name: `WeDaApp`
4. Save to: `/Users/jesesu/Documents/Swift/iOSFueled/WeatherDashboardApp/`

### Step 3: Add Everything to Workspace (2 minutes)

1. In the workspace, **right-click** → Add Files to "WeDaApp"
2. Add `WeDaApp.xcodeproj`
3. Add each package:
   - `NetworkingKit/Package.swift`
   - `DollarGeneralPersist/Package.swift`  
   - `DollarGeneralTemplateHelpers/Package.swift`
   - `ArkanaKeys/ArkanaKeys/Package.swift`
   - `ArkanaKeys/ArkanaKeysInterfaces/Package.swift`

### Step 4: Link Packages to App

1. Select **WeDaApp project** → **WeDaApp target**
2. **General** tab → **Frameworks, Libraries, and Embedded Content**
3. Click **+** and add:
   - NetworkingKit
   - DollarGeneralPersist
   - DollarGeneralTemplateHelpers
   - ArkanaKeys

### Step 5: Replace Generated Files

1. **Delete** these auto-generated files from Xcode:
   - `WeDaAppApp.swift`
   - `ContentView.swift`

2. **Add our files**:
   - Right-click `WeDaApp` folder → **Add Files to "WeDaApp"**
   - Select `WeDaApp/Code` folder
   - ✅ Create groups
   - ✅ Add to target: WeDaApp
   - Click Add

### Step 6: Configure API Key

```bash
cd /Users/jesesu/Documents/Swift/iOSFueled/WeatherDashboardApp

# Install Arkana
bundle install

# Add API key (get free key from openweathermap.org)
echo "OpenWeatherMapAPIKey=YOUR_KEY_HERE" > .env
echo "OpenWeatherMapBaseUrl=https://api.openweathermap.org" >> .env

# Generate encrypted keys
bundle exec arkana
```

### Step 7: Build & Run! 🎉

1. Select iPhone 15 simulator
2. **Cmd + R** to run

You should see a working app with 3 tabs (placeholder screens)!

---

## If You Get Errors

### "Cannot find module 'ArkanaKeys'"
→ Run `bundle exec arkana` from the project directory

### Packages not found
→ **File → Packages → Resolve Package Versions**

### Build errors
→ **Product → Clean Build Folder** (Cmd + Shift + K), then rebuild

---

## What You'll See

A working iOS app with:
- ✅ 3-tab interface (Search, Favorites, History)
- ✅ All Swift packages linked
- ✅ Placeholder screens ready for implementation
- ✅ Full architecture in place

## Next Steps

Now you can implement features using TDD:
1. Write tests first in `WeDaAppTests/`
2. Implement services
3. Build ViewModels  
4. Create real UI screens

Need help with next steps? Just ask!
