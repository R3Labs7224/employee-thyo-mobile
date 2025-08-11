// lib/models/task.dart
class Task {
  final int? id;
  final int? employeeId;
  final int? attendanceId;
  final int? siteId;
  final String title;
  final String? description;
  final String status;
  final String? startTime;
  final String? endTime;
  final double? latitude;
  final double? longitude;
  final String? taskImage;
  final String? siteName;
  final String? attendanceDate;
  final String? createdAt;

  Task({
    this.id,
    this.employeeId,
    this.attendanceId,
    this.siteId,
    required this.title,
    this.description,
    this.status = 'active',
    this.startTime,
    this.endTime,
    this.latitude,
    this.longitude,
    this.taskImage,
    this.siteName,
    this.attendanceDate,
    this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      employeeId: json['employee_id'],
      attendanceId: json['attendance_id'],
      siteId: json['site_id'],
      title: json['title'] ?? '',
      description: json['description'],
      status: json['status'] ?? 'active',
      startTime: json['start_time'],
      endTime: json['end_time'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      taskImage: json['task_image'],
      siteName: json['site_name'],
      attendanceDate: json['attendance_date'],
      createdAt: json['created_at'],
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
      attendanceStatus: json['attendance_status'] ?? 'not_checked_in',
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
      totalTasks: json['total_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      activeTasks: json['active_tasks'] ?? 0,
      cancelledTasks: json['cancelled_tasks'] ?? 0,
    );
  }
}

// Create task request model
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
      'description': description ?? '',
      'site_id': siteId,
      'latitude': latitude,
      'longitude': longitude,
      if (taskImage != null) 'task_image': taskImage,
    };
  }
}

// Complete task request model
class CompleteTaskRequest {
  final int taskId;
  final String? completionNotes;

  CompleteTaskRequest({
    required this.taskId,
    this.completionNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'task_id': taskId,
      if (completionNotes != null) 'completion_notes': completionNotes,
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
      taskId: json['task_id'],
      title: json['title'],
      siteName: json['site_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationMinutes: json['duration_minutes'],
    );
  }
}