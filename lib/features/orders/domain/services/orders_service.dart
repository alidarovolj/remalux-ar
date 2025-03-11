import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:remalux_ar/core/services/storage_service.dart';
import 'package:remalux_ar/features/orders/domain/models/order.dart';

class OrdersService {
  final String baseUrl = 'https://api.remalux.kz/api';

  Future<List<Order>> getMyOrders({int page = 1, int perPage = 10}) async {
    final token = await StorageService.getToken();
    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/orders/my-orders?page=$page&perPage=$perPage'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> ordersJson = data['data'];
      return ordersJson.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders: ${response.statusCode}');
    }
  }
}
