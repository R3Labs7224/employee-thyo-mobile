class PettyCashRequest {
  final int? id;
  final double amount;
  final String reason;
  final String requestDate;
  final String status;
  final String? receiptImage;
  final String? approvedByName;
  final String? approvalDate;
  final String? notes;

  PettyCashRequest({
    this.id,
    required this.amount,
    required this.reason,
    required this.requestDate,
    required this.status,
    this.receiptImage,
    this.approvedByName,
    this.approvalDate,
    this.notes,
  });

  factory PettyCashRequest.fromJson(Map<String, dynamic> json) {
    return PettyCashRequest(
      id: json['id'],
      amount: json['amount'].toDouble(),
      reason: json['reason'],
      requestDate: json['request_date'],
      status: json['status'],
      receiptImage: json['receipt_image'],
      approvedByName: json['approved_by_name'],
      approvalDate: json['approval_date'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'reason': reason,
      'request_date': requestDate,
      'receipt_image': receiptImage,
    };
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
      totalRequests: json['total_requests'],
      totalAmount: json['total_amount'].toDouble(),
      approvedAmount: json['approved_amount'].toDouble(),
      pendingAmount: json['pending_amount'].toDouble(),
      rejectedAmount: json['rejected_amount'].toDouble(),
    );
  }
}
