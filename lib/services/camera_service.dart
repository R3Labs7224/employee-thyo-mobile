import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Add this import
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../config/app_config.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  final ImagePicker _picker = ImagePicker();

  Future<String?> captureImage({ImageSource source = ImageSource.camera}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        return await _processImage(image);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> _processImage(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final List<int> imageBytes = await file.readAsBytes();

      // Check file size
      if (imageBytes.length > AppConfig.maxImageSize) {
        // Compress image if too large
        final compressedBytes = await _compressImage(imageBytes);
        return base64Encode(compressedBytes);
      }

      return base64Encode(imageBytes);
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List> _compressImage(List<int> imageBytes) async {
    try {
      // Convert List<int> to Uint8List
      final Uint8List uint8ImageBytes = Uint8List.fromList(imageBytes);
      
      // Decode image
      img.Image? image = img.decodeImage(uint8ImageBytes);
      if (image == null) return uint8ImageBytes;

      // Resize if too large
      if (image.width > 800 || image.height > 800) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? 800 : null,
          height: image.height > image.width ? 800 : null,
        );
      }

      // Encode with lower quality and return as Uint8List
      final List<int> compressedBytes = img.encodeJpg(image, quality: 70);
      return Uint8List.fromList(compressedBytes);
    } catch (e) {
      return Uint8List.fromList(imageBytes);
    }
  }

  Future<String?> captureSelfie() async {
    return await captureImage(source: ImageSource.camera);
  }

  Future<String?> captureTaskImage() async {
    return await captureImage(source: ImageSource.camera);
  }

  Future<String?> captureReceiptImage() async {
    return await captureImage(source: ImageSource.camera);
  }
}
