// lib/screens/home/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/petty_cash_provider.dart';
import '../../providers/employee_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';

import '../../utils/helpers.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  Future<void> _initializeDashboard() async {
    final employeeProvider = Provider.of<EmployeeProvider>(context, listen: false);
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);

    // Fetch all dashboard data
    await Future.wait([
      employeeProvider.fetchProfile(),
      attendanceProvider.fetchAttendance(),
      taskProvider.fetchTasks(),
      pettyCashProvider.fetchPettyCashRequests(),
    ]);
  }

  Future<void> _refreshDashboard() async {
    await _initializeDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: Consumer4<EmployeeProvider, AttendanceProvider, TaskProvider, PettyCashProvider>(
        builder: (context, employeeProvider, attendanceProvider, taskProvider, pettyCashProvider, child) {
          if (employeeProvider.isLoading || 
              attendanceProvider.isLoading || 
              taskProvider.isLoading || 
              pettyCashProvider.isLoading) {
            return const LoadingWidget();
          }

          if (employeeProvider.error != null ||
              attendanceProvider.error != null ||
              taskProvider.error != null ||
              pettyCashProvider.error != null) {
            return _buildErrorWidget();
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeCard(EmployeeProvider employeeProvider) {
    final employee = employeeProvider.employee;
    if (employee == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                employee.name.isNotEmpty ? employee.name[0].toUpperCase() : 'E',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
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
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    employee.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    employee.employeeCode,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(
                  Icons.business,
                  color: Colors.grey[600],
                ),
                Text(
                  employee.departmentName ?? 'N/A',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, AttendanceProvider attendanceProvider) {
    final todayAttendance = attendanceProvider.todayAttendance;
    final canCheckIn = attendanceProvider.canCheckIn;
    final canCheckOut = attendanceProvider.canCheckOut;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.login,
                    label: 'Check In',
                    color: Colors.green,
                    enabled: canCheckIn,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.checkIn),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    context: context,
                    icon: Icons.logout,
                    label: 'Check Out',
                    color: Colors.orange,
                    enabled: canCheckOut,
                    onTap: () => Navigator.pushNamed(context, AppRoutes.checkOut),
                  ),
                ),
              ],
            ),
            if (todayAttendance != null) ...[
              const SizedBox(height: 16),
              _buildTodayStatus(todayAttendance),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? color : Colors.grey,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: enabled ? color : Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: enabled ? color : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatus(attendance) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (attendance.checkInTime != null) ...[
                      Text('In: ${attendance.checkInTime}'),
                      if (attendance.checkOutTime != null) ...[
                        const SizedBox(width: 16),
                        Text('Out: ${attendance.checkOutTime}'),
                      ],
                    ] else
                      const Text('Not checked in yet'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(attendance.status),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              attendance.status?.toUpperCase() ?? 'PENDING',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    AttendanceProvider attendanceProvider,
    TaskProvider taskProvider,
    PettyCashProvider pettyCashProvider,
  ) {
    final attendanceStats = attendanceProvider.summary;
    final taskSummary = taskProvider.summary;
    final pettyCashSummary = pettyCashProvider.summary;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          title: 'Attendance',
          value: '${attendanceStats['approvedDays'] ?? 0}/${attendanceStats['totalDays'] ?? 0}',
          subtitle: 'This Month',
          icon: Icons.calendar_today,
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
        ),
        _buildStatCard(
          title: 'Tasks',
          value: '${taskSummary?.completedTasks ?? 0}',
          subtitle: 'Completed',
          icon: Icons.task_alt,
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, AppRoutes.tasks),
        ),
        _buildStatCard(
          title: 'Petty Cash',
          value: '\$${pettyCashSummary?.pendingAmount?.toStringAsFixed(0) ?? '0'}',
          subtitle: 'Pending',
          icon: Icons.account_balance_wallet,
          color: Colors.orange,
          onTap: () => Navigator.pushNamed(context, AppRoutes.pettyCash),
        ),
        _buildStatCard(
          title: 'Salary',
          value: 'View',
          subtitle: 'Slips',
          icon: Icons.payment,
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, AppRoutes.salary),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 24),
                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                '$title • $subtitle',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaySection(
    AttendanceProvider attendanceProvider,
    TaskProvider taskProvider,
  ) {
    final activeTask = taskProvider.activeTask;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (activeTask != null)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.orange,
                child: const Icon(Icons.task, color: Colors.white),
              ),
              title: Text(activeTask.title),
              subtitle: Text('Active Task • ${activeTask.siteName ?? 'No site'}'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.pushNamed(context, AppRoutes.completeTask),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[400],
                child: const Icon(Icons.task, color: Colors.white),
              ),
              title: const Text('No Active Tasks'),
              subtitle: const Text('Create a new task to get started'),
              trailing: const Icon(Icons.add),
              onTap: taskProvider.canCreateTask
                  ? () => Navigator.pushNamed(context, AppRoutes.createTask)
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Links',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Attendance History'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.request_page),
                title: const Text('Petty Cash Requests'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, AppRoutes.pettyCash),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard data',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please check your connection and try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}