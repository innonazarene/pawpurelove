import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/care_log.dart';
import '../models/pet_schedule.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'add_edit_schedule_screen.dart';

class SchedulesScreen extends StatefulWidget {
  final String petId;

  const SchedulesScreen({super.key, required this.petId});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  List<PetSchedule> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Ask for permission when screen is opened
    NotificationService().requestPermissions();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _schedules = storage.getAllSchedules().where((s) => s.petId == widget.petId).toList()
        ..sort((a, b) => a.nextScheduledDate.compareTo(b.nextScheduledDate));
      _isLoading = false;
    });
  }

  Future<void> _toggleSchedule(PetSchedule schedule, bool isActive) async {
    final updated = schedule.copyWith(isActive: isActive);
    final storage = await StorageService.getInstance();
    await storage.updateSchedule(updated);
    
    if (isActive) {
      final profile = storage.getPetById(widget.petId);
      await NotificationService().schedulePetNotification(updated, profile?.name ?? 'your pet');
    } else {
      await NotificationService().cancelNotification(updated.id);
    }
    
    _loadSchedules();
  }

  Future<void> _deleteSchedule(String id) async {
    final storage = await StorageService.getInstance();
    await storage.deleteSchedule(id);
    await NotificationService().cancelNotification(id);
    _loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedules & Reminders'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _schedules.isEmpty
              ? _buildEmptyState()
              : _buildSchedulesList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditScheduleScreen(petId: widget.petId),
            ),
          );
          if (result == true) _loadSchedules();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text('Add Reminder', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.pastelBlue.withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.schedule_rounded, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          Text(
            'No schedules set',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textBrown),
          ),
          const SizedBox(height: 8),
          Text(
            'Add routines, vaccinations, and other reminders.',
            style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final timeFormat = DateFormat.jm().format(schedule.nextScheduledDate);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PawCard(
            borderColor: schedule.isActive ? AppColors.primary.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: schedule.isActive ? _getColorForType(schedule.type).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _getIconForType(schedule.type),
                    color: schedule.isActive ? _getColorForType(schedule.type) : Colors.grey,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        schedule.title,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: schedule.isActive ? AppColors.textDark : Colors.grey,
                          decoration: schedule.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '$timeFormat • ${schedule.frequency.label}',
                            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: schedule.isActive,
                  onChanged: (val) => _toggleSchedule(schedule, val),
                  activeColor: AppColors.primary,
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.error),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.error)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) async {
                    if (value == 'edit') {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditScheduleScreen(
                            petId: widget.petId,
                            editSchedule: schedule,
                          ),
                        ),
                      );
                      if (result == true) _loadSchedules();
                    } else if (value == 'delete') {
                      _deleteSchedule(schedule.id);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
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
      case CareType.note: return Icons.note_rounded;
    }
  }

  Color _getColorForType(CareType type) {
    switch (type.category) {
      case 'daily': return AppColors.warning;
      case 'health': return AppColors.health;
      case 'memory': return AppColors.memory;
      default: return AppColors.primary;
    }
  }
}
