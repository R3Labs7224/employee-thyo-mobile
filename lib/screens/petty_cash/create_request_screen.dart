// lib/screens/petty_cash/create_request_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/petty_cash_provider.dart';
import '../../services/camera_service.dart';
import '../../config/theme.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/loading_widget.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _dateController = TextEditingController();
  final CameraService _cameraService = CameraService();

  File? _receiptImage;
  String? _receiptImageBase64;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _captureReceipt() async {
    try {
      final XFile? image = await _cameraService.captureReceiptImage();
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture receipt: ${e.toString()}');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _cameraService.pickReceiptFromGallery();
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick receipt: ${e.toString()}');
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
        _receiptImage = file;
        _receiptImageBase64 = 'data:image/jpeg;base64,$base64String';
      });
    } catch (e) {
      _showErrorSnackBar('Failed to process image: ${e.toString()}');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _captureReceipt();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              if (_receiptImage != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _receiptImage = null;
                      _receiptImageBase64 = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);
      final reason = _reasonController.text.trim();
      final requestDate = _dateController.text;

      final pettyCashProvider = Provider.of<PettyCashProvider>(context, listen: false);
      
      final success = await pettyCashProvider.submitRequest(
        amount: amount,
        reason: reason,
        requestDate: requestDate,
        receiptImageBase64: _receiptImageBase64,
      );

      if (success && mounted) {
        _showSuccessSnackBar('Request submitted successfully!');
        Navigator.pop(context);
      } else if (mounted) {
        _showErrorSnackBar(pettyCashProvider.error ?? 'Failed to submit request');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to submit request: ${e.toString()}');
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
        title: 'Create Petty Cash Request',
        showBackButton: true,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAmountField(),
            const SizedBox(height: 16),
            _buildReasonField(),
            const SizedBox(height: 16),
            _buildDateField(),
            const SizedBox(height: 16),
            _buildReceiptSection(),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountField() {
    return TextFormField(
      controller: _amountController,
      keyboardType: TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount *',
        hintText: 'Enter amount',
        prefixIcon: const Icon(Icons.attach_money),
        border: const OutlineInputBorder(),
        suffixText: '\$',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        if (amount > 10000) {
          return 'Amount cannot exceed \$10,000';
        }
        return null;
      },
    );
  }

  Widget _buildReasonField() {
    return TextFormField(
      controller: _reasonController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Reason *',
        hintText: 'Enter reason for petty cash request',
        prefixIcon: Icon(Icons.description),
        border: OutlineInputBorder(),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a reason';
        }
        if (value.trim().length < 10) {
          return 'Reason must be at least 10 characters';
        }
        return null;
      },
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Request Date *',
        hintText: 'Select date',
        prefixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: _selectDate,
        ),
      ),
      onTap: _selectDate,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }

  Widget _buildReceiptSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Receipt Image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _showImageSourceDialog,
                  icon: Icon(_receiptImage != null ? Icons.edit : Icons.add_a_photo),
                  label: Text(_receiptImage != null ? 'Change' : 'Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_receiptImage != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_receiptImage!),
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
                      'Receipt uploaded (${_getFileSizeText()})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              InkWell(
                onTap: _showImageSourceDialog,
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add receipt image',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '(Optional)',
                        style: TextStyle(
                          color: Colors.grey[500],
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

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Submit Request',
        onPressed: _isLoading ? null : _submitRequest,
        isLoading: _isLoading,
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  String _getFileSizeText() {
    if (_receiptImage == null) return '';
    
    final sizeInMB = _cameraService.getImageSizeInMB(_receiptImage!);
    return '${sizeInMB.toStringAsFixed(1)} MB';
  }
}