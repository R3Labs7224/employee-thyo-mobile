import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/petty_cash_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);

    await Future.wait([
      attendanceProvider.fetchAttendance(),
      taskProvider.fetchTasks(),
      pettyCashProvider.fetchPettyCashRequests(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dashboard',
        showBackButton: false,
      ),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadInitialData,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildWelcomeCard(),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildTodayStatus(),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildQuickActions(),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildStatsCards(),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildRecentActivity(),
                ),
                const SizedBox(height: 16),
                SlideTransition(
                  position: _slideAnimation,
                  child: _buildUpcomingReminders(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final employee = authProvider.employee;
        return Drawer(
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(
                  employee?.name ?? 'Employee',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                accountEmail: Text(employee?.email ?? ''),
                currentAccountPicture: ScaleTransition(
                  scale: _scaleAnimation,
                  child: CircleAvatar(
                    backgroundColor: AppTheme.accentColor,
                    child: Text(
                      employee?.name?.substring(0, 1).toUpperCase() ?? 'E',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Colors.indigo],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerItem(
                      Icons.dashboard,
                      'Dashboard',
                      () => Navigator.pop(context),
                      isSelected: true,
                    ),
                    _buildDrawerItem(
                      Icons.access_time,
                      'Attendance',
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.attendance);
                      },
                    ),
                    _buildDrawerItem(
                      Icons.task,
                      'Tasks',
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.tasks);
                      },
                    ),
                    _buildDrawerItem(
                      Icons.attach_money,
                      'Petty Cash',
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.pettyCash);
                      },
                    ),
                    _buildDrawerItem(
                      Icons.payment,
                      'Salary',
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.salary);
                      },
                    ),
                    _buildDrawerItem(
                      Icons.person,
                      'Profile',
                      () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.profile);
                      },
                    ),
                    const Divider(),
                    _buildDrawerItem(
                      Icons.settings,
                      'Settings',
                      () {
                        Navigator.pop(context);
                        _showSettingsDialog();
                      },
                    ),
                    _buildDrawerItem(
                      Icons.help_outline,
                      'Help & Support',
                      () {
                        Navigator.pop(context);
                        _showSupportDialog();
                      },
                    ),
                    _buildDrawerItem(
                      Icons.logout,
                      'Logout',
                      () {
                        Navigator.pop(context);
                        _showLogoutDialog();
                      },
                      textColor: Colors.red,
                      iconColor: Colors.red,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isSelected = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? (isSelected ? AppTheme.primaryColor : Colors.grey[600]),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: textColor ?? (isSelected ? AppTheme.primaryColor : Colors.black87),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final employee = authProvider.employee;
        return CustomCard(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: AppTheme.accentColor,
                    child: Text(
                      employee?.name?.substring(0, 1).toUpperCase() ?? 'E',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        employee?.name ?? 'Employee',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        employee?.departmentName ?? '',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          employee?.employeeCode ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.waving_hand,
                  color: AppTheme.accentColor,
                  size: 28,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTodayStatus() {
    return Consumer<AttendanceProvider>(
      builder: (context, provider, _) {
        final todayAttendance = provider.todayAttendance;
        final permissions = provider.permissions;
        
        return CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today\'s Status',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd MMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusItem(
                        'Check In',
                        todayAttendance?.checkInTime != null
                            ? DateFormat('HH:mm').format(
                                DateTime.parse(todayAttendance!.checkInTime!))
                            : 'Not checked in',
                        Icons.login,
                        todayAttendance?.checkInTime != null
                            ? AppTheme.successColor
                            : Colors.grey,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Expanded(
                      child: _buildStatusItem(
                        'Check Out',
                        todayAttendance?.checkOutTime != null
                            ? DateFormat('HH:mm').format(
                                DateTime.parse(todayAttendance!.checkOutTime!))
                            : 'Not checked out',
                        Icons.logout,
                        todayAttendance?.checkOutTime != null
                            ? Colors.orange
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildAttendanceStatusBanner(permissions, todayAttendance),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAttendanceStatusBanner(permissions, todayAttendance) {
    String message;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (permissions?.canCheckin == true) {
      message = 'Ready to check in for today';
      backgroundColor = AppTheme.successColor.withOpacity(0.1);
      textColor = AppTheme.successColor;
      icon = Icons.play_circle_outline;
    } else if (permissions?.canCheckout == true) {
      message = 'You are checked in. Remember to check out';
      backgroundColor = AppTheme.accentColor.withOpacity(0.1);
      textColor = AppTheme.accentColor;
      icon = Icons.access_time;
    } else if (todayAttendance?.checkOutTime != null) {
      message = 'You have completed your shift for today';
      backgroundColor = AppTheme.primaryColor.withOpacity(0.1);
      textColor = AppTheme.primaryColor;
      icon = Icons.check_circle_outline;
    } else {
      message = 'Check your attendance status';
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey[600]!;
      icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
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
        Consumer<AttendanceProvider>(
          builder: (context, attendanceProvider, _) {
            final permissions = attendanceProvider.permissions;
            
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.login,
                        label: 'Check In',
                        color: AppTheme.successColor,
                        onTap: permissions?.canCheckIn == true
                            ? () => Navigator.pushNamed(context, AppRoutes.checkIn)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.logout,
                        label: 'Check Out',
                        color: Colors.orange,
                        onTap: permissions?.canCheckOut == true
                            ? () => Navigator.pushNamed(context, AppRoutes.checkOut)
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.add_task,
                        label: 'Create Task',
                        color: AppTheme.primaryColor,
                        onTap: permissions?.canCreateTasks == true
                            ? () => Navigator.pushNamed(context, AppRoutes.createTask)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        icon: Icons.receipt,
                        label: 'Petty Cash',
                        color: AppTheme.accentColor,
                        onTap: () => Navigator.pushNamed(context, AppRoutes.createRequest),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return CustomCard(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onTap != null ? color.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: onTap != null ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: onTap != null ? color : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: onTap != null ? color : Colors.grey,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Month Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Consumer3<AttendanceProvider, TaskProvider, PettyCashProvider>(
          builder: (context, attendanceProvider, taskProvider, pettyCashProvider, _) {
            if (attendanceProvider.isLoading || 
                taskProvider.isLoading || 
                pettyCashProvider.isLoading) {
              return const LoadingWidget(message: 'Loading statistics...');
            }

            final attendanceSummary = attendanceProvider.summary;
            final taskSummary = taskProvider.summary;
            final pettyCashSummary = pettyCashProvider.summary;

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Attendance',
                        value: '${attendanceSummary?.approvedDays ?? 0}',
                        subtitle: '${attendanceSummary?.totalDays ?? 0} days',
                        icon: Icons.calendar_today,
                        color: AppTheme.primaryColor,
                        progress: attendanceSummary != null && attendanceSummary.totalDays > 0
                            ? attendanceSummary.approvedDays / attendanceSummary.totalDays
                            : 0.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Tasks',
                        value: '${taskSummary?.completedTasks ?? 0}',
                        subtitle: '${taskSummary?.totalTasks ?? 0} total',
                        icon: Icons.task_alt,
                        color: AppTheme.accentColor,
                        progress: taskSummary != null && taskSummary.totalTasks > 0
                            ? taskSummary.completedTasks / taskSummary.totalTasks
                            : 0.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Working Hours',
                        value: '${attendanceSummary?.totalHours.toStringAsFixed(1) ?? '0.0'}',
                        subtitle: 'hrs worked',
                        icon: Icons.schedule,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Petty Cash',
                        value: '₹${pettyCashSummary?.pendingAmount.toStringAsFixed(0) ?? '0'}',
                        subtitle: 'pending',
                        icon: Icons.attach_money,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
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
    double? progress,
  }) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.attendance),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Consumer<AttendanceProvider>(
          builder: (context, provider, _) {
            if (provider.attendanceList.isEmpty) {
              return CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No recent activity',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your attendance history will appear here',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.attendanceList.take(3).length,
              itemBuilder: (context, index) {
                final attendance = provider.attendanceList[index];
                return CustomCard(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(attendance.status).withOpacity(0.2),
                      child: Icon(
                        Icons.access_time,
                        color: _getStatusColor(attendance.status),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      DateFormat('dd MMM yyyy').format(DateTime.parse(attendance.date)),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${attendance.checkInTime != null ? DateFormat('HH:mm').format(DateTime.parse(attendance.checkInTime!)) : '--:--'} - ${attendance.checkOutTime != null ? DateFormat('HH:mm').format(DateTime.parse(attendance.checkOutTime!)) : '--:--'}',
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(attendance.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        attendance.status?.toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          color: _getStatusColor(attendance.status),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpcomingReminders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reminders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Consumer2<TaskProvider, PettyCashProvider>(
          builder: (context, taskProvider, pettyCashProvider, _) {
            final List<Widget> reminders = [];

            // Active tasks reminder
            if (taskProvider.summary != null && taskProvider.summary!.activeTasks > 0) {
              reminders.add(_buildReminderCard(
                'Active Tasks',
                'You have ${taskProvider.summary!.activeTasks} active task${taskProvider.summary!.activeTasks == 1 ? '' : 's'} to complete',
                Icons.task,
                AppTheme.accentColor,
                () => Navigator.pushNamed(context, AppRoutes.tasks),
              ));
            }

            // Pending petty cash reminder
            if (pettyCashProvider.summary != null && pettyCashProvider.summary!.pendingAmount > 0) {
              reminders.add(_buildReminderCard(
                'Pending Approval',
                'Petty cash worth ₹${pettyCashProvider.summary!.pendingAmount.toStringAsFixed(0)} is pending approval',
                Icons.pending,
                Colors.orange,
                () => Navigator.pushNamed(context, AppRoutes.pettyCash),
              ));
            }

            // Salary slip reminder (if it's after 5th of the month)
            if (DateTime.now().day > 5) {
              reminders.add(_buildReminderCard(
                'Salary Slip',
                'Check your latest salary slip',
                Icons.payment,
                AppTheme.primaryColor,
                () => Navigator.pushNamed(context, AppRoutes.salary),
              ));
            }

            if (reminders.isEmpty) {
              return CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All caught up!',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No pending reminders at the moment',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(children: reminders);
          },
        ),
      ],
    );
  }

  Widget _buildReminderCard(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return CustomCard(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppTheme.successColor;
      case 'pending':
        return AppTheme.accentColor;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings panel will be available in future updates.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For technical support, please contact:'),
            SizedBox(height: 8),
            Text('Email: support@company.com'),
            Text('Phone: +91 1234567890'),
            SizedBox(height: 8),
            Text('Working Hours: 9:00 AM - 6:00 PM'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
