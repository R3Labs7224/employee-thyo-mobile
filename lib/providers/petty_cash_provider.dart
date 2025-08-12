// lib/providers/petty_cash_provider.dart
import 'package:flutter/material.dart';
import '../models/petty_cash.dart';
import '../services/petty_cash_service.dart';

class PettyCashProvider with ChangeNotifier {
  final PettyCashService _pettyCashService = PettyCashService();

  List<PettyCashRequest> _requests = [];
  PettyCashSummary? _summary;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<PettyCashRequest> get requests => _requests;
  PettyCashSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filter getters
  List<PettyCashRequest> get pendingRequests => 
      _pettyCashService.filterByStatus(_requests, 'pending');
  
  List<PettyCashRequest> get approvedRequests => 
      _pettyCashService.filterByStatus(_requests, 'approved');
  
  List<PettyCashRequest> get rejectedRequests => 
      _pettyCashService.filterByStatus(_requests, 'rejected');

  // Statistics getters
  int get pendingCount => _pettyCashService.getPendingRequestsCount(_requests);
  double get approvedAmount => _pettyCashService.getApprovedAmount(_requests);
  double get totalRequestedAmount => _pettyCashService.getTotalRequestedAmount(_requests);

   bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> initializeIfNeeded() async {
    if (!_isInitialized && !_isLoading) {
      await fetchPettyCashRequests();
      _isInitialized = true;
    }
  }

  Future<void> refresh() async {
    _isInitialized = false;
    await fetchPettyCashRequests();
    _isInitialized = true;
  }

  // Update existing fetchPettyCashRequests method to set initialized flag
  Future<void> fetchPettyCashRequests() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // ... existing fetch logic ...
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to fetch petty cash requests: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Submit new petty cash request
  Future<bool> submitRequest({
    required double amount,
    required String reason,
    String? requestDate,
    String? receiptImageBase64,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _pettyCashService.createPettyCashRequest(
        amount: amount,
        reason: reason,
        requestDate: requestDate,
        receiptImageBase64: receiptImageBase64,
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

  // Get requests for current month
  List<PettyCashRequest> getCurrentMonthRequests() {
    return _pettyCashService.getCurrentMonthRequests(_requests);
  }

  // Get request by ID
  PettyCashRequest? getRequestById(int requestId) {
    try {
      return _requests.firstWhere((request) => request.id == requestId);
    } catch (e) {
      return null;
    }
  }

  // Get requests by date range
  List<PettyCashRequest> getRequestsByDateRange(DateTime startDate, DateTime endDate) {
    return _requests.where((request) {
      final requestDate = DateTime.parse(request.requestDate);
      return requestDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
             requestDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset data
  void reset() {
    _requests.clear();
    _summary = null;
    _error = null;
    notifyListeners();
  }
}