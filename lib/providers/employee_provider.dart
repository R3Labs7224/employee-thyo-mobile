// lib/providers/employee_provider.dart
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

  // Getters
  Employee? get employee => _employee;
  AttendanceStats? get attendanceStats => _attendanceStats;
  PettyCashStats? get pettyCashStats => _pettyCashStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch employee profile with stats
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _employeeService.getProfile();

      if (response.success && response.data != null) {
        _employee = response.data!.profile;
        _attendanceStats = response.data!.attendanceStats;
        _pettyCashStats = response.data!.pettyCashStats;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch profile: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update profile (only email and phone)
  Future<bool> updateProfile({
    String? email,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _employeeService.updateProfile(
        email: email,
        phone: phone,
      );

      if (response.success) {
        // Update local employee data
        if (_employee != null) {
          _employee = Employee(
            id: _employee!.id,
            employeeCode: _employee!.employeeCode,
            name: _employee!.name,
            email: email ?? _employee!.email,
            phone: phone ?? _employee!.phone,
            basicSalary: _employee!.basicSalary,
            dailyWage: _employee!.dailyWage,
            joiningDate: _employee!.joiningDate,
            departmentName: _employee!.departmentName,
            shiftName: _employee!.shiftName,
            startTime: _employee!.startTime,
            endTime: _employee!.endTime,
            siteName: _employee!.siteName,
            siteAddress: _employee!.siteAddress,
          );
        }

        _error = null;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to update profile: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update employee data locally (for auth updates)
  void updateEmployee(Employee updatedEmployee) {
    _employee = updatedEmployee;
    notifyListeners();
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
    notifyListeners();
  }

  // Reset data
  void reset() {
    _employee = null;
    _attendanceStats = null;
    _pettyCashStats = null;
    _error = null;
    notifyListeners();
  }
}