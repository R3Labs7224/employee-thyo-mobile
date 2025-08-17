// lib/models/task.dart - FIXED VERSION
// Helper function for safe integer conversion
int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// Helper function for safe nullable integer conversion
int? _safeIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

// Helper function for safe double conversion
double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

// Helper function for safe string conversion
String _safeString(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

class Task {
  final int id;
  final int employeeId;
  final int attendanceId;
  final int siteId;
  final String title;
  final String description;
  final String status;
  final String? startTime;
  final String? endTime;
  final double latitude;
  final double longitude;
  final String? taskImage;
  final String? siteName;
  final String? attendanceDate;
  final String? createdAt;

  Task({
    required this.id,
    required this.employeeId,
    required this.attendanceId,
    required this.siteId,
    required this.title,
    required this.description,
    required this.status,
    this.startTime,
    this.endTime,
    required this.latitude,
    required this.longitude,
    this.taskImage,
    this.siteName,
    this.attendanceDate,
    this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: _safeInt(json['id']),
      employeeId: _safeInt(json['employee_id']),
      attendanceId: _safeInt(json['attendance_id']),
      siteId: _safeInt(json['site_id']),
      title: _safeString(json['title']),
      description: _safeString(json['description']),
      status: _safeString(json['status']).isNotEmpty 
          ? _safeString(json['status']) : 'active',
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      latitude: _safeDouble(json['latitude']),
      longitude: _safeDouble(json['longitude']),
      taskImage: json['task_image']?.toString(),
      siteName: json['site_name']?.toString(),
      attendanceDate: json['attendance_date']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'attendance_id': attendanceId,
      'site_id': siteId,
      'title': title,
      'description': description,
      'status': status,
      'start_time': startTime,
      'end_time': endTime,
      'latitude': latitude,
      'longitude': longitude,
      'task_image': taskImage,
      'site_name': siteName,
      'attendance_date': attendanceDate,
      'created_at': createdAt,
    };
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
}

class TaskResponse {
  final List<Task> tasks;
  final TaskSummary summary;
  final bool canCreateTask;
  final String attendanceStatus;

  TaskResponse({
    required this.tasks,
    required this.summary,
    required this.canCreateTask,
    required this.attendanceStatus,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      tasks: (json['tasks'] as List)
          .map((item) => Task.fromJson(item))
          .toList(),
      summary: TaskSummary.fromJson(json['summary']),
      canCreateTask: json['can_create_task'] ?? false,
      attendanceStatus: _safeString(json['attendance_status']).isNotEmpty 
          ? _safeString(json['attendance_status']) 
          : 'not_checked_in',
    );
  }
}

class TaskSummary {
  final int totalTasks;
  final int completedTasks;
  final int activeTasks;
  final int cancelledTasks;

  TaskSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.activeTasks,
    required this.cancelledTasks,
  });

  factory TaskSummary.fromJson(Map<String, dynamic> json) {
    return TaskSummary(
      totalTasks: _safeInt(json['total_tasks']),
      completedTasks: _safeInt(json['completed_tasks']),
      activeTasks: _safeInt(json['active_tasks']),
      cancelledTasks: _safeInt(json['cancelled_tasks']),
    );
  }
}

// FIXED: Create task request model - corrected parameter names
class CreateTaskRequest {
  final String title;
  final String? description;
  final int siteId;
  final double latitude;
  final double longitude;
  final String? taskImage; // base64 encoded image

  CreateTaskRequest({
    required this.title,
    this.description,
    required this.siteId,
    required this.latitude,
    required this.longitude,
    this.taskImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description ?? '', // FIXED: Changed from 'completion_notes' to 'description'
      'site_id': siteId,
      'latitude': latitude,
      'longitude': longitude,
      if (taskImage != null) 'image': taskImage, // FIXED: Changed from 'completion_image' to 'image'
    };
  }
}

// Complete task request model (this one was correct)
class CompleteTaskRequest {
  final int taskId;
  final String? completionNotes;
  final double? latitude;
  final double? longitude;
  final String? completionImage; // base64 encoded image

  CompleteTaskRequest({
    required this.taskId,
    this.completionNotes,
    this.latitude,
    this.longitude,
    this.completionImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      if (completionNotes != null) 'completion_notes': completionNotes,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (completionImage != null) 'completion_image': completionImage,
    };
  }
}

// Task action response model
class TaskActionResponse {
  final int taskId;
  final String? title;
  final String? siteName;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;

  TaskActionResponse({
    required this.taskId,
    this.title,
    this.siteName,
    this.startTime,
    this.endTime,
    this.durationMinutes,
  });

  factory TaskActionResponse.fromJson(Map<String, dynamic> json) {
    return TaskActionResponse(
      taskId: _safeInt(json['task_id']),
      title: json['title']?.toString(),
      siteName: json['site_name']?.toString(),
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
      durationMinutes: _safeIntNullable(json['duration_minutes']),
    );
  }
}