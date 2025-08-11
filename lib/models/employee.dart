// lib/models/employee.dart
class Employee {
  final int id;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final double? basicSalary;
  final double? dailyWage;
  final String? joiningDate;
  final String? departmentName;
  final String? shiftName;
  final String? startTime;
  final String? endTime;
  final String? siteName;
  final String? siteAddress;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    this.basicSalary,
    this.dailyWage,
    this.joiningDate,
    this.departmentName,
    this.shiftName,
    this.startTime,
    this.endTime,
    this.siteName,
    this.siteAddress,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      employeeCode: json['employee_code'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      basicSalary: json['basic_salary'] != null ? double.tryParse(json['basic_salary'].toString()) : null,
      dailyWage: json['daily_wage'] != null ? double.tryParse(json['daily_wage'].toString()) : null,
      joiningDate: json['joining_date'],
      departmentName: json['department_name'],
      shiftName: json['shift_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      siteName: json['site_name'],
      siteAddress: json['site_address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'basic_salary': basicSalary,
      'daily_wage': dailyWage,
      'joining_date': joiningDate,
      'department_name': departmentName,
      'shift_name': shiftName,
      'start_time': startTime,
      'end_time': endTime,
      'site_name': siteName,
      'site_address': siteAddress,
    };
  }
}

class LoginResponse {
  final Employee employee;
  final String token;

  LoginResponse({
    required this.employee,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      employee: Employee.fromJson(json['employee']),
      token: json['token'],
    );
  }
}

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
      totalDays: json['total_days'] ?? 0,
      approvedDays: json['approved_days'] ?? 0,
      totalHours: (json['total_hours'] ?? 0).toDouble(),
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
      totalRequests: json['total_requests'] ?? 0,
      approvedAmount: (json['approved_amount'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
    );
  }
}