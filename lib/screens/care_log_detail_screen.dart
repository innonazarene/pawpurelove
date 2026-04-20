import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import 'add_edit_log_screen.dart';
import 'activity_map_screen.dart';
import 'package:latlong2/latlong.dart';

class CareLogDetailScreen extends StatefulWidget {
  final String logId;

  const CareLogDetailScreen({super.key, required this.logId});

  @override
  State<CareLogDetailScreen> createState() => _CareLogDetailScreenState();
}

class _CareLogDetailScreenState extends State<CareLogDetailScreen> {
  CareLog? _log;
  bool _wasEdited = false;

  @override
  void initState() {
    super.initState();
    _loadLog();
  }

  Future<void> _loadLog() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _log = storage.getCareLogById(widget.logId);
    });
  }

  Future<void> _deleteLog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Entry'),
        content: const Text('Are you sure you want to delete this entry? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await StorageService.getInstance();
      // Delete associated images
      if (_log != null) {
        for (final path in _log!.imagePaths) {
          await ImageLocationService.deleteImage(path);
        }
      }
      await storage.deleteCareLog(widget.logId);
      if (!mounted) return;
      Navigator.pop(context, true); // true = deleted
    }
  }

  Future<void> _editLog() async {
    if (_log == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditLogScreen(existingLog: _log!),
      ),
    );
    if (result == true) {
      _wasEdited = true;
      _loadLog();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_log == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final log = _log!;
    final color = _getColorForType(log.type);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          Navigator.pop(context, _wasEdited);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: log.hasImages ? 300 : 0,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              onPressed: () => Navigator.pop(context, _wasEdited),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
            actions: [
              IconButton(
                onPressed: _editLog,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary),
                ),
              ),
              IconButton(
                onPressed: _deleteLog,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                ),
              ),
            ],
            flexibleSpace: log.hasImages
                ? FlexibleSpaceBar(
                    background: _buildImageGallery(log.imagePaths),
                  )
                : null,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type badge & date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getIconForType(log.type), size: 16, color: color),
                            const SizedBox(width: 6),
                            Text(
                              log.type.label,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM d, yyyy').format(log.dateTime),
                        style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    log.title ?? log.type.label,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(log.dateTime),
                    style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textLight),
                  ),

                  // Value (for weight)
                  if (log.value != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.monitor_weight_rounded, color: color, size: 28),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${log.value!.toStringAsFixed(2)} ${log.unit ?? ''}',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textBrown,
                                ),
                              ),
                              Text(
                                'Recorded value',
                                style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Notes
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Notes',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                      ),
                      child: Text(
                        log.notes!,
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          color: AppColors.textDark,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],

                  // Location
                  if (log.hasLocation) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Location',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        if (log.latitude != null && log.longitude != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityMapScreen(
                                petId: log.petId,
                                initialCoordinate: LatLng(log.latitude!, log.longitude!),
                              ),
                            ),
                          );
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.pastelBlue),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.dailyCare.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.location_on_rounded, color: AppColors.dailyCare),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    log.locationName ?? 'Saved Location',
                                    style: GoogleFonts.nunito(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${log.latitude!.toStringAsFixed(5)}, ${log.longitude!.toStringAsFixed(5)}',
                                    style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.dailyCare.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.map_rounded, size: 16, color: AppColors.dailyCare),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Map',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.dailyCare,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Images section (if no images in app bar)
                  if (!log.hasImages) ...[
                    const SizedBox(height: 20),
                    Text(
                      'No photos attached',
                      style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _editLog,
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Edit'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _deleteLog,
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          label: const Text('Delete', style: TextStyle(color: AppColors.error)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.error),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> paths) {
    if (paths.length == 1) {
      return _buildImage(paths[0]);
    }

    return PageView.builder(
      itemCount: paths.length,
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(paths[index]),
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}/${paths.length}',
                  style: GoogleFonts.nunito(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImage(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.pastelPink.withValues(alpha: 0.3),
      child: Center(
        child: Icon(Icons.image_not_supported_rounded, size: 48, color: AppColors.textMuted),
      ),
    );
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
      case CareType.note: return Icons.favorite_rounded;
    }
  }

  Color _getColorForType(CareType type) {
    switch (type.category) {
      case 'daily': return AppColors.dailyCare;
      case 'health': return AppColors.dailyCare;
      case 'memory': return AppColors.dailyCare;
      default: return AppColors.primary;
    }
  }
}
