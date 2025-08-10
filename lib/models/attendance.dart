import 'package:ems/models/employee.dart';

class Attendance {
  final int? id;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final double? workingHours;
  final String? status;
  final String? siteName;
  final String? checkInSelfie;

  Attendance({
    this.id,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
    this.status,
    this.siteName,
    this.checkInSelfie,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'],
      date: json['date'],
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
      workingHours: json['working_hours']?.toDouble(),
      status: json['status'],
      siteName: json['site_name'],
      checkInSelfie: json['check_in_selfie'],
    );
  }
}

class AttendanceResponse {
  final List<Attendance> attendance;
  final AttendanceSummary summary;
  final TodayAttendance today;
  final Permissions permissions;

  AttendanceResponse({
    required this.attendance,
    required this.summary,
    required this.today,
    required this.permissions,
  });

  factory AttendanceResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceResponse(
      attendance: (json['attendance'] as List)
          .map((item) => Attendance.fromJson(item))
          .toList(),
      summary: AttendanceSummary.fromJson(json['summary']),
      today: TodayAttendance.fromJson(json['today']),
      permissions: Permissions.fromJson(json['permissions']),
    );
  }
}

class AttendanceSummary {
  final int totalDays;
  final int approvedDays;
  final int pendingDays;
  final int rejectedDays;
  final double totalHours;
  final double avgHours;

  AttendanceSummary({
    required this.totalDays,
    required this.approvedDays,
    required this.pendingDays,
    required this.rejectedDays,
    required this.totalHours,
    required this.avgHours,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: json['total_days'],
      approvedDays: json['approved_days'],
      pendingDays: json['pending_days'],
      rejectedDays: json['rejected_days'],
      totalHours: json['total_hours'].toDouble(),
      avgHours: json['avg_hours'].toDouble(),
    );
  }
}

class TodayAttendance {
  final String? checkInTime;
  final String? checkOutTime;

  TodayAttendance({
    this.checkInTime,
    this.checkOutTime,
  });

  factory TodayAttendance.fromJson(Map<String, dynamic> json) {
    return TodayAttendance(
      checkInTime: json['check_in_time'],
      checkOutTime: json['check_out_time'],
    );
  }
}
