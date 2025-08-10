import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class EmployeeProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  Employee? _employee;
  MonthlyStats? _monthlyStats;
  PettyCashStats? _pettyCashStats;
  AttendanceStats? _attendanceStats;
  bool _isLoading = false;
  String? _error;

  // Getters
  Employee? get employee => _employee;
  MonthlyStats? get monthlyStats => _monthlyStats;
  PettyCashStats? get pettyCashStats => _pettyCashStats;
  AttendanceStats? get attendanceStats => _attendanceStats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch employee profile
  Future<void> fetchProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.get<ProfileResponse>(
        AppConfig.profileEndpoint,
        fromJson: (data) => ProfileResponse.fromJson(data),
      );

      if (response.success && response.data != null) {
        _employee = response.data!.profile;
        _attendanceStats = response.data!.attendanceStats;
        _pettyCashStats = response.data!.pettyCashStats;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch profile: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Update employee profile
  Future<bool> updateProfile({
    required String email,
    required String phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.put(
        AppConfig.profileEndpoint,
        {
          'email': email,
          'phone': phone,
        },
      );

      if (response.success) {
        // Update local employee data
        if (_employee != null) {
          _employee = Employee(
            id: _employee!.id,
            employeeCode: _employee!.employeeCode,
            name: _employee!.name,
            email: email,
            phone: phone,
            departmentName: _employee!.departmentName,
            shiftName: _employee!.shiftName,
            startTime: _employee!.startTime,
            endTime: _employee!.endTime,
            siteName: _employee!.siteName,
            siteAddress: _employee!.siteAddress,
            siteLatitude: _employee!.siteLatitude,
            siteLongitude: _employee!.siteLongitude,
            basicSalary: _employee!.basicSalary,
            dailyWage: _employee!.dailyWage,
            joiningDate: _employee!.joiningDate,
          );
        }
        
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

  // Set employee data (used by AuthProvider after login)
  void setEmployee(Employee employee) {
    _employee = employee;
    notifyListeners();
  }

  // Set monthly stats (used by AuthProvider after login)
  void setMonthlyStats(MonthlyStats stats) {
    _monthlyStats = stats;
    notifyListeners();
  }

  // Clear employee data (used during logout)
  void clearEmployeeData() {
    _employee = null;
    _monthlyStats = null;
    _pettyCashStats = null;
    _attendanceStats = null;
    _error = null;
    notifyListeners();
  }

  // Get employee's work shift information
  WorkShiftInfo? get workShiftInfo {
    if (_employee == null) return null;
    
    return WorkShiftInfo(
      shiftName: _employee!.shiftName,
      startTime: _employee!.startTime,
      endTime: _employee!.endTime,
    );
  }

  // Get employee's site information
  SiteInfo? get siteInfo {
    if (_employee == null) return null;
    
    return SiteInfo(
      siteName: _employee!.siteName,
      siteAddress: _employee!.siteAddress,
      latitude: _employee!.siteLatitude,
      longitude: _employee!.siteLongitude,
    );
  }

  // Get employee's salary information
  SalaryInfo? get salaryInfo {
    if (_employee == null) return null;
    
    return SalaryInfo(
      basicSalary: _employee!.basicSalary,
      dailyWage: _employee!.dailyWage,
    );
  }

  // Check if employee data is available
  bool get hasEmployeeData => _employee != null;

  // Get employee's full name with code
  String get employeeDisplayName {
    if (_employee == null) return 'Unknown Employee';
    return '${_employee!.name} (${_employee!.employeeCode})';
  }

  // Get employee initials for avatar
  String get employeeInitials {
    if (_employee == null || _employee!.name.isEmpty) return 'E';
    
    final nameParts = _employee!.name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  // Validate if employee can perform certain actions
  bool canPerformLocationBasedActions() {
    return _employee != null && 
           _employee!.siteLatitude != 0 && 
           _employee!.siteLongitude != 0;
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh employee data
  Future<void> refreshEmployeeData() async {
    await fetchProfile();
  }
}

// Additional models for employee provider
class ProfileResponse {
  final Employee profile;
  final AttendanceStats attendanceStats;
  final PettyCashStats pettyCashStats;

  ProfileResponse({
    required this.profile,
    required this.attendanceStats,
    required this.pettyCashStats,
  });

  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    return ProfileResponse(
      profile: Employee.fromJson(json['profile']),
      attendanceStats: AttendanceStats.fromJson(json['attendance_stats']),
      pettyCashStats: PettyCashStats.fromJson(json['petty_cash_stats']),
    );
  }
}

class AttendanceStats {
  final int totalDays;
  final int approvedDays;
  final double totalHours;

  AttendanceStats({
    required this.totalDays,
    required this.approvedDays,
    required this.totalHours,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalDays: json['total_days'],
      approvedDays: json['approved_days'],
      totalHours: json['total_hours'].toDouble(),
    );
  }
}

class PettyCashStats {
  final int totalRequests;
  final double approvedAmount;
  final double pendingAmount;

  PettyCashStats({
    required this.totalRequests,
    required this.approvedAmount,
    required this.pendingAmount,
  });

  factory PettyCashStats.fromJson(Map<String, dynamic> json) {
    return PettyCashStats(
      totalRequests: json['total_requests'],
      approvedAmount: json['approved_amount'].toDouble(),
      pendingAmount: json['pending_amount'].toDouble(),
    );
  }
}

class WorkShiftInfo {
  final String shiftName;
  final String startTime;
  final String endTime;

  WorkShiftInfo({
    required this.shiftName,
    required this.startTime,
    required this.endTime,
  });

  // Parse time string to Duration
  Duration get startDuration {
    final parts = startTime.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
    );
  }

  Duration get endDuration {
    final parts = endTime.split(':');
    return Duration(
      hours: int.parse(parts[0]),
      minutes: int.parse(parts[1]),
    );
  }

  // Calculate shift duration
  Duration get shiftDuration {
    return endDuration - startDuration;
  }

  // Get formatted shift time
  String get formattedShiftTime => '$startTime - $endTime';
}

class SiteInfo {
  final String siteName;
  final String siteAddress;
  final double latitude;
  final double longitude;

  SiteInfo({
    required this.siteName,
    required this.siteAddress,
    required this.latitude,
    required this.longitude,
  });

  // Get formatted coordinates
  String get formattedCoordinates => '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

class SalaryInfo {
  final double? basicSalary;
  final double? dailyWage;

  SalaryInfo({
    this.basicSalary,
    this.dailyWage,
  });

  // Check if employee has basic salary
  bool get hasBasicSalary => basicSalary != null && basicSalary! > 0;

  // Check if employee has daily wage
  bool get hasDailyWage => dailyWage != null && dailyWage! > 0;

  // Get primary salary type
  String get salaryType {
    if (hasBasicSalary) return 'Monthly Salary';
    if (hasDailyWage) return 'Daily Wage';
    return 'Not Set';
  }

  // Get primary salary amount
  double get primarySalaryAmount {
    if (hasBasicSalary) return basicSalary!;
    if (hasDailyWage) return dailyWage!;
    return 0.0;
  }
}
