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
      id: json['id'] ?? 0,
      employeeId: json['employee_id'] ?? 0,
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      basicSalary: (json['basic_salary'] ?? 0).toDouble(),
      totalWorkingDays: json['total_working_days'] ?? 0,
      presentDays: json['present_days'] ?? 0,
      calculatedSalary: (json['calculated_salary'] ?? json['gross_salary'] ?? 0).toDouble(),
      totalHours: (json['total_hours'] ?? 0).toDouble(),
      bonus: (json['bonus'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      netSalary: (json['net_salary'] ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      generatedDate: json['generated_date'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
    );
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
      totalDays: json['total_days'] ?? 0,
      approvedDays: json['approved_days'] ?? 0,
      pendingDays: json['pending_days'] ?? 0,
      totalHours: (json['total_hours'] ?? 0).toDouble(),
    );
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
      basicSalary: (json['basic_salary'] ?? 0).toDouble(),
      dailyWage: (json['daily_wage'] ?? 0).toDouble(),
      name: json['name'] ?? '',
      employeeCode: json['employee_code'] ?? '',
      departmentName: json['department_name'] ?? 'No Department',
      epfNumber: json['epf_number'],
    );
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
      totalEarned: (json['total_earned'] ?? 0).toDouble(),
      totalDeductions: (json['total_deductions'] ?? 0).toDouble(),
      totalBonus: (json['total_bonus'] ?? 0).toDouble(),
      totalMonths: json['total_months'] ?? 0,
      avgMonthlySalary: (json['avg_monthly_salary'] ?? 0).toDouble(),
    );
  }
}