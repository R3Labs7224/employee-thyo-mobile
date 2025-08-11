// lib/models/salary.dart
class SalarySlip {
  final int id;
  final int employeeId;
  final int month;
  final int year;
  final double basicSalary;
  final int presentDays;
  final int totalWorkingDays;
  final double grossSalary;
  final double deductions;
  final double bonus;
  final double advance;
  final double netSalary;
  final String? generatedDate;
  final String? employeeName;
  final String? employeeCode;
  final double? currentBasicSalary;
  final String? departmentName;
  final String? createdAt;

  SalarySlip({
    required this.id,
    required this.employeeId,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.presentDays,
    required this.totalWorkingDays,
    required this.grossSalary,
    required this.deductions,
    required this.bonus,
    required this.advance,
    required this.netSalary,
    this.generatedDate,
    this.employeeName,
    this.employeeCode,
    this.currentBasicSalary,
    this.departmentName,
    this.createdAt,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: json['id'],
      employeeId: json['employee_id'],
      month: json['month'],
      year: json['year'],
      basicSalary: (json['basic_salary'] ?? 0).toDouble(),
      presentDays: json['present_days'] ?? 0,
      totalWorkingDays: json['total_working_days'] ?? 0,
      grossSalary: (json['gross_salary'] ?? 0).toDouble(),
      deductions: (json['deductions'] ?? 0).toDouble(),
      bonus: (json['bonus'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      netSalary: (json['net_salary'] ?? 0).toDouble(),
      generatedDate: json['generated_date'],
      employeeName: json['employee_name'],
      employeeCode: json['employee_code'],
      currentBasicSalary: json['current_basic_salary']?.toDouble(),
      departmentName: json['department_name'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'month': month,
      'year': year,
      'basic_salary': basicSalary,
      'present_days': presentDays,
      'total_working_days': totalWorkingDays,
      'gross_salary': grossSalary,
      'deductions': deductions,
      'bonus': bonus,
      'advance': advance,
      'net_salary': netSalary,
      'generated_date': generatedDate,
      'employee_name': employeeName,
      'employee_code': employeeCode,
      'current_basic_salary': currentBasicSalary,
      'department_name': departmentName,
      'created_at': createdAt,
    };
  }

  String get monthName {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month];
  }
}

class SalaryResponse {
  final List<SalarySlip> salarySlips;
  final CurrentMonthSummary? currentMonthSummary;

  SalaryResponse({
    required this.salarySlips,
    this.currentMonthSummary,
  });

  factory SalaryResponse.fromJson(Map<String, dynamic> json) {
    return SalaryResponse(
      salarySlips: (json['salary_slips'] as List)
          .map((item) => SalarySlip.fromJson(item))
          .toList(),
      currentMonthSummary: json['current_month_summary'] != null
          ? CurrentMonthSummary.fromJson(json['current_month_summary'])
          : null,
    );
  }
}

class CurrentMonthSummary {
  final int totalDays;
  final int approvedDays;
  final int pendingDays;
  final double totalHours;

  CurrentMonthSummary({
    required this.totalDays,
    required this.approvedDays,
    required this.pendingDays,
    required this.totalHours,
  });

  factory CurrentMonthSummary.fromJson(Map<String, dynamic> json) {
    return CurrentMonthSummary(
      totalDays: json['total_days'] ?? 0,
      approvedDays: json['approved_days'] ?? 0,
      pendingDays: json['pending_days'] ?? 0,
      totalHours: (json['total_hours'] ?? 0).toDouble(),
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
}