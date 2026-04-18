import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../widgets/common_widgets.dart';

class AddEditLogScreen extends StatefulWidget {
  final CareLog? existingLog;
  final CareType? initialType;
  final String? petId;

  const AddEditLogScreen({
    super.key,
    this.existingLog,
    this.initialType,
    this.petId,
  });

  bool get isEditing => existingLog != null;

  @override
  State<AddEditLogScreen> createState() => _AddEditLogScreenState();
}

class _AddEditLogScreenState extends State<AddEditLogScreen> {
  late CareType _selectedType;
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _valueController = TextEditingController();
  List<String> _imagePaths = [];
  double? _latitude;
  double? _longitude;
  String? _locationName;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingLog != null) {
      final log = widget.existingLog!;
      _selectedType = log.type;
      _titleController.text = log.title ?? '';
      _notesController.text = log.notes ?? '';
      if (log.value != null) _valueController.text = log.value!.toStringAsFixed(1);
      _imagePaths = List.from(log.imagePaths);
      _latitude = log.latitude;
      _longitude = log.longitude;
      _locationName = log.locationName;
    } else {
      _selectedType = widget.initialType ?? CareType.note;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final paths = await ImageLocationService.pickMultipleImages(context);
    if (paths.isNotEmpty) {
      setState(() => _imagePaths.addAll(paths));
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    final loc = await ImageLocationService.getCurrentLocation();
    if (loc != null) {
      setState(() {
        _latitude = loc.latitude;
        _longitude = loc.longitude;
        _locationName = loc.name;
      });
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not get location. Please check permissions.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    setState(() => _isLoadingLocation = false);
  }

  void _removeImage(int index) {
    setState(() => _imagePaths.removeAt(index));
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _locationName = null;
    });
  }

  Future<void> _save() async {
    final storage = await StorageService.getInstance();

    String? petId = widget.petId;
    if (petId == null) {
      final profile = storage.getPetProfile();
      if (profile == null) return;
      petId = profile.id;
    }

    // Validate
    if (_selectedType == CareType.weightLog) {
      final val = double.tryParse(_valueController.text);
      if (val == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please enter a valid weight'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      // Also update profile weight
      final profile = storage.getPetProfile();
      if (profile != null) {
        profile.weight = val;
        await storage.savePetProfile(profile);
      }
    }

    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : (_selectedType == CareType.weightLog
            ? '${_valueController.text} kg'
            : _selectedType.label);

    if (widget.isEditing) {
      final updated = widget.existingLog!.copyWith(
        title: title,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        value: double.tryParse(_valueController.text),
        unit: _selectedType == CareType.weightLog ? 'kg' : null,
        imagePaths: _imagePaths,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationName,
      );
      await storage.updateCareLog(updated);
    } else {
      final log = CareLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: petId,
        type: _selectedType,
        dateTime: DateTime.now(),
        title: title,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        value: double.tryParse(_valueController.text),
        unit: _selectedType == CareType.weightLog ? 'kg' : null,
        imagePaths: _imagePaths,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationName,
      );
      await storage.saveCareLog(log);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(widget.isEditing ? 'Entry updated!' : 'Entry saved!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? 'Edit Entry' : 'Add Entry',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textBrown,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector (only for new entries)
            if (!widget.isEditing) ...[
              _buildLabel('Type'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CareType.values.map((t) {
                  final isSelected = _selectedType == t;
                  return ChoiceChip(
                    label: Text(t.label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedType = t),
                    selectedColor: AppColors.primary,
                    labelStyle: GoogleFonts.inter(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ] else ...[
              // Show type badge for edit
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _selectedType.label,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Value field (for weight)
            if (_selectedType == CareType.weightLog) ...[
              _buildLabel('Weight (kg)'),
              TextField(
                controller: _valueController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'Enter weight in kg',
                  prefixIcon: Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Title
            _buildLabel('Title'),
            TextField(
              controller: _titleController,
              style: GoogleFonts.inter(fontSize: 16, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Enter a title',
                prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 20),

            // Notes
            _buildLabel('Notes'),
            TextField(
              controller: _notesController,
              maxLines: 4,
              style: GoogleFonts.inter(fontSize: 15),
              decoration: const InputDecoration(hintText: 'Add notes...'),
            ),
            const SizedBox(height: 24),

            // Images Section
            _buildLabel('Photos'),
            const SizedBox(height: 8),

            // Image grid
            if (_imagePaths.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      return _buildAddImageButton();
                    }
                    return _buildImageTile(index);
                  },
                ),
              ),
            ] else ...[
              _buildEmptyImagePicker(),
            ],

            const SizedBox(height: 24),

            // Location Section
            _buildLabel('Location'),
            const SizedBox(height: 8),
            if (_latitude != null && _longitude != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.pastelBlue),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.health.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.health),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _locationName ?? 'Location saved',
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _clearLocation,
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ] else ...[
              GestureDetector(
                onTap: _isLoadingLocation ? null : _getLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: [
                      _isLoadingLocation
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            )
                          : Icon(
                              Icons.add_location_alt_rounded,
                              size: 32,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                      const SizedBox(height: 8),
                      Text(
                        _isLoadingLocation ? 'Getting location...' : 'Add Current Location',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 36),

            // Save button
            GradientButton(
              text: widget.isEditing ? 'Update Entry' : 'Save Entry',
              icon: Icons.check_rounded,
              onPressed: _save,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildEmptyImagePicker() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_rounded, size: 32, color: AppColors.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            Text(
              'Add Photos',
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted, fontWeight: FontWeight.w500),
            ),
            Text(
              'Camera or Gallery',
              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        width: 100,
        height: 120,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 28, color: AppColors.primary.withValues(alpha: 0.5)),
            Text('Add', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final path = _imagePaths[index];
    final file = File(path);
    return Container(
      width: 100,
      height: 120,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: file.existsSync()
                ? Image.file(file, width: 100, height: 120, fit: BoxFit.cover)
                : Container(
                    color: AppColors.pastelPink.withValues(alpha: 0.3),
                    child: const Icon(Icons.image_not_supported_rounded),
                  ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
