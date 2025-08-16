// lib/providers/salary_provider.dart
import 'package:ems/models/salary.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SalaryProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // State variables
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  bool _disposed = false;

  // Data
  List<SalarySlip> _salarySlips = [];
  AttendanceSummary? _currentMonthAttendance;
  EmployeeInfo? _employeeInfo;
  double? _estimatedCurrentSalary;
  YearlySummary? _yearlySummary;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  List<SalarySlip> get salarySlips => _salarySlips;
  AttendanceSummary? get currentMonthAttendance => _currentMonthAttendance;
  EmployeeInfo? get employeeInfo => _employeeInfo;
  double? get estimatedCurrentSalary => _estimatedCurrentSalary;
  YearlySummary? get yearlySummary => _yearlySummary;

  // Main data fetching method
  Future<void> fetchSalaryData({int? year, int? month}) async {
    if (_disposed) return;
    
    debugPrint('💰 SalaryProvider: Fetching salary data...');
    
    _setLoading(true);
    _error = null;

    try {
      final Map<String, String> queryParams = {};
      if (year != null) queryParams['year'] = year.toString();
      if (month != null) queryParams['month'] = month.toString();

      final response = await _apiService.get(
        'employee/salary.php', 
        queryParams: queryParams,
      );
      
      debugPrint('💰 SalaryProvider: Response received - ${response.success}');
      
      if (response.success && response.data != null) {
        await _processSuccessResponse(response.data);
        _isInitialized = true;
        debugPrint('✅ SalaryProvider: Data processed successfully');
      } else {
        _error = response.message;
        debugPrint('❌ SalaryProvider: API returned error - $_error');
      }
    } catch (e) {
      _error = 'Error fetching salary data: $e';
      debugPrint('❌ SalaryProvider: Exception - $e');
    } finally {
      _setLoading(false);
    }
  }

  // Process successful API response
  Future<void> _processSuccessResponse(dynamic data) async {
    try {
      debugPrint('💰 SalaryProvider: Processing response data...');
      
      // Convert to Map if needed
      Map<String, dynamic> responseData = data is Map<String, dynamic> ? data : {};
      
      // Process salary slips
      if (responseData['salary_slips'] != null) {
        _salarySlips = (responseData['salary_slips'] as List)
            .map((item) => SalarySlip.fromJson(item))
            .toList();
        debugPrint('💰 SalaryProvider: Processed ${_salarySlips.length} salary slips');
      } else {
        _salarySlips = [];
      }

      // Process current month attendance
      if (responseData['current_month_attendance'] != null) {
        _currentMonthAttendance = AttendanceSummary.fromJson(responseData['current_month_attendance']);
        debugPrint('💰 SalaryProvider: Processed attendance summary');
      }

      // Process employee info
      if (responseData['employee_info'] != null) {
        _employeeInfo = EmployeeInfo.fromJson(responseData['employee_info']);
        debugPrint('💰 SalaryProvider: Processed employee info');
      }

      // Process estimated salary
      _estimatedCurrentSalary = responseData['estimated_current_salary']?.toDouble();
      debugPrint('💰 SalaryProvider: Estimated salary: $_estimatedCurrentSalary');

      // Process yearly summary
      if (responseData['yearly_summary'] != null) {
        _yearlySummary = YearlySummary.fromJson(responseData['yearly_summary']);
        debugPrint('💰 SalaryProvider: Processed yearly summary');
      }

    } catch (e) {
      debugPrint('❌ SalaryProvider: Error processing response - $e');
      throw Exception('Error processing salary data: $e');
    }
  }

  // Get salary slip by month and year
  SalarySlip? getSalarySlip(int month, int year) {
    try {
      return _salarySlips.firstWhere(
        (slip) => slip.month == month && slip.year == year,
      );
    } catch (e) {
      return null;
    }
  }

  // Get current year salary slips
  List<SalarySlip> getCurrentYearSlips() {
    final currentYear = DateTime.now().year;
    return _salarySlips.where((slip) => slip.year == currentYear).toList();
  }

  // Calculate total earnings for year
  double getTotalEarningsForYear(int year) {
    return _salarySlips
        .where((slip) => slip.year == year)
        .fold(0.0, (sum, slip) => sum + slip.netSalary);
  }

  // Clear error
  void clearError() {
    if (_error != null) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  // Reset all data
  void reset() {
    _salarySlips.clear();
    _currentMonthAttendance = null;
    _employeeInfo = null;
    _estimatedCurrentSalary = null;
    _yearlySummary = null;
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    _safeNotifyListeners();
    debugPrint('💰 SalaryProvider: Data reset');
  }

  // Initialize if needed
  Future<void> initializeIfNeeded() async {
    if (!_isInitialized && !_isLoading) {
      debugPrint('💰 SalaryProvider: Initializing salary data');
      await fetchSalaryData(year: DateTime.now().year);
    }
  }

  // Refresh data
  Future<void> refresh() async {
    debugPrint('💰 SalaryProvider: Refreshing salary data');
    _isInitialized = false;
    await fetchSalaryData(year: DateTime.now().year);
  }

  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    // Use addPostFrameCallback to avoid setState during build
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
    debugPrint('💰 SalaryProvider: Disposed');
  }

  // Debug method
  void debugPrintState() {
    debugPrint('💰 SalaryProvider State:');
    debugPrint('  - Salary Slips: ${_salarySlips.length}');
    debugPrint('  - Loading: $_isLoading');
    debugPrint('  - Error: $_error');
    debugPrint('  - Initialized: $_isInitialized');
    debugPrint('  - Estimated Salary: $_estimatedCurrentSalary');
    debugPrint('  - Current Attendance: ${_currentMonthAttendance?.totalDays ?? 'N/A'}');
  }
}