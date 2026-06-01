import 'package:dio/dio.dart';
import '../models/category_model.dart';
import 'api_constants.dart';

class CategoryApiService {
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

  Future<List<Category>> getAllCategories(String storeId) async {
    try {
      final response = await _dio.get('/categories', queryParameters: {'storeId': storeId});
      if (response.statusCode == 200 && response.data['success'] == true) {
        List data = response.data['data'];
        return data.map((json) => Category.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Category> createCategory(Category category) async {
    try {
      final response = await _dio.post('/categories', data: category.toJson());
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['success'] == true) {
        return Category(
          id: response.data['data'],
          storeId: category.storeId,
          name: category.name,
          order: category.order,
          icon: category.icon,
          imageUrl: category.imageUrl,
        );
      }
      throw response.data['message'];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> updateCategory(String id, Category category) async {
    try {
      final response = await _dio.put('/categories/$id', data: category.toJson());
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteCategory(String id) async {
    try {
      final response = await _dio.delete('/categories/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
