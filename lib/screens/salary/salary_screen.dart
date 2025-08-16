// lib/screens/salary/salary_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/salary_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/salary/salary_slip_card.dart';
import '../../utils/helpers.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({Key? key}) : super(key: key);

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _selectedYear = DateTime.now().year;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // FIXED: Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSalaryScreen();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // FIXED: Separate initialization method to avoid setState during build
  Future<void> _initializeSalaryScreen() async {
    if (_isInitialized) return;
    
    debugPrint('💰 SalaryScreen: Initializing...');
    
    try {
      final salaryProvider = Provider.of<SalaryProvider>(context, listen: false);
      
      // Initialize the provider if needed
      await salaryProvider.initializeIfNeeded();
      
      // Start animation after data is loaded
      if (mounted) {
        _animationController.forward();
        
        setState(() {
          _isInitialized = true;
        });
      }
      
      debugPrint('✅ SalaryScreen: Initialization complete');
    } catch (e) {
      debugPrint('❌ SalaryScreen: Initialization error - $e');
    }
  }

  Future<void> _loadSalaryData() async {
    if (!mounted) return;
    
    debugPrint('🔄 SalaryScreen: Loading salary data for year: $_selectedYear');
    
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    await provider.fetchSalaryData(year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Salary Information',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSalaryData,
          ),
        ],
      ),
      body: _isInitialized 
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildYearSelector(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCurrentMonthTab(),
                        _buildSalarySlipsTab(),
                        _buildSummaryTab(),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : const LoadingWidget(),
    );
  }

  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceColor,
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_view_month_rounded, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Year:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: List.generate(5, (index) {
                    final year = DateTime.now().year - index;
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (value) {
                    if (value != null && value != _selectedYear) {
                      setState(() {
                        _selectedYear = value;
                      });
                      _loadSalaryData();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surfaceColor,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primaryColor,
        tabs: const [
          Tab(text: 'Current Month'),
          Tab(text: 'Salary Slips'),
          Tab(text: 'Summary'),
        ],
      ),
    );
  }

  Widget _buildCurrentMonthTab() {
    return Consumer<SalaryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        return RefreshIndicator(
          onRefresh: _loadSalaryData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildEstimatedSalaryCard(provider),
                const SizedBox(height: 16),
                _buildAttendanceBreakdown(provider),
                const SizedBox(height: 16),
                _buildEmployeeInfoCard(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSalarySlipsTab() {
    return Consumer<SalaryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        if (provider.salarySlips.isEmpty) {
          return RefreshIndicator(
            onRefresh: _loadSalaryData,
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
                        'No salary slips found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Salary slips will appear here once generated',
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
          onRefresh: _loadSalaryData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.salarySlips.length,
            itemBuilder: (context, index) {
              final salarySlip = provider.salarySlips[index];
              return SalarySlipCard(
                salarySlip: salarySlip,
                onTap: () => _showSalarySlipDetails(salarySlip),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab() {
    return Consumer<SalaryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        return RefreshIndicator(
          onRefresh: _loadSalaryData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildYearlySummaryCard(provider),
                const SizedBox(height: 16),
                _buildMonthlyBreakdownCard(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return RefreshIndicator(
      onRefresh: _loadSalaryData,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Error Loading Data',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red[500],
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSalaryData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedSalaryCard(SalaryProvider provider) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppTheme.successColor.withOpacity(0.1),
              AppTheme.accentColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimated Current Salary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Based on approved attendance',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              Helpers.formatCurrency(provider.estimatedCurrentSalary ?? 0),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '*Final salary may vary based on deductions and bonuses',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBreakdown(SalaryProvider provider) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Month Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.currentMonthAttendance != null) ...[
              _buildAttendanceProgress(
                'Approved Days',
                provider.currentMonthAttendance!.approvedDays,
                provider.currentMonthAttendance!.totalDays,
                AppTheme.successColor,
              ),
              const SizedBox(height: 12),
              if (provider.currentMonthAttendance!.pendingDays > 0)
                _buildAttendanceProgress(
                  'Pending Days',
                  provider.currentMonthAttendance!.pendingDays,
                  provider.currentMonthAttendance!.totalDays,
                  Colors.orange,
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      'Total Hours',
                      '${provider.currentMonthAttendance!.totalHours.toStringAsFixed(1)}h',
                      Icons.access_time,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoTile(
                      'Pending Days',
                      '${provider.currentMonthAttendance!.pendingDays} day${provider.currentMonthAttendance!.pendingDays != 1 ? 's' : ''} pending approval',
                      Icons.pending,
                      provider.currentMonthAttendance!.pendingDays > 0 
                          ? AppTheme.errorColor 
                          : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No attendance data available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceProgress(String label, int value, int total, Color color) {
    double progress = total > 0 ? value / total : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              '$value/$total',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildEmployeeInfoCard(SalaryProvider provider) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Salary Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.employeeInfo != null) ...[
              _buildInfoRow('Basic Salary', Helpers.formatCurrency(provider.employeeInfo!.basicSalary)),
              if (provider.employeeInfo!.dailyWage > 0)
                _buildInfoRow('Daily Wage', Helpers.formatCurrency(provider.employeeInfo!.dailyWage)),
              if (provider.employeeInfo!.epfNumber != null)
                _buildInfoRow('EPF Number', provider.employeeInfo!.epfNumber!),
            ] else ...[
              Text(
                'No employee information available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYearlySummaryCard(SalaryProvider provider) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Yearly Summary - $_selectedYear',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.yearlySummary != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      'Total Earned',
                      Helpers.formatCurrency(provider.yearlySummary!.totalEarned),
                      Icons.account_balance_wallet,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoTile(
                      'Total Deductions',
                      Helpers.formatCurrency(provider.yearlySummary!.totalDeductions),
                      Icons.remove_circle_outline,
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      'Total Bonus',
                      Helpers.formatCurrency(provider.yearlySummary!.totalBonus),
                      Icons.add_circle_outline,
                      AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoTile(
                      'Months Paid',
                      '${provider.yearlySummary!.totalMonths}',
                      Icons.calendar_month,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No yearly summary available',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdownCard(SalaryProvider provider) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Breakdown - $_selectedYear',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (provider.salarySlips.isNotEmpty) ...[
              ...provider.getCurrentYearSlips().map((slip) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat.MMMM().format(DateTime(slip.year, slip.month)),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      Helpers.formatCurrency(slip.netSalary),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total for Year',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    Helpers.formatCurrency(provider.getTotalEarningsForYear(_selectedYear)),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'No salary data available for $_selectedYear',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSalarySlipDetails(salarySlip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Salary Slip - ${DateFormat.MMMM().format(DateTime(salarySlip.year, salarySlip.month))} ${salarySlip.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Basic Salary', Helpers.formatCurrency(salarySlip.basicSalary)),
            _buildInfoRow('Present Days', '${salarySlip.presentDays}'),
            _buildInfoRow('Total Hours', '${salarySlip.totalHours.toStringAsFixed(1)}h'),
            _buildInfoRow('Gross Salary', Helpers.formatCurrency(salarySlip.grossSalary)),
            if (salarySlip.bonus > 0)
              _buildInfoRow('Bonus', Helpers.formatCurrency(salarySlip.bonus)),
            if (salarySlip.advance > 0)
              _buildInfoRow('Advance', Helpers.formatCurrency(salarySlip.advance)),
            if (salarySlip.deductions > 0)
              _buildInfoRow('Deductions', Helpers.formatCurrency(salarySlip.deductions)),
            const Divider(),
            _buildInfoRow('Net Salary', Helpers.formatCurrency(salarySlip.netSalary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}