// lib/models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String timestamp;
  final int? serverTime;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    required this.timestamp,
    this.serverTime,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic)? fromJson,
  ) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJson != null 
          ? fromJson(json['data']) 
          : json['data'],
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      serverTime: json['server_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'timestamp': timestamp,
      'server_time': serverTime,
    };
  }

  // Helper methods
  bool get isSuccess => success;
  bool get isError => !success;
  
  // Create error response
  factory ApiResponse.error(String message) {
    return ApiResponse<T>(
      success: false,
      message: message,
      data: null,
      timestamp: DateTime.now().toIso8601String(),
    );
  }

  // Create success response
  factory ApiResponse.success(String message, {T? data}) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}