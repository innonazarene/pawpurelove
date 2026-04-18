import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../widgets/common_widgets.dart';
import 'add_edit_log_screen.dart';
import 'care_log_detail_screen.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<CareLog> _healthLogs = [];
  PetProfile? _profile;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _profile = storage.getPetProfile();
      _healthLogs = storage.getCareLogsForCategory('health');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24, right: 24, bottom: 8,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.pastelBlue.withValues(alpha: 0.4),
                    AppColors.background,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health & Wellness',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monitor ${_profile?.name ?? 'your pup'}\'s health journey',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textMuted,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 13),
                tabAlignment: TabAlignment.start,
                tabs: const [
                  Tab(text: 'Weight'),
                  Tab(text: 'Vaccinations'),
                  Tab(text: 'Vet Visits'),
                  Tab(text: 'Symptoms'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWeightTab(),
            _buildLogTab(CareType.vaccination, Icons.vaccines_rounded, AppColors.success),
            _buildLogTab(CareType.vetVisit, Icons.local_hospital_rounded, AppColors.health),
            _buildLogTab(CareType.symptom, Icons.healing_rounded, AppColors.warning),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddHealthLog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Record'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildWeightTab() {
    final weightLogs = _healthLogs
        .where((l) => l.type == CareType.weightLog && l.value != null)
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current weight card
          PawCard(
            borderColor: AppColors.pastelBlue,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.health.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.monitor_weight_rounded, color: AppColors.health, size: 28),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current Weight', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
                    Text(
                      '${_profile?.weight.toStringAsFixed(1) ?? '0.0'} kg',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textBrown,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Weight chart
          if (weightLogs.length >= 2) ...[
            const SectionHeader(title: 'Weight Trend'),
            const SizedBox(height: 12),
            PawCard(
              borderColor: AppColors.pastelBlue.withValues(alpha: 0.5),
              padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
              child: SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true, drawVerticalLine: false, horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true, reservedSize: 40,
                        getTitlesWidget: (value, meta) => Text('${value.toInt()}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                      )),
                      bottomTitles: AxisTitles(sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= weightLogs.length) return const SizedBox();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(DateFormat('MM/dd').format(weightLogs[i].dateTime), style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)),
                          );
                        },
                      )),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: weightLogs.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value!)).toList(),
                        isCurved: true, color: AppColors.health, barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: AppColors.health,
                          ),
                        ),
                        belowBarData: BarAreaData(show: true, color: AppColors.health.withValues(alpha: 0.08)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            PawCard(
              borderColor: AppColors.pastelBlue.withValues(alpha: 0.5),
              child: Column(
                children: [
                  Icon(Icons.show_chart_rounded, size: 48, color: AppColors.health.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text('Log at least 2 weight entries to see a chart', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted), textAlign: TextAlign.center),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // Weight history
          if (weightLogs.isNotEmpty) ...[
            const SectionHeader(title: 'Weight History'),
            const SizedBox(height: 8),
            ...weightLogs.reversed.take(10).map((log) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildHealthLogTile(log, Icons.monitor_weight_rounded, AppColors.health),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildLogTab(CareType type, IconData icon, Color color) {
    final logs = _healthLogs.where((l) => l.type == type).toList();

    if (logs.isEmpty) {
      return EmptyStateWidget(
        icon: icon,
        title: 'No ${type.label} records',
        subtitle: 'Tap the button below to add your first ${type.label.toLowerCase()} record with optional photo and location.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final log = logs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildHealthLogTile(log, icon, color),
        );
      },
    );
  }

  Widget _buildHealthLogTile(CareLog log, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _viewDetail(log),
      child: PawCard(
        borderColor: color.withValues(alpha: 0.15),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Image preview for entries with photos
            if (log.hasImages)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: _buildImagePreview(log.imagePaths[0]),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.title ?? log.type.label,
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        if (log.notes != null)
                          Text(log.notes!, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(DateFormat('MMM d, yyyy').format(log.dateTime),
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                            if (log.hasImages) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.photo_rounded, size: 13, color: AppColors.textMuted.withValues(alpha: 0.6)),
                              const SizedBox(width: 2),
                              Text('${log.imagePaths.length}', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
                            ],
                            if (log.hasLocation) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.location_on_rounded, size: 13, color: AppColors.textMuted.withValues(alpha: 0.6)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Action menu
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textMuted.withValues(alpha: 0.6)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) {
                      if (v == 'view') _viewDetail(log);
                      if (v == 'edit') _editLog(log);
                      if (v == 'delete') _deleteLog(log);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'view', child: Row(children: [
                        Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 8), Text('View Details'),
                      ])),
                      const PopupMenuItem(value: 'edit', child: Row(children: [
                        Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit'),
                      ])),
                      const PopupMenuItem(value: 'delete', child: Row(children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error), SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ])),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String path) {
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover, width: double.infinity);
    }
    return Container(color: AppColors.pastelPink.withValues(alpha: 0.3));
  }

  void _showAddHealthLog() {
    // Determine type based on current tab
    CareType type;
    switch (_tabController.index) {
      case 0: type = CareType.weightLog; break;
      case 1: type = CareType.vaccination; break;
      case 2: type = CareType.vetVisit; break;
      case 3: type = CareType.symptom; break;
      default: type = CareType.weightLog;
    }
    _addLog(type);
  }

  Future<void> _addLog(CareType type) async {
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
    if (result == true) _loadData();
  }

  Future<void> _deleteLog(CareLog log) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Record'),
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

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) => false;
}
