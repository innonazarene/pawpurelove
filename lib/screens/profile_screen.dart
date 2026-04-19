import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final bool isNewPet;
  final String? editPetId;

  const ProfileScreen({super.key, this.isNewPet = false, this.editPetId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PetProfile? _profile;
  late TextEditingController _nameController;
  String _selectedBreed = '';
  String _selectedGender = 'Male';
  int _ageYears = 1;
  int _ageMonths = 0;
  double _weight = 1.0;
  String? _photoPath;

  bool get _isNew => widget.isNewPet || _profile == null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.isNewPet) return; // New pet, nothing to load

    final storage = await StorageService.getInstance();
    PetProfile? profile;
    if (widget.editPetId != null) {
      profile = storage.getPetById(widget.editPetId!);
    } else {
      profile = storage.getActivePet();
    }

    if (profile != null) {
      setState(() {
        _profile = profile;
        _nameController.text = profile!.name;
        _selectedBreed = profile.breed;
        _selectedGender = profile.gender;
        _ageYears = profile.ageYears;
        _ageMonths = profile.ageMonths;
        _weight = profile.weight;
        _photoPath = profile.photoPath;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final path = await ImageLocationService.pickImage(context);
    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  void _removePhoto() {
    setState(() => _photoPath = null);
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a name'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_selectedBreed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a breed'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final storage = await StorageService.getInstance();

    if (_isNew) {
      // Creating new pet
      final newProfile = PetProfile(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        breed: _selectedBreed,
        ageYears: _ageYears,
        ageMonths: _ageMonths,
        gender: _selectedGender,
        weight: _weight,
        photoPath: _photoPath,
      );
      await storage.addPetProfile(newProfile);
      await storage.setActivePetId(newProfile.id);
    } else {
      // Updating existing pet
      final updatedProfile = PetProfile(
        id: _profile!.id,
        name: _nameController.text.trim(),
        breed: _selectedBreed,
        ageYears: _ageYears,
        ageMonths: _ageMonths,
        gender: _selectedGender,
        weight: _weight,
        photoPath: _photoPath,
        createdAt: _profile!.createdAt,
      );
      await storage.updatePetProfile(updatedProfile);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(_isNew ? 'Pet added!' : 'Profile updated!'),
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
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isNew ? 'Add New Pet' : 'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textBrown,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: Text(
              'Save',
              style: GoogleFonts.nunito(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo upload
            Center(
              child: _buildPhotoUpload(),
            ),
            const SizedBox(height: 32),

            // Name
            _buildLabel('Name'),
            TextField(
              controller: _nameController,
              style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textDark),
              decoration: const InputDecoration(
                hintText: 'Your dog\'s name',
                prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),

            // Breed
            _buildLabel('Breed'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.pastelPink.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedBreed.isEmpty ? null : _selectedBreed,
                decoration: const InputDecoration(
                  hintText: 'Select breed',
                  prefixIcon: Icon(Icons.pets_outlined, color: AppColors.primary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                items: DogBreed.allBreeds.map((b) {
                  return DropdownMenuItem(
                    value: b.name,
                    child: Text(b.name, style: GoogleFonts.nunito(fontSize: 15)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedBreed = v ?? ''),
              ),
            ),
            const SizedBox(height: 24),

            // Gender
            _buildLabel('Gender'),
            Row(
              children: ['Male', 'Female'].map((g) {
                final isSelected = _selectedGender == g;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedGender = g),
                    child: Container(
                      margin: EdgeInsets.only(right: g == 'Male' ? 8 : 0, left: g == 'Female' ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            g == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                            color: isSelected ? Colors.white : AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            g,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Age
            _buildLabel('Age'),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Years', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      _buildNumberPicker(_ageYears, 0, 20, (v) => setState(() => _ageYears = v)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Months', style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted)),
                      const SizedBox(height: 4),
                      _buildNumberPicker(_ageMonths, 0, 11, (v) => setState(() => _ageMonths = v)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Weight
            _buildLabel('Weight (kg)'),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _weight,
                    min: 0.5,
                    max: 80,
                    divisions: 159,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.pastelPink,
                    label: '${_weight.toStringAsFixed(1)} kg',
                    onChanged: (v) => setState(() => _weight = v),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_weight.toStringAsFixed(1)} kg',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Save button
            GradientButton(
              text: _isNew ? 'Add Pet' : 'Save Changes',
              icon: _isNew ? Icons.pets_rounded : Icons.check_rounded,
              onPressed: _saveProfile,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoUpload() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickPhoto,
          child: Stack(
            children: [
              // Photo or placeholder
              if (_photoPath != null && File(_photoPath!).existsSync())
                ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.file(
                    File(_photoPath!),
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: AppColors.warmGradient,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.pets, color: AppColors.primary, size: 48),
                ),
              // Camera badge
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_photoPath != null)
          TextButton.icon(
            onPressed: _removePhoto,
            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
            label: Text(
              'Remove photo',
              style: GoogleFonts.nunito(fontSize: 13, color: AppColors.error),
            ),
          )
        else
          Text(
            'Tap to add photo',
            style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted),
          ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildNumberPicker(int value, int min, int max, ValueChanged<int> onChanged) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: value > min ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.primary,
            iconSize: 20,
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          IconButton(
            onPressed: value < max ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.primary,
            iconSize: 20,
          ),
        ],
      ),
    );
  }
}
