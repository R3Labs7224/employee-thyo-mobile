import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_card.dart';
import '../../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Profile'),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Consumer<AuthProvider>(
          builder: (context, authProvider, _) {
            final employee = authProvider.employee;
            
            if (employee == null) {
              return const Center(
                child: Text('Employee data not found'),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildProfileHeader(employee),
                  const SizedBox(height: 24),
                  _buildPersonalInfo(employee),
                  const SizedBox(height: 16),
                  _buildWorkInfo(employee),
                  const SizedBox(height: 16),
                  _buildSalaryInfo(employee),
                  const SizedBox(height: 16),
                  _buildLocationInfo(employee),
               
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(employee) {
    return CustomCard(
      child: Container(
        width: MediaQuery.of(context).size.width*0.9,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.accentColor.withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Center(
                child: Text(
                  Helpers.getInitials(employee.name),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              employee.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
           Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                employee.employeeCode,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfo(employee) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Personal Information', Icons.person),
            const SizedBox(height: 16),
            _buildInfoRow('Full Name', employee.name),
            _buildInfoRow('Email', employee.email),
            _buildInfoRow('Phone', employee.phone),
            if (employee.joiningDate != null)
              _buildInfoRow('Joining Date', Helpers.formatDate(DateTime.parse(employee.joiningDate!))),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkInfo(employee) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Work Information', Icons.work),
            const SizedBox(height: 16),
            _buildInfoRow('Employee ID', employee.employeeCode),
            _buildInfoRow('Department', employee.departmentName),
            _buildInfoRow('Shift', employee.shiftName),
            _buildInfoRow('Working Hours', '${employee.startTime} - ${employee.endTime}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSalaryInfo(employee) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Salary Information', Icons.account_balance_wallet),
            const SizedBox(height: 16),
            if (employee.basicSalary != null)
              _buildInfoRow('Basic Salary', Helpers.formatCurrency(employee.basicSalary!)),
            if (employee.dailyWage != null && employee.dailyWage! > 0)
              _buildInfoRow('Daily Wage', Helpers.formatCurrency(employee.dailyWage!)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo(employee) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Work Location', Icons.location_on),
            const SizedBox(height: 16),
            _buildInfoRow('Site Name', employee.siteName),
            _buildInfoRow('Address', employee.siteAddress),
            _buildInfoRow('Coordinates', '${employee.siteLatitude.toStringAsFixed(6)}, ${employee.siteLongitude.toStringAsFixed(6)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: const Text('Profile editing feature will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change feature will be available in a future update. Please contact your supervisor for password changes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(AuthProvider authProvider) {
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
              authProvider.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
