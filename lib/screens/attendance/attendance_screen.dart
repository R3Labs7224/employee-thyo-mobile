// lib/screens/attendance/attendance_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/attendance_provider.dart';
import '../../models/attendance.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
    await attendanceProvider.fetchAttendance();
  }

  Future<void> _selectMonth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedMonth = DateFormat('yyyy-MM').format(picked);
      });
      await _fetchAttendance();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Attendance',
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.calendar_month),
        //     onPressed: _selectMonth,
        //     tooltip: 'Select Month',
        //   ),
        // ],
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, attendanceProvider, child) {
          if (attendanceProvider.isLoading) {
            return const LoadingWidget();
          }

          if (attendanceProvider.error != null) {
            return _buildErrorWidget(attendanceProvider.error!);
          }

          return RefreshIndicator(
            onRefresh: _fetchAttendance,
            child: Column(
              children: [
                _buildHeader(attendanceProvider),

                _buildStatsSection(attendanceProvider),
                Expanded(
                  child: _buildAttendanceList(attendanceProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
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
              'Failed to load attendance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchAttendance,
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

  Widget _buildHeader(AttendanceProvider attendanceProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor.withOpacity(0.1),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance for',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  DateFormat('MMMM yyyy').format(_selectedDate),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          _buildTodayStatus(attendanceProvider),
        ],
      ),
    );
  }

  Widget _buildTodayStatus(AttendanceProvider attendanceProvider) {
    final todayAttendance = attendanceProvider.todayAttendance;
    
    if (todayAttendance == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Not Checked In',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(todayAttendance.status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        todayAttendance.status.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  

  

  Widget _buildStatsSection(AttendanceProvider attendanceProvider) {
    final stats = attendanceProvider.getMonthlyStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Total',
              stats['total'].toString(),
              Colors.blue,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Approved',
              stats['approved'].toString(),
              Colors.green,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Pending',
              stats['pending'].toString(),
              Colors.orange,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Rejected',
              stats['rejected'].toString(),
              Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
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
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList(AttendanceProvider attendanceProvider) {
    final attendanceList = attendanceProvider.attendanceList;

    if (attendanceList.isEmpty) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Motivating icon with gradient background
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.2),
                    AppTheme.primaryColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.wb_sunny_outlined,
                size: 64,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            
            // Welcome message
            Text(
              '🌟 Welcome to Your Journey!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            
            // Motivating message
            Text(
              'Ready to make today count?\nYour attendance journey starts with a single check-in!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Call to action button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/check-in');
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Start Your Day'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
            ),
            const SizedBox(height: 16),
            
            // Encouraging subtitle
            Text(
              'Every great achievement begins with the decision to try',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: attendanceList.length,
      itemBuilder: (context, index) {
        final attendance = attendanceList[index];
        return _buildAttendanceCard(attendance);
      },
    );
  }

  Widget _buildAttendanceCard(Attendance attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, MMM dd').format(DateTime.parse(attendance.date)),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(attendance.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    attendance.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTimeInfo(
                    'Check In',
                    attendance.checkInTime ?? '--:--',
                    Icons.login,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildTimeInfo(
                    'Check Out',
                    attendance.checkOutTime ?? '--:--',
                    Icons.logout,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildTimeInfo(
                    'Hours',
                    attendance.workingHours?.toStringAsFixed(1) ?? '0.0',
                    Icons.schedule,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            if (attendance.siteName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      attendance.siteName!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
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
}