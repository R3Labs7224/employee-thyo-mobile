import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_card.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/task/task_card.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({Key? key}) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    await provider.fetchTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tasks',
        actions: [
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              return provider.canCreateTask
                  ? IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.createTask),
                    )
                  : const SizedBox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildDateSelector(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildTasksTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Consumer<TaskProvider>(
        builder: (context, provider, _) {
          return provider.canCreateTask
              ? FloatingActionButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.createTask),
                  backgroundColor: AppTheme.primaryColor,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : const SizedBox();
        },
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.surfaceColor,
      child: CustomCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('dd MMMM yyyy').format(DateTime.parse(_selectedDate)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _selectDate(),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppTheme.primaryColor,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppTheme.primaryColor,
      tabs: const [
        Tab(text: 'Summary'),
        Tab(text: 'Tasks'),
      ],
    );
  }

  Widget _buildSummaryTab() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        return RefreshIndicator(
          onRefresh: _loadTasks,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatusBanner(provider),
              const SizedBox(height: 16),
              if (provider.summary != null) ...[
                _buildSummaryCards(provider.summary!),
                const SizedBox(height: 16),
              ],
              _buildCreateTaskCard(provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const LoadingWidget();
        }

        if (provider.error != null) {
          return _buildErrorWidget(provider.error!);
        }

        if (provider.tasks.isEmpty) {
          return RefreshIndicator(
            onRefresh: _loadTasks,
            child: ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No tasks found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tasks will appear here once created',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadTasks,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.tasks.length,
            itemBuilder: (context, index) {
              final task = provider.tasks[index];
              return TaskCard(
                task: task,
                onTap: () => _showTaskDetails(task),
                onComplete: task.status == 'active'
                    ? () => Navigator.pushNamed(
                        context,
                        AppRoutes.completeTask,
                        arguments: task,
                      )
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStatusBanner(TaskProvider provider) {
    String message;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (provider.attendanceStatus == 'checked_out') {
      message = 'You have checked out. Task creation is disabled.';
      backgroundColor = Colors.grey.withOpacity(0.1);
      textColor = Colors.grey[600]!;
      icon = Icons.info_outline;
    } else if (provider.attendanceStatus == 'not_checked_in') {
      message = 'Please check in to start creating tasks';
      backgroundColor = Colors.orange.withOpacity(0.1);
      textColor = Colors.orange[700]!;
      icon = Icons.warning_outlined;
    } else if (provider.canCreateTask) {
      message = 'You can create new tasks while checked in';
      backgroundColor = AppTheme.successColor.withOpacity(0.1);
      textColor = AppTheme.successColor;
      icon = Icons.check_circle_outline;
    } else {
      message = 'Complete your active task before creating a new one';
      backgroundColor = AppTheme.accentColor.withOpacity(0.1);
      textColor = AppTheme.accentColor;
      icon = Icons.pending_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Task Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                summary.totalTasks.toString(),
                Icons.task,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Completed',
                summary.completedTasks.toString(),
                Icons.check_circle,
                AppTheme.successColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Active',
                summary.activeTasks.toString(),
                Icons.pending,
                AppTheme.accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Cancelled',
                summary.cancelledTasks.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateTaskCard(TaskProvider provider) {
    return CustomCard(
      onTap: provider.canCreateTask
          ? () => Navigator.pushNamed(context, AppRoutes.createTask)
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: provider.canCreateTask
              ? LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.1),
                    AppTheme.accentColor.withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: provider.canCreateTask ? null : Colors.grey[100],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: provider.canCreateTask
                    ? AppTheme.primaryColor
                    : Colors.grey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_task,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Task',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: provider.canCreateTask
                          ? AppTheme.primaryColor
                          : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    provider.canCreateTask
                        ? 'Tap to create a new task'
                        : 'Task creation unavailable',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (provider.canCreateTask)
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.primaryColor,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error Loading Tasks',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadTasks,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _selectDate() {
    showDatePicker(
      context: context,
      initialDate: DateTime.parse(_selectedDate),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    ).then((selectedDate) {
      if (selectedDate != null) {
        setState(() {
          _selectedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
        });
        _loadTasks();
      }
    });
  }

  void _showTaskDetails(task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Details',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Title', task.title),
            _buildDetailRow('Description', task.description),
            _buildDetailRow('Site', task.siteName ?? 'Unknown'),
            _buildDetailRow('Status', task.status?.toUpperCase() ?? 'UNKNOWN'),
            if (task.startTime != null)
              _buildDetailRow('Started', DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(task.startTime!))),
            if (task.endTime != null)
              _buildDetailRow('Completed', DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(task.endTime!))),
            const SizedBox(height: 16),
            if (task.status == 'active')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      AppRoutes.completeTask,
                      arguments: task,
                    );
                  },
                  child: const Text('Complete Task'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
