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
  final double? basicSalary;
  final double? dailyWage;
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
      basicSalary: json['basic_salary']?.toDouble(),
      dailyWage: json['daily_wage']?.toDouble(),
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
      'daily_wage': dailyWage,
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
      monthlyStats: MonthlyStats.fromJson(json['monthly_stats']),
      pendingPettyCash: json['pending_petty_cash'].toDouble(),
      activeTasks: json['active_tasks'],
      permissions: Permissions.fromJson(json['permissions']),
    );
  }
}

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
      totalDays: json['total_days'],
      approvedDays: json['approved_days'],
      totalHours: json['total_hours'].toDouble(),
    );
  }
}

class Permissions {
  final bool canCheckin;
  final bool canCheckout;
  final bool canCreateTask;

  Permissions({
    required this.canCheckin,
    required this.canCheckout,
    required this.canCreateTask,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      canCheckin: json['can_checkin'],
      canCheckout: json['can_checkout'],
      canCreateTask: json['can_create_task'],
    );
  }
}
