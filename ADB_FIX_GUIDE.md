# ADB Fix Guide for OnePlus Nord CE 4

## 🚨 Your App Package Name
**Package Name**: `com.example.mute_zones`

## 🔧 Step-by-Step ADB Fix

### **Step 1: Download ADB (Minimal ADB & Fastboot)**

**Option A: Minimal ADB & Fastboot (Recommended)**
- Download from: https://forum.xda-developers.com/t/tool-minimal-adb-and-fastboot-2-9-18.2317790/
- This is a lightweight tool that includes ADB

**Option B: Official Android SDK Platform Tools**
- Download from: https://developer.android.com/studio/releases/platform-tools
- Extract to a folder like `C:\adb`

### **Step 2: Install Minimal ADB & Fastboot**

1. **Run the installer** you downloaded
2. **Choose installation folder** (default is usually fine)
3. **Complete installation** - it will create a shortcut

### **Step 3: Open Minimal ADB and Fastboot**

1. **Find the shortcut** on your desktop or start menu
2. **Click to open** - you'll get a black Command Prompt window
3. **Test ADB** by typing:
   ```bash
   adb devices
   ```
4. **If it shows "List of devices attached"** → ADB is working ✅

### **Step 4: Enable Developer Options on Your Phone**

1. **Go to Settings > About phone**
2. **Tap "Build number" 7 times** until you see "You're now a developer"
3. **Go to Settings > System > Developer Options**
4. **Enable "USB Debugging"**
5. **Connect your phone via USB**
6. **Allow USB debugging** when prompted on your phone

### **Step 5: Grant Notification Listener Permission**

In the ADB command prompt, run this command:

```bash
adb shell pm grant com.example.mute_zones android.permission.BIND_NOTIFICATION_LISTENER_SERVICE
```

### **Step 6: Grant Additional Permissions**

Run these additional commands for complete functionality:

```bash
# Grant notification policy permission
adb shell pm grant com.example.mute_zones android.permission.ACCESS_NOTIFICATION_POLICY

# Grant write settings permission
adb shell pm grant com.example.mute_zones android.permission.WRITE_SETTINGS

# Grant post notifications permission
adb shell pm grant com.example.mute_zones android.permission.POST_NOTIFICATIONS
```

## 🚨 If ADB is Still Not Recognized

### **Fix 1: Add ADB to PATH Manually**

1. **Find ADB installation path** (usually):
   ```
   C:\Program Files (x86)\Minimal ADB and Fastboot
   ```

2. **Open Environment Variables**:
   - Press `Win + R`
   - Type `sysdm.cpl`
   - Click "Environment Variables"

3. **Edit Path**:
   - Under "System variables", select "Path"
   - Click "Edit"
   - Click "New"
   - Paste the ADB path
   - Click "OK" on all dialogs

4. **Restart Command Prompt** and try:
   ```bash
   adb devices
   ```

### **Fix 2: Use Full Path**

If PATH doesn't work, use the full path:
```bash
"C:\Program Files (x86)\Minimal ADB and Fastboot\adb.exe" devices
```

## 📱 Alternative: Grant Permissions via App Settings

If ADB doesn't work, you can grant permissions manually:

### **Step 1: Enable Notification Listener**
1. **Go to Settings > Apps > Special app access > Notification access**
2. **Find "mute_zones"** in the list
3. **Enable it**

### **Step 2: Grant System Settings Permission**
1. **Go to Settings > Apps > mute_zones > Permissions**
2. **Enable "Modify system settings"**

### **Step 3: Disable Battery Optimization**
1. **Go to Settings > Battery > Battery optimization**
2. **Find "mute_zones"**
3. **Set to "Don't optimize"**

## 🧪 Test the Permissions

### **Test 1: Check ADB Connection**
```bash
adb devices
```
Should show your device listed.

### **Test 2: Check Permissions**
```bash
adb shell dumpsys package com.example.mute_zones | findstr permission
```
Should show the granted permissions.

### **Test 3: Test App Functionality**
1. **Open the app**
2. **Go to Settings**
3. **Check if permissions show as "Granted"**
4. **Use test buttons** to verify mute/DND functionality

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
1. **Make sure NotificationListenerService is properly registered**
2. **Check AndroidManifest.xml** for the service declaration
3. **Reinstall the app** if necessary

## ✅ Expected Results

After following these steps:
- ✅ ADB will be recognized and working
- ✅ Notification listener permission will be granted
- ✅ App will appear in "Device and app notification" settings
- ✅ Do Not Disturb mode will work properly
- ✅ Phone will mute automatically when entering zones

## 🎯 Quick Commands Summary

```bash
# Check ADB connection
adb devices

# Grant notification listener permission
adb shell pm grant com.example.mute_zones android.permission.BIND_NOTIFICATION_LISTENER_SERVICE

# Grant notification policy permission
adb shell pm grant com.example.mute_zones android.permission.ACCESS_NOTIFICATION_POLICY

# Grant write settings permission
adb shell pm grant com.example.mute_zones android.permission.WRITE_SETTINGS

# Grant post notifications permission
adb shell pm grant com.example.mute_zones android.permission.POST_NOTIFICATIONS
```

The key is getting ADB working first, then using the correct package name (`com.example.mute_zones`) for your app! 