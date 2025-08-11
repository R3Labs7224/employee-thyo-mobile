// lib/services/auth_service.dart
import '../models/api_response.dart';
import '../models/employee.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Login with employee code and password
  Future<ApiResponse<LoginResponse>> login(String employeeCode, String password) async {
    try {
      final response = await _apiService.post<LoginResponse>(
        AppConfig.loginEndpoint,
        {
          'employee_code': employeeCode,
          'password': password,
        },
        fromJson: (data) => LoginResponse.fromJson(data),
        requiresAuth: false,
      );

      if (response.success && response.data != null) {
        // Store token and employee data
        await _storageService.saveToken(response.data!.token);
        await _storageService.saveEmployeeData(response.data!.employee.toJson());
        
        // Set token for future API calls
        _apiService.setToken(response.data!.token);
      }

      return response;
    } catch (e) {
      return ApiResponse.error('Login failed: ${e.toString()}');
    }
  }

  // Logout
  Future<ApiResponse<void>> logout() async {
    try {
      // Call logout API (optional, continue even if it fails)
      await _apiService.post(
        AppConfig.logoutEndpoint,
        {},
      );
    } catch (e) {
      // Continue with logout even if API call fails
    }

    // Clear local storage
    await _storageService.clearAll();
    _apiService.clearToken();

    return ApiResponse.success('Logged out successfully');
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getToken();
    if (token != null) {
      _apiService.setToken(token);
      return true;
    }
    return false;
  }

  // Get stored employee data
  Future<Employee?> getStoredEmployee() async {
    final employeeData = await _storageService.getEmployeeData();
    if (employeeData != null) {
      return Employee.fromJson(employeeData);
    }
    return null;
  }

  // Get stored token
  Future<String?> getStoredToken() async {
    return await _storageService.getToken();
  }

  // Clear authentication data
  Future<void> clearAuth() async {
    await _storageService.clearAll();
    _apiService.clearToken();
  }
}