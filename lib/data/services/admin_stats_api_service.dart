import 'package:dio/dio.dart';
import 'api_client.dart';

class AdminStatsApiService {
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

  Future<Map<String, dynamic>> getSystemStats({String? period, String? from, String? to}) async {
    try {
      final Map<String, dynamic> params = {};
      if (period != null) params['period'] = period;
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;

      final response = await _dio.get('/admin/stats', queryParameters: params);
      if (response.statusCode == 200) {
        final resData = response.data;
        if (resData is Map && resData.containsKey('data') && resData['data'] != null) {
          return Map<String, dynamic>.from(resData['data']);
        }
        return Map<String, dynamic>.from(resData);
      }
      throw Exception('Không thể tải số liệu thống kê hệ thống');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getMerchantStats(String storeId, {String? period, String? from, String? to}) async {
    try {
      final Map<String, dynamic> params = {'storeId': storeId};
      if (period != null) params['period'] = period;
      if (from != null) params['from'] = from;
      if (to != null) params['to'] = to;

      final response = await _dio.get('/merchants/stats', queryParameters: params);
      if (response.statusCode == 200) {
        final resData = response.data;
        if (resData is Map && resData.containsKey('data') && resData['data'] != null) {
          return Map<String, dynamic>.from(resData['data']);
        }
        return Map<String, dynamic>.from(resData);
      }
      throw Exception('Không thể tải số liệu thống kê cửa hàng');
    } catch (e) {
      throw _handleError(e);
    }
  }
}
