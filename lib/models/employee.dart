import 'package:ems/models/attendance.dart';

class Employee {
  final String id;
  final String employeeCode;
  final String name;
  final String email;
  final String phone;
  final String departmentName;
  final String shiftName;
  final String startTime;
  final String endTime;
  final String siteName;
  final String siteAddress;
  final double siteLatitude;
  final double siteLongitude;
  final String? basicSalary;
  final String? dailyWage;
  final String? joiningDate;

  Employee({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.phone,
    required this.departmentName,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    required this.siteName,
    required this.siteAddress,
    required this.siteLatitude,
    required this.siteLongitude,
    this.basicSalary,
    this.dailyWage,
    this.joiningDate,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      employeeCode: json['employee_code'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      departmentName: json['department_id'],
      shiftName: json['shift_id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      siteName: json['site_id'],
      siteAddress: json['site_address'],
      siteLatitude: json['site_latitude'].toDouble(),
      siteLongitude: json['site_longitude'].toDouble(),
      basicSalary: json['basic_salary'],
      dailyWage: json['daily_wage'],
      joiningDate: json['joining_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_code': employeeCode,
      'name': name,
      'email': email,
      'phone': phone,
      'department_name': departmentName,
      'shift_name': shiftName,
      'start_time': startTime,
      'end_time': endTime,
      'site_name': siteName,
      'site_address': siteAddress,
      'site_latitude': siteLatitude,
      'site_longitude': siteLongitude,
      'basic_salary': basicSalary,
      'daily_wage': dailyWage??"0",
      'joining_date': joiningDate,
    };
  }
}

class LoginResponse {
  final Employee employee;
  final String token;
  final Attendance? todayAttendance;
  final MonthlyStats monthlyStats;
  final double pendingPettyCash;
  final int activeTasks;
  final Permissions permissions;

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
      token: json['token'],
      todayAttendance: json['today_attendance'] != null 
          ? Attendance.fromJson(json['today_attendance'])
          : null,
      monthlyStats: MonthlyStats.fromJson(json['monthly_stats'] ?? {}),
      pendingPettyCash: (json['pending_petty_cash'] ?? 0.0).toDouble(),
      activeTasks: json['active_tasks'] ?? 0,
      permissions: Permissions.fromJson(json['permissions'] ?? {}),
    );
  }
}

class MonthlyStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final double totalOvertime;
  final double attendancePercentage;

  MonthlyStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.totalOvertime,
    required this.attendancePercentage,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      totalDays: json['total_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      absentDays: json['absent_days'] ?? 0,
      lateDays: json['late_days'] ?? 0,
      totalOvertime: (json['total_overtime'] ?? 0.0).toDouble(),
      attendancePercentage: (json['attendance_percentage'] ?? 0.0).toDouble(),
    );
  }
}

class Permissions {
  final bool canCheckIn;
  final bool canCheckOut;
  final bool canViewAttendance;
  final bool canCreateTasks;
  final bool canRequestPettyCash;
  final bool canViewSalary;
  final bool canEditProfile;

  Permissions({
    required this.canCheckIn,
    required this.canCheckOut,
    required this.canViewAttendance,
    required this.canCreateTasks,
    required this.canRequestPettyCash,
    required this.canViewSalary,
    required this.canEditProfile,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      canCheckIn: json['can_check_in'] ?? false,
      canCheckOut: json['can_check_out'] ?? false,
      canViewAttendance: json['can_view_attendance'] ?? false,
      canCreateTasks: json['can_create_tasks'] ?? false,
      canRequestPettyCash: json['can_request_petty_cash'] ?? false,
      canViewSalary: json['can_view_salary'] ?? false,
      canEditProfile: json['can_edit_profile'] ?? false,
    );
  }
}


