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