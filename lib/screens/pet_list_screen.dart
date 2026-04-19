import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../widgets/common_widgets.dart';
import 'profile_screen.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});

  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  List<PetProfile> _pets = [];
  String? _activePetId;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _pets = storage.getAllPetProfiles();
      _activePetId = storage.getActivePetId();
    });
  }

  Future<void> _switchPet(String petId) async {
    final storage = await StorageService.getInstance();
    await storage.setActivePetId(petId);
    setState(() => _activePetId = petId);
    if (!mounted) return;
    Navigator.pop(context, true); // return true to refresh home
  }

  Future<void> _addNewPet() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen(isNewPet: true)),
    );
    if (result == true) _loadPets();
  }

  Future<void> _editPet(PetProfile pet) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProfileScreen(editPetId: pet.id)),
    );
    if (result == true) _loadPets();
  }

  Future<void> _deletePet(PetProfile pet) async {
    if (_pets.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You need at least one pet profile'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete ${pet.name}?'),
        content: Text(
          'This will permanently delete ${pet.name}\'s profile and all their care logs. This cannot be undone.',
        ),
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
      if (pet.photoPath != null) {
        await ImageLocationService.deleteImage(pet.photoPath!);
      }
      await storage.deletePetProfile(pet.id);
      _loadPets();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Pets',
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
      ),
      body: _pets.isEmpty
          ? EmptyStateWidget(
              icon: Icons.pets_rounded,
              title: 'No pets yet',
              subtitle: 'Add your first furry friend!',
              actionLabel: 'Add Pet',
              onAction: _addNewPet,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _pets.length,
              itemBuilder: (context, index) {
                final pet = _pets[index];
                final isActive = pet.id == _activePetId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPetCard(pet, isActive),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'pet_list_fab',
        onPressed: _addNewPet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Pet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildPetCard(PetProfile pet, bool isActive) {
    return GestureDetector(
      onTap: () => _switchPet(pet.id),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.pastelPink.withValues(alpha: 0.5),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo
            _buildPetAvatar(pet, 64),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pet.name,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textBrown,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Active',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pet.breed} • ${pet.ageDisplay}',
                    style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildChip(Icons.monitor_weight_outlined, '${pet.weight.toStringAsFixed(1)} kg'),
                      const SizedBox(width: 6),
                      _buildChip(
                        pet.gender == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                        pet.gender,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Actions
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted.withValues(alpha: 0.6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'switch') _switchPet(pet.id);
                if (v == 'edit') _editPet(pet);
                if (v == 'delete') _deletePet(pet);
              },
              itemBuilder: (_) => [
                if (!isActive)
                  const PopupMenuItem(value: 'switch', child: Row(children: [
                    Icon(Icons.swap_horiz_rounded, size: 18), SizedBox(width: 8), Text('Set Active'),
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
      ),
    );
  }

  Widget _buildPetAvatar(PetProfile pet, double size) {
    if (pet.photoPath != null) {
      final file = File(pet.photoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: Image.file(file, width: size, height: size, fit: BoxFit.cover),
        );
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(Icons.pets, color: AppColors.primary, size: size * 0.45),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.pastelPink.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 3),
          Text(text, style: GoogleFonts.nunito(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        ],
      ),
    );
  }
}
