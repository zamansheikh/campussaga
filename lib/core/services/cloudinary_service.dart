import 'dart:io';
import 'package:cloudinary_flutter/cloudinary_object.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/cloudinary_config.dart';

/// Cloudinary Service - Singleton providing access to Cloudinary for image uploads
class CloudinaryService {
  late final CloudinaryObject cloudinary;

  CloudinaryService() {
    cloudinary = CloudinaryObject.fromCloudName(
      cloudName: CloudinaryConfig.cloudName,
    );
  }

  /// Upload an image to Cloudinary and return the URL
  ///
  /// [file] - The image file to upload
  /// [folder] - Optional folder name in Cloudinary
  /// [publicId] - Optional custom public ID for the image
  Future<String> uploadImage({
    required File file,
    String folder = 'campus_saga',
    String? publicId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = publicId ?? 'img_$timestamp';

      // Use HTTP multipart request for unsigned upload
      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/${CloudinaryConfig.cloudName}/image/upload',
      );

      final request = http.MultipartRequest('POST', url);

      // Add the image file
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      // Add upload parameters (only params allowed for unsigned upload)
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = folder;
      if (publicId != null) {
        request.fields['public_id'] = fileName;
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final secureUrl = responseData['secure_url'] as String;
        return secureUrl;
      } else {
        final errorData = json.decode(response.body);
        throw Exception(
          'Failed to upload image: ${errorData['error']?['message'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      throw Exception('Error uploading to Cloudinary: $e');
    }
  }

  /// Get the Cloudinary URL for an uploaded image
  String getImageUrl(String url) {
    return url;
  }
}
