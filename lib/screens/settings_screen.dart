import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../widgets/common_widgets.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<PetProfile> _allPets = [];
  List<PetProfile> _livingPets = [];
  List<PetProfile> _memorialPets = [];
  int _totalLogs = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    final all = storage.getAllPetProfiles();
    final living = storage.getLivingPetProfiles();
    final memorial = storage.getMemorialPetProfiles();
    final allLogs = storage.getAllCareLogs();

    setState(() {
      _allPets = all;
      _livingPets = living;
      _memorialPets = memorial;
      _totalLogs = allLogs.length;
      _isLoading = false;
    });
  }

  Future<void> _exportDataToCsv() async {
    try {
      final storage = await StorageService.getInstance();
      final logs = storage.getAllCareLogs();
      final petNameMap = { for(var p in _allPets) p.id: p.name };

      String csvContent = "Date,Pet Name,Category,Activity,Notes,Location\n";
      for (var log in logs) {
        final String date = DateFormat('yyyy-MM-dd HH:mm').format(log.dateTime);
        final String petName = petNameMap[log.petId] ?? 'Unknown';
        final String category = log.type.name; // Use Enum name to be safe
        final String title = '"${(log.title ?? '').replaceAll('"', '""')}"';
        final String notes = '"${(log.notes ?? '').replaceAll('"', '""')}"';
        final String location = '"${(log.locationName ?? '').replaceAll('"', '""')}"';

        csvContent += "$date,$petName,$category,$title,$notes,$location\n";
      }

      Directory? dir;
      if (Platform.isAndroid || Platform.isIOS) {
        dir = await getApplicationDocumentsDirectory();
      } else {
        dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      final file = File('${dir.path}/pawpurelove_export_${DateTime.now().millisecondsSinceEpoch}.csv');
      await file.writeAsString(csvContent);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported successfully to: ${file.path}'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting data: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _factoryReset() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all pets, logs, schedules, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final storage = await StorageService.getInstance();
      await storage.clearAllData();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('General Reports & Analytics'),
            const SizedBox(height: 16),
            _buildReportsCard(),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Data Management'),
            const SizedBox(height: 16),
            _buildExportCard(),

            if (_memorialPets.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildSectionHeader('Memorials'),
              const SizedBox(height: 8),
              Text(
                'Forever in our hearts.',
                style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              ..._memorialPets.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMemorialCard(p),
              )),
            ],
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textBrown,
      ),
    );
  }

  Widget _buildReportsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.pastelPink.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Pets Summary',
                style: GoogleFonts.nunito(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              Icon(Icons.analytics_rounded, color: AppColors.primary, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Total Pet Profiles', '${_allPets.length}'),
          _buildStatRow('Living Pets', '${_livingPets.length}'),
          _buildStatRow('Memorial Pets', '${_memorialPets.length}'),
          _buildStatRow('Total Care Activities', '$_totalLogs'),
          const Divider(height: 32),
          Text(
            'Individual Pet Summaries',
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 12),
          ..._allPets.map((pet) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildMiniAvatar(pet),
                    const SizedBox(width: 8),
                    Text(
                      pet.name,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: pet.isDeceased ? AppColors.textMuted : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${pet.ageDisplay} • ${pet.weight.toStringAsFixed(2)}kg',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.nunito(fontSize: 15, color: AppColors.textDark)),
          Text(value, style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildExportCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.pastelPink.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Care Logs',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Download a CSV file containing all activities for all your pets.',
            style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _exportDataToCsv,
              icon: const Icon(Icons.download_rounded),
              label: const Text('Export to CSV'),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceCard,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _factoryReset,
              icon: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
              label: const Text('Clear All Data (Factory Reset)', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surfaceCard,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemorialCard(PetProfile pet) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
          _buildPetAvatar(pet, 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      pet.name,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const Icon(Icons.favorite, color: Colors.grey, size: 20),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${pet.breed} • ${pet.ageDisplay}',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniAvatar(PetProfile pet) {
    if (pet.photoPath != null) {
      final file = File(pet.photoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(file, width: 32, height: 32, fit: BoxFit.cover),
        );
      }
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.pastelPink),
      ),
      child: const Icon(Icons.pets, color: AppColors.primary, size: 16),
    );
  }

  Widget _buildPetAvatar(PetProfile pet, double size) {
    if (pet.photoPath != null) {
      final file = File(pet.photoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.28),
          child: ColorFiltered( // Add grayscale for memorial
            colorFilter: const ColorFilter.matrix(<double>[
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: Image.file(file, width: size, height: size, fit: BoxFit.cover),
          ),
        );
      }
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(Icons.pets, color: Colors.grey.shade400, size: size * 0.45),
    );
  }
}
