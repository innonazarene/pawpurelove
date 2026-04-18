import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';
import 'daily_care_screen.dart';
import 'health_screen.dart';
import 'memory_screen.dart';
import 'profile_screen.dart';
import 'pet_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  PetProfile? _profile;
  List<PetProfile> _allPets = [];
  List<CareLog> _todayLogs = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _profile = storage.getActivePet();
      _allPets = storage.getAllPetProfiles();
      _todayLogs = storage.getTodaysLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeTab(),
      const DailyCareScreen(),
      const HealthScreen(),
      const MemoryScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.restaurant_rounded, Icons.restaurant_outlined, 'Care'),
                _buildNavItem(2, Icons.monitor_heart_rounded, Icons.monitor_heart_outlined, 'Health'),
                _buildNavItem(3, Icons.photo_album_rounded, Icons.photo_album_outlined, 'Memory'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _loadData();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 24,
                right: 24,
                bottom: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.name ?? 'Your Pup',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBrown,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PetListScreen()),
                      );
                      _loadData();
                    },
                    child: _buildProfileAvatar(),
                  ),
                ],
              ),
            ),
          ),

          // Pet Switcher (if multiple pets)
          if (_allPets.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: SizedBox(
                  height: 56,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _allPets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _allPets.length) {
                        // Add pet button
                        return GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen(isNewPet: true)),
                            );
                            if (result == true) _loadData();
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), style: BorderStyle.solid),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 18, color: AppColors.primary.withValues(alpha: 0.6)),
                                const SizedBox(width: 6),
                                Text('Add', style: GoogleFonts.inter(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        );
                      }

                      final pet = _allPets[index];
                      final isActive = pet.id == _profile?.id;
                      return GestureDetector(
                        onTap: () async {
                          final storage = await StorageService.getInstance();
                          await storage.setActivePetId(pet.id);
                          _loadData();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive ? AppColors.primary : AppColors.pastelPink,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              _buildSmallPetAvatar(pet),
                              const SizedBox(width: 8),
                              Text(
                                pet.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                                  color: isActive ? AppColors.primary : AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

          // Pet Info Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: _buildPetInfoCard(),
            ),
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      QuickActionButton(
                        icon: Icons.restaurant_rounded,
                        label: 'Feed',
                        color: AppColors.dailyCare,
                        onTap: () => _quickLog(CareType.feeding),
                      ),
                      QuickActionButton(
                        icon: Icons.water_drop_rounded,
                        label: 'Water',
                        color: AppColors.info,
                        onTap: () => _quickLog(CareType.water),
                      ),
                      QuickActionButton(
                        icon: Icons.directions_walk_rounded,
                        label: 'Walk',
                        color: AppColors.success,
                        onTap: () => _quickLog(CareType.walk),
                      ),
                      QuickActionButton(
                        icon: Icons.shower_rounded,
                        label: 'Groom',
                        color: AppColors.memory,
                        onTap: () => _quickLog(CareType.grooming),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Today's Activity
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: SectionHeader(
                title: 'Today\'s Activity',
                actionText: '${_todayLogs.length} logged',
              ),
            ),
          ),

          if (_todayLogs.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: PawCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.pastelYellow.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.wb_sunny_rounded, color: AppColors.warning, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No activities yet today', style: Theme.of(context).textTheme.titleMedium),
                            Text('Tap quick actions above to start logging!', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          if (_todayLogs.isNotEmpty)
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final log = _todayLogs[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: CareLogTile(
                      icon: _getIconForType(log.type),
                      iconColor: _getColorForType(log.type),
                      title: log.title ?? log.type.label,
                      subtitle: log.notes ?? 'Logged successfully',
                      time: DateFormat.jm().format(log.dateTime),
                      onDelete: () => _deleteLog(log.id),
                    ),
                  );
                },
                childCount: _todayLogs.length > 5 ? 5 : _todayLogs.length,
              ),
            ),

          // Feature Cards
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: const SectionHeader(title: 'Features'),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  _buildFeatureCard(
                    icon: Icons.restaurant_rounded,
                    title: 'Daily Care',
                    subtitle: 'Feeding, walks, grooming & more',
                    color: AppColors.dailyCare,
                    borderColor: AppColors.pastelPink,
                    onTap: () => setState(() => _currentIndex = 1),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.monitor_heart_rounded,
                    title: 'Health & Wellness',
                    subtitle: 'Vaccinations, weight, vet visits',
                    color: AppColors.health,
                    borderColor: AppColors.pastelBlue,
                    onTap: () => setState(() => _currentIndex = 2),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.photo_album_rounded,
                    title: 'Memory & Joy',
                    subtitle: 'Milestones, notes & beautiful moments',
                    color: AppColors.memory,
                    borderColor: AppColors.pastelPurple,
                    onTap: () => setState(() => _currentIndex = 3),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    if (_profile?.photoPath != null) {
      final file = File(_profile!.photoPath!);
      if (file.existsSync()) {
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.file(file, fit: BoxFit.cover),
          ),
        );
      }
    }
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: const Icon(Icons.pets, color: AppColors.primary, size: 26),
    );
  }

  Widget _buildSmallPetAvatar(PetProfile pet) {
    if (pet.photoPath != null) {
      final file = File(pet.photoPath!);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 28, height: 28, fit: BoxFit.cover),
        );
      }
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: AppColors.warmGradient,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.pets, color: AppColors.primary, size: 14),
    );
  }

  Widget _buildPetInfoCard() {
    if (_profile == null) return const SizedBox();
    return PawCard(
      borderColor: AppColors.primary.withValues(alpha: 0.15),
      child: Row(
        children: [
          // Pet photo
          if (_profile!.photoPath != null && File(_profile!.photoPath!).existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                File(_profile!.photoPath!),
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.warmGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.pets, color: AppColors.primary, size: 32),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profile!.name,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_profile!.breed} • ${_profile!.ageDisplay}',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.monitor_weight_outlined, '${_profile!.weight.toStringAsFixed(1)} kg'),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      _profile!.gender == 'Male' ? Icons.male_rounded : Icons.female_rounded,
                      _profile!.gender,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProfileScreen(editPetId: _profile!.id)),
              );
              _loadData();
            },
            icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pastelPink.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return PawCard(
      borderColor: borderColor,
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Future<void> _quickLog(CareType type) async {
    final storage = await StorageService.getInstance();
    final profile = storage.getActivePet();
    if (profile == null) return;

    final log = CareLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      petId: profile.id,
      type: type,
      dateTime: DateTime.now(),
      title: type.label,
      notes: '${type.label} logged at ${DateFormat.jm().format(DateTime.now())}',
    );

    await storage.saveCareLog(log);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('${type.label} logged for ${profile.name}!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
    _loadData();
  }

  Future<void> _deleteLog(String logId) async {
    final storage = await StorageService.getInstance();
    await storage.deleteCareLog(logId);
    _loadData();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌤️';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
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
