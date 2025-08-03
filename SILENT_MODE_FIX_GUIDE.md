# Silent Mode Fix Guide

## Issue
The app is not putting the phone in silent mode when entering mute zones. This is due to missing Android permissions.

## Root Cause
The app needs the `ACCESS_NOTIFICATION_POLICY` permission to control the phone's ringer mode. This permission can only be granted through Android system settings, not through the normal permission request dialog.

## Solution

### Step 1: Grant Notification Policy Permission

1. **Open the app** and go to the Settings screen
2. **Look for the "Notification Policy Permission" card**
3. **If it shows "Required" (orange warning icon):**
   - Tap the "Open Settings" button
   - This will take you to the app's permission settings
   - Find "Notification access" or "Do Not Disturb access"
   - Enable the permission for this app
4. **If it shows "Granted" (green checkmark):** The permission is already set correctly

### Step 2: Test the Mute Functionality

1. **In the Settings screen**, if the permission is granted, you'll see test buttons
2. **Tap "Test Mute"** to manually mute your phone
3. **Tap "Test Unmute"** to manually unmute your phone
4. **If these buttons work**, the automatic mute in zones should also work

### Step 3: Enable Location Tracking

1. **Toggle the location tracking switch** in the app bar
2. **The app will check permissions** before starting
3. **If permission is missing**, you'll get a notification to grant it

### Step 4: Create and Test Mute Zones

1. **Go to the Map screen**
2. **Tap on the map** to create a mute zone
3. **Set the zone name, radius, and make it active**
4. **Walk into the zone** - your phone should automatically mute
5. **Walk out of the zone** - your phone should automatically unmute

## Troubleshooting

### If the app still doesn't mute:

1. **Check Android version**: This feature works on Android 6.0 (API 23) and above
2. **Check device manufacturer**: Some manufacturers (Samsung, Xiaomi, etc.) have additional battery optimization settings
3. **Disable battery optimization** for this app:
   - Go to Android Settings > Apps > Your App > Battery
   - Set to "Unrestricted" or disable battery optimization
4. **Check Do Not Disturb settings**:
   - Make sure the app has permission to control Do Not Disturb
   - Some devices require manual permission in Do Not Disturb settings

### For Samsung devices:
1. Go to Settings > Apps > Your App > Permissions
2. Enable "Do Not Disturb access"
3. Go to Settings > Notifications > Advanced settings > Do Not Disturb access
4. Enable access for this app

### For Xiaomi devices:
1. Go to Settings > Apps > Your App > Permissions
2. Enable "Display over other apps" and "Do Not Disturb access"
3. Go to Settings > Additional settings > Battery & performance > Manage apps battery usage
4. Set this app to "No restrictions"

## Technical Details

The app uses the following Android permissions:
- `ACCESS_NOTIFICATION_POLICY`: Required to control ringer mode
- `MODIFY_AUDIO_SETTINGS`: Required to change audio settings
- `ACCESS_FINE_LOCATION`: Required for precise location tracking
- `ACCESS_BACKGROUND_LOCATION`: Required for background location tracking

The `ACCESS_NOTIFICATION_POLICY` permission is special because:
- It can only be granted through system settings
- It's required for apps to control Do Not Disturb mode
- It's part of Android's security model to prevent apps from silently changing notification settings

## Code Changes Made

1. **Added permission checking** in the Flutter code
2. **Improved error handling** in the Android native code
3. **Added test buttons** to verify mute functionality
4. **Added permission status display** in the settings screen
5. **Added automatic permission checking** before starting location tracking

## Testing

To verify the fix is working:

1. **Grant the notification policy permission**
2. **Use the test buttons** in settings to verify mute/unmute works
3. **Create a mute zone** and walk into it
4. **Check that the phone goes silent** when entering the zone
5. **Check that the phone unmutes** when leaving the zone

The app will show notifications when entering/leaving mute zones to confirm it's working. 