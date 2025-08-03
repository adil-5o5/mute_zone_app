// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/mute_zone.dart';
import '../services/location_service.dart';
import '../widgets/edit_zone_dialog.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const MethodChannel _channel = MethodChannel('mute_zones_location');
  List<MuteZone> _muteZones = [];
  bool _isLocationTracking = false;
  bool _hasNotificationPolicyPermission = false;
  bool _hasWriteSettingsPermission = false;
  bool _hasNotificationListenerPermission = false;

  @override
  void initState() {
    super.initState();
    _loadMuteZones();
    _checkLocationTrackingStatus();
    _checkNotificationPolicyPermission();
  }

  void _checkLocationTrackingStatus() {
    // ULTRA-FAST: Immediate state update
    setState(() {
      _isLocationTracking = LocationService.isServiceRunning;
    });
  }

  Future<void> _checkNotificationPolicyPermission() async {
    // ULTRA-FAST: Parallel permission checks
    final futures = await Future.wait([
      LocationService.checkNotificationPolicyPermission(),
      LocationService.checkWriteSettingsPermission(),
      LocationService.checkNotificationListenerPermission(),
    ]);
    
    setState(() {
      _hasNotificationPolicyPermission = futures[0];
      _hasWriteSettingsPermission = futures[1];
      _hasNotificationListenerPermission = futures[2];
    });
  }

  Future<void> _testMute(bool mute) async {
    // ULTRA-FAST: Direct execution without delays
    await _channel.invokeMethod('setRingerMode', {'mute': mute});
  }

  void _showNotificationListenerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Notification Listener Required"),
        content: const Text(
          "Please enable Notification Listener Service so the app can control Do Not Disturb mode.\n\n"
          "This is crucial for OnePlus devices to properly mute your phone when entering mute zones."
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: const Text("Open Settings"),
            onPressed: () {
              Navigator.of(context).pop();
              LocationService.openNotificationListenerSettings();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _loadMuteZones() async {
    setState(() {
      _muteZones = LocationService.getMuteZones();
    });
  }

  void _editZone(MuteZone zone) {
    showDialog(
      context: context,
      builder: (context) => EditZoneDialog(
        zone: zone,
        onSave: (updatedZone) async {
          await LocationService.updateMuteZone(updatedZone);
          await _loadMuteZones();
        },
      ),
    );
  }

  void _deleteZone(MuteZone zone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Zone'),
        content: Text('Are you sure you want to delete "${zone.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await LocationService.removeMuteZone(zone.id);
              await _loadMuteZones();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _checkNotificationPolicyPermission();
            },
            tooltip: 'Refresh permissions',
          ),
          Switch(
            value: _isLocationTracking,
            onChanged: (value) async {
              try {
                if (value) {
                  // ULTRA-FAST: Parallel permission checks
                  final futures = await Future.wait([
                    LocationService.checkNotificationPolicyPermission(),
                    LocationService.checkWriteSettingsPermission(),
                    LocationService.checkNotificationListenerPermission(),
                  ]);
                  
                  final hasNotificationPermission = futures[0];
                  final hasWriteSettingsPermission = futures[1];
                  final hasNotificationListenerPermission = futures[2];
                  
                  if (!hasNotificationPermission && !hasWriteSettingsPermission && !hasNotificationListenerPermission) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('System settings permission is required. Please grant "Modify system settings" or enable "Notification Listener Service".'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                    return;
                  }
                  await LocationService.startLocationTracking();
                } else {
                  await LocationService.stopLocationTracking();
                }
                _checkLocationTrackingStatus();
                _checkNotificationPolicyPermission();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${e.toString()}')),
                );
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Location Tracking',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        _isLocationTracking ? Icons.location_on : Icons.location_off,
                        color: _isLocationTracking ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isLocationTracking ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: _isLocationTracking ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLocationTracking 
                        ? 'Monitoring your location for mute zones'
                        : 'Location tracking is disabled',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Settings Permissions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  // Notification Policy Permission
                  Row(
                    children: [
                      Icon(
                        _hasNotificationPolicyPermission ? Icons.check_circle : Icons.warning,
                        color: _hasNotificationPolicyPermission ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notification Policy',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _hasNotificationPolicyPermission ? 'Granted' : 'Required',
                              style: TextStyle(
                                color: _hasNotificationPolicyPermission ? Colors.green : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Write Settings Permission
                  Row(
                    children: [
                      Icon(
                        _hasWriteSettingsPermission ? Icons.check_circle : Icons.warning,
                        color: _hasWriteSettingsPermission ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Modify System Settings',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _hasWriteSettingsPermission ? 'Granted' : 'Required',
                              style: TextStyle(
                                color: _hasWriteSettingsPermission ? Colors.green : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Notification Listener Permission
                  Row(
                    children: [
                      Icon(
                        _hasNotificationListenerPermission ? Icons.check_circle : Icons.warning,
                        color: _hasNotificationListenerPermission ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Notification Listener Service',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              _hasNotificationListenerPermission ? 'Active' : 'Required',
                              style: TextStyle(
                                color: _hasNotificationListenerPermission ? Colors.green : Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    (_hasNotificationPolicyPermission || _hasWriteSettingsPermission || _hasNotificationListenerPermission)
                        ? 'App can control phone ringer mode'
                        : 'Permissions needed to mute/unmute phone',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  
                  if (!_hasNotificationPolicyPermission && !_hasWriteSettingsPermission && !_hasNotificationListenerPermission) ...[
                    const SizedBox(height: 8),
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () async {
                            await LocationService.openWriteSettingsPermission();
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('Grant System Settings Permission'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            _showNotificationListenerDialog();
                          },
                          icon: const Icon(Icons.list),
                          label: const Text('Enable Notification Listener'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _testMute(true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone muted for testing')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.volume_off),
                            label: const Text('Test Mute'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await _testMute(false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Phone unmuted for testing')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                            icon: const Icon(Icons.volume_up),
                            label: const Text('Test Unmute'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _muteZones.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.location_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No mute zones created yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap on the map to create your first mute zone',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: _muteZones.map((zone) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          zone.isActive ? Icons.location_on : Icons.location_off,
                          color: zone.isActive ? Colors.blue : Colors.grey,
                        ),
                        title: Text(zone.name),
                        subtitle: Text(
                          'Lat: ${zone.latitude.toStringAsFixed(4)}, '
                          'Lng: ${zone.longitude.toStringAsFixed(4)}\n'
                          'Radius: ${zone.radius.toStringAsFixed(0)}m • '
                          '${zone.isActive ? 'Active' : 'Inactive'}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _editZone(zone),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteZone(zone),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}