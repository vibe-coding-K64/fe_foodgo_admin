import 'package:dio/dio.dart';
import 'api_client.dart';

class ReportApiService {
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

  /// Lấy danh sách khiếu nại, có thể filter theo status
  Future<List<Map<String, dynamic>>> getAllReports({String? status}) async {
    try {
      final response = await _dio.get(
        '/reports',
        queryParameters: status != null && status != 'Tất cả' ? {'status': _mapStatus(status)} : null,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          List list = data['data'];
          return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Cập nhật trạng thái khiếu nại
  Future<void> updateStatus(String id, String status, {String adminNote = ''}) async {
    try {
      await _dio.put('/reports/$id/status', data: {
        'status': _mapStatus(status),
        'adminNote': adminNote,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Map từ tiếng Việt sang status BE
  String _mapStatus(String vi) {
    switch (vi) {
      case 'Mở':
        return 'open';
      case 'Đang xử lý':
        return 'processing';
      case 'Đã giải quyết':
        return 'resolved';
      default:
        return vi.toLowerCase();
    }
  }

  /// Map từ status BE sang tiếng Việt
  static String mapStatusVi(String status) {
    switch (status) {
      case 'open':
        return 'Mở';
      case 'processing':
        return 'Đang xử lý';
      case 'resolved':
        return 'Đã giải quyết';
      default:
        return status;
    }
  }
}
