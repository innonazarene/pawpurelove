import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'add_edit_log_screen.dart';
import 'care_log_detail_screen.dart';

class DailyCareScreen extends StatefulWidget {
  const DailyCareScreen({super.key});

  @override
  State<DailyCareScreen> createState() => _DailyCareScreenState();
}

class _DailyCareScreenState extends State<DailyCareScreen> {
  List<CareLog> _dailyLogs = [];
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
      _dailyLogs = storage.getCareLogsForCategory('daily');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24, right: 24, bottom: 16,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
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
                    'Daily Care',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textBrown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Keep ${_profile?.name ?? 'your pup'} happy & healthy',
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textLight),
                  ),
                ],
              ),
            ),
          ),

          // Care Categories
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: [
                  _buildCareCard(
                    icon: Icons.restaurant_rounded,
                    title: 'Feeding',
                    subtitle: 'Log meals & treats',
                    color: AppColors.dailyCare,
                    bgColor: const Color(0xFFFFF3E8),
                    type: CareType.feeding,
                  ),
                  _buildCareCard(
                    icon: Icons.water_drop_rounded,
                    title: 'Water',
                    subtitle: 'Track intake',
                    color: AppColors.info,
                    bgColor: const Color(0xFFE8F4FD),
                    type: CareType.water,
                  ),
                  _buildCareCard(
                    icon: Icons.directions_walk_rounded,
                    title: 'Walks',
                    subtitle: 'Exercise & strolls',
                    color: AppColors.success,
                    bgColor: const Color(0xFFE8F5E9),
                    type: CareType.walk,
                  ),
                  _buildCareCard(
                    icon: Icons.shower_rounded,
                    title: 'Grooming',
                    subtitle: 'Bath & brushing',
                    color: AppColors.memory,
                    bgColor: const Color(0xFFF3E8FD),
                    type: CareType.grooming,
                  ),
                ],
              ),
            ),
          ),

          // Recent Logs
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: SectionHeader(
                title: 'Recent Activity',
                actionText: '${_dailyLogs.length} total',
              ),
            ),
          ),

          if (_dailyLogs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: EmptyStateWidget(
                  icon: Icons.restaurant_outlined,
                  title: 'No daily care logs yet',
                  subtitle: 'Tap a category above to start logging your dog\'s daily care routine.',
                ),
              ),
            ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final log = _dailyLogs[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: _buildDailyLogTile(log),
                );
              },
              childCount: _dailyLogs.length > 30 ? 30 : _dailyLogs.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildCareCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required CareType type,
  }) {
    return GestureDetector(
      onTap: () => _addLog(type),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyLogTile(CareLog log) {
    return GestureDetector(
      onTap: () => _viewDetail(log),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getColor(log.type).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_getIcon(log.type), color: _getColor(log.type), size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    log.title ?? log.type.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    log.notes ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Time + menu
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(log.dateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz_rounded, size: 18, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (v) {
                    if (v == 'view') _viewDetail(log);
                    if (v == 'edit') _editLog(log);
                    if (v == 'delete') _deleteLog(log);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'view', child: Row(children: [
                      Icon(Icons.visibility_rounded, size: 18), SizedBox(width: 8), Text('View'),
                    ])),
                    const PopupMenuItem(value: 'edit', child: Row(children: [
                      Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit'),
                    ])),
                    const PopupMenuItem(value: 'delete', child: Row(children: [
                      Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                      SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error)),
                    ])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
        title: const Text('Delete Entry'),
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
      await storage.deleteCareLog(log.id);
      _loadData();
    }
  }

  IconData _getIcon(CareType type) {
    switch (type) {
      case CareType.feeding: return Icons.restaurant_rounded;
      case CareType.water: return Icons.water_drop_rounded;
      case CareType.walk: return Icons.directions_walk_rounded;
      case CareType.grooming: return Icons.shower_rounded;
      default: return Icons.pets_rounded;
    }
  }

  Color _getColor(CareType type) {
    switch (type) {
      case CareType.feeding: return AppColors.dailyCare;
      case CareType.water: return AppColors.info;
      case CareType.walk: return AppColors.success;
      case CareType.grooming: return AppColors.memory;
      default: return AppColors.primary;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(dt);
  }
}
