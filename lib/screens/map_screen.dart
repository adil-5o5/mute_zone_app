// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../models/mute_zone.dart';
import '../services/location_service.dart';
import '../widgets/edit_zone_dialog.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  List<MuteZone> _muteZones = [];
  Position? _currentPosition;
  bool _isInMuteZone = false;

  @override
  void initState() {
    super.initState();
    _loadMuteZones();
    _getCurrentLocation();
  }

  Future<void> _loadMuteZones() async {
    setState(() {
      _muteZones = LocationService.getMuteZones();
      _updateMapElements();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      // ULTRA-FAST: Get location with maximum speed
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5), // ULTRA-FAST: 5 second timeout
      );
      setState(() {
        _currentPosition = position;
      });
      _checkMuteZoneStatus(position);
      
      // ULTRA-FAST: Animate to current location with maximum speed
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16.0, // Zoom level
          ),
        );
      }
    } catch (e) {
      print('ULTRA-FAST: Error getting current location: $e');
    }
  }

  void _checkMuteZoneStatus(Position position) {
    setState(() {
      _isInMuteZone = LocationService.isInMuteZone;
    });
  }

  void _updateMapElements() {
    setState(() {
      _markers.clear();
      _circles.clear();
      
      for (var zone in _muteZones) {
        if (!zone.isActive) continue;
        
        _markers.add(
          Marker(
            markerId: MarkerId(zone.id),
            position: LatLng(zone.latitude, zone.longitude),
            infoWindow: InfoWindow(
              title: zone.name,
              snippet: 'Radius: ${zone.radius.toStringAsFixed(0)}m',
              onTap: () => _showZoneOptions(zone),
            ),
          ),
        );
        
        _circles.add(
          Circle(
            circleId: CircleId(zone.id),
            center: LatLng(zone.latitude, zone.longitude),
            radius: zone.radius,
            fillColor: _isInMuteZone ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.3),
            strokeColor: _isInMuteZone ? Colors.red : Colors.blue,
            strokeWidth: 2,
          ),
        );
      }
    });
  }

  void _showZoneOptions(MuteZone zone) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Zone'),
              onTap: () {
                Navigator.pop(context);
                _editZone(zone);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Zone', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteZone(zone);
              },
            ),
          ],
        ),
      ),
    );
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

  void _onMapTapped(LatLng position) {
    final nameController = TextEditingController();
    final radiusController = TextEditingController(text: '50');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Mute Zone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Zone Name'),
            ),
            TextField(
              controller: radiusController,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text;
              final radius = double.tryParse(radiusController.text) ?? 50.0;
              if (name.isNotEmpty) {
                final newZone = MuteZone(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  latitude: position.latitude,
                  longitude: position.longitude,
                  radius: radius,
                );
                await LocationService.addMuteZone(newZone);
                await _loadMuteZones();
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : const LatLng(37.7749, -122.4194), // Default to San Francisco
              zoom: 15,
            ),
            markers: _markers,
            circles: _circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              // ULTRA-FAST: If we already have current position, animate to it immediately
              if (_currentPosition != null) {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(
                    LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    16.0,
                  ),
                );
              }
            },
            onTap: _onMapTapped,
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      _isInMuteZone ? Icons.volume_off : Icons.volume_up,
                      color: _isInMuteZone ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _isInMuteZone ? 'Phone is muted' : 'Phone is not muted',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isInMuteZone ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton(
              onPressed: () => _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(
                  _currentPosition != null
                      ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                      : const LatLng(37.7749, -122.4194),
                  16.0,
                ),
              ),
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}