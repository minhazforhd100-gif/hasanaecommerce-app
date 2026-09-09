import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class ApiService {
  // Replace this only after the actual MyBoneek API endpoint is confirmed.
  static const String baseUrl = '';

  static Future<List<Product>> fetchProducts() async {
    if (baseUrl.isEmpty) return [];
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode != 200) {
      throw Exception('Unable to load products');
    }
    final decoded = jsonDecode(response.body);
    final list = decoded is List ? decoded : (decoded['data'] ?? []);
    return list.map<Product>((e) => Product.fromJson(e)).toList();
  }

  static Future<String> placeOrder({
    required String name,
    required String phone,
    required String address,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    if (baseUrl.isEmpty) {
      // Backend is not configured yet. No fake order is submitted.
      throw Exception('ORDER_API_NOT_CONFIGURED');
    }
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customer_name': name,
        'phone': phone,
        'address': address,
        'payment_method': 'COD',
        'total': total,
        'items': items,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to place order');
    }
    final body = jsonDecode(response.body);
    return '${body['order_id'] ?? body['id'] ?? 'ORDER'}';
  }
}
