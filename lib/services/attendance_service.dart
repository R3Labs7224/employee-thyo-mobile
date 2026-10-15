// lib/services/attendance_service.dart - UPDATED: Fixed to match your API structure
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/attendance.dart';
import '../models/api_response.dart';
import '../services/auth_service.dart';

class AttendanceService {
  final AuthService _authService = AuthService();

  // Get attendance history for a specific month
  Future<ApiResponse<List<Attendance>>> getAttendanceHistory([String? month]) async {
    try {
      final token = await _authService.getStoredToken(); // Use getStoredToken() method
      if (token == null) {
        return ApiResponse.error('No authentication token found');
      }

      final queryParams = month != null ? '?month=$month' : '';
      final url = Uri.parse('${AppConfig.baseUrl}/api/employee/attendance.php$queryParams');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        final List<dynamic> data = responseData['data'] ?? [];
        final List<Attendance> attendanceList = data
            .map((json) => Attendance.fromJson(json))
            .toList();
        
        return ApiResponse.success(
          responseData['message'] ?? 'Success',
          data: attendanceList,
        );
      } else {
        return ApiResponse.error(
          responseData['message'] ?? 'Failed to fetch attendance history'
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Check in - UPDATED: Removed selfieBase64 parameter
  Future<ApiResponse<AttendanceActionResponse>> checkIn({
    required int siteId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _authService.getStoredToken(); // Use getStoredToken() method
      if (token == null) {
        return ApiResponse.error('No authentication token found');
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/employee/attendance.php');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'check_in',
          'site_id': siteId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Return a simple success response since we don't store timestamps
        final actionResponse = AttendanceActionResponse(
          attendanceId: 0, // Not returned from API
          date: DateTime.now().toIso8601String().split('T')[0],
          checkInTime: null, // Not stored anymore
          checkOutTime: null,
        );
        
        return ApiResponse.success(
          responseData['message'] ?? 'Check-in successful',
          data: actionResponse,
        );
      } else {
        return ApiResponse.error(
          responseData['message'] ?? 'Check-in failed'
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Check out - UPDATED: Removed selfieBase64 parameter
  Future<ApiResponse<AttendanceActionResponse>> checkOut({
    required int siteId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final token = await _authService.getStoredToken(); // Use getStoredToken() method
      if (token == null) {
        return ApiResponse.error('No authentication token found');
      }

      final url = Uri.parse('${AppConfig.baseUrl}/api/employee/attendance.php');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'action': 'check_out',
          'site_id': siteId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      final responseData = json.decode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] == true) {
        // Return success response without timestamps
        final actionResponse = AttendanceActionResponse(
          attendanceId: 0, // Not returned from API
          date: DateTime.now().toIso8601String().split('T')[0],
          checkInTime: null, // Not stored anymore
          checkOutTime: null, // Not stored anymore
          workingHours: null, // Can't calculate without timestamps
        );
        
        return ApiResponse.success(
          responseData['message'] ?? 'Check-out successful',
          data: actionResponse,
        );
      } else {
        return ApiResponse.error(
          responseData['message'] ?? 'Check-out failed'
        );
      }
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Get today's attendance status
  Future<Attendance?> getTodayAttendance() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final response = await getAttendanceHistory(today.substring(0, 7)); // Get current month
      
      if (response.success && response.data != null) {
        return response.data!.firstWhere(
          (attendance) => attendance.date == today,
          orElse: () => throw StateError('No attendance found for today'),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}