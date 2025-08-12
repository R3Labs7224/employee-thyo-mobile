// lib/screens/home/main_home_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import 'dashboard_screen.dart';

class MainHomeLayout extends StatefulWidget {
  const MainHomeLayout({super.key});

  @override
  State<MainHomeLayout> createState() => _MainHomeLayoutState();
}

class _MainHomeLayoutState extends State<MainHomeLayout> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const DashboardScreen(),
    // Add other main screens here if needed
  ];



  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AuthProvider>(context, listen: false).logout();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EMS Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
  
    );
  }

  Widget _buildNavigationDrawer() {
    return Drawer(
      child: Column(
        children: [
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              final employee = authProvider.employee;
              return UserAccountsDrawerHeader(
                accountName: Text(employee?.name ?? 'Employee'),
                accountEmail: Text(employee?.email ?? ''),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Text(
                    employee?.name.isNotEmpty == true 
                        ? employee!.name[0].toUpperCase() 
                        : 'E',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor,
                      AppTheme.primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  selected: _selectedIndex == 0,
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 0;
                    });
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.person,
                  title: 'Profile',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.profile);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.access_time,
                  title: 'Attendance',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.attendance);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.task,
                  title: 'Tasks',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.tasks);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.attach_money,
                  title: 'Petty Cash',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.pettyCash);
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.receipt,
                  title: 'Salary',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.salary);
                  },
                ),
                const Divider(),
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '');
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    Navigator.pop(context);
                    _showHelpDialog();
                  },
                ),
              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog();
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool selected = false,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? (selected ? AppTheme.primaryColor : null),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? (selected ? AppTheme.primaryColor : null),
          fontWeight: selected ? FontWeight.bold : null,
        ),
      ),
      selected: selected,
      selectedTileColor: AppTheme.primaryColor.withOpacity(0.1),
      onTap: onTap,
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help & Support'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('For technical support, please contact:'),
              SizedBox(height: 8),
              Text('📧 Email: support@ems.com'),
              Text('📞 Phone: +1 234 567 8900'),
              SizedBox(height: 16),
              Text('App Version: 1.0.0'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}