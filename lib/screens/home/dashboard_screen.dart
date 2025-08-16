// lib/screens/home/dashboard_screen.dart
import 'package:ems/utils/snackbar_helper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/petty_cash_provider.dart';
import '../../providers/employee_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/helpers.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboard();
    });
  }

  Future<void> _initializeDashboard() async {
    if (!mounted || _isInitialized) return;
    
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);

      // Initialize providers if needed
      await Future.wait([
        employeeProvider.initializeIfNeeded(),
        attendanceProvider.initializeIfNeeded(),
        taskProvider.initializeIfNeeded(),
        pettyCashProvider.initializeIfNeeded(),
      ]);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context,'Failed to load dashboard data: ${e.toString()}');
      }
    }
  }

  Future<void> _refreshDashboard() async {
    try {
      final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);

      await Future.wait([
        employeeProvider.refresh(),
        attendanceProvider.refresh(),
        taskProvider.refresh(),
        pettyCashProvider.refresh(),
      ]);

      if (mounted) {
        SnackbarHelper.showSuccess(context,'Dashboard refreshed successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError (context,'Failed to refresh dashboard: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer4<EmployeeProvider, AttendanceProvider, TaskProvider, PettyCashProvider>(
        builder: (context, employeeProvider, attendanceProvider, taskProvider, pettyCashProvider, child) {
          // Check for any loading states
          final isAnyLoading = employeeProvider.isLoading ||
                              attendanceProvider.isLoading ||
                              taskProvider.isLoading ||
                              pettyCashProvider.isLoading ||
                              !_isInitialized;

          // Show errors via snackbars instead of error widgets
          _showErrorsIfAny([
            employeeProvider.error,
            attendanceProvider.error,
            taskProvider.error,
            pettyCashProvider.error,
          ]);

          if (isAnyLoading) {
            return const LoadingWidget();
          }

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(employeeProvider),
                  const SizedBox(height: 16),
                  _buildQuickActions(context, attendanceProvider),
                  const SizedBox(height: 16),
                  _buildStatsGrid(attendanceProvider, taskProvider, pettyCashProvider),
                  const SizedBox(height: 16),
                  _buildTodaySection(attendanceProvider, taskProvider),
                  const SizedBox(height: 16),
                  _buildQuickLinks(context),
                  const SizedBox(height: 80), // Add bottom padding for navigation
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Show errors via snackbars only once
  Set<String> _shownErrors = <String>{};
  
  void _showErrorsIfAny(List<String?> errors) {
    final validErrors = errors.where((error) => error != null).cast<String>();
    for (final error in validErrors) {
      if (!_shownErrors.contains(error)) {
        _shownErrors.add(error);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            SnackbarHelper.showError(context, error);
          }
        });
      }
    }
    
    // Clear shown errors if no errors present
    if (validErrors.isEmpty) {
      _shownErrors.clear();
    }
  }

  Widget _buildWelcomeCard(EmployeeProvider employeeProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final employee = authProvider.employee;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  employee?.name?.substring(0, 1).toUpperCase() ?? 'E',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      employee?.name ?? 'Employee',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                   
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Employee ID: ${employee?.employeeCode ?? 'N/A'}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AttendanceProvider attendanceProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Check In',
                icon: Icons.login,
                color: Colors.green,
                onTap: () => Navigator.pushNamed(context, AppRoutes.checkIn),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                title: 'Check Out',
                icon: Icons.logout,
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, AppRoutes.checkOut),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    AttendanceProvider attendanceProvider,
    TaskProvider taskProvider,
    PettyCashProvider pettyCashProvider,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Overview',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              title: 'Pending Tasks',
              value: '${authProvider.activeTasks}',
              icon: Icons.task_alt,
              color: Colors.blue,
            ),
            _buildStatCard(
              title: 'Petty Cash',
              value: '${authProvider.pendingPettyCash}',
              icon: Icons.account_balance_wallet,
              color: Colors.purple,
            ),
            _buildStatCard(
              title: 'This Month',
              value: '${authProvider.monthlyStats?.approvedDays ?? 0}',
              subtitle: 'Present Days',
              icon: Icons.calendar_month,
              color: Colors.green,
            ),
            _buildStatCard(
              title: 'Total Days',
              value: '${authProvider.monthlyStats?.totalDays ?? 0}',
              subtitle: 'This Month',
              icon: Icons.calendar_today,
              color: Colors.orange,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodaySection(
    AttendanceProvider attendanceProvider,
    TaskProvider taskProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildStatusRow(
                'Check In',
                attendanceProvider.todayAttendance?.checkInTime != null 
                    ? attendanceProvider.todayAttendance!.checkInTime!
                    : 'Not checked in',
                attendanceProvider.todayAttendance?.checkInTime != null 
                    ? Colors.green 
                    : Colors.grey,
              ),
              const Divider(),
              _buildStatusRow(
                'Check Out',
                attendanceProvider.todayAttendance?.checkOutTime != null 
                    ? attendanceProvider.todayAttendance!.checkOutTime!
                    : 'Not checked out',
                attendanceProvider.todayAttendance?.checkOutTime != null 
                    ? Colors.orange 
                    : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Links',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickLinkCard(
              title: 'Attendance',
              icon: Icons.schedule,
              onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
            ),
            _buildQuickLinkCard(
              title: 'Tasks',
              icon: Icons.assignment,
              onTap: () => Navigator.pushNamed(context, AppRoutes.tasks),
            ),
            _buildQuickLinkCard(
              title: 'Petty Cash',
              icon: Icons.money,
              onTap: () => Navigator.pushNamed(context, AppRoutes.pettyCash),
            ),
            _buildQuickLinkCard(
              title: 'Salary',
              icon: Icons.payment,
              onTap: () => Navigator.pushNamed(context, AppRoutes.salary),
            ),
            _buildQuickLinkCard(
              title: 'Profile',
              icon: Icons.person,
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLinkCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }}