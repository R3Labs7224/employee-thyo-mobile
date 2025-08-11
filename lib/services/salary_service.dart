// lib/services/salary_service.dart
import '../models/api_response.dart';
import '../models/salary.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class SalaryService {
  final ApiService _apiService = ApiService();

  // Get salary slips with optional filters
  Future<ApiResponse<SalaryResponse>> getSalarySlips({
    int? year,
    int? month,
    int? limit,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      
      if (year != null) {
        queryParams['year'] = year.toString();
      }
      
      if (month != null) {
        queryParams['month'] = month.toString();
      }
      
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await _apiService.get<SalaryResponse>(
        AppConfig.salaryEndpoint,
        queryParams: queryParams,
        fromJson: (data) => SalaryResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch salary data: ${e.toString()}');
    }
  }

  // Get salary slip for specific month and year
  SalarySlip? getSalarySlipForMonth(List<SalarySlip> salarySlips, int year, int month) {
    try {
      return salarySlips.firstWhere(
        (slip) => slip.year == year && slip.month == month,
      );
    } catch (e) {
      return null;
    }
  }

  // Get latest salary slip
  SalarySlip? getLatestSalarySlip(List<SalarySlip> salarySlips) {
    if (salarySlips.isEmpty) return null;
    
    salarySlips.sort((a, b) {
      final dateA = DateTime(a.year, a.month);
      final dateB = DateTime(b.year, b.month);
      return dateB.compareTo(dateA);
    });
    
    return salarySlips.first;
  }

  // Calculate year-to-date earnings
  double calculateYearToDateEarnings(List<SalarySlip> salarySlips, int year) {
    return salarySlips
        .where((slip) => slip.year == year)
        .fold(0.0, (sum, slip) => sum + slip.netSalary);
  }

  // Get salary slips for a specific year
  List<SalarySlip> getSalarySlipsForYear(List<SalarySlip> salarySlips, int year) {
    return salarySlips.where((slip) => slip.year == year).toList();
  }

  // Calculate average monthly salary
  double calculateAverageMonthlyS

(List<SalarySlip> salarySlips) {
    if (salarySlips.isEmpty) return 0.0;
    
    final totalSalary = salarySlips.fold(0.0, (sum, slip) => sum + slip.netSalary);
    return totalSalary / salarySlips.length;
  }

  // Get months with salary slips for a specific year
  List<int> getMonthsWithSalary(List<SalarySlip> salarySlips, int year) {
    return salarySlips
        .where((slip) => slip.year == year)
        .map((slip) => slip.month)
        .toSet()
        .toList()
      ..sort();
  }

  // Estimate current month salary based on attendance
  double estimateCurrentMonthSalary({
    required double basicSalary,
    required int approvedDays,
    required int totalWorkingDays,
  }) {
    if (totalWorkingDays == 0) return 0.0;
    
    final dailyRate = basicSalary / totalWorkingDays;
    return dailyRate * approvedDays;
  }
}