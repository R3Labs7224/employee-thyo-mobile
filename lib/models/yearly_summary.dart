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