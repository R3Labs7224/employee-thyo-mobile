// lib/providers/task_provider.dart
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/task_service.dart';

class TaskProvider with ChangeNotifier {
  final TaskService _taskService = TaskService();

  List<Task> _tasks = [];
  TaskSummary? _summary;
  bool _canCreateTask = false;
  String _attendanceStatus = 'not_checked_in';
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Task> get tasks => _tasks;
  TaskSummary? get summary => _summary;
  bool get canCreateTask => _canCreateTask;
  String get attendanceStatus => _attendanceStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Task? get activeTask => _taskService.getActiveTask(_tasks);

  // Fetch tasks for a specific date
  Future<void> fetchTasks({String? date, int? limit}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _taskService.getTasks(date: date, limit: limit);

      if (response.success && response.data != null) {
        _tasks = response.data!.tasks;
        _summary = response.data!.summary;
        _canCreateTask = response.data!.canCreateTask;
        _attendanceStatus = response.data!.attendanceStatus;
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch tasks: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Create a new task
  Future<bool> createTask({
    required String title,
    String? description,
    required int siteId,
    required double latitude,
    required double longitude,
    String? taskImageBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _taskService.createTask(
        title: title,
        description: description,
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
        taskImageBase64: taskImageBase64,
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

  // Complete a task
  Future<bool> completeTask({
    required int taskId,
    String? completionNotes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _taskService.completeTask(
        taskId: taskId,
        completionNotes: completionNotes,
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

  // Get task by ID
  Task? getTaskById(int taskId) {
    return _taskService.getTaskById(_tasks, taskId);
  }

  // Get tasks by status
  List<Task> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Get completed tasks
  List<Task> get completedTasks => getTasksByStatus('completed');

  // Get active tasks
  List<Task> get activeTasks => getTasksByStatus('active');

  // Get cancelled tasks
  List<Task> get cancelledTasks => getTasksByStatus('cancelled');

  // Check if can create task based on response
  bool get canCreateTaskNow {
    return _taskService.canCreateTask(TaskResponse(
      tasks: _tasks,
      summary: _summary ?? TaskSummary(
        totalTasks: 0,
        completedTasks: 0,
        activeTasks: 0,
        cancelledTasks: 0,
      ),
      canCreateTask: _canCreateTask,
      attendanceStatus: _attendanceStatus,
    ));
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset data
  void reset() {
    _tasks.clear();
    _summary = null;
    _canCreateTask = false;
    _attendanceStatus = 'not_checked_in';
    _error = null;
    notifyListeners();
  }
}