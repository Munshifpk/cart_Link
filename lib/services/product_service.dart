import 'dart:convert';
import 'package:http/http.dart' as http;

const String _backendUrl = 'http://localhost:5000/api/products';

class ProductService {
  // Fetch products; if ownerId provided backend will filter by owner
  static Future<Map<String, dynamic>> getProducts({String? ownerId}) async {
    try {
      final uri = Uri.parse(_backendUrl).replace(
        queryParameters: ownerId != null ? {'ownerId': ownerId} : null,
      );

      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final body = json.decode(resp.body);
        // support both { success: true, data: [...] } and raw array responses
        if (body is Map && body.containsKey('data')) {
          return {'success': true, 'data': body['data'] ?? []};
        } else if (body is List) {
          return {'success': true, 'data': body};
        } else {
          return {'success': false, 'message': 'Unexpected response format'};
        }
      } else {
        return {'success': false, 'message': 'Server returned ${resp.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createProduct(Map<String, dynamic> data) async {
    try {
      final res = await http.post(Uri.parse(_backendUrl), headers: {'Content-Type': 'application/json'}, body: jsonEncode(data)).timeout(const Duration(seconds: 15));
      print('CreateProduct: status=${res.statusCode} body=${res.body}');
      final body = jsonDecode(res.body);
      if (res.statusCode == 201) return {'success': true, 'data': body['data']};
      return {'success': false, 'message': body['message'] ?? 'Server returned ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final res = await http.delete(Uri.parse('$_backendUrl/$id')).timeout(const Duration(seconds: 15));
      print('DeleteProduct: status=${res.statusCode}');
      if (res.statusCode == 200 || res.statusCode == 204) {
        return {'success': true};
      }
      final body = jsonDecode(res.body);
      return {'success': false, 'message': body['message'] ?? 'Server returned ${res.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
