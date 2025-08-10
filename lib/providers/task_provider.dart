import 'package:ems/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';

import '../config/app_config.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Task> _tasks = [];
  TaskSummary? _summary;
  bool _canCreateTask = false;
  String _attendanceStatus = '';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Task> get tasks => _tasks;
  TaskSummary? get summary => _summary;
  bool get canCreateTask => _canCreateTask;
  String get attendanceStatus => _attendanceStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchTasks({String? date, int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      
      if (date != null) {
        queryParams['date'] = date;
      }

      final response = await _apiService.get<TaskResponse>(
        AppConfig.tasksEndpoint,
        queryParams: queryParams,
        fromJson: (data) => TaskResponse.fromJson(data),
      );

      if (response.success && response.data != null) {
        _tasks = response.data!.tasks;
        _summary = response.data!.summary;
        _canCreateTask = response.data!.canCreateTask;
        _attendanceStatus = response.data!.attendanceStatus;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch tasks: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createTask({
    required String title,
    required String description,
    required int siteId,
    required double latitude,
    required double longitude,
    required String imageBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.post(
        AppConfig.tasksEndpoint,
        {
          'title': title,
          'description': description,
          'site_id': siteId,
          'latitude': latitude,
          'longitude': longitude,
          'image': imageBase64,
        },
      );

      if (response.success) {
        // Refresh tasks
        await fetchTasks();
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
      _error = 'Failed to create task: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> completeTask({
    required int taskId,
    required String completionNotes,
    required double latitude,
    required double longitude,
    String? completionImageBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'task_id': taskId,
        'completion_notes': completionNotes,
        'latitude': latitude,
        'longitude': longitude,
      };

      if (completionImageBase64 != null) {
        body['completion_image'] = completionImageBase64;
      }

      final response = await _apiService.put(
        AppConfig.tasksEndpoint,
        body,
      );

      if (response.success) {
        // Refresh tasks
        await fetchTasks();
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
      _error = 'Failed to complete task: ${e.toString()}';
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
