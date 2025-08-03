import 'package:flutter/services.dart';

class PackageInfo {
  static const MethodChannel _channel = MethodChannel('package_info');

  static Future<String> getPackageName() async {
    try {
      final packageName = await _channel.invokeMethod<String>('getPackageName') ?? 'com.example.mute_zones';
      print('Package Name: $packageName');
      return packageName;
    } catch (e) {
      print('Error getting package name: $e');
      return 'com.example.mute_zones'; // Fallback
    }
  }

  static Future<void> printPackageInfo() async {
    final packageName = await getPackageName();
    print('📱 App Package Name: $packageName');
    print('🔧 ADB Commands for this app:');
    print('');
    print('# Grant notification listener permission');
    print('adb shell pm grant $packageName android.permission.BIND_NOTIFICATION_LISTENER_SERVICE');
    print('');
    print('# Grant notification policy permission');
    print('adb shell pm grant $packageName android.permission.ACCESS_NOTIFICATION_POLICY');
    print('');
    print('# Grant write settings permission');
    print('adb shell pm grant $packageName android.permission.WRITE_SETTINGS');
    print('');
    print('# Grant post notifications permission');
    print('adb shell pm grant $packageName android.permission.POST_NOTIFICATIONS');
    print('');
  }
} 