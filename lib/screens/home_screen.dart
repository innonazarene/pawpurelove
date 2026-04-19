import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../models/care_log.dart';
import '../services/storage_service.dart';
import '../widgets/common_widgets.dart';
import '../utils/quotes.dart';
import 'daily_care_screen.dart';
import 'health_screen.dart';
import 'memory_screen.dart';
import 'profile_screen.dart';
import 'schedules_screen.dart';
import 'add_edit_log_screen.dart';
import 'pet_list_screen.dart';
import 'activity_map_screen.dart';
import 'walk_tracker_screen.dart';
import '../models/pet_schedule.dart';
import '../services/notification_service.dart';

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
  List<PetSchedule> _pendingSchedules = [];
  String _currentQuote = PetQuotes.getRandomQuote();
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _loadData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final storage = await StorageService.getInstance();
    setState(() {
      _profile = storage.getActivePet();
      _allPets = storage.getAllPetProfiles();
      _todayLogs = storage.getTodaysLogs();
      _currentQuote = PetQuotes.getRandomQuote();
      if (_profile != null) {
        final allSchedules = storage.getActivePetSchedules();
        _pendingSchedules = allSchedules
            .where((s) => s.isActive && s.nextScheduledDate.isBefore(DateTime.now()))
            .toList();
      } else {
        _pendingSchedules = [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeTab(),
      DailyCareScreen(key: ValueKey('daily_${_profile?.id}')),
      HealthScreen(key: ValueKey('health_${_profile?.id}')),
      MemoryScreen(key: ValueKey('memory_${_profile?.id}')),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) _loadData();
        },
        physics: const BouncingScrollPhysics(),
        children: screens,
      ),
      floatingActionButton: _profile != null
          ? FloatingActionButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddEditLogScreen(petId: _profile!.id)),
                );
                if (result == true) _loadData();
              },
              backgroundColor: AppColors.primary,
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.pets_rounded, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        padding: EdgeInsets.zero,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.restaurant_rounded, Icons.restaurant_outlined, 'Care'),
                const SizedBox(width: 48),
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
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        if (index == 0) _loadData();
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              style: GoogleFonts.nunito(
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
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _profile?.name ?? 'Your Pup',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textBrown,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildNotificationBell(),
                      const SizedBox(width: 16),
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
                ],
              ),
            ),
          ),

          // Daily Wisdom Quote
          if (_currentQuote.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: PawCard(
                  borderColor: AppColors.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.format_quote_rounded, color: AppColors.primary.withValues(alpha: 0.5), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _currentQuote,
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textBrown,
                          ),
                        ),
                      ),
                    ],
                  ),
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
                                Text('Add', style: GoogleFonts.nunito(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500)),
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
                                style: GoogleFonts.nunito(
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFeatureCard(
                    icon: Icons.directions_walk_rounded,
                    title: 'Live Walk Tracker',
                    subtitle: 'Track your live route with GPS',
                    color: AppColors.success,
                    borderColor: AppColors.pastelGreen,
                    onTap: () {
                      if (_profile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => WalkTrackerScreen(petId: _profile!.id)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.map_rounded,
                    title: 'Activity Map',
                    subtitle: 'See exactly where memory milestones & walks took place',
                    color: AppColors.info,
                    borderColor: AppColors.pastelBlue,
                    onTap: () {
                      if (_profile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ActivityMapScreen(petId: _profile!.id)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureCard(
                    icon: Icons.schedule_rounded,
                    title: 'Schedules & Reminders',
                    subtitle: 'Daily routines and upcoming appointments',
                    color: AppColors.warning,
                    borderColor: AppColors.pastelYellow,
                    onTap: () {
                      if (_profile != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SchedulesScreen(petId: _profile!.id)),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Core Modules', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textBrown)),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 1, color: Colors.grey.withValues(alpha: 0.2))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    children: [
                      _buildGridFeatureCard(
                        icon: Icons.home_rounded,
                        title: 'Home',
                        subtitle: 'Dashboard overview',
                        color: AppColors.primary,
                        borderColor: AppColors.pastelPink,
                        onTap: () {
                          setState(() => _currentIndex = 0);
                          _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                      _buildGridFeatureCard(
                        icon: Icons.restaurant_rounded,
                        title: 'Daily Care',
                        subtitle: 'Feeding & grooming',
                        color: AppColors.dailyCare,
                        borderColor: AppColors.pastelPink,
                        onTap: () {
                          setState(() => _currentIndex = 1);
                          _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                      _buildGridFeatureCard(
                        icon: Icons.monitor_heart_rounded,
                        title: 'Health',
                        subtitle: 'Vaccines & vet',
                        color: AppColors.health,
                        borderColor: AppColors.pastelBlue,
                        onTap: () {
                          setState(() => _currentIndex = 2);
                          _pageController.animateToPage(2, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                      _buildGridFeatureCard(
                        icon: Icons.photo_album_rounded,
                        title: 'Memory',
                        subtitle: 'Moments & notes',
                        color: AppColors.memory,
                        borderColor: AppColors.pastelPurple,
                        onTap: () {
                          setState(() => _currentIndex = 3);
                          _pageController.animateToPage(3, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                        },
                      ),
                    ],
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

  Widget _buildNotificationBell() {
    return GestureDetector(
      onTap: _pendingSchedules.isNotEmpty ? _showPendingSchedulesBottomSheet : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: _pendingSchedules.isNotEmpty ? 0.1 : 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_active_rounded, 
              color: _pendingSchedules.isNotEmpty ? AppColors.primary : AppColors.textMuted, 
              size: 24,
            ),
          ),
          if (_pendingSchedules.isNotEmpty)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                child: Text(
                  '${_pendingSchedules.length}',
                  style: GoogleFonts.nunito(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showPendingSchedulesBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pending Reminders', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textBrown)),
            const SizedBox(height: 8),
            Text('Mark these routines as completed.', style: GoogleFonts.nunito(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 24),
            ..._pendingSchedules.map((schedule) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PawCard(
                  borderColor: AppColors.primary.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getColorForType(schedule.type).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getIconForType(schedule.type), color: _getColorForType(schedule.type), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(schedule.title, style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textDark)),
                          const SizedBox(height: 2),
                          Text('Due: ${DateFormat.yMMMd().add_jm().format(schedule.nextScheduledDate)}', style: GoogleFonts.nunito(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        _acceptSchedule(schedule);
                      },
                      child: Text('Done', style: GoogleFonts.nunito(fontWeight: FontWeight.w600, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            );
          }),
          ],
        ),
      ),
    );
  }

  Future<void> _acceptSchedule(PetSchedule schedule) async {
    final storage = await StorageService.getInstance();
    
    // Automatically log it 
    final log = CareLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        petId: schedule.petId,
        type: schedule.type,
        dateTime: DateTime.now(),
        title: schedule.title,
        notes: schedule.notes ?? 'Completed from reminder!',
    );
    await storage.saveCareLog(log);

    // Update the schedule
    PetSchedule updatedSchedule;
    if (schedule.frequency == ScheduleFrequency.once) {
      updatedSchedule = schedule.copyWith(isActive: false);
    } else {
      DateTime nextDate = NotificationService().calculateNext(schedule.nextScheduledDate, schedule.frequency);
      
      while (nextDate.isBefore(DateTime.now())) {
        nextDate = NotificationService().calculateNext(nextDate, schedule.frequency);
      }

      updatedSchedule = schedule.copyWith(
        nextScheduledDate: nextDate,
      );
      // Re-schedule native notification for the next cycle
      await NotificationService().schedulePetNotification(updatedSchedule, _profile?.name ?? 'Pet');
    }
    await storage.updateSchedule(updatedSchedule);

    _loadData();
    
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text('${schedule.title} marked as done!'),
        ],
      ),
      backgroundColor: AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
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
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBrown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_profile!.breed} • ${_profile!.ageDisplay}',
                  style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textLight),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(Icons.monitor_weight_outlined, '${_profile!.weight.toStringAsFixed(2)} kg'),
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
          Text(text, style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark)),
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
                Text(title, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
        ],
      ),
    );
  }

  Widget _buildGridFeatureCard({
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const Spacer(),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.textMuted,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
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
    if (hour >= 5 && hour < 12) return 'Good Morning';
    if (hour >= 12 && hour < 17) return 'Good Afternoon';
    if (hour >= 17 && hour < 22) return 'Good Evening';
    return 'Hi Night Owl 🦉';
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
