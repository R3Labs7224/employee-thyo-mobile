// lib/providers/attendance_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  final AttendanceService _attendanceService = AttendanceService();

  List<Attendance> _attendanceList = [];
  Attendance? _todayAttendance;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Attendance> get attendanceList => _attendanceList;
  Attendance? get todayAttendance => _todayAttendance;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get canCheckIn => _attendanceService.canCheckIn(_todayAttendance);
  bool get canCheckOut => _attendanceService.canCheckOut(_todayAttendance);

  // Permissions getter (for backward compatibility)
  Map<String, bool> get permissions => {
    'canCheckIn': canCheckIn,
    'canCheckOut': canCheckOut,
    'canViewAttendance': true,
  };

  // Summary getter (for backward compatibility)
  Map<String, dynamic> get summary => getMonthlyStats();

  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
String get selectedMonth => _selectedMonth;

// Method to change selected month
Future<void> setSelectedMonth(String month) async {
  if (_selectedMonth != month) {
    _selectedMonth = month;
    await fetchAttendance();
  }
}

  Future<void> initializeIfNeeded() async {
    if (!_isInitialized && !_isLoading) {
      await fetchAttendance();
      _isInitialized = true;
    }
  }

  Future<void> refresh() async {
    _isInitialized = false;
    await fetchAttendance();
    _isInitialized = true;
  }

Future<void> fetchAttendance() async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    // Get attendance history for current/selected month
    final response = await _attendanceService.getAttendanceHistory(
      month: _selectedMonth, // You'll need to add this property
    );

    if (response.success) {
      _attendanceList = response.data ?? [];
      print("Attendence List: $_attendanceList");
      
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
      _error = null;
    } else {
      _error = response.message;
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


  Future<bool> checkIn({
  required int siteId,
  required double latitude,
  required double longitude,
  String? selfieBase64,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _attendanceService.checkIn(
      siteId: siteId,
      latitude: latitude,
      longitude: longitude,
      selfieBase64: selfieBase64,
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

// And the checkOut method:
Future<bool> checkOut({
  required int siteId,
  required double latitude,
  required double longitude,
  String? selfieBase64,
}) async {
  _isLoading = true;
  _error = null;
  notifyListeners();

  try {
    final response = await _attendanceService.checkOut(
      siteId: siteId,
      latitude: latitude,
      longitude: longitude,
      selfieBase64: selfieBase64,
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

  // Get attendance for specific date
  Attendance? getAttendanceForDate(String date) {
    try {
      return _attendanceList.firstWhere((attendance) => attendance.date == date);
    } catch (e) {
      return null;
    }
  }

  // Get monthly statistics
  Map<String, int> getMonthlyStats() {
    final approved = _attendanceList.where((a) => a.isApproved).length;
    final pending = _attendanceList.where((a) => a.isPending).length;
    final rejected = _attendanceList.where((a) => a.isRejected).length;

    return {
      'total': _attendanceList.length,
      'approved': approved,
      'pending': pending,
      'rejected': rejected,
      'totalDays': _attendanceList.length,
      'approvedDays': approved,
      'pendingDays': pending,
      'rejectedDays': rejected,
    };
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset data
  void reset() {
    _attendanceList.clear();
    _todayAttendance = null;
    _error = null;
    notifyListeners();
  }
}