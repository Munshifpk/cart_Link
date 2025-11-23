import 'dart:convert';
import 'package:http/http.dart' as http;

const String _backendUrl = 'http://localhost:5000/api/shops';

class ShopService {
  static Future<Map<String, dynamic>> getAllShops() async {
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
