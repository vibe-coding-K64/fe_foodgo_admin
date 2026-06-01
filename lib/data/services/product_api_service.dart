import 'package:dio/dio.dart';
import '../models/product_model.dart';
import 'api_constants.dart';

class ProductApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  String _handleError(dynamic e) {
    if (e is DioException) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          return data['message'].toString();
        }
      }
      return e.message ?? 'Lỗi kết nối mạng';
    }
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<List<Product>> getAllProducts(String storeId) async {
    try {
      final response = await _dio.get('/products', queryParameters: {'storeId': storeId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        List data = response.data['data'];
        return data.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final response = await _dio.get('/products/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return Product.fromJson(response.data['data']);
      }
      throw response.data['message'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> createProduct(Product product) async {
    try {
      final response = await _dio.post('/products', data: product.toJson());
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return;
      }
      throw response.data['message'] ?? 'Lỗi không xác định';
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> updateProduct(String id, Product product) async {
    try {
      final response = await _dio.put('/products/$id', data: product.toJson());
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      throw response.data['message'] ?? 'Lỗi không xác định';
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final response = await _dio.delete('/products/$id');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return true;
      }
      throw response.data['message'] ?? 'Lỗi không xác định';
    } catch (e) {
      throw _handleError(e);
    }
  }
}
