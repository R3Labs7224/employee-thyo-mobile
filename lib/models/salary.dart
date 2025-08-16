// lib/models/salary.dart

// Helper functions for safe type conversion
int _safeInt(dynamic value) => value is int ? value : int.tryParse(value?.toString() ?? '0') ?? 0;
double _safeDouble(dynamic value) => value is double ? value : double.tryParse(value?.toString() ?? '0.0') ?? 0.0;
String _safeString(dynamic value) => value?.toString() ?? '';
bool _safeBool(dynamic value) => value is bool ? value : (value?.toString().toLowerCase() == 'true');

// lib/models/salary_slip.dart
class SalarySlip {
  final int id;
  final int employeeId;
  final int month;
  final int year;
  final double basicSalary;
  final int totalWorkingDays;
  final int presentDays;
  final double calculatedSalary;
  final double totalHours;
  final double bonus;
  final double advance;
  final double deductions;
  final double netSalary;
  final String status;
  final String? generatedDate;
  final DateTime createdAt;
  final String? employeeName;
  final String? employeeCode;

  SalarySlip({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.calculatedSalary,
    required this.totalHours,
    required this.bonus,
    required this.advance,
    required this.deductions,
    required this.netSalary,
    required this.status,
    this.generatedDate,
    required this.createdAt,
    this.employeeName,
    this.employeeCode,
  });

  // Getter for UI compatibility
  double get grossSalary => calculatedSalary;

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: _safeInt(json['id']),
      employeeId: _safeInt(json['employee_id']),
      month: _safeInt(json['month']),
      year: _safeInt(json['year']),
      basicSalary: _safeDouble(json['basic_salary']),
      totalWorkingDays: _safeInt(json['total_working_days']),
      presentDays: _safeInt(json['present_days']),
      calculatedSalary: _safeDouble(json['calculated_salary'] ?? json['gross_salary']),
      totalHours: _safeDouble(json['total_hours']),
      bonus: _safeDouble(json['bonus']),
      advance: _safeDouble(json['advance']),
      deductions: _safeDouble(json['deductions']),
      netSalary: _safeDouble(json['net_salary']),
      status: _safeString(json['status']).isEmpty ? 'draft' : _safeString(json['status']),
      generatedDate: json['generated_date']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      employeeName: json['employee_name']?.toString(),
      employeeCode: json['employee_code']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'month': month,
      'year': year,
      'basic_salary': basicSalary,
      'total_working_days': totalWorkingDays,
      'present_days': presentDays,
      'calculated_salary': calculatedSalary,
      'gross_salary': grossSalary,
      'total_hours': totalHours,
      'bonus': bonus,
      'advance': advance,
      'deductions': deductions,
      'net_salary': netSalary,
      'status': status,
      'generated_date': generatedDate,
      'created_at': createdAt.toIso8601String(),
      'employee_name': employeeName,
      'employee_code': employeeCode,
    };
  }
}

// Helper function to safely parse DateTime
DateTime _parseDateTime(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is DateTime) return value;
  
  try {
    return DateTime.parse(value.toString());
  } catch (e) {
    return DateTime.now();
  }
}

// lib/models/attendance_summary.dart
class AttendanceSummary {
  final int totalDays;
  final int approvedDays;
  final int pendingDays;
  final double totalHours;

  AttendanceSummary({
    required this.totalDays,
    required this.approvedDays,
    required this.pendingDays,
    required this.totalHours,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: _safeInt(json['total_days']),
      approvedDays: _safeInt(json['approved_days']),
      pendingDays: _safeInt(json['pending_days']),
      totalHours: _safeDouble(json['total_hours']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'approved_days': approvedDays,
      'pending_days': pendingDays,
      'total_hours': totalHours,
    };
  }

  double get attendancePercentage {
    if (totalDays == 0) return 0.0;
    return (approvedDays / totalDays) * 100;
  }
}

// lib/models/employee_info.dart
class EmployeeInfo {
  final double basicSalary;
  final double dailyWage;
  final String name;
  final String employeeCode;
  final String departmentName;
  final String? epfNumber;

  EmployeeInfo({
    required this.basicSalary,
    required this.dailyWage,
    required this.name,
    required this.employeeCode,
    required this.departmentName,
    this.epfNumber,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      basicSalary: _safeDouble(json['basic_salary']),
      dailyWage: _safeDouble(json['daily_wage']),
      name: _safeString(json['name']),
      employeeCode: _safeString(json['employee_code']),
      departmentName: _safeString(json['department_name']),
      epfNumber: json['epf_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basic_salary': basicSalary,
      'daily_wage': dailyWage,
      'name': name,
      'employee_code': employeeCode,
      'department_name': departmentName,
      'epf_number': epfNumber,
    };
  }
}

// lib/models/yearly_summary.dart
class YearlySummary {
  final double totalEarned;
  final double totalDeductions;
  final double totalBonus;
  final int totalMonths;
  final double avgMonthlySalary;

  YearlySummary({
    required this.totalEarned,
    required this.totalDeductions,
    required this.totalBonus,
    required this.totalMonths,
    required this.avgMonthlySalary,
  });

  factory YearlySummary.fromJson(Map<String, dynamic> json) {
    return YearlySummary(
      totalEarned: _safeDouble(json['total_earned']),
      totalDeductions: _safeDouble(json['total_deductions']),
      totalBonus: _safeDouble(json['total_bonus']),
      totalMonths: _safeInt(json['total_months']),
      avgMonthlySalary: _safeDouble(json['avg_monthly_salary']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_earned': totalEarned,
      'total_deductions': totalDeductions,
      'total_bonus': totalBonus,
      'total_months': totalMonths,
      'avg_monthly_salary': avgMonthlySalary,
    };
  }
}