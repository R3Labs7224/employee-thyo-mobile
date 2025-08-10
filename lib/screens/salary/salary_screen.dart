import 'package:ems/providers/salary_provider.dart';
import 'package:ems/widgets/salary/salary_slip_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/helpers.dart';

class SalaryScreen extends StatefulWidget {
  const SalaryScreen({Key? key}) : super(key: key);

  @override
  State<SalaryScreen> createState() => _SalaryScreenState();
}

class _SalaryScreenState extends State<SalaryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _selectedYear = DateTime.now().year;

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

    _animationController.forward();
    _loadSalaryData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSalaryData() async {
    final provider = Provider.of<SalaryProvider>(context, listen: false);
    await provider.fetchSalaryData(year: _selectedYear);
  }

  @override
  Widget build(BuildContext context) {
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
      body: FadeTransition(
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
      ),
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
              Expanded(
                child: Text(
                  'Year: $_selectedYear',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _selectYear(),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primaryColor,
      tabs: const [
        Tab(text: 'Current'),
        Tab(text: 'History'),
        Tab(text: 'Summary'),
      ],
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCurrentMonthCard(provider),
              const SizedBox(height: 16),
              _buildEstimatedSalaryCard(provider),
              const SizedBox(height: 16),
              _buildAttendanceBreakdown(provider),
              const SizedBox(height: 16),
              _buildEmployeeInfoCard(provider),
            ],
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildYearlySummaryCard(provider),
              const SizedBox(height: 16),
              _buildMonthlyBreakdown(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentMonthCard(provider) {
    final currentMonth = DateFormat('MMMM yyyy').format(DateTime.now());
    
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.calendar_month,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentMonth,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Current month progress',
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
            if (provider.currentMonthAttendance != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTile(
                      'Working Days',
                      '${provider.currentMonthAttendance!.approvedDays}/${provider.currentMonthAttendance!.totalDays}',
                      Icons.calendar_today,
                      AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoTile(
                      'Total Hours',
                      '${provider.currentMonthAttendance!.totalHours.toStringAsFixed(1)}h',
                      Icons.schedule,
                      AppTheme.accentColor,
                    ),
                  ),
                ],
              ),
              if (provider.currentMonthAttendance!.pendingDays > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.pending,
                        color: Colors.orange[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${provider.currentMonthAttendance!.pendingDays} day${provider.currentMonthAttendance!.pendingDays > 1 ? 's' : ''} pending approval',
                          style: TextStyle(
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEstimatedSalaryCard(provider) {
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

  Widget _buildAttendanceBreakdown(provider) {
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

  Widget _buildEmployeeInfoCard(provider) {
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildYearlySummaryCard(provider) {
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
                      'Months Paid',
                      provider.yearlySummary!.monthsPaid.toString(),
                      Icons.calendar_month,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInfoTile(
                'Average Monthly',
                Helpers.formatCurrency(provider.yearlySummary!.avgMonthlySalary),
                Icons.trending_up,
                AppTheme.accentColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyBreakdown(provider) {
    if (provider.salarySlips.isEmpty) {
      return CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'No salary data available for breakdown',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ),
        ),
      );
    }

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...provider.salarySlips.take(6).map((slip) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('MMM yyyy').format(DateTime(slip.year, slip.month)),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    Helpers.formatCurrency(slip.netSalary),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: slip.status == 'paid' ? AppTheme.successColor : Colors.orange,
                    ),
                  ),
                ],
              ),
            )),
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

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Salary Data',
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
            onPressed: _loadSalaryData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _selectYear() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Year'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: 5,
            itemBuilder: (context, index) {
              final year = DateTime.now().year - index;
              return ListTile(
                title: Text(year.toString()),
                selected: year == _selectedYear,
                onTap: () {
                  setState(() {
                    _selectedYear = year;
                  });
                  Navigator.pop(context);
                  _loadSalaryData();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSalarySlipDetails(salarySlip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salary Slip - ${DateFormat('MMM yyyy').format(DateTime(salarySlip.year, salarySlip.month))}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Basic Salary', Helpers.formatCurrency(salarySlip.basicSalary)),
            _buildDetailRow('Working Days', '${salarySlip.presentDays}/${salarySlip.totalWorkingDays}'),
            _buildDetailRow('Calculated Salary', Helpers.formatCurrency(salarySlip.calculatedSalary)),
            if (salarySlip.bonus > 0)
              _buildDetailRow('Bonus', Helpers.formatCurrency(salarySlip.bonus)),
            if (salarySlip.advance > 0)
              _buildDetailRow('Advance', Helpers.formatCurrency(salarySlip.advance)),
            if (salarySlip.deductions > 0)
              _buildDetailRow('Deductions', Helpers.formatCurrency(salarySlip.deductions)),
            const Divider(),
            _buildDetailRow('Net Salary', Helpers.formatCurrency(salarySlip.netSalary), isTotal: true),
            _buildDetailRow('Status', salarySlip.status.toUpperCase()),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.black : Colors.grey[600],
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.successColor : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
