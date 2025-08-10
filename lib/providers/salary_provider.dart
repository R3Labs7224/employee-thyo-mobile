import 'package:flutter/material.dart';
import '../models/salary.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class SalaryProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<SalarySlip> _salarySlips = [];
  CurrentMonthAttendance? _currentMonthAttendance;
  double? _estimatedCurrentSalary;
  YearlySummary? _yearlySummary;
  EmployeeInfo? _employeeInfo;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SalarySlip> get salarySlips => _salarySlips;
  CurrentMonthAttendance? get currentMonthAttendance => _currentMonthAttendance;
  double? get estimatedCurrentSalary => _estimatedCurrentSalary;
  YearlySummary? get yearlySummary => _yearlySummary;
  EmployeeInfo? get employeeInfo => _employeeInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchSalaryData({int? year, int? month}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      
      if (month != null) {
        queryParams['month'] = month.toString();
      }

      final response = await _apiService.get<SalaryResponse>(
        AppConfig.salaryEndpoint,
        queryParams: queryParams,
        fromJson: (data) => SalaryResponse.fromJson(data),
      );

      if (response.success && response.data != null) {
        _salarySlips = response.data!.salarySlips;
        _currentMonthAttendance = response.data!.currentMonthAttendance;
        _estimatedCurrentSalary = response.data!.estimatedCurrentSalary;
        _yearlySummary = response.data!.yearlySummary;
        _employeeInfo = response.data!.employeeInfo;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch salary data: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
