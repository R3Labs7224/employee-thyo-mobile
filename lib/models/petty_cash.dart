// lib/models/petty_cash.dart
class PettyCashRequest {
  final int? id;
  final int? employeeId;
  final double amount;
  final String reason;
  final String requestDate;
  final String? receiptImage;
  final String status;
  final int? approvedBy;
  final String? approvedByName;
  final String? approvalDate;
  final String? remarks;
  final String? createdAt;

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
    this.createdAt,
  });

  factory PettyCashRequest.fromJson(Map<String, dynamic> json) {
    return PettyCashRequest(
      id: json['id'],
      employeeId: json['employee_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      reason: json['reason'] ?? '',
      requestDate: json['request_date'] ?? '',
      receiptImage: json['receipt_image'],
      status: json['status'] ?? 'pending',
      approvedBy: json['approved_by'],
      approvedByName: json['approved_by_name'],
      approvalDate: json['approval_date'],
      remarks: json['remarks'],
      createdAt: json['created_at'],
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
      'created_at': createdAt,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

class PettyCashResponse {
  final List<PettyCashRequest> requests;
  final PettyCashSummary summary;

  PettyCashResponse({
    required this.requests,
    required this.summary,
  });

  factory PettyCashResponse.fromJson(Map<String, dynamic> json) {
    return PettyCashResponse(
      requests: (json['requests'] as List)
          .map((item) => PettyCashRequest.fromJson(item))
          .toList(),
      summary: PettyCashSummary.fromJson(json['summary']),
    );
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
      totalRequests: json['total_requests'] ?? 0,
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      approvedAmount: (json['approved_amount'] ?? 0).toDouble(),
      pendingAmount: (json['pending_amount'] ?? 0).toDouble(),
      rejectedAmount: (json['rejected_amount'] ?? 0).toDouble(),
    );
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
  final int requestId;
  final double amount;
  final String requestDate;
  final String status;

  PettyCashRequestResponse({
    required this.requestId,
    required this.amount,
    required this.requestDate,
    required this.status,
  });

  factory PettyCashRequestResponse.fromJson(Map<String, dynamic> json) {
    return PettyCashRequestResponse(
      requestId: json['request_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      requestDate: json['request_date'],
      status: json['status'] ?? 'pending',
    );
  }
}