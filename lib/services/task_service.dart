// lib/services/task_service.dart
import '../models/api_response.dart';
import '../models/task.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class TaskService {
  final ApiService _apiService = ApiService();

  // Get tasks for a specific date
  Future<ApiResponse<TaskResponse>> getTasks({
    String? date,
    int? limit,
  }) async {
    try {
      final Map<String, String> queryParams = {};
      
      if (date != null) {
        queryParams['date'] = date;
      }
      
      if (limit != null) {
        queryParams['limit'] = limit.toString();
      }

      final response = await _apiService.get<TaskResponse>(
        AppConfig.tasksEndpoint,
        queryParams: queryParams,
        fromJson: (data) => TaskResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch tasks: ${e.toString()}');
    }
  }

  // Create a new task
  Future<ApiResponse<TaskActionResponse>> createTask({
    required String title,
    String? description,
    required int siteId,
    required double latitude,
    required double longitude,
    String? taskImageBase64,
  }) async {
    try {
      final requestData = CreateTaskRequest(
        title: title,
        description: description,
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
        taskImage: taskImageBase64,
      );

      final response = await _apiService.post<TaskActionResponse>(
        AppConfig.tasksEndpoint,
        requestData.toJson(),
        fromJson: (data) => TaskActionResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to create task: ${e.toString()}');
    }
  }

  // Complete a task
  Future<ApiResponse<TaskActionResponse>> completeTask({
    required int taskId,
    String? completionNotes,
  }) async {
    try {
      final requestData = CompleteTaskRequest(
        taskId: taskId,
        completionNotes: completionNotes,
      );

      final response = await _apiService.put<TaskActionResponse>(
        AppConfig.tasksEndpoint,
        requestData.toJson(),
        fromJson: (data) => TaskActionResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to complete task: ${e.toString()}');
    }
  }

  // Get active task
  Task? getActiveTask(List<Task> tasks) {
    try {
      return tasks.firstWhere((task) => task.isActive);
    } catch (e) {
      return null;
    }
  }

  // Check if employee can create a new task
  bool canCreateTask(TaskResponse taskResponse) {
    return taskResponse.canCreateTask && 
           taskResponse.attendanceStatus == 'checked_in';
  }

  // Get task by ID
  Task? getTaskById(List<Task> tasks, int taskId) {
    try {
      return tasks.firstWhere((task) => task.id == taskId);
    } catch (e) {
      return null;
    }
  }
}