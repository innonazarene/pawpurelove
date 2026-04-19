import 'package:shared_preferences/shared_preferences.dart';
import '../models/pet_profile.dart';
import '../models/care_log.dart';
import '../models/pet_schedule.dart';

class StorageService {
  static const String _petProfilesKey = 'pet_profiles';
  static const String _activePetKey = 'active_pet_id';
  static const String _careLogsKey = 'care_logs';
  static const String _petSchedulesKey = 'pet_schedules';
  static const String _onboardingKey = 'onboarding_complete';

  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Onboarding
  bool get isOnboardingComplete => _prefs.getBool(_onboardingKey) ?? false;
  Future<void> setOnboardingComplete() => _prefs.setBool(_onboardingKey, true);

  // ===== Multiple Pet Profiles =====

  /// Get all pet profiles
  List<PetProfile> getAllPetProfiles() {
    final strList = _prefs.getStringList(_petProfilesKey) ?? [];
    return strList.map((s) {
      try {
        return PetProfile.decode(s);
      } catch (_) {
        return null;
      }
    }).whereType<PetProfile>().toList();
  }

  /// Save a new pet profile (adds to list)
  Future<void> addPetProfile(PetProfile profile) async {
    final profiles = getAllPetProfiles();
    profiles.add(profile);
    await _saveAllProfiles(profiles);
    // Set as active if it's the first pet
    if (profiles.length == 1) {
      await setActivePetId(profile.id);
    }
  }

  /// Update an existing pet profile
  Future<void> updatePetProfile(PetProfile updated) async {
    final profiles = getAllPetProfiles();
    final index = profiles.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      profiles[index] = updated;
      await _saveAllProfiles(profiles);
    }
  }

  /// Delete a pet profile and its care logs
  Future<void> deletePetProfile(String petId) async {
    final profiles = getAllPetProfiles();
    profiles.removeWhere((p) => p.id == petId);
    await _saveAllProfiles(profiles);

    // Delete associated care logs
    final logs = getAllCareLogs();
    logs.removeWhere((l) => l.petId == petId);
    await _prefs.setStringList(_careLogsKey, logs.map((l) => l.encode()).toList());

    // Delete associated schedules
    final schedules = getAllSchedules();
    schedules.removeWhere((s) => s.petId == petId);
    await _prefs.setStringList(_petSchedulesKey, schedules.map((s) => s.encode()).toList());

    // Update active pet if the deleted one was active
    final activePetId = getActivePetId();
    if (activePetId == petId) {
      if (profiles.isNotEmpty) {
        await setActivePetId(profiles.first.id);
      } else {
        await _prefs.remove(_activePetKey);
      }
    }
  }

  /// Get pet by ID
  PetProfile? getPetById(String id) {
    try {
      return getAllPetProfiles().firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Save all profiles to storage
  Future<void> _saveAllProfiles(List<PetProfile> profiles) async {
    await _prefs.setStringList(
      _petProfilesKey,
      profiles.map((p) => p.encode()).toList(),
    );
  }

  // ===== Active Pet =====

  String? getActivePetId() => _prefs.getString(_activePetKey);

  Future<void> setActivePetId(String petId) async {
    await _prefs.setString(_activePetKey, petId);
  }

  PetProfile? getActivePet() {
    final id = getActivePetId();
    if (id == null) {
      // Fallback to first pet
      final pets = getAllPetProfiles();
      if (pets.isNotEmpty) return pets.first;
      return null;
    }
    return getPetById(id);
  }

  // ===== Backward compatibility =====
  // These methods work with the active pet for backward compat

  Future<void> savePetProfile(PetProfile profile) async {
    final profiles = getAllPetProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      profiles[index] = profile;
    } else {
      profiles.add(profile);
    }
    await _saveAllProfiles(profiles);
    await setActivePetId(profile.id);
  }

  PetProfile? getPetProfile() => getActivePet();

  // ===== Care Logs =====

  Future<void> saveCareLog(CareLog log) async {
    final logs = getCareLogsRaw();
    logs.add(log.encode());
    await _prefs.setStringList(_careLogsKey, logs);
  }

  Future<void> updateCareLog(CareLog updatedLog) async {
    final logs = getAllCareLogs();
    final index = logs.indexWhere((l) => l.id == updatedLog.id);
    if (index != -1) {
      logs[index] = updatedLog;
      await _prefs.setStringList(
        _careLogsKey,
        logs.map((l) => l.encode()).toList(),
      );
    }
  }

  Future<void> deleteCareLog(String logId) async {
    final logs = getAllCareLogs();
    logs.removeWhere((l) => l.id == logId);
    await _prefs.setStringList(
      _careLogsKey,
      logs.map((l) => l.encode()).toList(),
    );
  }

  List<String> getCareLogsRaw() {
    return _prefs.getStringList(_careLogsKey) ?? [];
  }

  List<CareLog> getAllCareLogs() {
    return getCareLogsRaw().map((s) {
      try {
        return CareLog.decode(s);
      } catch (_) {
        return null;
      }
    }).whereType<CareLog>().toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  /// Get care logs for the active pet only
  List<CareLog> getActiveCareLogs() {
    final petId = getActivePetId();
    if (petId == null) return getAllCareLogs();
    return getAllCareLogs().where((l) => l.petId == petId).toList();
  }

  List<CareLog> getCareLogsByType(CareType type) {
    return getActiveCareLogs().where((l) => l.type == type).toList();
  }

  List<CareLog> getCareLogsByPet(String petId) {
    return getAllCareLogs().where((l) => l.petId == petId).toList();
  }

  List<CareLog> getCareLogsForCategory(String category) {
    return getActiveCareLogs().where((l) => l.type.category == category).toList();
  }

  List<CareLog> getTodaysLogs() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    return getActiveCareLogs().where((l) => l.dateTime.isAfter(todayStart)).toList();
  }

  CareLog? getCareLogById(String id) {
    try {
      return getAllCareLogs().firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===== Pet Schedules =====

  Future<void> saveSchedule(PetSchedule schedule) async {
    final schedules = getSchedulesRaw();
    schedules.add(schedule.encode());
    await _prefs.setStringList(_petSchedulesKey, schedules);
  }

  Future<void> updateSchedule(PetSchedule updatedSchedule) async {
    final schedules = getAllSchedules();
    final index = schedules.indexWhere((s) => s.id == updatedSchedule.id);
    if (index != -1) {
      schedules[index] = updatedSchedule;
      await _prefs.setStringList(
        _petSchedulesKey,
        schedules.map((s) => s.encode()).toList(),
      );
    }
  }

  Future<void> deleteSchedule(String scheduleId) async {
    final schedules = getAllSchedules();
    schedules.removeWhere((s) => s.id == scheduleId);
    await _prefs.setStringList(
      _petSchedulesKey,
      schedules.map((s) => s.encode()).toList(),
    );
  }

  List<String> getSchedulesRaw() {
    return _prefs.getStringList(_petSchedulesKey) ?? [];
  }

  List<PetSchedule> getAllSchedules() {
    return getSchedulesRaw().map((s) {
      try {
        return PetSchedule.decode(s);
      } catch (_) {
        return null;
      }
    }).whereType<PetSchedule>().toList()
      ..sort((a, b) => a.nextScheduledDate.compareTo(b.nextScheduledDate));
  }

  List<PetSchedule> getActivePetSchedules() {
    final petId = getActivePetId();
    if (petId == null) return [];
    return getAllSchedules().where((s) => s.petId == petId).toList();
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
