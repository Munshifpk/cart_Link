import 'dart:convert';
import 'package:cart_link/constant.dart';
import 'package:http/http.dart' as http;

class CustomerAuthService {
  /// Check if a mobile exists. Expected to return a map like:
  /// { 'success': true, 'exists': false, 'message': '...' }
  static Future<Map<String, dynamic>> checkMobileExists(String mobile) async {
    final uri = backendUri('$kApiCustomerAuth/check-mobile/$mobile');
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
    final uri = backendUri('$kApiCustomerAuth/register');
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
      final uri = backendUri(kApiCustomers);
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

  /// Update customer profile data
  static Future<Map<String, dynamic>> updateCustomerProfile({
    required String customerId,
    String? customerName,
    String? email,
    String? address,
    int? mobile,
  }) async {
    try {
      final uri = backendUri('$kApiCustomers/$customerId');
      final body = <String, dynamic>{};
      if (customerName != null) body['customerName'] = customerName;
      if (email != null) body['email'] = email;
      if (address != null) body['address'] = address;
      if (mobile != null) body['mobile'] = mobile;

      final resp = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final responseBody = jsonDecode(resp.body);
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Profile updated successfully',
        };
      } else {
        final responseBody = jsonDecode(resp.body);
        return {
          'success': false,
          'message':
              responseBody['message'] ?? 'Server returned ${resp.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Change customer password
  static Future<Map<String, dynamic>> changePassword({
    required String customerId,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final uri = backendUri('$kApiCustomerAuth/change-password');
      final body = {
        'customerId': customerId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final resp = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final responseBody = jsonDecode(resp.body);
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Password changed successfully',
        };
      } else {
        final responseBody = jsonDecode(resp.body);
        return {
          'success': false,
          'message':
              responseBody['message'] ?? 'Server returned ${resp.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
