class Constants {
  // App Constants
  static const String appName = 'Employee Management';
  static const String appVersion = '1.0.0';
  
  // Shared Preferences Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyEmployeeData = 'employee_data';
  static const String keyLanguage = 'selected_language';
  static const String keyTheme = 'theme_mode';
  
  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String displayDateFormat = 'dd MMM yyyy';
  static const String displayTimeFormat = 'HH:mm';
  
  // Status Constants
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusActive = 'active';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  
  // Attendance Status
  static const String attendanceCheckedIn = 'checked_in';
  static const String attendanceCheckedOut = 'checked_out';
  static const String attendanceAbsent = 'absent';
  
  // Task Status
  static const String taskActive = 'active';
  static const String taskCompleted = 'completed';
  static const String taskCancelled = 'cancelled';
  
  // Petty Cash Status
  static const String pettyCashPending = 'pending';
  static const String pettyCashApproved = 'approved';
  static const String pettyCashRejected = 'rejected';
  
  // Error Messages
  static const String errorNetworkConnection = 'No internet connection';
  static const String errorServerConnection = 'Unable to connect to server';
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorInvalidCredentials = 'Invalid credentials';
  static const String errorSessionExpired = 'Session expired. Please login again.';
  
  // Success Messages
  static const String successCheckIn = 'Checked in successfully';
  static const String successCheckOut = 'Checked out successfully';
  static const String successTaskCreated = 'Task created successfully';
  static const String successTaskCompleted = 'Task completed successfully';
  static const String successPettyCashSubmitted = 'Petty cash request submitted';
  
  // Image Constants
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const double imageQuality = 0.8;
  static const int imageMaxWidth = 1024;
  static const int imageMaxHeight = 1024;
  
  // Location Constants
  static const double locationAccuracyRadius = 500.0; // 500 meters
  static const int locationTimeoutSeconds = 30;
  
  // Animation Durations
  static const int animationDurationShort = 300;
  static const int animationDurationMedium = 500;
  static const int animationDurationLong = 800;
}
