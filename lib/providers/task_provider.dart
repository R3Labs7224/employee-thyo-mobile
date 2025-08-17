// lib/providers/task_provider.dart - Fixed loading state management
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
  bool _isInitialized = false;
  String _currentDate = '';

  // Getters
  List<Task> get tasks => _tasks;
  TaskSummary? get summary => _summary;
  bool get canCreateTask => _canCreateTask;
  String get attendanceStatus => _attendanceStatus;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  
  Task? get activeTask => _taskService.getActiveTask(_tasks);

  // Initialize data if not already loaded
  Future<void> initializeIfNeeded() async {
    if (!_isInitialized && !_isLoading) {
      debugPrint('🔧 TaskProvider: Initializing...');
      await fetchTasks();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    debugPrint('🔧 TaskProvider: Refreshing...');
    _isInitialized = false;
    await fetchTasks();
  }

  // FIXED: Complete implementation of fetchTasks method
  Future<void> fetchTasks({String? date}) async {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      debugPrint('🔧 TaskProvider: Already loading, skipping fetch');
      return;
    }
    
    _setLoading(true);
    _error = null;
    
    // Use current date if not specified
    final targetDate = date ?? DateTime.now().toIso8601String().split('T')[0];
    _currentDate = targetDate;
    
    debugPrint('🔄 TaskProvider: Fetching tasks for date: $targetDate');

    try {
      final response = await _taskService.getTasks(date: targetDate);

      if (response.success && response.data != null) {
        final taskResponse = response.data!;
        print("Task Response: ${taskResponse.attendanceStatus}");
        _tasks = taskResponse.tasks;
        _summary = taskResponse.summary;
        _canCreateTask = taskResponse.canCreateTask;
        _attendanceStatus = taskResponse.attendanceStatus;
        _error = null;
        _isInitialized = true;
        
        debugPrint('✅ TaskProvider: Tasks loaded successfully');
        debugPrint('📊 TaskProvider: ${_tasks.length} tasks, canCreate: $_canCreateTask, status: $_attendanceStatus');
      } else {
        _error = response.message ?? 'Failed to fetch tasks';
        debugPrint('❌ TaskProvider: Error - $_error');
      }
    } catch (e) {
      _error = 'Failed to fetch tasks: ${e.toString()}';
      debugPrint('❌ TaskProvider: Exception - $_error');
    } finally {
      // FIXED: Always reset loading state in finally block
      _setLoading(false);
    }
  }

  // FIXED: Create a new task with proper loading state management
  Future<bool> createTask({
    required String title,
    String? description,
    required int siteId,
    required double latitude,
    required double longitude,
    String? taskImageBase64,
  }) async {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      debugPrint('🔧 TaskProvider: Already loading, skipping create');
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      debugPrint('🔄 TaskProvider: Creating task: $title');
      
      final response = await _taskService.createTask(
        title: title,
        description: description,
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
        taskImageBase64: taskImageBase64,
      );

      if (response.success) {
        debugPrint('✅ TaskProvider: Task created successfully');
        
        // FIXED: Fetch fresh data after successful creation
        await fetchTasks(date: _currentDate);
        return true;
      } else {
        _error = response.message;
        debugPrint('❌ TaskProvider: Create task error - $_error');
        return false;
      }
    } catch (e) {
      _error = 'Failed to create task: ${e.toString()}';
      debugPrint('❌ TaskProvider: Create task exception - $_error');
      return false;
    } finally {
      // FIXED: Always reset loading state
      _setLoading(false);
    }
  }

  // FIXED: Complete a task with proper loading state management
  Future<bool> completeTask({
    required int taskId,
    String? completionNotes,
  }) async {
    // Prevent multiple simultaneous calls
    if (_isLoading) {
      debugPrint('🔧 TaskProvider: Already loading, skipping complete');
      return false;
    }

    _setLoading(true);
    _error = null;

    try {
      debugPrint('🔄 TaskProvider: Completing task: $taskId');
      
      final response = await _taskService.completeTask(
        taskId: taskId,
        completionNotes: completionNotes,
      );

      if (response.success) {
        debugPrint('✅ TaskProvider: Task completed successfully');
        
        // FIXED: Fetch fresh data after successful completion
        await fetchTasks(date: _currentDate);
        return true;
      } else {
        _error = response.message;
        debugPrint('❌ TaskProvider: Complete task error - $_error');
        return false;
      }
    } catch (e) {
      _error = 'Failed to complete task: ${e.toString()}';
      debugPrint('❌ TaskProvider: Complete task exception - $_error');
      return false;
    } finally {
      // FIXED: Always reset loading state
      _setLoading(false);
    }
  }

  // Helper methods
  Task? getTaskById(int taskId) {
    return _taskService.getTaskById(_tasks, taskId);
  }

  List<Task> getTasksByStatus(String status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  List<Task> get completedTasks => getTasksByStatus('completed');
  List<Task> get activeTasks => getTasksByStatus('active');
  List<Task> get cancelledTasks => getTasksByStatus('cancelled');

  bool get canCreateTaskNow {
    return _canCreateTask && _attendanceStatus == 'checked_in';
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      _safeNotifyListeners();
    }
  }

  void reset() {
    _tasks.clear();
    _summary = null;
    _canCreateTask = false;
    _attendanceStatus = 'not_checked_in';
    _error = null;
    _isLoading = false;
    _isInitialized = false;
    _currentDate = '';
    _safeNotifyListeners();
    debugPrint('🔧 TaskProvider: Data reset');
  }

  // FIXED: Private helper methods with better state management
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      debugPrint('🔧 TaskProvider: Loading state changed to: $loading');
      _safeNotifyListeners();
    }
  }

  void _safeNotifyListeners() {
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // Track disposal to prevent notifications after disposal
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // FIXED: Add debug method to print current state
  void debugPrintState() {
    debugPrint('🔧 TaskProvider State:');
    debugPrint('  - Loading: $_isLoading');
    debugPrint('  - Tasks: ${_tasks.length}');
    debugPrint('  - Can Create: $_canCreateTask');
    debugPrint('  - Attendance: $_attendanceStatus');
    debugPrint('  - Error: $_error');
    debugPrint('  - Initialized: $_isInitialized');
  }
}