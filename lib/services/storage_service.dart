// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _employeeDataKey = 'employee_data';
  static const String _lastSyncKey = 'last_sync';
  static const String _appVersionKey = 'app_version';

  // Save authentication token
  Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      debugPrint('💾 Token saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save token: $e');
      rethrow;
    }
  }

  // Get authentication token
  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      debugPrint('🔑 Token retrieved: ${token != null ? 'Found' : 'Not found'}');
      return token;
    } catch (e) {
      debugPrint('❌ Failed to get token: $e');
      return null;
    }
  }

  // Save employee data
  Future<void> saveEmployeeData(Map<String, dynamic> employeeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = json.encode(employeeData);
      await prefs.setString(_employeeDataKey, jsonString);
      debugPrint('💾 Employee data saved successfully');
    } catch (e) {
      debugPrint('❌ Failed to save employee data: $e');
      rethrow;
    }
  }

  // Get employee data
  Future<Map<String, dynamic>?> getEmployeeData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_employeeDataKey);
      
      if (jsonString != null) {
        try {
          final data = json.decode(jsonString) as Map<String, dynamic>;
          debugPrint('👤 Employee data retrieved successfully');
          return data;
        } catch (e) {
          debugPrint('❌ Failed to decode employee data: $e');
          // Clear corrupted data
          await prefs.remove(_employeeDataKey);
          return null;
        }
      }
      
      debugPrint('👤 No employee data found');
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get employee data: $e');
      return null;
    }
  }

  // Save last sync timestamp
  Future<void> saveLastSync(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
      debugPrint('🔄 Last sync saved: ${timestamp.toIso8601String()}');
    } catch (e) {
      debugPrint('❌ Failed to save last sync: $e');
    }
  }

  // Get last sync timestamp
  Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampString = prefs.getString(_lastSyncKey);
      
      if (timestampString != null) {
        try {
          return DateTime.parse(timestampString);
        } catch (e) {
          debugPrint('❌ Failed to parse last sync timestamp: $e');
          return null;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Failed to get last sync: $e');
      return null;
    }
  }

  // Save app version
  Future<void> saveAppVersion(String version) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_appVersionKey, version);
    } catch (e) {
      debugPrint('❌ Failed to save app version: $e');
    }
  }

  // Get app version
  Future<String?> getAppVersion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_appVersionKey);
    } catch (e) {
      debugPrint('❌ Failed to get app version: $e');
      return null;
    }
  }

  // Clear all stored data
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_employeeDataKey);
      await prefs.remove(_lastSyncKey);
      debugPrint('🧹 All storage data cleared');
      // Keep app version for tracking
    } catch (e) {
      debugPrint('❌ Failed to clear storage: $e');
    }
  }

  // Clear only authentication data
  Future<void> clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_employeeDataKey);
      debugPrint('🧹 Auth data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear auth data: $e');
    }
  }

  // Check if user data exists
  Future<bool> hasUserData() async {
    try {
      final token = await getToken();
      final employeeData = await getEmployeeData();
      final hasData = token != null && employeeData != null;
      debugPrint('🔍 User data exists: $hasData');
      return hasData;
    } catch (e) {
      debugPrint('❌ Failed to check user data: $e');
      return false;
    }
  }

  // Save generic key-value data
  Future<void> saveString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (e) {
      debugPrint('❌ Failed to save string for key $key: $e');
    }
  }

  // Get generic string data
  Future<String?> getString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (e) {
      debugPrint('❌ Failed to get string for key $key: $e');
      return null;
    }
  }

  // Save boolean data
  Future<void> saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('❌ Failed to save bool for key $key: $e');
    }
  }

  // Get boolean data
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(key) ?? defaultValue;
    } catch (e) {
      debugPrint('❌ Failed to get bool for key $key: $e');
      return defaultValue;
    }
  }

  // Save integer data
  Future<void> saveInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (e) {
      debugPrint('❌ Failed to save int for key $key: $e');
    }
  }

  // Get integer data
  Future<int> getInt(String key, {int defaultValue = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? defaultValue;
    } catch (e) {
      debugPrint('❌ Failed to get int for key $key: $e');
      return defaultValue;
    }
  }

  // Remove specific key
  Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('❌ Failed to remove key $key: $e');
    }
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      debugPrint('❌ Failed to check key $key: $e');
      return false;
    }
  }
}