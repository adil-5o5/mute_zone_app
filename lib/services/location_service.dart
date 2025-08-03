import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/mute_zone.dart';

class LocationService {
  static const MethodChannel _channel = MethodChannel('mute_zones_location');
  static const String _muteZonesKey = 'mute_zones';
  
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  static StreamSubscription<Position>? _locationSubscription;
  static List<MuteZone> _muteZones = [];
  static bool _isServiceRunning = false;
  static bool _isInMuteZone = false;

  static Future<void> initialize() async {
    await _initializeNotifications();
    await _loadMuteZones();
  }

  static Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(initializationSettings);
  }

  static Future<void> _loadMuteZones() async {
    final prefs = await SharedPreferences.getInstance();
    final zonesJson = prefs.getStringList(_muteZonesKey) ?? [];
    _muteZones = zonesJson
        .map((json) => MuteZone.fromJson(jsonDecode(json)))
        .where((zone) => zone.isActive)
        .toList();
  }

  static Future<void> startLocationTracking() async {
    if (_isServiceRunning) return;

    // Request permissions
    final locationPermission = await Permission.location.request();
    final backgroundLocationPermission = await Permission.locationAlways.request();
    final notificationPermission = await Permission.notification.request();
    
    // Check notification policy permission (this requires system settings)
    final hasNotificationPolicyPermission = await checkNotificationPolicyPermission();
    final hasWriteSettingsPermission = await checkWriteSettingsPermission();
    final hasNotificationAccessPermission = await checkNotificationAccessPermission();
    
    if (!hasNotificationPolicyPermission && !hasWriteSettingsPermission && !hasNotificationAccessPermission) {
      // This permission can only be granted through system settings
      throw Exception('System settings permission is required to control phone ringer mode. Please grant "Modify system settings" or "Device and app notification" permission in system settings by tapping the "Open Settings" button in the Settings screen.');
    }

    if (locationPermission.isDenied || backgroundLocationPermission.isDenied) {
      throw Exception('Location permissions are required');
    }

    // Check location service
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      throw Exception('Location services are disabled');
    }

    // Start location tracking with ULTRA-FAST settings
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 1, // ULTRA-FAST: Update every 1 meter
        timeLimit: Duration(seconds: 10), // ULTRA-FAST: Time limit for immediate updates
      ),
    ).listen(_onLocationUpdate);

    _isServiceRunning = true;
    await _showNotification('Mute Zones Active', 'Monitoring your location');
  }

  static Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    _isServiceRunning = false;
    await _notifications.cancelAll();
  }

  static void _onLocationUpdate(Position position) {
    final currentLat = position.latitude;
    final currentLng = position.longitude;
    
    bool wasInMuteZone = _isInMuteZone;
    _isInMuteZone = false;
    MuteZone? currentZone;

    // Check if current location is in any mute zone
    for (final zone in _muteZones) {
      if (zone.isLocationInZone(currentLat, currentLng)) {
        _isInMuteZone = true;
        currentZone = zone;
        break;
      }
    }

    // Handle mute zone state changes
    if (_isInMuteZone && !wasInMuteZone) {
      _setRingerMode(true); // Mute
      _showNotification(
        'Entered Mute Zone',
        'Phone muted: ${currentZone?.name}',
      );
    } else if (!_isInMuteZone && wasInMuteZone) {
      _setRingerMode(false); // Unmute
      _showNotification(
        'Left Mute Zone',
        'Phone unmuted',
      );
    }
  }

  static Future<void> _setRingerMode(bool mute) async {
    try {
      // ULTRA-FAST: Direct execution without permission checks
      await setDoNotDisturbMode(mute);
      await _channel.invokeMethod('setRingerMode', {'mute': mute});
      print('ULTRA-FAST: Ringer mode ${mute ? 'muted' : 'unmuted'}');
    } catch (e) {
      print('Error setting ringer mode: $e');
    }
  }

  static Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'mute_zones_channel',
      'Mute Zones',
      channelDescription: 'Notifications for mute zone events',
      importance: Importance.low,
      priority: Priority.low,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      platformChannelSpecifics,
    );
  }

  static Future<void> addMuteZone(MuteZone zone) async {
    _muteZones.add(zone);
    await _saveMuteZones();
  }

  static Future<void> removeMuteZone(String zoneId) async {
    _muteZones.removeWhere((zone) => zone.id == zoneId);
    await _saveMuteZones();
  }

  static Future<void> updateMuteZone(MuteZone updatedZone) async {
    final index = _muteZones.indexWhere((zone) => zone.id == updatedZone.id);
    if (index != -1) {
      _muteZones[index] = updatedZone;
      await _saveMuteZones();
    }
  }

  static Future<void> _saveMuteZones() async {
    final prefs = await SharedPreferences.getInstance();
    final zonesJson = _muteZones
        .map((zone) => jsonEncode(zone.toJson()))
        .toList();
    await prefs.setStringList(_muteZonesKey, zonesJson);
  }

  static List<MuteZone> getMuteZones() {
    return List.unmodifiable(_muteZones);
  }

  static bool get isServiceRunning => _isServiceRunning;
  static bool get isInMuteZone => _isInMuteZone;
  
  static Future<bool> checkNotificationPolicyPermission() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>('checkNotificationPolicyPermission') ?? false;
      return hasPermission;
    } catch (e) {
      print('Error checking notification policy permission: $e');
      return false;
    }
  }
  
  static Future<bool> checkWriteSettingsPermission() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>('checkWriteSettingsPermission') ?? false;
      return hasPermission;
    } catch (e) {
      print('Error checking write settings permission: $e');
      return false;
    }
  }
  
  static Future<bool> checkNotificationAccessPermission() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>('checkNotificationAccessPermission') ?? false;
      return hasPermission;
    } catch (e) {
      print('Error checking notification access permission: $e');
      return false;
    }
  }
  
  static Future<bool> checkNotificationListenerPermission() async {
    try {
      final hasPermission = await _channel.invokeMethod<bool>('checkNotificationListenerPermission') ?? false;
      return hasPermission;
    } catch (e) {
      print('Error checking notification listener permission: $e');
      return false;
    }
  }
  
  static Future<void> openNotificationPolicySettings() async {
    await openAppSettings();
  }
  
  static Future<void> openWriteSettingsPermission() async {
    try {
      await _channel.invokeMethod('openWriteSettingsPermission');
    } catch (e) {
      print('Error opening write settings permission: $e');
      // Fallback to app settings
      await openAppSettings();
    }
  }
  
  static Future<void> openNotificationAccessSettings() async {
    try {
      await _channel.invokeMethod('openNotificationAccessSettings');
    } catch (e) {
      print('Error opening notification access settings: $e');
      // Fallback to app settings
      await openAppSettings();
    }
  }
  
  static Future<void> openNotificationListenerSettings() async {
    try {
      await _channel.invokeMethod('openNotificationListenerSettings');
    } catch (e) {
      print('Error opening notification listener settings: $e');
      // Fallback to app settings
      await openAppSettings();
    }
  }
  
  static Future<void> setDoNotDisturbMode(bool enable) async {
    try {
      await _channel.invokeMethod('setDoNotDisturbMode', {'enable': enable});
      print('Do Not Disturb mode ${enable ? 'enabled' : 'disabled'}');
    } catch (e) {
      print('Error setting Do Not Disturb mode: $e');
    }
  }
} 