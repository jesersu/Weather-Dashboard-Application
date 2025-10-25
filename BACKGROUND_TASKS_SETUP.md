# Background Tasks Setup Guide

## Issue: BGTaskScheduler Error 3

**Error Message**: `❌ Failed to schedule background refresh: The operation couldn't be completed. (BGTaskSchedulerErrorDomain error 3.)`

**Error Code**: `BGTaskSchedulerErrorCodeNotPermitted` (error 3)

**Cause**: The app doesn't have permission to schedule background tasks because required Xcode project configuration is missing.

---

## Understanding the Error

Apple's `BGTaskScheduler` requires **explicit permission** to schedule background tasks for:
- 🔋 Battery efficiency
- 🔒 Security and privacy
- 📱 User control over background behavior

**Error 3 specifically means**: The app is not permitted because one or more required configurations are missing.

---

## Required Configuration (2 Steps)

### ✅ Step 1: Add BGTaskSchedulerPermittedIdentifiers

This tells iOS which background task identifiers your app is allowed to use.

#### Option A: Using Info.plist (Traditional Approach)

1. **Open Xcode** and navigate to your project
2. **Find Info.plist**:
   - In project navigator: `WeDaApp` → `WeDaApp` → `Info.plist`
   - If you don't see `Info.plist` as a file, it might be embedded in Build Settings

3. **Add the permitted identifiers array**:
   - Right-click in Info.plist → Add Row
   - Key: `BGTaskSchedulerPermittedIdentifiers`
   - Type: Array

4. **Add your task identifier**:
   - Expand the array
   - Add Item (String): `com.dollarg.wedaapp.refresh`

**Info.plist XML** (if editing as source code):
```xml
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.dollarg.wedaapp.refresh</string>
</array>
```

#### Option B: Using Target Settings (Modern Xcode 14+)

If you don't have a separate Info.plist file:

1. **Select your project** in the navigator
2. **Select the WeDaApp target**
3. **Go to "Info" tab**
4. **Click the "+" button** under "Custom iOS Target Properties"
5. **Add**:
   - Key: `BGTaskSchedulerPermittedIdentifiers`
   - Type: Array
6. **Expand the array** and add item:
   - Value: `com.dollarg.wedaapp.refresh`

---

### ✅ Step 2: Enable Background Modes Capability

This adds the necessary entitlements for background execution.

1. **Open Xcode** and select your project
2. **Select the WeDaApp target**
3. **Go to "Signing & Capabilities" tab**
4. **Click "+ Capability"** button (top-left)
5. **Search for "Background Modes"**
6. **Add "Background Modes"** capability
7. **Check these checkboxes**:
   - ✅ **Background fetch** (for BGAppRefreshTask)
   - ✅ **Background processing** (for BGProcessingTask)

**What this does**:
- Creates/updates `WeDaApp.entitlements` file
- Adds background execution permissions to your app
- Allows iOS to wake your app for scheduled tasks

**Expected entitlements**:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
```

---

## Verification Steps

### 1. Check Configuration

After completing both steps above:

**Verify Info.plist/Target Settings**:
```bash
# Option 1: If using Info.plist file
cat WeDaApp/WeDaApp/Info.plist | grep -A 3 "BGTaskSchedulerPermittedIdentifiers"

# Option 2: Check build settings
xcodebuild -showBuildSettings -target WeDaApp | grep INFOPLIST
```

**Verify Entitlements**:
```bash
# Find entitlements file
find . -name "*.entitlements"

# Check contents (should show UIBackgroundModes)
cat WeDaApp/WeDaApp.entitlements
```

### 2. Clean Build

After configuration changes:

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean build
xcodebuild clean -workspace WeDaApp.xcworkspace -scheme WeDaApp

# Rebuild
xcodebuild build -workspace WeDaApp.xcworkspace -scheme WeDaApp -destination 'platform=iOS Simulator,name=iPhone 16'
```

### 3. Test Background Task Scheduling

**Run the app** and check console logs:

✅ **Success (after fix)**:
```
✅ Registered background refresh task: com.dollarg.wedaapp.refresh
✅ Scheduled background refresh for 2025-10-25 04:00:00 +0000
```

❌ **Failure (before fix)**:
```
❌ Failed to schedule background refresh: The operation couldn't be completed. (BGTaskSchedulerErrorDomain error 3.)
```

---

## Testing Background Tasks

### Simulator Testing

⚠️ **Important**: Background tasks have limitations on simulator:
- May not execute at scheduled times
- `e -l objc` debugger commands required to test
- Real device testing recommended for accurate behavior

**Force execution on simulator**:

