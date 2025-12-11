import 'dart:convert';
import 'package:cart_link/constant.dart';
import 'package:http/http.dart' as http;

class OrderService {
  // Create a new order from checkout (one customer, one shop)
  static Future<Map<String, dynamic>> createOrder({
    required String customerId,
    required String shopId,
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final uri = backendUri('/api/orders');
      final body = {
        'customerId': customerId,
        'shopId': shopId,
        'products': products,
      };

      print('OrderService.createOrder -> $uri');
      print('Order body: ${jsonEncode(body)}');

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      print('CreateOrder: status=${res.statusCode} body=${res.body}');

      final respBody = jsonDecode(res.body);
      if (res.statusCode == 201) {
        return {
          'success': true,
          'data': respBody['data'] ?? respBody,
        };
      }

      return {
        'success': false,
        'message': respBody['message'] ?? 'Failed to create order',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get customer's orders
  static Future<Map<String, dynamic>> getCustomerOrders({
    required String customerId,
  }) async {
    try {
      final uri = backendUri('/api/orders/customer/$customerId');

      print('OrderService.getCustomerOrders -> $uri');

      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'data': body['data'] ?? [],
        };
      }

      return {
        'success': false,
        'message': 'Failed to fetch orders',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get order by ID
  static Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      final uri = backendUri('/api/orders/$orderId');

      print('OrderService.getOrderById -> $uri');

      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return {
          'success': true,
          'data': body['data'],
        };
      }

      return {
        'success': false,
        'message': 'Order not found',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Update order status
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String orderId,
    required String orderStatus,
  }) async {
    try {
      final uri = backendUri('/api/orders/$orderId/status');
      final body = {'orderStatus': orderStatus};

      print('OrderService.updateOrderStatus -> $uri');

      final res = await http
          .patch(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));

      print('UpdateOrderStatus: status=${res.statusCode}');

      if (res.statusCode == 200) {
        final respBody = jsonDecode(res.body);
        return {
          'success': true,
          'data': respBody['data'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to update order status',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
