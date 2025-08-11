// lib/screens/tasks/create_task_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/task_provider.dart';
import '../../providers/site_provider.dart';
import '../../models/site.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  Site? _selectedSite;
  List<Site> _availableSites = [];
  Position? _currentPosition;
  File? _taskImage;
  String? _taskImageBase64;
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
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check location permission
      final hasPermission = await _locationService.checkPermission();
      if (!hasPermission) {
        final granted = await _locationService.requestPermission();
        if (!granted) {
          setState(() {
            _error = 'Location permission is required to create tasks';
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

      // Fetch available sites
      if (mounted) {
        final siteProvider = Provider.of<SiteProvider>(context, listen: false);
        await siteProvider.fetchSites();
        _availableSites = siteProvider.sites;
      }

      _animationController.forward();
    } catch (e) {
      _error = 'Failed to initialize: ${e.toString()}';
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _captureTaskImage() async {
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
        _taskImage = file;
        _taskImageBase64 = 'data:image/jpeg;base64,$base64String';
      });
    } catch (e) {
      _showErrorSnackBar('Failed to process image: ${e.toString()}');
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSite == null) {
      _showErrorSnackBar('Please select a site');
      return;
    }

    if (_currentPosition == null) {
      _showErrorSnackBar('Location not available');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      
      final success = await taskProvider.createTask(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : null,
        siteId: _selectedSite!.id,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        taskImageBase64: _taskImageBase64,
      );

      if (success && mounted) {
        _showSuccessSnackBar('Task created successfully!');
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorSnackBar(taskProvider.error ?? 'Failed to create task');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to create task: ${e.toString()}');
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
        title: 'Create Task',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? _buildErrorWidget()
              : _buildTaskForm(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Task Creation Error',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Failed to initialize task creation',
              style: TextStyle(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: null,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildSiteSelection(),
            const SizedBox(height: 16),
            _buildLocationInfo(),
            const SizedBox(height: 16),
            _buildTaskImageSection(),
            const SizedBox(height: 32),
            _buildCreateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: const InputDecoration(
        labelText: 'Task Title *',
        hintText: 'Enter task title',
        prefixIcon: Icon(Icons.title),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a task title';
        }
        if (value.trim().length < 3) {
          return 'Title must be at least 3 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Description',
        hintText: 'Enter task description (optional)',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildSiteSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Select Site *',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_availableSites.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No sites available. Please contact administrator.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              DropdownButtonFormField<Site>(
                value: _selectedSite,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Choose Site',
                ),
                items: _availableSites.map((site) {
                  final distance = _currentPosition != null && site.hasCoordinates
                      ? _calculateDistance(site)
                      : null;

                  return DropdownMenuItem<Site>(
                    value: site,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.name),
                        if (distance != null)
                          Text(
                            '${distance.toStringAsFixed(0)}m away',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (site) {
                  setState(() {
                    _selectedSite = site;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a site';
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
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
              const Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Text('Location not available'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskImageSection() {
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
                  'Task Image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _captureTaskImage,
                  icon: Icon(_taskImage != null ? Icons.edit : Icons.add_a_photo),
                  label: Text(_taskImage != null ? 'Change' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_taskImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_taskImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Task image captured',
                      style: TextStyle(
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              InkWell(
                onTap: _captureTaskImage,
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
                        'Tap to add task image',
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

  Widget _buildCreateButton() {
    final canCreate = _selectedSite != null &&
        _currentPosition != null &&
        !_isLoading;

    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Create Task',
        onPressed: canCreate ? _createTask : null,
        isLoading: _isLoading,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  double _calculateDistance(Site site) {
    if (_currentPosition == null || !site.hasCoordinates) {
      return 0.0;
    }

    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      site.latitude!,
      site.longitude!,
    );
  }
}