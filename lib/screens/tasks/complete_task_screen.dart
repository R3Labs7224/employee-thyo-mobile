import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/task_provider.dart';
import '../../models/task.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';
import '../../utils/validators.dart';

class CompleteTaskScreen extends StatefulWidget {
  const CompleteTaskScreen({Key? key}) : super(key: key);

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
  String? _completionImageBase64;
  bool _isLoading = false;
  bool _locationPermissionGranted = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    
    // Get task from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Task) {
        setState(() {
          _task = args;
        });
      }
    });

    _checkLocationPermission();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkLocationPermission() async {
    setState(() {
      _isLoading = true;
    });

    final permission = await _locationService.checkLocationPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      final requestResult = await _locationService.requestLocationPermission();
      _locationPermissionGranted = requestResult != LocationPermission.denied &&
          requestResult != LocationPermission.deniedForever;
    } else {
      _locationPermissionGranted = true;
    }

    if (_locationPermissionGranted) {
      await _getCurrentLocation();
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  Future<void> _captureCompletionImage() async {
    final image = await _cameraService.captureTaskImage();
    if (image != null) {
      setState(() {
        _completionImageBase64 = image;
      });
    }
  }

  Future<void> _completeTask() async {
    if (!_formKey.currentState!.validate()) return;

    if (_task == null) {
      _showErrorDialog('Task information not found');
      return;
    }

    if (_currentPosition == null) {
      _showErrorDialog('Location is required to complete the task');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final success = await taskProvider.completeTask(
      taskId: _task!.id!,
      completionNotes: _notesController.text.trim(),
      latitude: _currentPosition!.latitude,
      longitude: _currentPosition!.longitude,
      completionImageBase64: _completionImageBase64,
    );

    if (success) {
      _showSuccessDialog();
    } else {
      _showErrorDialog(taskProvider.error ?? 'Failed to complete task');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: const Text('Task completed successfully!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Complete Task'),
        body: const Center(
          child: Text('Task not found'),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Complete Task'),
      body: _isLoading
          ? const LoadingWidget(message: 'Completing task...')
          : SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(_animationController),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskInfoCard(),
                      const SizedBox(height: 24),
                      _buildCompletionForm(),
                      const SizedBox(height: 24),
                      _buildLocationCard(),
                      const SizedBox(height: 24),
                      _buildImageCard(),
                      const SizedBox(height: 32),
                      CustomButton(
                        text: 'Complete Task',
                        onPressed: _canCompleteTask() ? _completeTask : null,
                        width: double.infinity,
                        backgroundColor: AppTheme.successColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTaskInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.task,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Task Information',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Review details before completion',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Title', _task!.title),
            _buildInfoRow('Description', _task!.description),
            if (_task!.siteName != null)
              _buildInfoRow('Site', _task!.siteName!),
            if (_task!.startTime != null)
              _buildInfoRow('Started At', _formatDateTime(_task!.startTime!)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Completion Notes *',
                hintText: 'Describe what was completed, any issues, etc.',
                prefixIcon: Icon(Icons.notes),
              ),
              validator: Validators.required,
              maxLines: 4,
              maxLength: 500,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _locationPermissionGranted && _currentPosition != null
                      ? Icons.location_on
                      : Icons.location_off,
                  color: _locationPermissionGranted && _currentPosition != null
                      ? AppTheme.successColor
                      : Colors.red,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GPS Location',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getLocationStatusText(),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      if (_currentPosition != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\nLng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!_locationPermissionGranted || _currentPosition == null)
                  ElevatedButton(
                    onPressed: _checkLocationPermission,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Completion Image (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _completionImageBase64 != null ? Icons.camera_alt : Icons.camera_alt_outlined,
                  color: _completionImageBase64 != null ? AppTheme.successColor : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture Completion Image',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _completionImageBase64 != null 
                            ? 'Image captured successfully'
                            : 'Optional: Take a photo showing completed work',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _captureCompletionImage,
                  child: Text(_completionImageBase64 != null ? 'Retake' : 'Capture'),
                ),
              ],
            ),
            if (_completionImageBase64 != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.successColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Completion Image Ready',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  String _formatDateTime(String dateTimeString) {
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _getLocationStatusText() {
    if (!_locationPermissionGranted) {
      return 'Location permission required';
    }
    if (_currentPosition == null) {
      return 'Getting current location...';
    }
    return 'Location acquired successfully';
  }

  bool _canCompleteTask() {
    return _locationPermissionGranted &&
        _currentPosition != null &&
        _notesController.text.isNotEmpty;
  }
}
