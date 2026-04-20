import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;
  ThemeNotifier._internal();

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  Future<void> init() async {
    final storage = await StorageService.getInstance();
    _isDarkMode = storage.isDarkMode;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final storage = await StorageService.getInstance();
    await storage.setDarkMode(_isDarkMode);
    notifyListeners();
  }
}
