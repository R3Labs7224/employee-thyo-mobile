// lib/providers/employee_provider.dart - Updated with better error handling
import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';

class EmployeeProvider with ChangeNotifier {
  final EmployeeService _employeeService = EmployeeService();

  Employee? _employee;
  AttendanceStats? _attendanceStats;
  PettyCashStats? _pettyCashStats;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  Employee? get employee => _employee;
  AttendanceStats? get attendanceStats => _attendanceStats;
  PettyCashStats? get pettyCashStats => _pettyCashStats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  // Fetch employee profile with stats
  Future<void> fetchProfile() async {
    // Prevent multiple simultaneous calls
    if (_isLoading) return;

    debugPrint('🔧 EmployeeProvider: Starting fetchProfile');
    _setLoading(true);
    _error = null;

    try {
      final response = await _employeeService.getProfile();
      debugPrint('🔧 EmployeeProvider: Service response success: ${response.success}');

      if (response.success && response.data != null) {
        debugPrint('🔧 EmployeeProvider: Parsing profile data');
        
        try {
          _employee = response.data!.profile;
          _attendanceStats = response.data!.attendanceStats;
          _pettyCashStats = response.data!.pettyCashStats;
          
          debugPrint('✅ EmployeeProvider: Profile parsed successfully');
          debugPrint('   - Employee: ${_employee?.name}');
          debugPrint('   - Attendance Days: ${_attendanceStats?.totalDays}');
          debugPrint('   - Petty Cash Requests: ${_pettyCashStats?.totalRequests}');
          
          _error = null;
          _isInitialized = true;
        } catch (parseError) {
          debugPrint('❌ EmployeeProvider: Profile parsing error: $parseError');
          _error = 'Failed to parse profile data: ${parseError.toString()}';
        }
      } else {
        _error = response.message ?? 'Failed to fetch profile';
        debugPrint('❌ EmployeeProvider: Service error: $_error');
      }
    } catch (e) {
      _error = 'Failed to fetch profile: ${e.toString()}';
      debugPrint('❌ EmployeeProvider: Network error: $e');
    }

    _setLoading(false);
  }

  // Update profile (only email and phone)
  Future<bool> updateProfile({
    String? email,
    String? phone,
  }) async {
    debugPrint('🔧 EmployeeProvider: Starting updateProfile');
    _setLoading(true);
    _error = null;

    try {
      final response = await _employeeService.updateProfile(
        email: email,
        phone: phone,
      );

      if (response.success) {
        // Update local employee data
        if (_employee != null) {
          _employee = _employee!.copyWith(
            email: email ?? _employee!.email,
            phone: phone ?? _employee!.phone,
          );
        }

        _error = null;
        _setLoading(false);
        debugPrint('✅ EmployeeProvider: Profile updated successfully');
        return true;
      } else {
        _error = response.message ?? 'Failed to update profile';
        _setLoading(false);
        debugPrint('❌ EmployeeProvider: Update failed: $_error');
        return false;
      }
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      debugPrint('❌ EmployeeProvider: Update error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Update employee data locally (for auth updates)
  void updateEmployee(Employee updatedEmployee) {
    _employee = updatedEmployee;
    _safeNotifyListeners();
    debugPrint('🔧 EmployeeProvider: Employee data updated locally');
  }

  // Get employee basic info
  Map<String, String?> getBasicInfo() {
    if (_employee == null) return {};
    
    return {
      'name': _employee!.name,
      'employeeCode': _employee!.employeeCode,
      'email': _employee!.email,
      'phone': _employee!.phone,
      'department': _employee!.departmentName,
      'joiningDate': _employee!.joiningDate,
    };
  }

  // Get work schedule info
  Map<String, String?> getWorkSchedule() {
    if (_employee == null) return {};
    
    return {
      'shiftName': _employee!.shiftName,
      'startTime': _employee!.startTime,
      'endTime': _employee!.endTime,
      'siteName': _employee!.siteName,
      'siteAddress': _employee!.siteAddress,
    };
  }

  // Get salary info
  Map<String, double?> getSalaryInfo() {
    if (_employee == null) return {};
    
    return {
      'basicSalary': _employee!.basicSalary,
      'dailyWage': _employee!.dailyWage,
    };
  }

  // Get attendance performance
  double get attendancePercentage {
    if (_attendanceStats == null || _attendanceStats!.totalDays == 0) return 0.0;
    return (_attendanceStats!.approvedDays / _attendanceStats!.totalDays) * 100;
  }

  // Get average working hours
  double get averageWorkingHours {
    if (_attendanceStats == null || _attendanceStats!.approvedDays == 0) return 0.0;
    return _attendanceStats!.totalHours / _attendanceStats!.approvedDays;
  }

  // Clear error
  void clearError() {
    _error = null;
    _safeNotifyListeners();
  }

  // Reset data
  void reset() {
    _employee = null;
    _attendanceStats = null;
    _pettyCashStats = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    _safeNotifyListeners();
    debugPrint('🔧 EmployeeProvider: Data reset');
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

  // Initialize data if not already loaded
  Future<void> initializeIfNeeded() async {
    if (!_isInitialized && !_isLoading) {
      debugPrint('🔧 EmployeeProvider: Initializing profile data');
      await fetchProfile();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    debugPrint('🔧 EmployeeProvider: Refreshing profile data');
    _isInitialized = false;
    await fetchProfile();
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
    debugPrint('🔧 EmployeeProvider State:');
    debugPrint('  - Employee: ${_employee?.name ?? 'None'}');
    debugPrint('  - Loading: $_isLoading');
    debugPrint('  - Error: $_error');
    debugPrint('  - Initialized: $_isInitialized');
    debugPrint('  - Attendance Days: ${_attendanceStats?.totalDays ?? 'N/A'}');
    debugPrint('  - Petty Cash Requests: ${_pettyCashStats?.totalRequests ?? 'N/A'}');
  }
}