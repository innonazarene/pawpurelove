import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../theme/app_theme.dart';
import '../models/pet_profile.dart';
import '../services/storage_service.dart';
import '../services/image_location_service.dart';
import '../widgets/common_widgets.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form controllers
  final _nameController = TextEditingController();
  String _selectedBreed = '';
  String _selectedGender = 'Male';
  int _ageYears = 1;
  int _ageMonths = 0;
  double _weight = 1.0;
  String? _photoPath;

  final List<_OnboardingPage> _pages = [
    _OnboardingPage(
      icon: Icons.pets,
      title: 'Welcome to\nPawureLove',
      subtitle: 'Your all-in-one companion for\nloving care of your furry best friend',
      color: AppColors.pastelPink,
    ),
    _OnboardingPage(
      icon: Icons.favorite_rounded,
      title: 'Track Daily Care',
      subtitle: 'Log feeding, walks, grooming\nand keep your pup happy & healthy',
      color: AppColors.pastelGreen,
    ),
    _OnboardingPage(
      icon: Icons.auto_graph_rounded,
      title: 'Health & Memories',
      subtitle: 'Monitor health records, weight\nand cherish every beautiful moment',
      color: AppColors.pastelBlue,
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      // Show profile setup
      setState(() => _currentPage = _pages.length);
    }
  }

  void _skipToSetup() {
    setState(() => _currentPage = _pages.length);
  }

  Future<void> _pickPhoto() async {
    final path = await ImageLocationService.pickImage(context);
    if (path != null) {
      setState(() => _photoPath = path);
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter your dog\'s name'),
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
    final profile = PetProfile(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      breed: _selectedBreed,
      ageYears: _ageYears,
      ageMonths: _ageMonths,
      gender: _selectedGender,
      weight: _weight,
      photoPath: _photoPath,
    );

    await storage.addPetProfile(profile);
    await storage.setOnboardingComplete();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPage >= _pages.length) {
      return _buildProfileSetup();
    }
    return _buildOnboardingPages();
  }

  Widget _buildOnboardingPages() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipToSetup,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.nunito(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: page.color.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page.icon, size: 64, color: AppColors.primary),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page.title,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textBrown,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page.subtitle,
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: AppColors.textLight,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Dots + button
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  // Page dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == i ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.primary
                              : AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  GradientButton(
                    text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                    icon: _currentPage == _pages.length - 1
                        ? Icons.pets
                        : Icons.arrow_forward_rounded,
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSetup() {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Header
              Center(
                child: Column(
                  children: [
                    // Photo upload
                    GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          if (_photoPath != null && File(_photoPath!).existsSync())
                            ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.file(
                                File(_photoPath!),
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.pets, size: 44, color: Colors.white),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _photoPath != null ? 'Tap to change photo' : 'Add a photo',
                      style: GoogleFonts.nunito(fontSize: 12, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Set Up Your Dog\'s Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textBrown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tell us about your furry friend',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Name
              _buildLabel('Dog\'s Name'),
              TextField(
                controller: _nameController,
                style: GoogleFonts.nunito(fontSize: 16, color: AppColors.textDark),
                decoration: const InputDecoration(
                  hintText: 'Enter your dog\'s name',
                  prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),

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
                  hintText: 'Choose your dog\'s breed',
                  prefixIcon: Icon(Icons.pets_outlined, color: AppColors.primary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), // ← was 0/4
                ),
                isExpanded: true,
                icon: const Padding(
                  padding: EdgeInsets.only(right: 12), // ← keeps chevron off the edge
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
                ),
                items: DogBreed.allBreeds.map((b) {
                  return DropdownMenuItem(
                    value: b.name,
                    child: Text(b.name, style: GoogleFonts.nunito(fontSize: 15)),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedBreed = v ?? ''),
              ),
            ),

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
                          color: isSelected ? AppColors.primary : AppColors.surfaceCard,
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
                      min: 0.1,
                      max: 20,
                      divisions: 159,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.pastelPink,
                      label: '${_weight.toStringAsFixed(2)} kg',
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
                      '${_weight.toStringAsFixed(2)} kg',
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
                text: 'Save & Continue',
                icon: Icons.check_rounded,
                onPressed: _saveProfile,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
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
        color: AppColors.surfaceCard,
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

class _OnboardingPage {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
