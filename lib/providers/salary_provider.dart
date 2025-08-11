// lib/providers/salary_provider.dart
import 'package:flutter/material.dart';
import '../models/salary.dart';
import '../services/salary_service.dart';

class SalaryProvider with ChangeNotifier {
  final SalaryService _salaryService = SalaryService();

  List<SalarySlip> _salarySlips = [];
  CurrentMonthSummary? _currentMonthSummary;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<SalarySlip> get salarySlips => _salarySlips;
  CurrentMonthSummary? get currentMonthSummary => _currentMonthSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Additional getters
  SalarySlip? get latestSalarySlip => _salaryService.getLatestSalarySlip(_salarySlips);
  double get averageMonthlySalary => _salaryService.calculateAverageMonthlyS (_salarySlips);

  // Fetch salary data
  Future<void> fetchSalaryData({int? year, int? month, int? limit}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _salaryService.getSalarySlips(
        year: year,
        month: month,
        limit: limit,
      );

      if (response.success && response.data != null) {
        _salarySlips = response.data!.salarySlips;
        _currentMonthSummary = response.data!.currentMonthSummary;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch salary data: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Get salary slip for specific month and year
  SalarySlip? getSalarySlipForMonth(int year, int month) {
    return _salaryService.getSalarySlipForMonth(_salarySlips, year, month);
  }

  // Calculate year-to-date earnings
  double getYearToDateEarnings(int year) {
    return _salaryService.calculateYearToDateEarnings(_salarySlips, year);
  }

  // Get salary slips for a specific year
  List<SalarySlip> getSalarySlipsForYear(int year) {
    return _salaryService.getSalarySlipsForYear(_salarySlips, year);
  }

  // Get months with salary slips for a specific year
  List<int> getMonthsWithSalary(int year) {
    return _salaryService.getMonthsWithSalary(_salarySlips, year);
  }

  // Estimate current month salary
  double estimateCurrentMonthSalary({
    required double basicSalary,
    required int approvedDays,
    required int totalWorkingDays,
  }) {
    return _salaryService.estimateCurrentMonthSalary(
      basicSalary: basicSalary,
      approvedDays: approvedDays,
      totalWorkingDays: totalWorkingDays,
    );
  }

  // Get salary statistics
  Map<String, dynamic> getSalaryStatistics() {
    if (_salarySlips.isEmpty) {
      return {
        'totalSlips': 0,
        'totalEarnings': 0.0,
        'averageSalary': 0.0,
        'highestSalary': 0.0,
        'lowestSalary': 0.0,
      };
    }

    final totalEarnings = _salarySlips.fold(0.0, (sum, slip) => sum + slip.netSalary);
    final salaryAmounts = _salarySlips.map((slip) => slip.netSalary).toList();
    salaryAmounts.sort();

    return {
      'totalSlips': _salarySlips.length,
      'totalEarnings': totalEarnings,
      'averageSalary': totalEarnings / _salarySlips.length,
      'highestSalary': salaryAmounts.last,
      'lowestSalary': salaryAmounts.first,
    };
  }

  // Get available years
  List<int> getAvailableYears() {
    return _salarySlips
        .map((slip) => slip.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // Sort descending
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset data
  void reset() {
    _salarySlips.clear();
    _currentMonthSummary = null;
    _error = null;
    notifyListeners();
  }
}