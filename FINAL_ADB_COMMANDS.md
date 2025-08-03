# 🚨 FINAL ADB COMMANDS FOR YOUR APP

## 📱 Your App Package Name
**Package Name**: `com.example.mute_zones`

## 🔧 Quick ADB Setup

### **Step 1: Download and Install ADB**
1. **Download Minimal ADB & Fastboot** from: https://forum.xda-developers.com/t/tool-minimal-adb-and-fastboot-2-9-18.2317790/
2. **Install it** and open the Command Prompt window
3. **Test ADB** by typing: `adb devices`

### **Step 2: Enable Developer Options on Your Phone**
1. **Go to Settings > About phone**
2. **Tap "Build number" 7 times**
3. **Go to Settings > System > Developer Options**
4. **Enable "USB Debugging"**
5. **Connect your phone via USB**
6. **Allow USB debugging** when prompted

## 🎯 EXACT COMMANDS FOR YOUR APP

Copy and paste these commands in the ADB Command Prompt:

```bash
# Check if ADB is working
adb devices

# Grant notification listener permission (CRUCIAL for OnePlus)
adb shell pm grant com.example.mute_zones android.permission.BIND_NOTIFICATION_LISTENER_SERVICE

# Grant notification policy permission
adb shell pm grant com.example.mute_zones android.permission.ACCESS_NOTIFICATION_POLICY

# Grant write settings permission
adb shell pm grant com.example.mute_zones android.permission.WRITE_SETTINGS

# Grant post notifications permission
adb shell pm grant com.example.mute_zones android.permission.POST_NOTIFICATIONS
```

## 🧪 Test Commands

```bash
# Check if permissions were granted
adb shell dumpsys package com.example.mute_zones | findstr permission

# Check if notification listener service is active
adb shell dumpsys notification | findstr mute_zones
```

## 📱 Alternative: Manual Permission Granting

If ADB doesn't work, do this manually:

1. **Go to Settings > Apps > Special app access > Notification access**
2. **Find "mute_zones"** and enable it
3. **Go to Settings > Apps > mute_zones > Permissions**
4. **Enable "Modify system settings"**
5. **Go to Settings > Battery > Battery optimization**
6. **Find "mute_zones"** and set to "Don't optimize"

## 🎯 What This Will Fix

After running these commands:
- ✅ App will appear in "Device and app notification" settings
- ✅ NotificationListenerService will be active
- ✅ Do Not Disturb mode will work properly
- ✅ Phone will mute automatically when entering zones
- ✅ All test buttons in the app will work

## 🚨 Troubleshooting

### **If ADB shows "unauthorized":**
1. **Disconnect and reconnect** your phone
2. **Revoke USB debugging** on your phone and re-enable it
3. **Try a different USB cable**

### **If permissions don't stick:**
1. **Restart your phone**
2. **Re-run the ADB commands**
3. **Check if the app appears in notification settings**

### **If app doesn't appear in notification settings:**
1. **Make sure you installed the latest APK** (`build\app\outputs\flutter-apk\app-release.apk`)
2. **Check that NotificationListenerService is properly registered**
3. **Reinstall the app** if necessary

## ✅ Expected Results

After following these steps:
- ✅ ADB will be recognized and working
- ✅ All permissions will be granted
- ✅ App will appear in notification settings
- ✅ Do Not Disturb mode will work properly
- ✅ Phone will mute automatically when entering zones

## 🎯 Quick Test

1. **Install the APK** (`build\app\outputs\flutter-apk\app-release.apk`)
2. **Run the ADB commands** above
3. **Open the app** and go to Settings
4. **Check if all permissions show as "Granted"**
5. **Use the test buttons** to verify functionality
6. **Create a mute zone** and test automatic muting

The key is using the correct package name: `com.example.mute_zones` 