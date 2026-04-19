import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/care_log.dart';
import '../models/pet_schedule.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

class AddEditScheduleScreen extends StatefulWidget {
  final String petId;
  final PetSchedule? editSchedule;

  const AddEditScheduleScreen({super.key, required this.petId, this.editSchedule});

  @override
  State<AddEditScheduleScreen> createState() => _AddEditScheduleScreenState();
}

class _AddEditScheduleScreenState extends State<AddEditScheduleScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  CareType _selectedType = CareType.feeding;
  ScheduleFrequency _selectedFrequency = ScheduleFrequency.daily;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editSchedule != null) {
      _titleController.text = widget.editSchedule!.title;
      _notesController.text = widget.editSchedule!.notes ?? '';
      _selectedType = widget.editSchedule!.type;
      _selectedFrequency = widget.editSchedule!.frequency;
      _selectedDate = widget.editSchedule!.nextScheduledDate;
      _selectedTime = TimeOfDay(
        hour: widget.editSchedule!.nextScheduledDate.hour,
        minute: widget.editSchedule!.nextScheduledDate.minute,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title'), backgroundColor: AppColors.warning),
      );
      return;
    }

    setState(() => _isLoading = true);

    final scheduledDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final schedule = PetSchedule(
      id: widget.editSchedule?.id,
      petId: widget.petId,
      title: _titleController.text.trim(),
      type: _selectedType,
      nextScheduledDate: scheduledDateTime,
      frequency: _selectedFrequency,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    final storage = await StorageService.getInstance();
    
    if (widget.editSchedule != null) {
      await storage.updateSchedule(schedule);
      await NotificationService().cancelNotification(schedule.id);
    } else {
      await storage.saveSchedule(schedule);
    }

    // Schedule new notification
    final profile = storage.getPetById(widget.petId);
    if (schedule.isActive) {
      await NotificationService().schedulePetNotification(schedule, profile?.name ?? 'Your pet');
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textDark,
            ),
            timePickerTheme: TimePickerThemeData(
              hourMinuteTextStyle: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
              dialTextStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              dayPeriodTextStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              helpTextStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                textStyle: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editSchedule == null ? 'New Schedule' : 'Edit Schedule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Title'),
            const SizedBox(height: 8),
            _buildTextField(_titleController, 'e.g., Morning Walk, Heartworm Pill...', Icons.title_rounded),
            
            const SizedBox(height: 24),
            _buildLabel('Category'),
            const SizedBox(height: 8),
            _buildTypeDropdown(),

            const SizedBox(height: 24),
            _buildLabel('Frequency'),
            const SizedBox(height: 8),
            _buildFrequencyDropdown(),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Start Date'),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(
                        DateFormat('MMM d, yyyy').format(_selectedDate),
                        Icons.calendar_today_rounded,
                        _pickDate,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Time'),
                      const SizedBox(height: 8),
                      _buildDateTimePicker(
                        _selectedTime.format(context),
                        Icons.access_time_rounded,
                        _pickTime,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildLabel('Notes (Optional)'),
            const SizedBox(height: 8),
            _buildTextField(_notesController, 'Any additional details...', Icons.notes_rounded, maxLines: 3),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSchedule,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        widget.editSchedule == null ? 'Save Schedule' : 'Update Schedule',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDark),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.primary.withValues(alpha: 0.6)) : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(maxLines == 1 ? 16 : 20),
        ),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<CareType>(
          value: _selectedType,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, color: AppColors.primary.withValues(alpha: 0.6)),
          items: CareType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getIconForType(type), size: 20, color: _getColorForType(type)),
                  const SizedBox(width: 12),
                  Text(type.label, style: GoogleFonts.inter(fontSize: 15, color: AppColors.textDark)),
                ],
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedType = val);
          },
        ),
      ),
    );
  }

  Widget _buildFrequencyDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ScheduleFrequency>(
          value: _selectedFrequency,
          isExpanded: true,
          icon: Icon(Icons.expand_more_rounded, color: AppColors.primary.withValues(alpha: 0.6)),
          items: ScheduleFrequency.values.map((freq) {
            return DropdownMenuItem(
              value: freq,
              child: Text(freq.label, style: GoogleFonts.inter(fontSize: 15, color: AppColors.textDark)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedFrequency = val);
          },
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary.withValues(alpha: 0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(fontSize: 15, color: AppColors.textDark),
              ),
            ),
          ],
        ),
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
}
