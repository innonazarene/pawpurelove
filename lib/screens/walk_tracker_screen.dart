import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../theme/app_theme.dart';
import 'dart:io';
import '../models/pet_profile.dart';

class WalkTrackerScreen extends StatefulWidget {
  final String petId;
  const WalkTrackerScreen({super.key, required this.petId});

  @override
  State<WalkTrackerScreen> createState() => _WalkTrackerScreenState();
}

class _WalkTrackerScreenState extends State<WalkTrackerScreen> {
  final MapController _mapController = MapController();
  
  bool _isTracking = false;
  bool _hasStarted = false;
  bool _isLoadingLocation = true;
  
  List<PetProfile> _allPets = [];
  Set<String> _selectedPetIds = {};
  
  StreamSubscription<Position>? _positionStream;
  Timer? _timer;
  
  // Stats
  int _secondsElapsed = 0;
  double _distanceMeters = 0;
  
  // Path
  List<LatLng> _routePoints = [];
  LatLng? _currentPosition;
  
  @override
  void initState() {
    super.initState();
    _initLocation();
  }
  
  Future<void> _initLocation() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _allPets = storage.getAllPetProfiles();
      _selectedPetIds.add(widget.petId);
    });
    // Check permission
    final startLoc = await ImageLocationService.getCurrentLocation();
    if (startLoc != null) {
      if (mounted) {
        setState(() {
          _currentPosition = LatLng(startLoc.latitude, startLoc.longitude);
          _isLoadingLocation = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('GPS permission is required to track walks.')),
        );
      }
    }
  }

  void _startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable GPS services')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    setState(() {
      _isTracking = true;
      _hasStarted = true;
      if (_currentPosition != null && _routePoints.isEmpty) {
        _routePoints.add(_currentPosition!);
      }
    });

    // Start Timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });

    // Android settings for foreground active stream
    late LocationSettings locationSettings;
    locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 3, // Update every 3 meters moved
    );

    _positionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (!mounted) return;
      
      final newPoint = LatLng(position.latitude, position.longitude);
      
      setState(() {
        if (_routePoints.isNotEmpty) {
           _distanceMeters += Geolocator.distanceBetween(
             _routePoints.last.latitude, _routePoints.last.longitude,
             newPoint.latitude, newPoint.longitude,
           );
        }
        _currentPosition = newPoint;
        _routePoints.add(newPoint);
        _mapController.move(newPoint, _mapController.camera.zoom); // follow user
      });
    });
  }

  void _pauseTracking() {
    setState(() {
      _isTracking = false;
    });
    _timer?.cancel();
    _positionStream?.pause();
  }

  void _resumeTracking() {
    setState(() {
      _isTracking = true;
    });
    // Start Timer again
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
    _positionStream?.resume();
  }

  Future<void> _endWalkAndSave() async {
    _pauseTracking();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Finish Walk?'),
        content: Text('Distance: ${(_distanceMeters / 1000).toStringAsFixed(2)} km\nDuration: ${_formatDuration(_secondsElapsed)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Walking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save Log'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      // Resume if cancelled
      _resumeTracking();
      return;
    }

    if (_routePoints.isEmpty) {
      Navigator.pop(context);
      return; // Nothing to save
    }

    // Prepare path array for CareLog
    final pathArray = _routePoints.map((latlng) => {
      'lat': latlng.latitude,
      'lng': latlng.longitude,
    }).toList();

    // Reverse geocode final position roughly
    String? locationName;
    try {
      final placemarks = await placemarkFromCoordinates(
        _routePoints.last.latitude,
        _routePoints.last.longitude,
      );
      if (placemarks.isNotEmpty) {
        locationName = '${placemarks.first.name ?? ''}, ${placemarks.first.locality ?? ''}'.trim();
        if (locationName.startsWith(',')) locationName = locationName.substring(1).trim();
      }
    } catch (_) {}

    final storage = await StorageService.getInstance();
    
    for (String id in _selectedPetIds) {
      final newLog = CareLog(
        id: DateTime.now().millisecondsSinceEpoch.toString() + id,
        petId: id,
        type: CareType.walk,
        dateTime: DateTime.now(),
        title: 'GPS Walk Tracked',
        notes: 'Walked ${(_distanceMeters / 1000).toStringAsFixed(2)} km in ${_formatDuration(_secondsElapsed)}.',
        latitude: _routePoints.last.latitude,
        longitude: _routePoints.last.longitude,
        locationName: locationName,
        routeCoordinates: pathArray,
      );

      await storage.saveCareLog(newLog);
    }
    
    if (mounted) {
      Navigator.pop(context); // Go back after saving
    }
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    int hours = minutes ~/ 60;
    minutes = minutes % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _isLoadingLocation
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition ?? const LatLng(0, 0),
                    initialZoom: 18.0,
                    maxZoom: 22.0,
                    keepAlive: true,
                  ),
                  children: [
                    TileLayer(
                      key: const ValueKey('osm_tracker'),
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.innonazarene.pawpurelove',
                      maxNativeZoom: 19,
                    ),
                    
                    // The path drawn
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 6.0,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          borderStrokeWidth: 2.0,
                          borderColor: Colors.white,
                          strokeJoin: StrokeJoin.round,
                          strokeCap: StrokeCap.round,
                        ),
                      ],
                    ),

                    // Current location marker
                    if (_currentPosition != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 60,
                            height: 60,
                            point: _currentPosition!,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Pulsing background effect
                                if (_isTracking)
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary.withValues(alpha: 0.2),
                                    ),
                                  ),
                                // Pin
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                  ],
                ),

                // Floating Stats Panel
                if (_hasStarted)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 70,
                    left: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text('Duration', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                _formatDuration(_secondsElapsed),
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                          Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
                          Column(
                            children: [
                              Text('Distance', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                '${(_distanceMeters / 1000).toStringAsFixed(2)} km',
                                style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                if (!_hasStarted && _allPets.length > 1)
                  Positioned(
                    right: 16,
                    top: MediaQuery.of(context).padding.top + 160,
                    bottom: 120, // leave space for start button
                    child: Container(
                      width: 65,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ListView.builder(
                        itemCount: _allPets.length,
                        itemBuilder: (context, index) {
                          final pet = _allPets[index];
                          final isSelected = _selectedPetIds.contains(pet.id);
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected && _selectedPetIds.length > 1) {
                                  _selectedPetIds.remove(pet.id);
                                } else {
                                  _selectedPetIds.add(pet.id);
                                }
                              });
                            },
                            child: Container(
                              width: 50,
                              height: 50,
                              margin: const EdgeInsets.only(bottom: 12, left: 8, right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
                              ),
                              child: ClipOval(
                                child: pet.photoPath != null && File(pet.photoPath!).existsSync()
                                    ? Image.file(File(pet.photoPath!), fit: BoxFit.cover)
                                    : Container(color: Colors.white, child: const Icon(Icons.pets, color: AppColors.primary, size: 20)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                // Control Buttons Bottom
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_hasStarted) ...[

                        GestureDetector(
                          onTap: _startTracking,
                          child: Container(
                            width: 200,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                                const SizedBox(width: 8),
                                Text('Start Walk', style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                          ),
                        )
                      ] else ...[
                        // Pause / Resume
                        GestureDetector(
                          onTap: _isTracking ? _pauseTracking : _resumeTracking,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)],
                            ),
                            child: Icon(
                              _isTracking ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: AppColors.textDark,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Stop & Save
                        GestureDetector(
                          onTap: _endWalkAndSave,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 10)],
                            ),
                            child: const Icon(Icons.stop_rounded, color: Colors.white, size: 32),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
