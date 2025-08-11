// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  Employee? _employee;
  String? _token;
  bool _isLoading = false; // Changed from true to false
  bool _isAuthenticated = false;
  String? _error;
  bool _isInitialized = false; // Add initialization flag

  // Getters
  Employee? get employee => _employee;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Initialize auth state from storage
  Future<void> initializeAuth() async {
    if (_isInitialized) return; // Prevent multiple initializations
    
    _isLoading = true;
    notifyListeners();

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _employee = await _authService.getStoredEmployee();
        _token = await _authService.getStoredToken();
        _isAuthenticated = true;
        
        // Debug logging
        debugPrint('🔐 Auth initialized - User authenticated: ${_employee?.name}');
      } else {
        debugPrint('🔐 Auth initialized - No stored credentials');
      }
    } catch (e) {
      _error = 'Failed to initialize authentication: ${e.toString()}';
      debugPrint('🔐 Auth initialization error: $e');
    }

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  // Login with employee code and password
  Future<bool> login(String employeeCode, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _authService.login(employeeCode, password);

      if (response.success && response.data != null) {
        _token = response.data!.token;
        _employee = response.data!.employee;
        _isAuthenticated = true;
        _error = null;
        
        debugPrint('✅ Login successful: ${_employee?.name}');
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        debugPrint('❌ Login failed: ${response.message}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      debugPrint('❌ Login error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      debugPrint('👋 User logged out');
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
      // Continue with logout even if API call fails
    }

    _token = null;
    _employee = null;
    _isAuthenticated = false;
    _error = null;

    _isLoading = false;
    notifyListeners();
  }

  // Update employee data
  void updateEmployee(Employee updatedEmployee) {
    _employee = updatedEmployee;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear authentication
  Future<void> clearAuth() async {
    await _authService.clearAuth();
    _token = null;
    _employee = null;
    _isAuthenticated = false;
    _error = null;
    _isInitialized = false;
    notifyListeners();
  }

  // Force refresh authentication state
  Future<void> refreshAuthState() async {
    _isInitialized = false;
    await initializeAuth();
  }
}