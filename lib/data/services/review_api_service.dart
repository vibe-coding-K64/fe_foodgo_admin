import 'package:dio/dio.dart';
import 'api_constants.dart';

class ReviewApiService {
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
    return e.toString();
  }

  Future<List<Map<String, dynamic>>> getAllReviews() async {
    try {
      final response = await _dio.get('/reviews/admin');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List data = response.data['data'];
        return data.map((json) => Map<String, dynamic>.from(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteReview(String id) async {
    try {
      final response = await _dio.delete('/reviews/admin/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
