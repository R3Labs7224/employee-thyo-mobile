// lib/screens/home/dashboard_screen.dart (Simplified for MainHomeLayout)
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
      debugPrint('Error initializing dashboard: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true; // Set to true even on error to show error UI
        });
      }
    }
  }

  Future<void> _refreshDashboard() async {
    if (!mounted) return;

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
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const LoadingWidget();
    }

    return Consumer4<EmployeeProvider, AttendanceProvider, TaskProvider, PettyCashProvider>(
      builder: (context, employeeProvider, attendanceProvider, taskProvider, pettyCashProvider, child) {
        // Show loading if any provider is loading
        final isAnyLoading = employeeProvider.isLoading || 
                            attendanceProvider.isLoading || 
                            taskProvider.isLoading || 
                            pettyCashProvider.isLoading;

        // Check for errors
        final hasErrors = employeeProvider.error != null ||
                         attendanceProvider.error != null ||
                         taskProvider.error != null ||
                         pettyCashProvider.error != null;

        if (isAnyLoading) {
          return const LoadingWidget();
        }

        if (hasErrors) {
          return _buildErrorWidget([
            employeeProvider.error,
            attendanceProvider.error,
            taskProvider.error,
            pettyCashProvider.error,
          ].where((error) => error != null).toList());
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
    );
  }

  Widget _buildErrorWidget(List<String?> errors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load dashboard data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (errors.isNotEmpty)
              Text(
                errors.first!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(EmployeeProvider employeeProvider) {
    final employee = employeeProvider.employee;
    if (employee == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[400],
                child: const Icon(Icons.person, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome!'),
                    Text('Employee data not available'),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.primaryColor.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
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
                  employee.departmentName ?? 'No Dept',
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.attendance);
                    },
                    icon: const Icon(Icons.access_time),
                    label: const Text('Attendance'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.tasks),
                    icon: const Icon(Icons.add_task),
                    label: const Text('Tasks'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(AttendanceProvider attendanceProvider, TaskProvider taskProvider, PettyCashProvider pettyCashProvider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Present Days',
          '${attendanceProvider.todayAttendance ?? 0}',
          Icons.calendar_today,
          Colors.green,
        ),
        _buildStatCard(
          'Active Tasks',
          '${taskProvider.activeTasks?.length ?? 0}',
          Icons.task_alt,
          Colors.blue,
        ),
        _buildStatCard(
          'Pending Requests',
          '${pettyCashProvider.pendingRequests?.length ?? 0}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Working Hours',
          '${attendanceProvider.attendanceList.first ?? '0.0'}h',
          Icons.schedule,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySection(AttendanceProvider attendanceProvider, TaskProvider taskProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: attendanceProvider.todayAttendance != null ? Colors.green : Colors.grey,
              child: Icon(
                attendanceProvider.todayAttendance != null ? Icons.check : Icons.schedule,
                color: Colors.white,
              ),
            ),
            title: const Text('Today\'s Attendance'),
            subtitle: Text(
              attendanceProvider.todayAttendance?.checkInTime != null
                  ? 'Checked in at ${attendanceProvider.todayAttendance!.checkInTime}'
                  : 'Not checked in yet',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.pushNamed(context, AppRoutes.attendance),
          ),
        ),
        const SizedBox(height: 8),
        if (taskProvider.tasks.isNotEmpty == true)
          ...taskProvider.tasks!.take(2).map((task) =>
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: task.status == 'completed' ? Colors.green : Colors.orange,
                  child: Icon(
                    task.status == 'completed' ? Icons.check : Icons.pending,
                    color: Colors.white,
                  ),
                ),
                title: Text(task.title),
                subtitle: Text('Due: ${task.endTime ?? 'No due date'}'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () => Navigator.pushNamed(context, AppRoutes.tasks),
              ),
            ),
          )
        else
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[400],
                child: const Icon(Icons.task, color: Colors.white),
              ),
              title: const Text('No Tasks for Today'),
              subtitle: const Text('Great! You\'re all caught up'),
              trailing: const Icon(Icons.add),
              onTap: () => Navigator.pushNamed(context, AppRoutes.tasks),
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
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickLinkCard(
                'View Profile',
                Icons.person,
                () => Navigator.pushNamed(context, AppRoutes.profile),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildQuickLinkCard(
                'Salary Info',
                Icons.attach_money,
                () => Navigator.pushNamed(context, AppRoutes.salary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickLinkCard(String title, IconData icon, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}