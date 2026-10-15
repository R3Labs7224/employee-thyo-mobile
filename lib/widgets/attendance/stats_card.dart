// lib/models/attendance_summary.dart - UPDATED: Removed working hours fields
class AttendanceSummary {
  final int totalDays;
  final int approvedDays;
  final int pendingDays;
  final int rejectedDays;

  AttendanceSummary({
    required this.totalDays,
    required this.approvedDays,
    required this.pendingDays,
    required this.rejectedDays,
  });

  // Safe conversion helpers
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    return 0;
  }

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: _safeInt(json['total_days']),
      approvedDays: _safeInt(json['approved_days']),
      pendingDays: _safeInt(json['pending_days']),
      rejectedDays: _safeInt(json['rejected_days']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'approved_days': approvedDays,
      'pending_days': pendingDays,
      'rejected_days': rejectedDays,
    };
  }

  // Calculate attendance percentage
  double get attendancePercentage {
    if (totalDays == 0) return 0.0;
    return (approvedDays / totalDays) * 100;
  }

  // Get attendance rate category
  String get attendanceRating {
    final percentage = attendancePercentage;
    if (percentage >= 95) return 'Excellent';
    if (percentage >= 85) return 'Good';
    if (percentage >= 70) return 'Average';
    if (percentage >= 50) return 'Below Average';
    return 'Poor';
  }

  // Check if employee has perfect attendance
  bool get isPerfectAttendance => approvedDays == totalDays && totalDays > 0;

  // Get total attendance (approved + pending)
  int get totalAttendance => approvedDays + pendingDays;

  // Create empty summary
  factory AttendanceSummary.empty() {
    return AttendanceSummary(
      totalDays: 0,
      approvedDays: 0,
      pendingDays: 0,
      rejectedDays: 0,
    );
  }

  // Create summary from attendance list
  factory AttendanceSummary.fromAttendanceList(List<dynamic> attendanceList) {
    if (attendanceList.isEmpty) {
      return AttendanceSummary.empty();
    }

    int approved = 0;
    int pending = 0;
    int rejected = 0;

    for (var attendance in attendanceList) {
      final status = attendance['status']?.toString().toLowerCase() ?? 'pending';
      switch (status) {
        case 'approved':
          approved++;
          break;
        case 'rejected':
          rejected++;
          break;
        default:
          pending++;
          break;
      }
    }

    return AttendanceSummary(
      totalDays: attendanceList.length,
      approvedDays: approved,
      pendingDays: pending,
      rejectedDays: rejected,
    );
  }
}