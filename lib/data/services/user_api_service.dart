import 'package:dio/dio.dart';
import 'api_client.dart';

class UserApiService {
  final Dio _dio = ApiClient().dio;

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

  Future<List<Map<String, dynamic>>> getAllUsers({int? role}) async {
    try {
      final response = await _dio.get(
        '/admin/users',
        queryParameters: role != null ? {'role': role} : null,
      );
      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((json) => Map<String, dynamic>.from(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> toggleUserActive(String userId) async {
    try {
      final response = await _dio.post('/admin/users/$userId/toggle-active');
      if (response.statusCode == 200) {
        return response.data == true;
      }
      throw Exception('Lỗi thay đổi trạng thái tài khoản');
    } catch (e) {
      throw _handleError(e);
    }
  }
}