1. **Run app in Xcode** with debugger attached
2. **Pause execution** (breakpoint or pause button)
3. **Run this command** in LLDB console:
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.dollarg.wedaapp.refresh"]
```
4. **Resume execution**
5. **Check logs** - you should see:
```
📱 Background refresh task started
🔄 Starting background weather fetch
✅ Background fetch completed: success
```

### Device Testing

For real-world testing:

1. **Run on physical device** (required for accurate testing)
2. **Go to Settings** → **Developer** → **Background Fetch**
3. **Enable "Background App Refresh"** for WeDaApp
4. **Add favorite cities** in the app
5. **Close the app** (swipe up from app switcher)
6. **Wait 4+ hours** (system decides when to run based on usage patterns)
7. **Check logs** via Console.app or Xcode Devices window

---

## Common Issues & Solutions

### Issue 1: Still Getting Error 3 After Configuration

**Cause**: Xcode didn't reload configuration

**Solution**:
```bash
# 1. Quit Xcode completely
# 2. Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# 3. Reopen Xcode and rebuild
```

### Issue 2: Background Modes Not Showing in Capabilities

**Cause**: Not signed in to Apple ID or team not selected

**Solution**:
1. Xcode → Settings → Accounts
2. Add Apple ID (free account works for testing)
3. Select WeDaApp target → Signing & Capabilities
4. Choose your team under "Signing"
5. Try adding Background Modes again

### Issue 3: Tasks Not Executing on Simulator

**Cause**: iOS simulator has limited background task support

**Solution**:
- Use debugger command (see "Simulator Testing" above)
- Test on real device for accurate behavior
- Background tasks are **system-managed** - iOS decides when to run them

### Issue 4: "Identifier Not Permitted" Error

**Cause**: Task identifier in code doesn't match permitted identifiers

**Solution**:

Check that these match **exactly**:

**In Code** (BackgroundTaskManager.swift:41):
```swift
static let backgroundRefreshTaskIdentifier = "com.dollarg.wedaapp.refresh"
```

**In Info.plist**:
```xml
<string>com.dollarg.wedaapp.refresh</string>
```

**They must match character-for-character** (case-sensitive)

### Issue 5: Entitlements File Not Found

**Cause**: Capability wasn't added correctly

**Solution**:
1. Delete Background Modes capability (if exists)
2. Clean build (⌘ + Shift + K)
3. Re-add Background Modes capability
4. Rebuild

---

## Understanding Background Task Scheduling

### How It Works

1. **Your app calls** `BGTaskScheduler.shared.submit(request)`
2. **iOS receives** the request and validates:
   - ✅ Task identifier is in permitted list
   - ✅ App has Background Modes entitlement
   - ✅ Earliest begin date is reasonable
3. **iOS schedules** the task based on:
   - 📱 Device usage patterns
   - 🔋 Battery level and charging status
   - 📶 Network availability
   - ⏰ Time of day (prefers when device is idle)
4. **iOS launches** your app in background when conditions are optimal
5. **Your app has** 30 seconds to complete the task
6. **Your app calls** `task.setTaskCompleted(success:)` to finish

### Best Practices

✅ **DO**:
- Schedule tasks at least 4+ hours in future
- Complete work within 30 seconds
- Handle task expiration gracefully
- Cache results locally
- Test on real device

❌ **DON'T**:
- Expect tasks to run at exact time
- Rely on background tasks for critical features
- Assume tasks will always run
- Perform network-intensive operations
- Forget to call `setTaskCompleted()`

---

## Debugging Tips

### Enable Verbose Logging

Add to your scheme:

1. **Edit Scheme** → **Run** → **Arguments**
2. **Environment Variables** → Add:
   - `BGTaskScheduler` = `1`

### Check Task Status

```swift
// In your code, check if task is pending
BGTaskScheduler.shared.getPendingTaskRequests { requests in
    print("Pending tasks: \(requests.count)")
    for request in requests {
        print("  - \(request.identifier), earliest: \(request.earliestBeginDate?.description ?? "nil")")
    }
}
```

### Monitor Background Activity

**On Mac**:
```bash
# Watch system logs for your app
log stream --predicate 'process == "WeDaApp"' --level debug
```

**On Device**:
1. Connect device to Mac
2. Open **Console.app**
3. Select your device
4. Filter by "WeDaApp"
5. Run app and watch for background task logs

---

## Quick Reference

### Task Identifier
```
com.dollarg.wedaapp.refresh
```

### Required Info.plist Key
```
BGTaskSchedulerPermittedIdentifiers (Array)
```

### Required Background Modes
- `fetch` (Background fetch)
- `processing` (Background processing)

### Minimum Schedule Interval
```
4 hours (14400 seconds)
```

### Execution Time Limit
```
30 seconds
```

### Simulator Test Command
```
e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.dollarg.wedaapp.refresh"]
```

---

## Additional Resources

### Official Documentation

- [BGTaskScheduler - Apple Developer](https://developer.apple.com/documentation/backgroundtasks/bgtaskscheduler)
- [Background Execution - Apple Developer](https://developer.apple.com/documentation/uikit/app_and_environment/scenes/preparing_your_ui_to_run_in_the_background)
- [WWDC 2019: Advances in App Background Execution](https://developer.apple.com/videos/play/wwdc2019/707/)

### Project Documentation

- `BackgroundTaskManager.swift` - Background task implementation
- `WeDaApp.swift` - Task registration and scheduling
- `README.md` - Project overview
- `CLAUDE.md` - Development guidelines

---

## Summary Checklist

Before running your app, verify:

- [ ] Added `BGTaskSchedulerPermittedIdentifiers` to Info.plist/Target Settings
- [ ] Value includes `com.dollarg.wedaapp.refresh`
- [ ] Enabled "Background Modes" capability in Xcode
- [ ] Checked "Background fetch" checkbox
- [ ] Checked "Background processing" checkbox
- [ ] Cleaned and rebuilt project
- [ ] Verified entitlements file exists and contains `UIBackgroundModes`
- [ ] Task identifier in code matches permitted identifier exactly
- [ ] Tested on real device (recommended) or used debugger command on simulator

**Once completed**, the error will be resolved and background tasks will schedule successfully! ✅

---

**Last Updated**: 2025-10-25
**App Version**: WeDaApp 1.0
**iOS Version**: iOS 18.0+
**Xcode Version**: 15.0+
