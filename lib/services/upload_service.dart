import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constant.dart';

class UploadService {
  /// Upload image to Cloudinary
  /// Returns map with 'success', 'url', and 'public_id'
  static Future<Map<String, dynamic>> uploadImage(String base64Image) async {
    try {
      final uri = backendUri('/api/upload/upload');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image': base64Image}),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Upload failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  /// Delete image from Cloudinary
  static Future<Map<String, dynamic>> deleteImage(String publicId) async {
    try {
      final uri = backendUri('/api/upload/delete');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'public_id': publicId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'success': false, 'message': 'Delete failed'};
    } catch (e) {
      return {'success': false, 'message': 'Delete error: $e'};
    }
  }
}
