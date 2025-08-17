// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  Employee? _employee;
  String? _token;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _error;
  bool _isInitialized = false;

  // Additional data from login response
  MonthlyStats? _monthlyStats;
  EmployeePermissions? _permissions;
  int _pendingPettyCash = 0;
  int _activeTasks = 0;

  // Getters
  Employee? get employee => _employee;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  MonthlyStats? get monthlyStats => _monthlyStats;
  EmployeePermissions? get permissions => _permissions;
  int get pendingPettyCash => _pendingPettyCash;
  int get activeTasks => _activeTasks;

  // Initialize auth state from storage
  Future<void> initializeAuth() async {
    if (_isInitialized) return; // Prevent multiple initializations
    
    debugPrint('🔐 AuthProvider: Initializing authentication');
    _setLoading(true);

    try {
      final isAuth = await _authService.isAuthenticated();
      if (isAuth) {
        _employee = await _authService.getStoredEmployee();
        _token = await _authService.getStoredToken();
        
        if (_employee != null && _token != null) {
          _isAuthenticated = true;
          debugPrint('🔐 AuthProvider: User authenticated - ${_employee?.name}');
        } else {
          debugPrint('🔐 AuthProvider: Invalid stored credentials, clearing');
          await _authService.clearAuth();
          _isAuthenticated = false;
        }
      } else {
        debugPrint('🔐 AuthProvider: No stored credentials');
        _isAuthenticated = false;
      }
    } catch (e) {
      _error = 'Failed to initialize authentication: ${e.toString()}';
      debugPrint('🔐 AuthProvider: Initialization error - $e');
      _isAuthenticated = false;
    }

    _setLoading(false);
    _isInitialized = true;
  }

  // Login with employee code and password
  Future<bool> login(String employeeCode, String password) async {
    debugPrint('🔐 AuthProvider: Starting login for employee: $employeeCode');
    _setLoading(true);
    _error = null;

    try {
      final response = await _authService.login(employeeCode, password);

      if (response.success && response.data != null) {
        final loginData = response.data!;
        
        // Set authentication data
        _token = loginData.token;
        _employee = loginData.employee;
        _isAuthenticated = true;
        _error = null;
        
        // Set additional data from login response
        _monthlyStats = loginData.monthlyStats;
        _permissions = loginData.permissions;
        _pendingPettyCash = loginData.pendingPettyCash;
        _activeTasks = loginData.activeTasks;
        
        debugPrint('✅ AuthProvider: Login successful - ${_employee?.name}');
        debugPrint('✅ Monthly Stats: ${_monthlyStats?.totalDays} total days');
        debugPrint('✅ Permissions: Can check-in: ${_permissions?.canCheckin}');
        
        _setLoading(false);
        return true;
      } else {
        _error = response.message ?? 'Login failed';
        debugPrint('❌ AuthProvider: Login failed - ${response.message}');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      debugPrint('❌ AuthProvider: Login exception - $e');
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    debugPrint('🔐 AuthProvider: Starting logout');
    _setLoading(true);

    try {
      await _authService.logout();
      debugPrint('👋 AuthProvider: Logout successful');
    } catch (e) {
      debugPrint('⚠️ AuthProvider: Logout error - $e');
      // Continue with logout even if API call fails
    }

    // Clear all authentication data
    _token = null;
    _employee = null;
    _isAuthenticated = false;
    _error = null;
    _monthlyStats = null;
    _permissions = null;
    _pendingPettyCash = 0;
    _activeTasks = 0;
    _isInitialized = true; // Keep initialized as true to prevent re-initialization

    _setLoading(false);
    debugPrint('🔐 AuthProvider: All auth data cleared');
  }

  // Update employee data
  void updateEmployee(Employee updatedEmployee) {
    _employee = updatedEmployee;
    _safeNotifyListeners();
    debugPrint('🔐 AuthProvider: Employee data updated - ${updatedEmployee.name}');
  }

  // Clear error
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  // Force refresh authentication state
  Future<void> refreshAuthState() async {
    debugPrint('🔐 AuthProvider: Refreshing auth state');
    _isInitialized = false;
    await initializeAuth();
  }

  // Check if user can perform specific actions
  bool canCheckIn() {
    return _permissions?.canCheckin ?? false;
  }

  bool canCheckOut() {
    return _permissions?.canCheckout ?? false;
  }

  bool canCreateTask() {
    return _permissions?.canCreateTask ?? false;
  }

  // Get employee work location
  Map<String, dynamic>? getWorkLocation() {
    if (_employee?.siteLatitude != null && _employee?.siteLongitude != null) {
      return {
        'latitude': _employee!.siteLatitude!,
        'longitude': _employee!.siteLongitude!,
        'siteName': _employee!.siteName ?? 'Unknown Site',
        'siteAddress': _employee!.siteAddress ?? 'Address not available',
      };
    }
    return null;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // Track disposal to prevent notifications after disposal
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Debug method to print current state
  void debugPrintState() {
    debugPrint('🔐 AuthProvider State:');
    debugPrint('  - Authenticated: $_isAuthenticated');
    debugPrint('  - Employee: ${_employee?.name ?? 'None'}');
    debugPrint('  - Token: ${_token != null ? 'Present' : 'None'}');
    debugPrint('  - Loading: $_isLoading');
    debugPrint('  - Error: $_error');
    debugPrint('  - Initialized: $_isInitialized');
    debugPrint('  - Pending Petty Cash: $_pendingPettyCash');
    debugPrint('  - Active Tasks: $_activeTasks');
  }
}
