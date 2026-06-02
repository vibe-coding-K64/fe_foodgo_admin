import 'package:dio/dio.dart';
import '../models/system_config_model.dart';
import 'api_client.dart';

class SystemConfigApiService {
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
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<SystemConfig> getSystemConfig() async {
    try {
      final response = await _dio.get('/system-configs');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return SystemConfig.fromJson(response.data['data']);
      }
      throw Exception('Không thể tải cấu hình hệ thống');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<SystemConfig> updateSystemConfig(SystemConfig config) async {
    try {
      final response = await _dio.put('/system-configs', data: config.toJson());
      if (response.statusCode == 200 && response.data['success'] == true) {
        return SystemConfig.fromJson(response.data['data']);
      }
      throw Exception(response.data['message'] ?? 'Không thể cập nhật cấu hình hệ thống');
    } catch (e) {
      throw _handleError(e);
    }
  }
}
