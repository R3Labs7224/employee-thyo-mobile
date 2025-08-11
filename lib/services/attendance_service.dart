// lib/services/attendance_service.dart
import '../models/api_response.dart';
import '../models/attendance.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class AttendanceService {
  final ApiService _apiService = ApiService();

  // Get attendance history for a specific month
  Future<ApiResponse<List<Attendance>>> getAttendanceHistory({String? month}) async {
    try {
      final Map<String, String> queryParams = {};
      if (month != null) {
        queryParams['month'] = month;
      }

      final response = await _apiService.get<List<Attendance>>(
        AppConfig.attendanceEndpoint,
        queryParams: queryParams,
        fromJson: (data) => (data as List)
            .map((item) => Attendance.fromJson(item))
            .toList(),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch attendance: ${e.toString()}');
    }
  }

  // Check in
  Future<ApiResponse<AttendanceActionResponse>> checkIn({
    required int siteId,
    required double latitude,
    required double longitude,
    String? selfieBase64,
  }) async {
    try {
      final requestData = AttendanceRequest(
        action: 'check_in',
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
        selfie: selfieBase64,
      );

      final response = await _apiService.post<AttendanceActionResponse>(
        AppConfig.attendanceEndpoint,
        requestData.toJson(),
        fromJson: (data) => AttendanceActionResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Check-in failed: ${e.toString()}');
    }
  }

  // Check out
  Future<ApiResponse<AttendanceActionResponse>> checkOut({
    required int siteId,
    required double latitude,
    required double longitude,
    String? selfieBase64,
  }) async {
    try {
      final requestData = AttendanceRequest(
        action: 'check_out',
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
        selfie: selfieBase64,
      );

      final response = await _apiService.post<AttendanceActionResponse>(
        AppConfig.attendanceEndpoint,
        requestData.toJson(),
        fromJson: (data) => AttendanceActionResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Check-out failed: ${e.toString()}');
    }
  }

  // Get today's attendance status
  Future<Attendance?> getTodayAttendance(List<Attendance> attendanceList) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    try {
      return attendanceList.firstWhere(
        (attendance) => attendance.date == today,
      );
    } catch (e) {
      return null;
    }
  }

  // Check if employee can check in
  bool canCheckIn(Attendance? todayAttendance) {
    return todayAttendance == null || todayAttendance.checkInTime == null;
  }

  // Check if employee can check out
  bool canCheckOut(Attendance? todayAttendance) {
    return todayAttendance != null && 
           todayAttendance.checkInTime != null && 
           todayAttendance.checkOutTime == null;
  }
}