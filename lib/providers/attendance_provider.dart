// lib/providers/attendance_provider.dart - UPDATED: Fixed to match updated service
import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  List<Attendance> _attendanceList = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  List<Attendance> get attendanceList => _attendanceList;
  Attendance? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Get attendance for specific month
  List<Attendance> getAttendanceForMonth(int year, int month) {
    final monthStr = '$year-${month.toString().padLeft(2, '0')}';
    return _attendanceList.where((attendance) => 
      attendance.date?.startsWith(monthStr) ?? false
    ).toList();
  }

  // Check if user is currently checked in (based on location data)
  bool get isCheckedIn {
    return _todayAttendance?.isCheckedIn == true && 
           _todayAttendance?.isCheckedOut == false;
  }

  // Check if user is checked out (based on location data)
  bool get isCheckedOut {
    return _todayAttendance?.isCheckedOut == true;
  }

  // Initialize provider
  Future<void> initialize() async {
    if (!_isInitialized) {
      await fetchAttendance();
    }
  }

  // Fetch attendance history
  Future<void> fetchAttendance([String? month]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _attendanceService.getAttendanceHistory(month);
      
      if (response.success && response.data != null) {
        _attendanceList = response.data ?? [];
        debugPrint("Attendance List: $_attendanceList");
        
        // Find today's attendance
        final today = DateTime.now().toIso8601String().split('T')[0];
        try {
          _todayAttendance = _attendanceList.firstWhere(
            (attendance) => attendance.date == today,
          );
        } catch (e) {
          _todayAttendance = null;
        }
        
        _isInitialized = true;
        _error = null; // Clear any previous errors since response was successful
        
        // Note: Empty attendance list is NOT an error condition
        // It's a normal state for new employees or months with no records
        
      } else {
        // Only set error if the API response indicates a failure
        // Empty data with success=true should not be treated as an error
        if (response.message.toLowerCase().contains('failed') || 
            response.message.toLowerCase().contains('error')) {
          _error = response.message;
        } else {
          // API returned success=false but message doesn't indicate failure
          // This might be a case where no data exists, which is fine
          _error = null;
        }
        
        _attendanceList = [];
        _todayAttendance = null;
      }
    } catch (e) {
      _error = 'Failed to fetch attendance: ${e.toString()}';
      _attendanceList = [];
      _todayAttendance = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Check in - UPDATED: Removed selfieBase64 parameter
  Future<bool> checkIn({
    required int siteId,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _attendanceService.checkIn(
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
      );

      if (response.success) {
        // Refresh attendance data to get the latest state
        await fetchAttendance();
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

  // Check out - UPDATED: Removed selfieBase64 parameter
  Future<bool> checkOut({
    required int siteId,
    required double latitude,
    required double longitude,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _attendanceService.checkOut(
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
      );

      if (response.success) {
        // Refresh attendance data to get the latest state
        await fetchAttendance();
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

  // Refresh attendance data
  Future<void> refresh() async {
    await fetchAttendance();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset provider state
  void reset() {
    _attendanceList = [];
    _todayAttendance = null;
    _isLoading = false;
    _isInitialized = false;
    _error = null;
    notifyListeners();
  }
}