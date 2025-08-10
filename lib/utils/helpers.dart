import 'dart:ui';

import 'package:ems/utils/const.dart';
import 'package:intl/intl.dart';


class Helpers {
  // Date Formatting
  static String formatDate(DateTime date) {
    return DateFormat(Constants.displayDateFormat).format(date);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat(Constants.displayTimeFormat).format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('${Constants.displayDateFormat} ${Constants.displayTimeFormat}').format(dateTime);
  }

  static String formatApiDate(DateTime date) {
    return DateFormat(Constants.dateFormat).format(date);
  }

  static String formatApiDateTime(DateTime dateTime) {
    return DateFormat(Constants.dateTimeFormat).format(dateTime);
  }

  static DateTime? parseApiDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Status Helpers
  static String getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case Constants.statusPending:
        return 'Pending';
      case Constants.statusApproved:
        return 'Approved';
      case Constants.statusRejected:
        return 'Rejected';
      case Constants.statusActive:
        return 'Active';
      case Constants.statusCompleted:
        return 'Completed';
      case Constants.statusCancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }

  // Number Formatting
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00');
    return '₹${formatter.format(amount)}';
  }

  static String formatHours(double hours) {
    if (hours == 0) return '0.0 hrs';
    return '${hours.toStringAsFixed(1)} hrs';
  }

  // Validation Helpers
  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  static bool isValidPhoneNumber(String phone) {
    return RegExp(r'^[0-9]{10}$').hasMatch(phone);
  }

  // String Helpers
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String getInitials(String name) {
    if (name.isEmpty) return 'NA';
    List<String> nameParts = name.split(' ');
    if (nameParts.length == 1) {
      return nameParts[0][0].toUpperCase();
    }
    return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
  }

  // Time Helpers
  static String getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static Duration parseTimeString(String timeString) {
    final parts = timeString.split(':');
    if (parts.length != 2) {
      throw FormatException('Invalid time format: $timeString');
    }
    
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    
    return Duration(hours: hours, minutes: minutes);
  }

  // File Size Helpers
  static String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Color Helpers
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2)}';
  }

  // Network Helpers
  static bool isNetworkError(String errorMessage) {
    return errorMessage.toLowerCase().contains('network') ||
           errorMessage.toLowerCase().contains('connection') ||
           errorMessage.toLowerCase().contains('timeout');
  }

  // Distance Helpers
  static String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}
