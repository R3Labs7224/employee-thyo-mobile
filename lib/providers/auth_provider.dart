import 'package:flutter/material.dart';
import '../models/employee.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../config/app_config.dart';

class AuthProvider with ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService = ApiService();

  Employee? _employee;
  String? _token;
  bool _isLoading = true;
  bool _isAuthenticated = false;

  AuthProvider(this._storageService) {
    _loadStoredAuth();
  }

  // Getters
  Employee? get employee => _employee;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> _loadStoredAuth() async {
    _isLoading = true;
    notifyListeners();

    final storedToken = await _storageService.getToken();
    final employeeData = await _storageService.getEmployeeData();

    if (storedToken != null && employeeData != null) {
      _token = storedToken;
      _employee = Employee.fromJson(employeeData);
      _apiService.setToken(storedToken);
      _isAuthenticated = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String employeeCode, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post<LoginResponse>(
        AppConfig.loginEndpoint,
        {
          'employee_code': employeeCode,
          'password': password,
          'device_info': 'Flutter App',
          'app_version': AppConfig.appVersion,
        },
        fromJson: (data) => LoginResponse.fromJson(data),
      );

      if (response.success && response.data != null) {
        _token = response.data!.token;
        _employee = response.data!.employee;
        _isAuthenticated = true;

        _apiService.setToken(_token!);
        await _storageService.saveToken(_token!);
        await _storageService.saveEmployeeData(_employee!.toJson());

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.post(AppConfig.logoutEndpoint, {});
    } catch (e) {
      // Continue with logout even if API call fails
    }

    _token = null;
    _employee = null;
    _isAuthenticated = false;
    _apiService.clearToken();
    
    await _storageService.clearAll();

    _isLoading = false;
    notifyListeners();
  }

  void updateEmployee(Employee updatedEmployee) {
    _employee = updatedEmployee;
    _storageService.saveEmployeeData(updatedEmployee.toJson());
    notifyListeners();
  }
}
