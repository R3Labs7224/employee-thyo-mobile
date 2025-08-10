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

  factory ApiResponse.fromJson(Map<String, dynamic> json, T? Function(dynamic) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      timestamp: json['timestamp'] ?? '',
      serverTime: json['server_time'],
    );
  }
}
