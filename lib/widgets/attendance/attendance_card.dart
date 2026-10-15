// lib/widgets/attendance/attendance_card.dart - UPDATED: Removed time references
import 'package:flutter/material.dart';
import '../../models/attendance.dart';
import '../../config/theme.dart';
import '../common/custom_card.dart';

class AttendanceCard extends StatelessWidget {
  final Attendance attendance;
  final VoidCallback? onTap;

  const AttendanceCard({
    super.key,
    required this.attendance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(attendance.date ?? ''),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              
              // Site information
              if (attendance.siteName != null) ...[
                Row(
                  children: [
                    const Icon(Icons.business, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        attendance.siteName!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Check-in/Check-out status
              Row(
                children: [
                  Expanded(
                    child: _buildLocationInfo(
                      'Check In',
                      attendance.isCheckedIn,
                      attendance.checkInLatitude,
                      attendance.checkInLongitude,
                      Colors.green,
                      Icons.login,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLocationInfo(
                      'Check Out',
                      attendance.isCheckedOut,
                      attendance.checkOutLatitude,
                      attendance.checkOutLongitude,
                      Colors.red,
                      Icons.logout,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Location coordinates (if available)
              if (attendance.checkInLatitude != null && attendance.checkInLongitude != null) ...[
                _buildLocationCoordinates(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color backgroundColor;
    String statusText;
    
    switch (attendance.status.toLowerCase()) {
      case 'approved':
        backgroundColor = Colors.green;
        statusText = 'Approved';
        break;
      case 'rejected':
        backgroundColor = Colors.red;
        statusText = 'Rejected';
        break;
      default:
        backgroundColor = Colors.orange;
        statusText = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLocationInfo(
    String label,
    bool isCompleted,
    double? latitude,
    double? longitude,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: isCompleted ? color : Colors.grey,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isCompleted ? color : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(icon, size: 12, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              isCompleted ? 'Completed' : 'Pending',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationCoordinates() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
              const Text(
                'Location Information',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Check-in location
          if (attendance.checkInLatitude != null && attendance.checkInLongitude != null) ...[
            _buildCoordinateRow(
              'Check In:',
              attendance.checkInLatitude!,
              attendance.checkInLongitude!,
              Colors.green,
            ),
          ],
          
          // Check-out location
          if (attendance.checkOutLatitude != null && attendance.checkOutLongitude != null) ...[
            const SizedBox(height: 4),
            _buildCoordinateRow(
              'Check Out:',
              attendance.checkOutLatitude!,
              attendance.checkOutLongitude!,
              Colors.red,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoordinateRow(String label, double latitude, double longitude, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Unknown Date';
    
    try {
      final date = DateTime.parse(dateStr);
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      
      final weekday = weekdays[date.weekday - 1];
      final month = months[date.month - 1];
      final day = date.day.toString().padLeft(2, '0');
      
      return '$weekday, $month $day';
    } catch (e) {
      return dateStr;
    }
  }
}