// lib/services/employee_service.dart
import '../models/api_response.dart';
import '../models/employee.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class EmployeeService {
  final ApiService _apiService = ApiService();

  // Get employee profile with stats
  Future<ApiResponse<ProfileResponse>> getProfile() async {
    try {
      final response = await _apiService.get<ProfileResponse>(
        AppConfig.profileEndpoint,
        fromJson: (data) => ProfileResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch profile: ${e.toString()}');
    }
  }

  // Update employee profile (only email and phone are allowed)
  Future<ApiResponse<void>> updateProfile({
    String? email,
    String? phone,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (email != null && email.isNotEmpty) {
        updateData['email'] = email;
      }
      
      if (phone != null && phone.isNotEmpty) {
        updateData['phone'] = phone;
      }

      if (updateData.isEmpty) {
        return ApiResponse.error('No fields to update');
      }

      final response = await _apiService.put(
        AppConfig.profileEndpoint,
        updateData,
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to update profile: ${e.toString()}');
    }
  }
}