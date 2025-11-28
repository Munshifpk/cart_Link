import 'dart:convert';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

String get _backendBase {
  if (kIsWeb) return 'http://localhost:5000';
  if (defaultTargetPlatform == TargetPlatform.android)
    return 'http://10.0.2.2:5000';
  return 'http://localhost:5000';
}

String get _backendUrl => '$_backendBase/api/customers';

class CustomerAuthService {
  /// Check if a mobile exists. Expected to return a map like:
  /// { 'success': true, 'exists': false, 'message': '...' }
  static Future<Map<String, dynamic>> checkMobileExists(String mobile) async {
    final uri = Uri.parse(
      '$_backendBase/api/customersauth/check-mobile/$mobile',
    );
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
  }) async {
    final uri = Uri.parse('$_backendBase/api/customersAuth/register');
    final body = {
      'customerName': customerName,
      'mobile': mobile,
      'email': email,
      'password': password,
    };
    try {
      // debug
      // ignore: avoid_print
      print('CustomerAuthService.register -> $uri');
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
      final uri = Uri.parse(_backendUrl);
      // debug
      // ignore: avoid_print
      print('CustomerService.getAllCustomers -> $uri');
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
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
