// lib/models/employee.dart - COMPLETE REPLACEMENT
import 'dart:convert';

// Helper functions for safe type conversion (MUST be at the top)
int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? 0;
  }
  if (value is double) return value.toInt();
  return 0;
}

double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed ?? 0.0;
  }
  return 0.0;
}

String _safeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

bool _safeBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) {
    return value.toLowerCase() == 'true' || value == '1';
  }
  if (value is int) return value == 1;
  return false;
}

// Main Employee Model
class Employee {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String? departmentId;
  final String? shiftId;
  final String? siteId;
  final double? basicSalary;
  final String? epfNumber;
  final double? dailyWage;
  final String? joiningDate;
  final String status;
  final String? profileImage;
  final String? createdAt;
  final String? updatedAt;
  final String? departmentName;
  final String? shiftName;
  final String? siteName;
  final String? startTime;
  final String? endTime;
  final String? siteAddress;
  final double? siteLatitude;
  final double? siteLongitude;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    this.departmentId,
    this.shiftId,
    this.siteId,
    this.basicSalary,
    this.epfNumber,
    this.dailyWage,
    this.joiningDate,
    this.status = 'active',
    this.profileImage,
    this.createdAt,
    this.updatedAt,
    this.departmentName,
    this.shiftName,
    this.siteName,
    this.startTime,
    this.endTime,
    this.siteAddress,
    this.siteLatitude,
    this.siteLongitude,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: _safeInt(json['id']),
      employeeCode: _safeString(json['employee_code']),
      name: _safeString(json['name']),
      email: _safeString(json['email']),
      phone: _safeString(json['phone']),
      departmentId: json['department_id']?.toString(),
      shiftId: json['shift_id']?.toString(),
      siteId: json['site_id']?.toString(),
      basicSalary: json['basic_salary'] != null ? _safeDouble(json['basic_salary']) : null,
      epfNumber: json['epf_number']?.toString(),
      dailyWage: json['daily_wage'] != null ? _safeDouble(json['daily_wage']) : null,
      joiningDate: json['joining_date']?.toString(),
      status: _safeString(json['status']).isNotEmpty ? _safeString(json['status']) : 'active',
      profileImage: json['profile_image']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      departmentName: json['department_name']?.toString(),
      shiftName: json['shift_name']?.toString(),
      siteName: json['site_name']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      siteAddress: json['site_address']?.toString(),
      siteLatitude: json['site_latitude'] != null ? _safeDouble(json['site_latitude']) : null,
      siteLongitude: json['site_longitude'] != null ? _safeDouble(json['site_longitude']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'department_id': departmentId,
      'shift_id': shiftId,
      'site_id': siteId,
      'basic_salary': basicSalary,
      'epf_number': epfNumber,
      'daily_wage': dailyWage,
      'joining_date': joiningDate,
      'status': status,
      'profile_image': profileImage,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'department_name': departmentName,
      'shift_name': shiftName,
      'site_name': siteName,
      'start_time': startTime,
      'end_time': endTime,
      'site_address': siteAddress,
      'site_latitude': siteLatitude,
      'site_longitude': siteLongitude,
    };
  }

  Employee copyWith({
    int? id,
    String? employeeCode,
    String? name,
    String? email,
    String? phone,
    String? departmentId,
    String? shiftId,
    String? siteId,
    double? basicSalary,
    String? epfNumber,
    double? dailyWage,
    String? joiningDate,
    String? status,
    String? profileImage,
    String? createdAt,
    String? updatedAt,
    String? departmentName,
    String? shiftName,
    String? siteName,
    String? startTime,
    String? endTime,
    String? siteAddress,
    double? siteLatitude,
    double? siteLongitude,
  }) {
    return Employee(
      id: id ?? this.id,
      employeeCode: employeeCode ?? this.employeeCode,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      departmentId: departmentId ?? this.departmentId,
      shiftId: shiftId ?? this.shiftId,
      siteId: siteId ?? this.siteId,
      basicSalary: basicSalary ?? this.basicSalary,
      epfNumber: epfNumber ?? this.epfNumber,
      dailyWage: dailyWage ?? this.dailyWage,
      joiningDate: joiningDate ?? this.joiningDate,
      status: status ?? this.status,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      departmentName: departmentName ?? this.departmentName,
      shiftName: shiftName ?? this.shiftName,
      siteName: siteName ?? this.siteName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      siteAddress: siteAddress ?? this.siteAddress,
      siteLatitude: siteLatitude ?? this.siteLatitude,
      siteLongitude: siteLongitude ?? this.siteLongitude,
    );
  }

  String getInitials() {
    if (name.isEmpty) return 'E';
    List<String> nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    } else {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
  }
}

// Updated LoginResponse - compatible with backend
class LoginResponse {
  final Employee employee;
  final String token;
  final dynamic todayAttendance;
  final MonthlyStats monthlyStats;
  final int pendingPettyCash;
  final int activeTasks;
  final EmployeePermissions permissions;

  LoginResponse({
    required this.employee,
    required this.token,
    this.todayAttendance,
    required this.monthlyStats,
    required this.pendingPettyCash,
    required this.activeTasks,
    required this.permissions,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      employee: Employee.fromJson(json['employee']),
      token: _safeString(json['token']),
      todayAttendance: json['today_attendance'],
      monthlyStats: MonthlyStats.fromJson(json['monthly_stats'] ?? {}),
      pendingPettyCash: _safeInt(json['pending_petty_cash']),
      activeTasks: _safeInt(json['active_tasks']),
      permissions: EmployeePermissions.fromJson(json['permissions'] ?? {}),
    );
  }
}

// Monthly Stats Model
class MonthlyStats {
  final int totalDays;
  final int approvedDays;
  final double totalHours;

  MonthlyStats({
    required this.totalDays,
    required this.approvedDays,
    required this.totalHours,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      totalDays: _safeInt(json['total_days']),
      approvedDays: _safeInt(json['approved_days']),
      totalHours: _safeDouble(json['total_hours']),
    );
  }
}

// Employee Permissions Model
class EmployeePermissions {
  final bool canCheckin;
  final bool canCheckout;
  final bool canCreateTask;

  EmployeePermissions({
    required this.canCheckin,
    required this.canCheckout,
    required this.canCreateTask,
  });

  factory EmployeePermissions.fromJson(Map<String, dynamic> json) {
    return EmployeePermissions(
      canCheckin: _safeBool(json['can_checkin']),
      canCheckout: _safeBool(json['can_checkout']),
      canCreateTask: _safeBool(json['can_create_task']),
    );
  }
}

// Profile Response Model - for profile endpoint
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
      attendanceStats: AttendanceStats.fromJson(json['attendance_stats'] ?? {}),
      pettyCashStats: PettyCashStats.fromJson(json['petty_cash_stats'] ?? {}),
    );
  }
}

// Attendance Stats Model - for profile endpoint
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
      totalDays: _safeInt(json['total_days']),
      approvedDays: _safeInt(json['approved_days']),
      totalHours: _safeDouble(json['total_hours']),
    );
  }
}

// Petty Cash Stats Model - for profile endpoint
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
      totalRequests: _safeInt(json['total_requests']),
      approvedAmount: _safeDouble(json['approved_amount']),
      pendingAmount: _safeDouble(json['pending_amount']),
    );
  }
}