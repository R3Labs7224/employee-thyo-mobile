class SalarySlip {
  final int id;
  final int month;
  final int year;
  final double basicSalary;
  final int totalWorkingDays;
  final int presentDays;
  final double calculatedSalary;
  final double bonus;
  final double advance;
  final double deductions;
  final double netSalary;
  final String status;
  final String generatedDate;

  SalarySlip({
    required this.id,
    required this.month,
    required this.year,
    required this.basicSalary,
    required this.totalWorkingDays,
    required this.presentDays,
    required this.calculatedSalary,
    required this.bonus,
    required this.advance,
    required this.deductions,
    required this.netSalary,
    required this.status,
    required this.generatedDate,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      id: json['id'],
      month: json['month'],
      year: json['year'],
      basicSalary: json['basic_salary'].toDouble(),
      totalWorkingDays: json['total_working_days'],
      presentDays: json['present_days'],
      calculatedSalary: json['calculated_salary'].toDouble(),
      bonus: json['bonus'].toDouble(),
      advance: json['advance'].toDouble(),
      deductions: json['deductions'].toDouble(),
      netSalary: json['net_salary'].toDouble(),
      status: json['status'],
      generatedDate: json['generated_date'],
    );
  }
}

class SalaryResponse {
  final List<SalarySlip> salarySlips;
  final CurrentMonthAttendance currentMonthAttendance;
  final double estimatedCurrentSalary;
  final YearlySummary yearlySummary;
  final EmployeeInfo employeeInfo;

  SalaryResponse({
    required this.salarySlips,
    required this.currentMonthAttendance,
    required this.estimatedCurrentSalary,
    required this.yearlySummary,
    required this.employeeInfo,
  });

  factory SalaryResponse.fromJson(Map<String, dynamic> json) {
    return SalaryResponse(
      salarySlips: (json['salary_slips'] as List)
          .map((item) => SalarySlip.fromJson(item))
          .toList(),
      currentMonthAttendance: CurrentMonthAttendance.fromJson(json['current_month_attendance']),
      estimatedCurrentSalary: json['estimated_current_salary'].toDouble(),
      yearlySummary: YearlySummary.fromJson(json['yearly_summary']),
      employeeInfo: EmployeeInfo.fromJson(json['employee_info']),
    );
  }
}

class CurrentMonthAttendance {
  final int totalDays;
  final int approvedDays;
  final int pendingDays;
  final double totalHours;

  CurrentMonthAttendance({
    required this.totalDays,
    required this.approvedDays,
    required this.pendingDays,
    required this.totalHours,
  });

  factory CurrentMonthAttendance.fromJson(Map<String, dynamic> json) {
    return CurrentMonthAttendance(
      totalDays: json['total_days'],
      approvedDays: json['approved_days'],
      pendingDays: json['pending_days'],
      totalHours: json['total_hours'].toDouble(),
    );
  }
}

class YearlySummary {
  final double totalEarned;
  final int monthsPaid;
  final double avgMonthlySalary;

  YearlySummary({
    required this.totalEarned,
    required this.monthsPaid,
    required this.avgMonthlySalary,
  });

  factory YearlySummary.fromJson(Map<String, dynamic> json) {
    return YearlySummary(
      totalEarned: json['total_earned'].toDouble(),
      monthsPaid: json['months_paid'],
      avgMonthlySalary: json['avg_monthly_salary'].toDouble(),
    );
  }
}

class EmployeeInfo {
  final double basicSalary;
  final double dailyWage;
  final String? epfNumber;

  EmployeeInfo({
    required this.basicSalary,
    required this.dailyWage,
    this.epfNumber,
  });

  factory EmployeeInfo.fromJson(Map<String, dynamic> json) {
    return EmployeeInfo(
      basicSalary: json['basic_salary'].toDouble(),
      dailyWage: json['daily_wage'].toDouble(),
      epfNumber: json['epf_number'],
    );
  }
}
