// lib/models/attendance.dart - UPDATED: Removed time and working hours fields
class Attendance {
  final int? id;
  final int? employeeId;
  final int? siteId;
  final String? date;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final String status;
  final String? siteName;
  final String? createdAt;

  Attendance({
    this.id,
    this.employeeId,
    this.siteId,
    this.date,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.status = 'pending',
    this.siteName,
    this.createdAt,
  });

  // Safe string conversion helper
  static String? _safeString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  // Safe double conversion helper
  static double? _safeDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Safe int conversion helper
  static int? _safeInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: _safeInt(json['id']),
      employeeId: _safeInt(json['employee_id']),
      siteId: _safeInt(json['site_id']),
      date: _safeString(json['date']),
      checkInLatitude: _safeDouble(json['check_in_latitude']),
      checkInLongitude: _safeDouble(json['check_in_longitude']),
      checkOutLatitude: _safeDouble(json['check_out_latitude']),
      checkOutLongitude: _safeDouble(json['check_out_longitude']),
      status: _safeString(json['status']) ?? 'pending',
      siteName: _safeString(json['site_name']),
      createdAt: _safeString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'site_id': siteId,
      'date': date,
      'check_in_latitude': checkInLatitude,
      'check_in_longitude': checkInLongitude,
      'check_out_latitude': checkOutLatitude,
      'check_out_longitude': checkOutLongitude,
      'status': status,
      'site_name': siteName,
      'created_at': createdAt,
    };
  }

  bool get isCheckedIn => checkInLatitude != null && checkInLongitude != null;
  bool get isCheckedOut => checkOutLatitude != null && checkOutLongitude != null;
  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';
  bool get isRejected => status == 'rejected';
}

// Check-in/Check-out request model - UPDATED: Removed selfie field
class AttendanceRequest {
  final String action; // 'check_in' or 'check_out'
  final int siteId;
  final double latitude;
  final double longitude;

  AttendanceRequest({
    required this.action,
    required this.siteId,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      'site_id': siteId,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

// Check-in/Check-out response model - UPDATED: Removed time fields
class AttendanceActionResponse {
  final int attendanceId;
  final String date;
  final String? checkInTime; // Kept for compatibility but will be null
  final String? checkOutTime; // Kept for compatibility but will be null
  final double? workingHours; // Kept for compatibility but will be null

  AttendanceActionResponse({
    required this.attendanceId,
    required this.date,
    this.checkInTime,
    this.checkOutTime,
    this.workingHours,
  });

  factory AttendanceActionResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceActionResponse(
      attendanceId: json['attendance_id'] ?? 0,
      date: json['date'] ?? '',
      checkInTime: null, // No longer storing times
      checkOutTime: null, // No longer storing times
      workingHours: null, // Can't calculate without times
    );
  }
}