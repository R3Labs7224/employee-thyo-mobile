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
  bool _isInitialized = false;

  // Getters
  List<PettyCashRequest> get requests => _requests;
  PettyCashSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

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

  // FIXED: Complete implementation of fetchPettyCashRequests method
  Future<void> fetchPettyCashRequests({String? month}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      debugPrint('🔄 Fetching petty cash requests for month: ${month ?? 'current'}');
      
      // Call the actual API service to fetch petty cash requests
      final response = await _pettyCashService.getPettyCashRequests(month: month);

      if (response.success && response.data != null) {
        // Extract the data from the API response
        final pettyCashResponse = response.data!;
        
        // Update the requests list
        _requests = pettyCashResponse.requests;
        
        // Update the summary if available
        _summary = pettyCashResponse.summary;
        
        // Clear any previous errors
        _error = null;
        
        // Mark as initialized
        _isInitialized = true;
        
        debugPrint('✅ Petty cash data loaded successfully: ${_requests.length} requests');
        debugPrint('📊 Summary - Total: ${_summary?.totalRequests}, Approved: \${_summary?.approvedAmount}');
      } else {
        // Handle API error response
        _error = response.message ?? 'Failed to fetch petty cash requests';
        _requests = [];
        _summary = null;
        
        debugPrint('❌ API Error: $_error');
      }
    } catch (e) {
      // Handle unexpected errors
      _error = 'Failed to fetch petty cash requests: ${e.toString()}';
      _requests = [];
      _summary = null;
      
      debugPrint('💥 Exception in fetchPettyCashRequests: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fetch requests for a specific month
  Future<void> fetchPettyCashRequestsForMonth(String month) async {
    await fetchPettyCashRequests(month: month);
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
        // Refresh requests after successful submission
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

  // Get requests by status
  List<PettyCashRequest> getRequestsByStatus(String status) {
    return _pettyCashService.filterByStatus(_requests, status);
  }

  // Get total amount for status
  double getTotalAmountByStatus(String status) {
    final filteredRequests = getRequestsByStatus(status);
    return filteredRequests.fold(0.0, (sum, request) => sum + request.amount);
  }

  // Check if there are any pending requests
  bool get hasPendingRequests => pendingCount > 0;

  // Get latest request
  PettyCashRequest? get latestRequest {
    if (_requests.isEmpty) return null;
    return _requests.first; // Assuming requests are ordered by date DESC
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
    _isInitialized = false;
    notifyListeners();
  }

  // Force refresh - bypasses initialization check
  Future<void> forceRefresh() async {
    await fetchPettyCashRequests();
  }
}