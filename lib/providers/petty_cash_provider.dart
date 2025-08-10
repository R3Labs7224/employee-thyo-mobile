import 'package:flutter/material.dart';
import '../models/petty_cash.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';

class PettyCashProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<PettyCashRequest> _requests = [];
  PettyCashSummary? _summary;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PettyCashRequest> get requests => _requests;
  PettyCashSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPettyCashRequests({String? month}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (month != null) {
        queryParams['month'] = month;
      }

      final response = await _apiService.get<PettyCashResponse>(
        AppConfig.pettyCashEndpoint,
        queryParams: queryParams,
        fromJson: (data) => PettyCashResponse.fromJson(data),
      );

      if (response.success && response.data != null) {
        _requests = response.data!.requests;
        _summary = response.data!.summary;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = 'Failed to fetch petty cash requests: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitRequest({
    required double amount,
    required String reason,
    required String requestDate,
    String? receiptImageBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final body = <String, dynamic>{
        'amount': amount,
        'reason': reason,
        'request_date': requestDate,
      };

      if (receiptImageBase64 != null) {
        body['receipt_image'] = receiptImageBase64;
      }

      final response = await _apiService.post(
        AppConfig.pettyCashEndpoint,
        body,
      );

      if (response.success) {
        // Refresh requests
        await fetchPettyCashRequests();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to submit request: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
