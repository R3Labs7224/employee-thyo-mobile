// lib/screens/tasks/complete_task_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CompleteTaskScreen extends StatefulWidget {
  const CompleteTaskScreen({super.key});

  @override
  State<CompleteTaskScreen> createState() => _CompleteTaskScreenState();
}

class _CompleteTaskScreenState extends State<CompleteTaskScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  Task? _task;
  Position? _currentPosition;
  File? _completionImage;
  String? _completionImageBase64;
  bool _isLoading = false;
  String? _error;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _initializeScreen();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get active task
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      _task = taskProvider.activeTask;

      if (_task == null) {
        setState(() {
          _error = 'No active task found. Please create a task first.';
          _isLoading = false;
        });
        return;
      }

      // Check location permission
      final hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        final granted = await _locationService.requestPermission();
        if (!granted) {
          setState(() {
            _error = 'Location permission is required to complete tasks';
            _isLoading = false;
          });
          return;
        }
      }

      // Get current location
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        _currentPosition = position;
      }

      _animationController.forward();
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _captureCompletionImage() async {
    try {
      final XFile? image = await _cameraService.captureTaskImage();
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: ${e.toString()}');
    }
  }

  Future<void> _processImage(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      
      // Validate image file
      if (!_cameraService.validateImageFile(file)) {
        _showErrorSnackBar('Invalid image file. Please select a valid image (max 5MB).');
        return;
      }

      // Convert to base64
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);

      setState(() {
        _completionImage = file;
        _completionImageBase64 = 'data:image/jpeg;base64,$base64String';
      });
    } catch (e) {
      _showErrorSnackBar('Failed to process image: ${e.toString()}');
    }
  }

  Future<void> _completeTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_task == null) {
      _showErrorSnackBar('No active task found');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final completionNotes = _notesController.text.trim();

      final success = await taskProvider.completeTask(
        taskId: _task!.id!,
        completionNotes: completionNotes.isNotEmpty ? completionNotes : null,
      );

      if (success && mounted) {
        _showSuccessSnackBar('Task completed successfully!');
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorSnackBar(taskProvider.error ?? 'Failed to complete task');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to complete task: ${e.toString()}');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Complete Task',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _buildTaskCompletionForm(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              'Task Completion Error',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.red[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeScreen,
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

  Widget _buildTaskCompletionForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskInfoCard(),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildCompletionNotesCard(),
            const SizedBox(height: 16),
            _buildCompletionImageCard(),
            const SizedBox(height: 32),
            _buildCompleteButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskInfoCard() {
    if (_task == null) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.task, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Task Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Title', _task!.title),
            if (_task!.description != null && _task!.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildInfoRow('Description', _task!.description!),
            ],
            const SizedBox(height: 8),
            _buildInfoRow('Site', _task!.siteName ?? 'Unknown'),
            const SizedBox(height: 8),
            _buildInfoRow('Started', _formatDateTime(_task!.startTime)),
            const SizedBox(height: 8),
            _buildStatusChip(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
          const SizedBox(width: 4),
          Text(
            'Active Task',
            style: TextStyle(
              color: Colors.orange[700],
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Current Location',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_currentPosition != null) ...[
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Accuracy: ${_currentPosition!.accuracy.toStringAsFixed(1)}m',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  const Text('Location not available'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Completion Notes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Add any notes about task completion (optional)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              validator: (value) {
                // Notes are optional, so no validation required
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionImageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Completion Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _captureCompletionImage,
                  icon: Icon(_completionImage != null ? Icons.edit : Icons.add_a_photo),
                  label: Text(_completionImage != null ? 'Change' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_completionImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_completionImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Completion photo captured',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              InkWell(
                onTap: _captureCompletionImage,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey[50],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add completion photo',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '(Optional)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Complete Task',
        onPressed: _isLoading ? null : _completeTask,
        isLoading: _isLoading,
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'Unknown';
    
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }
}