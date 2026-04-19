import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class LocationCluster {
  final double lat;
  final double lng;
  final List<CareLog> logs;

  LocationCluster(this.lat, this.lng, this.logs);

  LatLng get coordinate => LatLng(lat, lng);
  int get count => logs.length;
}

class ActivityMapScreen extends StatefulWidget {
  final String petId;
  final LatLng? initialCoordinate;
  const ActivityMapScreen({super.key, required this.petId, this.initialCoordinate});

  @override
  State<ActivityMapScreen> createState() => _ActivityMapScreenState();
}

class _ActivityMapScreenState extends State<ActivityMapScreen> {
  final MapController _mapController = MapController();
  List<LocationCluster> _clusters = [];
  bool _isSatellite = false;
  LatLng? _initialCenter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    final storage = await StorageService.getInstance();
    final allLogs = storage.getCareLogsByPet(widget.petId);

    final Map<String, LocationCluster> grouped = {};

    for (final log in allLogs) {
      if (log.latitude == null || log.longitude == null) continue;

      // Group roughly around the same ~11 meters radius by truncating decimal places
      final cid = '${log.latitude!.toStringAsFixed(4)}_${log.longitude!.toStringAsFixed(4)}';

      if (!grouped.containsKey(cid)) {
        grouped[cid] = LocationCluster(log.latitude!, log.longitude!, [log]);
      } else {
        grouped[cid]!.logs.add(log);
      }
    }

    setState(() {
      _clusters = grouped.values.toList();
      if (_clusters.isNotEmpty) {
        // Find rough center of all points or just use the first point
        _initialCenter = widget.initialCoordinate ?? _clusters.first.coordinate;
      } else {
        // Default coordinate if no logs exist (e.g., global center)
        _initialCenter = widget.initialCoordinate ?? const LatLng(0, 0);
      }
      _isLoading = false;
    });
  }

  IconData _getIconForType(CareType type) {
    switch (type) {
      case CareType.feeding: return Icons.restaurant_rounded;
      case CareType.water: return Icons.water_drop_rounded;
      case CareType.walk: return Icons.directions_walk_rounded;
      case CareType.grooming: return Icons.shower_rounded;
      case CareType.medication: return Icons.medication_rounded;
      case CareType.vaccination: return Icons.vaccines_rounded;
      case CareType.vetVisit: return Icons.local_hospital_rounded;
      case CareType.weightLog: return Icons.monitor_weight_rounded;
      case CareType.symptom: return Icons.healing_rounded;
      case CareType.milestone: return Icons.emoji_events_rounded;
      case CareType.note: return Icons.note_rounded;
    }
  }

  Color _getColorForType(CareType type) {
    switch (type.category) {
      case 'daily': return AppColors.dailyCare;
      case 'health': return AppColors.health;
      case 'memory': return AppColors.memory;
      default: return AppColors.primary;
    }
  }

  void _showClusterDetails(LocationCluster cluster) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Activity',
              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textBrown),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: cluster.logs.length,
                itemBuilder: (context, index) {
                  final log = cluster.logs[index];
                  final color = _getColorForType(log.type);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(_getIconForType(log.type), color: color, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(log.title ?? log.type.label, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
                              if (log.locationName != null) ...[
                                const SizedBox(height: 2),
                                Text(log.locationName!, style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textLight)),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialCenter ?? const LatLng(0, 0),
                    initialZoom: 16.5,
                    maxZoom: 22.0,
                  ),
                  children: [
                    TileLayer(
                      key: ValueKey(_isSatellite),
                      urlTemplate: _isSatellite
                          ? 'https://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.innonazarene.pawpurelove',
                      maxNativeZoom: _isSatellite ? 18 : 19, 
                    ),
                    PolylineLayer(
                      polylines: _clusters.expand((c) => c.logs)
                          .where((log) => log.routeCoordinates != null && log.routeCoordinates!.isNotEmpty)
                          .map((log) {
                            return Polyline(
                              points: log.routeCoordinates!.map((coord) => LatLng(coord['lat']!, coord['lng']!)).toList(),
                              strokeWidth: 5.0,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              borderStrokeWidth: 1.5,
                              borderColor: Colors.white,
                              strokeJoin: StrokeJoin.round,
                              strokeCap: StrokeCap.round,
                            );
                          }).toList(),
                    ),
                    MarkerLayer(
                      markers: _clusters.map((cluster) {
                        // Inherit color from the most recent log in cluster
                        final primeColor = _getColorForType(cluster.logs.last.type);
                        final primeIcon = _getIconForType(cluster.logs.last.type);

                        return Marker(
                          width: 50.0,
                          height: 50.0,
                          point: cluster.coordinate,
                          child: GestureDetector(
                            onTap: () => _showClusterDetails(cluster),
                            child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Marker Pin
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: primeColor, width: 2.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(primeIcon, color: primeColor, size: 20),
                                ),

                                // Overlapping Counter Badge (2x, 3x)
                                if (cluster.count > 1)
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.error,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.white, width: 1.5),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                                        ],
                                      ),
                                      child: Text(
                                        '${cluster.count}x',
                                        style: GoogleFonts.nunito(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
                
                // Map style toggle floating card
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        _isSatellite ? Icons.map_rounded : Icons.satellite_alt_rounded,
                        color: AppColors.primary,
                      ),
                      tooltip: _isSatellite ? 'Switch to Normal Map' : 'Switch to Satellite',
                      onPressed: () {
                        setState(() {
                          _isSatellite = !_isSatellite;
                        });
                      },
                    ),
                  ),
                ),
                
                // Centering control
                Positioned(
                  bottom: 32,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'mapCenterBtn',
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    child: const Icon(Icons.my_location_rounded),
                    onPressed: () {
                      if (_initialCenter != null) {
                        _mapController.move(_initialCenter!, 16.5);
                      }
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
