import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  /// Check if a mobile exists. Expected to return a map like:
  /// { 'success': true, 'exists': false, 'message': '...' }
  static Future<Map<String, dynamic>> checkMobileExists(String mobile) async {
    // Local dev (Flutter web / desktop)
    final uri = Uri(
      scheme: 'http',
      host: 'localhost',
      port: 5000,
      pathSegments: ['api', 'auth', 'check-mobile', mobile],
    );
    // Android emulator (uncomment if testing on Android emulator):
    //final uri = Uri(scheme: 'http', host: '10.0.2.2', port: 5000, pathSegments: ['api','auth','check-mobile', mobile]);
    // Real device on LAN (replace with your machine IP):
    // final uri = Uri(scheme: 'http', host: '192.168.x.x', port: 5000, pathSegments: ['api','auth','check-mobile', mobile]);
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final jsonBody = jsonDecode(res.body);
        if (jsonBody is Map<String, dynamic>) {
          return {
            'success': true,
            'exists': jsonBody['exists'] ?? false,
            'message': jsonBody['message'],
          };
        }
        return {'success': false, 'message': 'Invalid response format'};
      } else {
        return {'success': false, 'message': 'Server returned ${res.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Register a new shop. Expected to return a map like:
  /// { 'success': true, 'message': '...' } or { 'success': false, 'error': '...' }
  static Future<Map<String, dynamic>> register({
    required String shopName,
    required String ownerName,
    required String mobile,
    required String email,
    required String password,
    required String businessType,
    required String address,
    required String taxId,
  }) async {
    final uri = Uri(
      scheme: 'http',
      host: 'localhost',
      port: 5000,
      pathSegments: ['api', 'auth', 'register'],
    );
    // Android emulator:
    // final uri = Uri(scheme: 'http', host: '10.0.2.2', port: 5000, pathSegments: ['api','auth','register']);
    // Physical device (replace with your machine IP):
    // final uri = Uri(scheme: 'http', host: '192.168.x.x', port: 5000, pathSegments: ['api','auth','register']);
    // If your backend is hosted with HTTPS:
    // final uri = Uri.https('your-domain.com', '/api/auth/register');
    final body = {
      'shopName': shopName,
      'ownerName': ownerName,
      'mobile': mobile,
      'email': email,
      'password': password,
      'businessType': businessType,
      'address': address,
      'taxId': taxId,
    };
    try {
      final res = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) {
        final jsonBody = jsonDecode(res.body);
        if (jsonBody is Map<String, dynamic>) {
          return {
            'success': jsonBody['success'] == true,
            'message': jsonBody['message'] ?? '',
            'error': jsonBody['error'],
            'token': jsonBody['token'],
            'owner': jsonBody['owner'],
          };
        }
        return {'success': false, 'message': 'Invalid response format'};
      } else {
        return {'success': false, 'message': 'Server returned ${res.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}