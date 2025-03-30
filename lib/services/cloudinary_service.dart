import 'package:cloudinary/cloudinary.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class CloudinaryService {
  static final String cloudName = 'your_cloud_name';
  static final String apiKey = 'your_api_key';
  static final String apiSecret = 'your_api_secret';

  static late final Cloudinary cloudinary;

  static void init() {
    cloudinary = Cloudinary.signedConfig(
      apiKey: '469575334913512',
      apiSecret: 'VQvjh-Ewml10qslAeE7vQ9Xc0xE',
      cloudName: 'dnyqtum7i',
    );
  }

  // Function to upload an image to Cloudinary
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final response = await cloudinary.upload(
        file: imageFile.path,
        resourceType: CloudinaryResourceType.auto,
        folder: 'tasty',
        // Optional parameters
        progressCallback: (count, total) {
          final progress = ((count / total) * 100).toStringAsFixed(2);
          print('Progress: $progress %');
        },
      );

      if (response.isSuccessful) {
        return response.secureUrl;
      } else {
        print('Cloudinary upload error: ${response.error}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // Function to pick an image from gallery or camera
  static Future<File?> pickImage({ImageSource source = ImageSource.gallery}) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: source,
      imageQuality: 85, // Optional: compress image quality
    );

    if (image != null) {
      return File(image.path);
    }
    return null;
  }
}