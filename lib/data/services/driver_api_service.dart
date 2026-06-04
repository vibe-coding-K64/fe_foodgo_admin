import 'package:dio/dio.dart';
import 'api_client.dart';

class DriverApiService {
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

  /// Lấy danh sách tất cả tài xế (role = 2)
  Future<List<Map<String, dynamic>>> getAllDrivers() async {
    try {
      final response = await _dio.get('/admin/users', queryParameters: {'role': 2});
      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((json) => Map<String, dynamic>.from(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Khoá / mở khoá tài khoản tài xế
  Future<bool> toggleDriverActive(String driverId) async {
    try {
      final response = await _dio.post('/admin/users/$driverId/toggle-active');
      if (response.statusCode == 200) {
        return response.data == true;
      }
      throw Exception('Lỗi thay đổi trạng thái tài xế');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Lấy thông tin chi tiết hồ sơ tài xế (phương tiện, doanh thu, đánh giá)
  Future<Map<String, dynamic>> getDriverProfile(String driverId) async {
    try {
      final response = await _dio.get('/admin/users/$driverId/driver-profile');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw 'Không tải được hồ sơ tài xế';
    } catch (e) {
      throw _handleError(e);
    }
  }
}
