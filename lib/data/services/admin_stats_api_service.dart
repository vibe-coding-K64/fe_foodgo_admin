import 'package:dio/dio.dart';
import 'api_constants.dart';

class AdminStatsApiService {
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

  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final response = await _dio.get('/admin/stats');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Không thể tải số liệu thống kê hệ thống');
    } catch (e) {
      throw _handleError(e);
    }
  }
}
