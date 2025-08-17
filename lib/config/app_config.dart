class AppConfig {
  static const String baseUrl = 'https://maagroup.in/report/api/';
  
  // Endpoints
  static const String loginEndpoint = 'auth/login.php';
  static const String logoutEndpoint = 'auth/logout.php';
  static const String profileEndpoint = 'employee/profile.php';
  static const String attendanceEndpoint = 'employee/attendance.php';
  static const String tasksEndpoint = 'employee/tasks.php';
  static const String pettyCashEndpoint = 'employee/petty_cash.php';
  static const String salaryEndpoint = 'employee/salary.php';
  static const String sitesEndpoint = 'common/sites.php';
  
  // App constants
  static const String appVersion = '1.0.0';
  static const int requestTimeout = 30000;
  static const double locationRadius = 500.0;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
}
