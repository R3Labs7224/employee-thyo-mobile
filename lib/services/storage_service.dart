import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Keys
  static const String _tokenKey = 'auth_token';
  static const String _employeeKey = 'employee_data';
  static const String _languageKey = 'selected_language';
  static const String _themeKey = 'theme_mode';

  // Token management
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  Future<String?> getToken() async {
    return _prefs.getString(_tokenKey);
  }

  // Employee data management
  Future<void> saveEmployeeData(Map<String, dynamic> employeeData) async {
    await _prefs.setString(_employeeKey, json.encode(employeeData));
  }

  Future<Map<String, dynamic>?> getEmployeeData() async {
    final jsonString = _prefs.getString(_employeeKey);
    if (jsonString != null) {
      return json.decode(jsonString);
    }
    return null;
  }

  // Language preference
  Future<void> saveLanguage(String languageCode) async {
    await _prefs.setString(_languageKey, languageCode);
  }

  Future<String?> getLanguage() async {
    return _prefs.getString(_languageKey);
  }

  // Theme preference
  Future<void> saveThemeMode(String themeMode) async {
    await _prefs.setString(_themeKey, themeMode);
  }

  Future<String?> getThemeMode() async {
    return _prefs.getString(_themeKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  // Remove specific keys
  Future<void> removeToken() async {
    await _prefs.remove(_tokenKey);
  }

  Future<void> removeEmployeeData() async {
    await _prefs.remove(_employeeKey);
  }
}
