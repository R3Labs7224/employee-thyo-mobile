// lib/models/petty_cash.dart
import 'package:flutter/foundation.dart';

class PettyCashRequest {
  final String? id;
  final String? employeeId;
  final double amount;
  final String reason;
  final String requestDate;
  final String? receiptImage;
  final String status;
  final int? approvedBy;
  final String? approvedByName;
  final String? approvalDate;
  final String? remarks;
  final String? notes; // Added notes field
  final String? createdAt;
  final String? updatedAt; // Added updatedAt field

  PettyCashRequest({
    this.id,
    this.employeeId,
    required this.amount,
    required this.reason,
    required this.requestDate,
    this.receiptImage,
    this.status = 'pending',
    this.approvedBy,
    this.approvedByName,
    this.approvalDate,
    this.remarks,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory PettyCashRequest.fromJson(Map<String, dynamic> json) {
    return PettyCashRequest(
      id: json['id']?.toString(),
      employeeId: json['employee_id']?.toString(),
      // FIXED: Proper type conversion for amount field
      amount: _parseDouble(json['amount']),
      reason: json['reason']?.toString() ?? '',
      requestDate: json['request_date']?.toString() ?? '',
      receiptImage: json['receipt_image']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      // FIXED: Handle both string and int for approvedBy
      approvedBy: _parseInt(json['approved_by']),
      approvedByName: json['approved_by_name']?.toString(),
      approvalDate: json['approval_date']?.toString(),
      remarks: json['remarks']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'employee_id': employeeId,
      'amount': amount,
      'reason': reason,
      'request_date': requestDate,
      'receipt_image': receiptImage,
      'status': status,
      'approved_by': approvedBy,
      'approved_by_name': approvedByName,
      'approval_date': approvalDate,
      'remarks': remarks,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';

  // Helper method to safely parse double from various types
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('⚠️ Warning: Could not parse double from: $value');
        return 0.0;
      }
    }
    debugPrint('⚠️ Warning: Unexpected type for amount: ${value.runtimeType}');
    return 0.0;
  }

  // Helper method to safely parse int from various types
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        debugPrint('⚠️ Warning: Could not parse int from: $value');
        return null;
      }
    }
    debugPrint('⚠️ Warning: Unexpected type for int field: ${value.runtimeType}');
    return null;
  }
}

class PettyCashResponse {
  final List<PettyCashRequest> requests;
  final PettyCashSummary summary;

  PettyCashResponse({
    required this.requests,
    required this.summary,
  });

  factory PettyCashResponse.fromJson(Map<String, dynamic> json) {
    try {
      // Parse requests array
      List<PettyCashRequest> requestsList = [];
      if (json['requests'] != null && json['requests'] is List) {
        requestsList = (json['requests'] as List)
            .map((item) {
              try {
                return PettyCashRequest.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                debugPrint('⚠️ Error parsing request item: $e');
                debugPrint('🔍 Item data: $item');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<PettyCashRequest>()
            .toList();
      }

      // Parse summary
      PettyCashSummary summaryObj;
      if (json['summary'] != null) {
        summaryObj = PettyCashSummary.fromJson(json['summary'] as Map<String, dynamic>);
      } else {
        // Create default summary if not provided
        summaryObj = PettyCashSummary(
          totalRequests: requestsList.length,
          totalAmount: requestsList.fold(0.0, (sum, request) => sum + request.amount),
          approvedAmount: requestsList
              .where((r) => r.isApproved)
              .fold(0.0, (sum, request) => sum + request.amount),
          pendingAmount: requestsList
              .where((r) => r.isPending)
              .fold(0.0, (sum, request) => sum + request.amount),
          rejectedAmount: requestsList
              .where((r) => r.isRejected)
              .fold(0.0, (sum, request) => sum + request.amount),
        );
      }

      return PettyCashResponse(
        requests: requestsList,
        summary: summaryObj,
      );
    } catch (e) {
      debugPrint('💥 Error in PettyCashResponse.fromJson: $e');
      debugPrint('🔍 JSON data: $json');
      rethrow;
    }
  }
}

class PettyCashSummary {
  final int totalRequests;
  final double totalAmount;
  final double approvedAmount;
  final double pendingAmount;
  final double rejectedAmount;

  PettyCashSummary({
    required this.totalRequests,
    required this.totalAmount,
    required this.approvedAmount,
    required this.pendingAmount,
    required this.rejectedAmount,
  });

  factory PettyCashSummary.fromJson(Map<String, dynamic> json) {
    return PettyCashSummary(
      totalRequests: _parseInt(json['total_requests']) ?? 0,
      totalAmount: _parseDouble(json['total_amount']),
      approvedAmount: _parseDouble(json['approved_amount']),
      pendingAmount: _parseDouble(json['pending_amount']),
      rejectedAmount: _parseDouble(json['rejected_amount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_requests': totalRequests,
      'total_amount': totalAmount,
      'approved_amount': approvedAmount,
      'pending_amount': pendingAmount,
      'rejected_amount': rejectedAmount,
    };
  }

  // Helper methods for safe type conversion
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        debugPrint('⚠️ Warning: Could not parse double from: $value');
        return 0.0;
      }
    }
    debugPrint('⚠️ Warning: Unexpected type for double field: ${value.runtimeType}');
    return 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        debugPrint('⚠️ Warning: Could not parse int from: $value');
        return 0;
      }
    }
    debugPrint('⚠️ Warning: Unexpected type for int field: ${value.runtimeType}');
    return 0;
  }
}

// Create petty cash request model
class CreatePettyCashRequest {
  final double amount;
  final String reason;
  final String? requestDate;
  final String? receiptImage; // base64 encoded image

  CreatePettyCashRequest({
    required this.amount,
    required this.reason,
    this.requestDate,
    this.receiptImage,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'reason': reason,
      'request_date': requestDate ?? DateTime.now().toIso8601String().split('T')[0],
      if (receiptImage != null) 'receipt_image': receiptImage,
    };
  }
}

// Petty cash request response model
class PettyCashRequestResponse {
  final String requestId;
  final String message;

  PettyCashRequestResponse({
    required this.requestId,
    required this.message,
  });

  factory PettyCashRequestResponse.fromJson(Map<String, dynamic> json) {
    return PettyCashRequestResponse(
      requestId: json['request_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request_id': requestId,
      'message': message,
    };
  }
}