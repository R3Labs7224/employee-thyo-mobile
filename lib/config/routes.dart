import 'package:ems/screens/attendance/check_out_screen.dart';
import 'package:ems/screens/petty_cash/create_request_screen.dart';
import 'package:ems/screens/petty_cash/petty_cash_screen.dart';
import 'package:ems/screens/profile/profile_screen.dart';
import 'package:ems/screens/salary/salary_screen.dart';
import 'package:ems/screens/tasks/complete_task_screen.dart';
import 'package:ems/screens/tasks/create_task_screen.dart';
import 'package:ems/screens/tasks/tasks_screen.dart';
import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/attendance/attendance_screen.dart';
import '../screens/attendance/check_in_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String attendance = '/attendance';
  static const String checkIn = '/check-in';
  static const String checkOut = '/check-out';
  static const String tasks = '/tasks';
  static const String createTask = '/create-task';
  static const String completeTask = '/complete-task';
  static const String pettyCash = '/petty-cash';
  static const String createRequest = '/create-request';
  static const String salary = '/salary';
  static const String profile = '/profile';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    dashboard: (context) => const DashboardScreen(),
    attendance: (context) => const AttendanceScreen(),
    checkIn: (context) => const CheckInScreen(),
    checkOut: (context) => const CheckOutScreen(),
    tasks: (context) => const TasksScreen(),
    createTask: (context) => const CreateTaskScreen(),
    completeTask: (context) => const CompleteTaskScreen(),
    pettyCash: (context) => const PettyCashScreen(),
    createRequest: (context) => const CreateRequestScreen(),
    salary: (context) => const SalaryScreen(),
    profile: (context) => const ProfileScreen(),
  };
}
