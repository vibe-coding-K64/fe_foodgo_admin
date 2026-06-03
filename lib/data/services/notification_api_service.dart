import 'package:dio/dio.dart';
import 'api_client.dart';

/// Notification API Service cho Admin Portal.
/// NotificationController BE (/api/drivers/notifications) chỉ lấy thông báo theo userId tài xế.
/// Admin sử dụng Firebase Firestore trực tiếp qua BE để lấy system-wide notifications.
/// Hiện tại service này lấy thông báo của chính admin (userId từ JWT).
class NotificationApiService {
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

  /// Lấy danh sách thông báo (dùng endpoint của driver nhưng với token Admin)
  Future<List<Map<String, dynamic>>> getNotifications({int? type}) async {
    try {
      final response = await _dio.get(
        '/drivers/notifications',
        queryParameters: type != null ? {'type': type} : null,
      );
      if (response.statusCode == 200) {
        final body = response.data;
        if (body is Map && body.containsKey('data')) {
          final List list = body['data'];
          return list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
      return [];
    } catch (e) {
      // Có thể admin không có thông báo driver - trả về rỗng
      return [];
    }
  }

  /// Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.put('/drivers/notifications/$notificationId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead() async {
    try {
      await _dio.put('/drivers/notifications/read-all');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Xoá một thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('/drivers/notifications/$notificationId');
    } catch (e) {
      throw _handleError(e);
    }
  }
}
