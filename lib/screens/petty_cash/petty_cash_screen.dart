// lib/screens/petty_cash/petty_cash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/petty_cash_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/helpers.dart';

class PettyCashScreen extends StatefulWidget {
  const PettyCashScreen({Key? key}) : super(key: key);

  @override
  State<PettyCashScreen> createState() => _PettyCashScreenState();
}

class _PettyCashScreenState extends State<PettyCashScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    
    // Initialize data loading
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPettyCash();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // FIXED: Complete implementation of data loading
  Future<void> _loadPettyCash() async {
    final provider = Provider.of<PettyCashProvider>(context, listen: false);
    
    try {
      // Fetch petty cash requests for the selected month
      await provider.fetchPettyCashRequestsForMonth(_selectedMonth);
    } catch (e) {
      // Error handling is managed by the provider
      debugPrint('Error loading petty cash data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Petty Cash',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: _selectMonth,
            tooltip: 'Select Month',
          ),
        ],
        // bottom: TabBar(
        //   controller: _tabController,
        //   tabs: const [
        //     Tab(text: 'Overview'),
        //     Tab(text: 'Requests'),
        //   ],
        // ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildRequestsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.pettyCash)
              .then((result) {
            if (result == true) {
              // Refresh data if request was created successfully
              _loadPettyCash();
            }
          });
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<PettyCashProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        return RefreshIndicator(
          onRefresh: _loadPettyCash,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Month selector
              _buildMonthSelector(),
              const SizedBox(height: 16),
              
              // Summary cards
              if (provider.summary != null) ...[
                _buildSummaryCards(provider.summary!),
                const SizedBox(height: 16),
              ],
              
              // Create request card
              _buildCreateRequestCard(),
              const SizedBox(height: 16),
              
              // Recent requests
              _buildRecentRequests(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<PettyCashProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        if (provider.requests.isEmpty) {
          return RefreshIndicator(
            onRefresh: _loadPettyCash,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No petty cash requests',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap the + button to create your first request',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadPettyCash,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.requests.length + 1, // +1 for month selector
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    _buildMonthSelector(),
                    const SizedBox(height: 16),
                  ],
                );
              }
              
              final request = provider.requests[index - 1];
              return _buildRequestCard(request);
            },
          ),
        );
      },
    );
  }

  Widget _buildMonthSelector() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.calendar_month,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Month',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.parse('$_selectedMonth-01')),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _selectMonth,
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Total Requests',
                summary.totalRequests.toString(),
                Icons.receipt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Total Amount',
                Helpers.formatCurrency(summary.totalAmount),
                Icons.account_balance_wallet,
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'Approved',
                Helpers.formatCurrency(summary.approvedAmount),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'Pending',
                Helpers.formatCurrency(summary.pendingAmount),
                Icons.pending,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRequestCard() {
    return CustomCard(
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.pettyCash)
            .then((result) {
          if (result == true) {
            _loadPettyCash();
          }
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submit a new petty cash request',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentRequests(PettyCashProvider provider) {
    final recentRequests = provider.requests.take(3).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (provider.requests.length > 3)
              TextButton(
                onPressed: () {
                  _tabController.animateTo(1); // Switch to Requests tab
                },
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (recentRequests.isEmpty)
          CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No recent requests',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...recentRequests.map((request) => _buildRequestCard(request)),
      ],
    );
  }

  Widget _buildRequestCard(request) {
    return CustomCard(
      onTap: () => _showRequestDetails(request),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  Helpers.formatCurrency(request.amount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              request.reason,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${Helpers.formatDate(DateTime.parse(request.requestDate))}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String text;
    
    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green;
        text = 'Approved';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Rejected';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = 'Pending';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Data',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadPettyCash,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _selectMonth() {
    showDatePicker(
      context: context,
      initialDate: DateTime.parse('$_selectedMonth-01'),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate != null) {
        final newMonth = DateFormat('yyyy-MM').format(selectedDate);
        if (newMonth != _selectedMonth) {
          setState(() {
            _selectedMonth = newMonth;
          });
          // Load data for the new month
          _loadPettyCash();
        }
      }
    });
  }

  void _showRequestDetails(request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Request Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 20),
            
            _buildDetailRow('Amount', Helpers.formatCurrency(request.amount)),
            _buildDetailRow('Reason', request.reason),
            _buildDetailRow('Request Date', Helpers.formatDate(DateTime.parse(request.requestDate))),
            
            if (request.approvedByName != null)
              _buildDetailRow('Approved By', request.approvedByName!),
            if (request.approvalDate != null)
              _buildDetailRow('Approval Date', Helpers.formatDate(DateTime.parse(request.approvalDate!))),
            if (request.remarks != null && request.remarks!.isNotEmpty)
              _buildDetailRow('Remarks', request.remarks!),
              
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}