// lib/services/camera_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  // Check camera permission
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }

  // Request camera permission
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  // Take a picture using camera
  Future<XFile?> takePicture() async {
    try {
      // Check camera permission
      bool hasPermission = await checkCameraPermission();
      if (!hasPermission) {
        bool granted = await requestCameraPermission();
        if (!granted) {
          throw Exception('Camera permission denied');
        }
      }

      // Take picture
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front, // Use front camera for selfies
      );

      return image;
    } catch (e) {
      throw Exception('Failed to take picture: ${e.toString()}');
    }
  }

  // Pick image from gallery
  Future<XFile?> pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return image;
    } catch (e) {
      throw Exception('Failed to pick image: ${e.toString()}');
    }
  }

  // Take multiple pictures
  Future<List<XFile>?> takeMultiplePictures() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      return images;
    } catch (e) {
      throw Exception('Failed to take pictures: ${e.toString()}');
    }
  }

  // Capture receipt image (alias for takePicture with different settings)
  Future<XFile?> captureReceiptImage() async {
    try {
      // Check camera permission
      bool hasPermission = await checkCameraPermission();
      if (!hasPermission) {
        bool granted = await requestCameraPermission();
        if (!granted) {
          throw Exception('Camera permission denied');
        }
      }

      // Take picture with settings optimized for receipts/documents
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920, // Higher resolution for receipts
        maxHeight: 1920,
        imageQuality: 90, // Higher quality for text clarity
        preferredCameraDevice: CameraDevice.rear, // Use rear camera for documents
      );

      return image;
    } catch (e) {
      throw Exception('Failed to capture receipt: ${e.toString()}');
    }
  }

  // Pick document/receipt from gallery
  Future<XFile?> pickReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 90,
      );

      return image;
    } catch (e) {
      throw Exception('Failed to pick receipt: ${e.toString()}');
    }
  }

  // Capture task image (alias for takePicture with task-specific settings)
  Future<XFile?> captureTaskImage() async {
    try {
      // Check camera permission
      bool hasPermission = await checkCameraPermission();
      if (!hasPermission) {
        bool granted = await requestCameraPermission();
        if (!granted) {
          throw Exception('Camera permission denied');
        }
      }

      // Take picture with settings optimized for task documentation
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920, // High resolution for task documentation
        maxHeight: 1920,
        imageQuality: 85, // Good quality for task photos
        preferredCameraDevice: CameraDevice.rear, // Use rear camera for task photos
      );

      return image;
    } catch (e) {
      throw Exception('Failed to capture task image: ${e.toString()}');
    }
  }

  // Validate image file
  bool validateImageFile(File imageFile) {
    try {
      // Check if file exists
      if (!imageFile.existsSync()) {
        return false;
      }

      // Check file size (max 5MB)
      int fileSizeInBytes = imageFile.lengthSync();
      double fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      if (fileSizeInMB > 5) {
        return false;
      }

      // Check file extension
      String extension = imageFile.path.split('.').last.toLowerCase();
      List<String> allowedExtensions = ['jpg', 'jpeg', 'png'];
      if (!allowedExtensions.contains(extension)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get image file size in MB
  double getImageSizeInMB(File imageFile) {
    try {
      int fileSizeInBytes = imageFile.lengthSync();
      return fileSizeInBytes / (1024 * 1024);
    } catch (e) {
      return 0.0;
    }
  }
}