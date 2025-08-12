// lib/models/attendance.dart
// Helper functions for safe type conversion
int? _safeIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed;
  }
  if (value is double) return value.toInt();
  return null;
}

int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    final parsed = int.tryParse(value);
    return parsed ?? 0;
  }
  if (value is double) return value.toInt();
  return 0;
}

double? _safeDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final parsed = double.tryParse(value);
    return parsed;
  }
  return null;
}

String _safeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

class Attendance {
  final int? id;
  final int? employeeId;
  final int? siteId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String? checkInSelfie;
  final double? workingHours;
  final String status;
  final String? siteName;
  final String? createdAt;

  Attendance({
    this.id,
    this.employeeId,
    this.siteId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkInSelfie,
    this.workingHours,
    this.status = 'pending',
    this.siteName,
    this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: _safeIntNullable(json['id']), // Fixed: Use safe conversion
      employeeId: _safeIntNullable(json['employee_id']), // Fixed
      siteId: _safeIntNullable(json['site_id']), // Fixed
      date: _safeString(json['date']),
      checkInTime: json['check_in_time']?.toString(),
      checkOutTime: json['check_out_time']?.toString(),
      checkInLatitude: _safeDouble(json['check_in_latitude']),
      checkInLongitude: _safeDouble(json['check_in_longitude']),
      checkOutLatitude: _safeDouble(json['check_out_latitude']),
      checkOutLongitude: _safeDouble(json['check_out_longitude']),
      checkInSelfie: json['check_in_selfie']?.toString(),
      workingHours: _safeDouble(json['working_hours']),
      status: _safeString(json['status']).isNotEmpty ? _safeString(json['status']) : 'pending',
      siteName: json['site_name']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'site_id': siteId,
      'date': date,
      'check_in_time': checkInTime,
      'check_out_time': checkOutTime,
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'check_in_selfie': checkInSelfie,
      'working_hours': workingHours,
      'status': status,
      'site_name': siteName,
      'created_at': createdAt,
    };
  }

  bool get isCheckedIn => checkInTime != null;
  bool get isCheckedOut => checkOutTime != null;
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

// Check-in/Check-out request model
class AttendanceRequest {
  final String action; // 'check_in' or 'check_out'
  final int siteId;
  final double latitude;
  final double longitude;
  final String? selfie; // base64 encoded image

  AttendanceRequest({
    required this.action,
    required this.siteId,
    required this.latitude,
    required this.longitude,
    this.selfie,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'site_id': siteId,
      'latitude': latitude,
      'longitude': longitude,
      if (selfie != null) 'selfie': selfie,
    };
  }
}

// Check-in/Check-out response model
class AttendanceActionResponse {
  final int attendanceId;
  final String date;
  final String? checkInTime;
  final String? checkOutTime;
  final String siteName;

  AttendanceActionResponse({
    required this.attendanceId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    required this.siteName,
  });

  factory AttendanceActionResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceActionResponse(
      attendanceId: _safeInt(json['attendance_id']), // Fixed: Use safe conversion
      date: _safeString(json['date']),
      checkInTime: json['check_in_time']?.toString(),
      checkOutTime: json['check_out_time']?.toString(),
      siteName: _safeString(json['site_name']),
    );
  }
}

// Attendance summary model for statistics
class AttendanceSummary {
  final int totalDays;
  final int approvedDays;
  final int pendingDays;
  final int rejectedDays;
  final double totalHours;
  final double averageHours;

  AttendanceSummary({
    required this.totalDays,
    required this.approvedDays,
    required this.pendingDays,
    required this.rejectedDays,
    required this.totalHours,
    required this.averageHours,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      totalDays: _safeInt(json['total_days']),
      approvedDays: _safeInt(json['approved_days']),
      pendingDays: _safeInt(json['pending_days']),
      rejectedDays: _safeInt(json['rejected_days']),
      totalHours: _safeDouble(json['total_hours']) ?? 0.0,
      averageHours: _safeDouble(json['average_hours']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_days': totalDays,
      'approved_days': approvedDays,
      'pending_days': pendingDays,
      'rejected_days': rejectedDays,
      'total_hours': totalHours,
      'average_hours': averageHours,
    };
  }

  double get attendancePercentage {
    if (totalDays == 0) return 0.0;
    return (approvedDays / totalDays) * 100;
  }
}