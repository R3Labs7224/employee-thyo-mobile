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