// lib/main.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'screens/map_screen.dart';
import 'screens/settings_screen.dart';
import 'services/location_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Optimize for maximum performance
  await _requestPermissions();
  await LocationService.initialize();
  
  runApp(const MyApp());
}

Future<void> _requestPermissions() async {
  await [
    Permission.location,
    Permission.locationAlways,
    Permission.notification,
  ].request();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mute Zones',
      debugShowCheckedModeBanner: false, // Remove debug banner for speed
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Optimize for maximum performance
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  bool _isLocationTracking = false;

  final List<Widget> _screens = [
    const MapScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkLocationTrackingStatus();
  }

  void _checkLocationTrackingStatus() {
    setState(() {
      _isLocationTracking = LocationService.isServiceRunning;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mute Zones'),
        actions: [
          Switch(
            value: _isLocationTracking,
            onChanged: (value) async {
              try {
                if (value) {
                  await LocationService.startLocationTracking();
                } else {
                  await LocationService.stopLocationTracking();
                }
                _checkLocationTrackingStatus();
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
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}