import 'package:ems/models/employee.dart';
import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class AttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Attendance> _attendanceList = [];
  AttendanceSummary? _summary;
  TodayAttendance? _todayAttendance;
  Permissions? _permissions;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Attendance> get attendanceList => _attendanceList;
  AttendanceSummary? get summary => _summary;
  TodayAttendance? get todayAttendance => _todayAttendance;
  Permissions? get permissions => _permissions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchAttendance({String? month, int limit = 30}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (month != null) {
        queryParams['month'] = month;
      }

      final response = await _apiService.get<AttendanceResponse>(
        AppConfig.attendanceEndpoint,
        queryParams: queryParams,
        fromJson: (data) => AttendanceResponse.fromJson(data),
      );

      if (response.success && response.data != null) {
        _attendanceList = response.data!.attendance;
        _summary = response.data!.summary;
        _todayAttendance = response.data!.today;
        _permissions = response.data!.permissions;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch attendance: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> checkIn({
    required int siteId,
    required double latitude,
    required double longitude,
    required String selfieBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConfig.attendanceEndpoint,
        {
          'action': 'check_in',
          'site_id': siteId,
          'latitude': latitude,
          'longitude': longitude,
          'selfie': selfieBase64,
        },
      );

      if (response.success) {
        // Refresh attendance data
        await fetchAttendance();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Check-in failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkOut({
    required int siteId,
    required double latitude,
    required double longitude,
    required String selfieBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConfig.attendanceEndpoint,
        {
          'action': 'check_out',
          'site_id': siteId,
          'latitude': latitude,
          'longitude': longitude,
          'selfie': selfieBase64,
        },
      );

      if (response.success) {
        // Refresh attendance data
        await fetchAttendance();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Check-out failed: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
