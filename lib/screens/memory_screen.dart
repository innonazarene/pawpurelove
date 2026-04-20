import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../widgets/common_widgets.dart';
import 'add_edit_log_screen.dart';
import 'care_log_detail_screen.dart';
import 'activity_map_screen.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  List<CareLog> _memoryLogs = [];
  PetProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _profile = storage.getPetProfile();
      _memoryLogs = storage.getCareLogsForCategory('memory');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24, right: 24, bottom: 16,
              ),
              decoration: BoxDecoration(
                color: ThemeNotifier().isDarkMode ? AppColors.background : null,
                gradient: ThemeNotifier().isDarkMode ? null : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.pastelPink.withValues(alpha: 0.4),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memory & Joy',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cherish every moment with ${_profile?.name ?? 'your pup'}',
                    style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),

          // Quick add cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildQuickCard(
                      icon: Icons.emoji_events_rounded,
                      title: 'Milestone',
                      subtitle: 'Special achievement',
                      color: AppColors.warning,
                      bgColor: const Color(0xFFFFF8E1),
                      onTap: () => _addMemory(CareType.milestone),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickCard(
                      icon: Icons.favorite_rounded,
                      title: 'Love Note',
                      subtitle: 'With photo & map',
                      color: AppColors.error,
                      bgColor: const Color(0xFFFCE4EC),
                      onTap: () => _addMemory(CareType.note),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: PawCard(
                borderColor: AppColors.pastelPurple.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat(
                      _memoryLogs.where((l) => l.type == CareType.milestone).length.toString(),
                      'Milestones',
                      Icons.emoji_events_rounded,
                      AppColors.warning,
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.1)),
                    _buildStat(
                      _memoryLogs.where((l) => l.type == CareType.note).length.toString(),
                      'Love Notes',
                      Icons.favorite_rounded,
                      AppColors.error,
                    ),
                    Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.1)),
                    _buildStat(
                      _memoryLogs.where((l) => l.hasImages).length.toString(),
                      'With Photos',
                      Icons.photo_rounded,
                      AppColors.dailyCare,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Memories list
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: const SectionHeader(title: 'All Memories'),
            ),
          ),

          if (_memoryLogs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: EmptyStateWidget(
                  icon: Icons.auto_awesome_rounded,
                  title: 'No memories yet',
                  subtitle: 'Start creating beautiful memories with photos and locations!',
                ),
              ),
            ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final log = _memoryLogs[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: _buildMemoryCard(log),
                );
              },
              childCount: _memoryLogs.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'memory_fab',
          onPressed: () => _addMemory(CareType.note),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Memory'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: ThemeNotifier().isDarkMode ? AppColors.surfaceCard : bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 14),
            Text(title, style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
            Text(subtitle, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textBrown),
        ),
        Text(label, style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildMemoryCard(CareLog log) {
    final isMilestone = log.type == CareType.milestone;
    final color = isMilestone ? AppColors.warning : AppColors.error;

    return GestureDetector(
      onTap: () => _viewDetail(log),
      child: PawCard(
        borderColor: (isMilestone ? AppColors.pastelYellow : AppColors.pastelPink).withValues(alpha: 0.6),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image preview
            if (log.hasImages)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: log.imagePaths.length == 1
                      ? _buildImage(log.imagePaths[0])
                      : Row(
                          children: [
                            Expanded(flex: 2, child: _buildImage(log.imagePaths[0])),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Column(
                                children: [
                                  Expanded(child: _buildImage(log.imagePaths.length > 1 ? log.imagePaths[1] : log.imagePaths[0])),
                                  if (log.imagePaths.length > 2) ...[
                                    const SizedBox(height: 2),
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildImage(log.imagePaths[2]),
                                          if (log.imagePaths.length > 3)
                                            Container(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              child: Center(
                                                child: Text(
                                                  '+${log.imagePaths.length - 3}',
                                                  style: GoogleFonts.nunito(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isMilestone ? Icons.emoji_events_rounded : Icons.favorite_rounded,
                          color: color, size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.title ?? (isMilestone ? 'Milestone' : 'Love Note'),
                              style: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
                            ),
                            Text(
                              DateFormat('MMMM d, yyyy').format(log.dateTime),
                              style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      // Action buttons
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textBrown.withValues(alpha: 0.6)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (v) {
                          if (v == 'edit') _editLog(log);
                          if (v == 'delete') _deleteLog(log);
                          if (v == 'view') _viewDetail(log);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'view', child: Row(children: [Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 8), Text('View')])),
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                        ],
                      ),
                    ],
                  ),
                  if (log.notes != null && log.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      log.notes!,
                      style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight, height: 1.5),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Location & image badges
                  if (log.hasLocation || log.hasImages) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (log.hasImages)
                          _buildBadge(Icons.photo_rounded, '${log.imagePaths.length} photo${log.imagePaths.length > 1 ? 's' : ''}', AppColors.dailyCare),
                        if (log.hasImages && log.hasLocation) const SizedBox(width: 8),
                        if (log.hasLocation)
                          GestureDetector(
                            onTap: () {
                              if (_profile != null && log.latitude != null && log.longitude != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ActivityMapScreen(
                                      petId: _profile!.id,
                                      initialCoordinate: LatLng(log.latitude!, log.longitude!),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: _buildBadge(Icons.location_on_rounded, log.locationName ?? 'Map', AppColors.dailyCare),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _buildImage(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    }
    return Container(color: AppColors.pastelPink.withValues(alpha: 0.3));
  }

  Future<void> _addMemory(CareType type) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditLogScreen(initialType: type)),
    );
    if (result == true) _loadData();
  }

  Future<void> _editLog(CareLog log) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditLogScreen(existingLog: log)),
    );
    if (result == true) _loadData();
  }

  Future<void> _viewDetail(CareLog log) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CareLogDetailScreen(logId: log.id)),
    );
    if (result == true) _loadData(); // true means deleted
  }

  Future<void> _deleteLog(CareLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Memory'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
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
      for (final path in log.imagePaths) {
        await ImageLocationService.deleteImage(path);
      }
      await storage.deleteCareLog(log.id);
      _loadData();
    }
  }
}
