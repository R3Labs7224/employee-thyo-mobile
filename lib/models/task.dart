class Task {
  final int? id;
  final String title;
  final String description;
  final String? siteName;
  final String status;
  final String? startTime;
  final String? endTime;
  final String? taskImage;
  final String? attendanceDate;

  Task({
    this.id,
    required this.title,
    required this.description,
    this.siteName,
    required this.status,
    this.startTime,
    this.endTime,
    this.taskImage,
    this.attendanceDate,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      siteName: json['site_name'],
      status: json['status'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      taskImage: json['task_image'],
      attendanceDate: json['attendance_date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'site_name': siteName,
      'status': status,
      'start_time': startTime,
      'end_time': endTime,
      'task_image': taskImage,
      'attendance_date': attendanceDate,
    };
  }
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
      canCreateTask: json['can_create_task'],
      attendanceStatus: json['attendance_status'],
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
      totalTasks: json['total_tasks'],
      completedTasks: json['completed_tasks'],
      activeTasks: json['active_tasks'],
      cancelledTasks: json['cancelled_tasks'],
    );
  }
}
