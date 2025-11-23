import 'dart:convert';
import 'package:http/http.dart' as http;

const String _backendUrl = 'http://localhost:5000/api/customers';

class CustomerAuthService {
  /// Check if a mobile exists. Expected to return a map like:
  /// { 'success': true, 'exists': false, 'message': '...' }
  static Future<Map<String, dynamic>> checkMobileExists(String mobile) async {
    // Local dev (Flutter web / desktop)
    final uri = Uri(
      scheme: 'http',
      host: 'localhost',
      port: 5000,
      pathSegments: ['api', 'customersauth', 'check-mobile', mobile],
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
        return {
          'success': false,
          'message': 'Server returned ${res.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Register a new shop. Expected to return a map like:
  /// { 'success': true, 'message': '...' } or { 'success': false, 'error': '...' }
  static Future<Map<String, dynamic>> register({
    required String customerName,
    required int mobile,
    required String email,
    required String password,
    required String location,
  }) async {
    final uri = Uri(
      scheme: 'http',
      host: 'localhost',
      port: 5000,
      pathSegments: ['api', 'customersAuth', 'register'],
    );
    // Android emulator:
    // final uri = Uri(scheme: 'http', host: '10.0.2.2', port: 5000, pathSegments: ['api','auth','register']);
    // Physical device (replace with your machine IP):
    // final uri = Uri(scheme: 'http', host: '192.168.x.x', port: 5000, pathSegments: ['api','auth','register']);
    // If your backend is hosted with HTTPS:
    // final uri = Uri.https('your-domain.com', '/api/auth/register');
    final body = {
      'customerName': customerName,
      'mobile': mobile,
      'email': email,
      'password': password,
      'location': location,
    };
    try {
      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      // Debug: log server response for easier diagnosis
      try {
        print('Customer register: status=${res.statusCode} body=${res.body}');
      } catch (_) {}

      dynamic jsonBody;
      try {
        jsonBody = jsonDecode(res.body);
      } catch (e) {
        return {
          'success': false,
          'message': 'Invalid JSON from server: ${res.body}',
        };
      }

      if (jsonBody is! Map<String, dynamic>) {
        return {'success': false, 'message': 'Invalid server response format.'};
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        return {'success': true, ...jsonBody};
      } else {
        // Use the message from the server if available, otherwise provide a fallback.
        return {
          'success': false,
          'message':
              jsonBody['message'] ?? 'Server returned status ${res.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}

class CustomerService {
  static Future<Map<String, dynamic>> getAllCustomers() async {
    try {
      final resp = await http
          .get(Uri.parse(_backendUrl))
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        return {'success': true, 'data': body['data'] ?? []};
      } else {
        return {
          'success': false,
          'message': 'Server returned ${resp.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
