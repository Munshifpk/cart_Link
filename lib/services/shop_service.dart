import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

String get _backendBase {
  if (kIsWeb) return 'http://localhost:5000';
  if (defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:5000';
  return 'http://localhost:5000';
}

String get _backendUrl => '$_backendBase/api/shops';

class ShopService {
  static Future<Map<String, dynamic>> getAllShops() async {
    try {
        final uri = Uri.parse(_backendUrl);
        // debug
        // ignore: avoid_print
        print('ShopService.getAllShops -> $uri');
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

  // Disabled stubs for create/update/delete to avoid runtime errors elsewhere.
  static Future<Map<String, dynamic>> createShop(
    Map<String, dynamic> payload,
  ) async {
    return {'success': false, 'message': 'Create shop disabled'};
  }

  static Future<Map<String, dynamic>> updateShop(
    String id,
    Map<String, dynamic> payload,
  ) async {
    return {'success': false, 'message': 'Update shop disabled'};
  }

  static Future<Map<String, dynamic>> deleteShop(String id) async {
    return {'success': false, 'message': 'Delete shop disabled'};
  }
}
