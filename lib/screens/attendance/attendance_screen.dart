// lib/screens/attendance/attendance_screen.dart - UPDATED: Removed time references
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/attendance_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/attendance.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../config/theme.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    if (!attendanceProvider.isInitialized) {
      await attendanceProvider.initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Attendance'),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading && !attendanceProvider.isInitialized) {
            return const LoadingWidget();
          }

          if (attendanceProvider.error != null) {
            return _buildErrorState(attendanceProvider);
          }

          return _buildAttendanceContent(attendanceProvider);
        },
      ),
      floatingActionButton: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading) {
            return const SizedBox.shrink();
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Check-in FAB
              if (!attendanceProvider.isCheckedIn)
                FloatingActionButton.extended(
                  heroTag: "checkin",
                  onPressed: () => _navigateToCheckIn(),
                  backgroundColor: AppTheme.primaryColor,
                  icon: const Icon(Icons.login),
                  label: const Text('Check In'),
                ),
              
              // Check-out FAB
              if (attendanceProvider.isCheckedIn && !attendanceProvider.isCheckedOut) ...[
                const SizedBox(height: 10),
                FloatingActionButton.extended(
                  heroTag: "checkout",
                  onPressed: () => _navigateToCheckOut(),
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.logout),
                  label: const Text('Check Out'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(AttendanceProvider attendanceProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            attendanceProvider.error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => attendanceProvider.refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceContent(AttendanceProvider attendanceProvider) {
    return RefreshIndicator(
      onRefresh: attendanceProvider.refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Today's Status Card
            _buildTodayStatusCard(attendanceProvider),
            const SizedBox(height: 20),
            
            // Monthly Summary Card
            _buildMonthlySummaryCard(attendanceProvider),
            const SizedBox(height: 20),
            
            // Recent Attendance History
            _buildRecentHistorySection(attendanceProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatusCard(AttendanceProvider attendanceProvider) {
    final todayAttendance = attendanceProvider.todayAttendance;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.today, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Text(
                  'Today\'s Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (todayAttendance == null) ...[
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange),
                  SizedBox(width: 8),
                  Text(
                    'No attendance recorded today',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ] else ...[
              // Check-in Status
              Row(
                children: [
                  Icon(
                    todayAttendance.isCheckedIn 
                        ? Icons.check_circle 
                        : Icons.radio_button_unchecked,
                    color: todayAttendance.isCheckedIn 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check In: ${todayAttendance.isCheckedIn ? "Completed" : "Pending"}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Check-out Status
              Row(
                children: [
                  Icon(
                    todayAttendance.isCheckedOut 
                        ? Icons.check_circle 
                        : Icons.radio_button_unchecked,
                    color: todayAttendance.isCheckedOut 
                        ? Colors.green 
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Check Out: ${todayAttendance.isCheckedOut ? "Completed" : "Pending"}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Site Information
              if (todayAttendance.siteName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.business, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Site: ${todayAttendance.siteName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              
              // Status Badge
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(todayAttendance.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(todayAttendance.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlySummaryCard(AttendanceProvider attendanceProvider) {
    final currentMonth = DateTime.now();
    final monthlyAttendance = attendanceProvider.getAttendanceForMonth(
      currentMonth.year, 
      currentMonth.month,
    );
    
    final totalDays = monthlyAttendance.length;
    final checkedInDays = monthlyAttendance.where((a) => a.isCheckedIn).length;
    final approvedDays = monthlyAttendance.where((a) => a.isApproved).length;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  _getMonthName(currentMonth),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Total Days',
                    totalDays.toString(),
                    Icons.event,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Check-ins',
                    checkedInDays.toString(),
                    Icons.login,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Approved',
                    approvedDays.toString(),
                    Icons.verified,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentHistorySection(AttendanceProvider attendanceProvider) {
    final recentAttendance = attendanceProvider.attendanceList.take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.history, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text(
              'Recent History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (recentAttendance.isEmpty) ...[
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No attendance history found',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        ] else ...[
          ...recentAttendance.map((attendance) => _buildAttendanceListItem(attendance)),
        ],
        
        const SizedBox(height: 80), // Space for FAB
      ],
    );
  }

  Widget _buildAttendanceListItem(Attendance attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(attendance.status),
          child: Icon(
            attendance.isCheckedOut ? Icons.check_circle : Icons.login,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          attendance.date != null ? _formatDate(attendance.date!) : 'Unknown Date',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (attendance.siteName != null)
              Text('Site: ${attendance.siteName}'),
            Row(
              children: [
                Text(
                  attendance.isCheckedIn ? 'Checked In' : 'Not Checked In',
                  style: TextStyle(
                    color: attendance.isCheckedIn ? Colors.green : Colors.red,
                  ),
                ),
                if (attendance.isCheckedOut) ...[
                  const Text(' • '),
                  const Text(
                    'Checked Out',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getStatusColor(attendance.status),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getStatusText(attendance.status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Pending';
    }
  }

  String _getMonthName(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _navigateToCheckIn() {
    Navigator.pushNamed(context, '/check-in');
  }

  void _navigateToCheckOut() {
    Navigator.pushNamed(context, '/check-out');
  }
}