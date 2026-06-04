import 'package:dio/dio.dart';
import '../models/order_model.dart';
import 'api_client.dart';

class OrderApiService {
  final Dio _dio = ApiClient().dio;

  Future<List<Order>> getOrdersByStoreId(String storeId) async {
    try {
      final response = await _dio.get('/orders', queryParameters: {'storeId': storeId});
      final List<dynamic> data = response.data;
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load orders: $e');
    }
  }

  Future<List<Order>> getAllPlatformOrders() async {
    try {
      final response = await _dio.get('/orders/admin');
      final List<dynamic> data = response.data;
      return data.map((json) => Order.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load all platform orders: $e');
    }
  }

  Future<Order> getOrderById(String id) async {
    try {
      final response = await _dio.get('/orders/$id');
      return Order.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get order detail: $e');
    }
  }

  Future<void> updateOrderStatus(String id, String status) async {
    try {
      int statusCode = 0;
      switch (status) {
        case 'Chờ xác nhận':
          statusCode = 0;
          break;
        case 'Đang chế biến':
        case 'Đang chuẩn bị':
          statusCode = 1;
          break;
        case 'Đang giao':
          statusCode = 2;
          break;
        case 'Hoàn thành':
          statusCode = 3;
          break;
        case 'Đã hủy':
          statusCode = 4;
          break;
        default:
          statusCode = 0;
      }
      await _dio.put('/orders/$id/status', data: {'status': statusCode});
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }
}
