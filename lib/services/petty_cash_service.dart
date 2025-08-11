// lib/services/petty_cash_service.dart
import '../models/api_response.dart';
import '../models/petty_cash.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class PettyCashService {
  final ApiService _apiService = ApiService();

  // Get petty cash requests for a specific month
  Future<ApiResponse<PettyCashResponse>> getPettyCashRequests({String? month}) async {
    try {
      final Map<String, String> queryParams = {};
      if (month != null) {
        queryParams['month'] = month;
      }

      final response = await _apiService.get<PettyCashResponse>(
        AppConfig.pettyCashEndpoint,
        queryParams: queryParams,
        fromJson: (data) => PettyCashResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to fetch petty cash requests: ${e.toString()}');
    }
  }

  // Create a new petty cash request
  Future<ApiResponse<PettyCashRequestResponse>> createPettyCashRequest({
    required double amount,
    required String reason,
    String? requestDate,
    String? receiptImageBase64,
  }) async {
    try {
      final requestData = CreatePettyCashRequest(
        amount: amount,
        reason: reason,
        requestDate: requestDate,
        receiptImage: receiptImageBase64,
      );

      final response = await _apiService.post<PettyCashRequestResponse>(
        AppConfig.pettyCashEndpoint,
        requestData.toJson(),
        fromJson: (data) => PettyCashRequestResponse.fromJson(data),
      );

      return response;
    } catch (e) {
      return ApiResponse.error('Failed to create petty cash request: ${e.toString()}');
    }
  }

  // Get pending requests count
  int getPendingRequestsCount(List<PettyCashRequest> requests) {
    return requests.where((request) => request.isPending).length;
  }

  // Get approved amount for current month
  double getApprovedAmount(List<PettyCashRequest> requests) {
    return requests
        .where((request) => request.isApproved)
        .fold(0.0, (sum, request) => sum + request.amount);
  }

  // Get total requested amount for current month
  double getTotalRequestedAmount(List<PettyCashRequest> requests) {
    return requests.fold(0.0, (sum, request) => sum + request.amount);
  }

  // Filter requests by status
  List<PettyCashRequest> filterByStatus(List<PettyCashRequest> requests, String status) {
    return requests.where((request) => request.status == status).toList();
  }

  // Get requests for current month
  List<PettyCashRequest> getCurrentMonthRequests(List<PettyCashRequest> requests) {
    final now = DateTime.now();
    final currentMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    
    return requests.where((request) {
      final requestMonth = request.requestDate.substring(0, 7); // YYYY-MM
      return requestMonth == currentMonth;
    }).toList();
  }
}