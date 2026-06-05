import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Lấy endpoint prefix dựa trên role (Merchant có storeId, Admin thì không)
  Future<String> _getEndpointPrefix() async {
    final prefs = await SharedPreferences.getInstance();
    final storeId = prefs.getString('storeId');
    return (storeId != null && storeId.isNotEmpty) ? '/merchants' : '/admins';
  }

  /// Lấy danh sách thông báo
  Future<List<Map<String, dynamic>>> getNotifications({int? type}) async {
    try {
      final prefix = await _getEndpointPrefix();
      final response = await _dio.get(
        '$prefix/notifications',
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
      throw _handleError(e);
    }
  }

  /// Đánh dấu một thông báo đã đọc
  Future<void> markAsRead(String notificationId) async {
    try {
      final prefix = await _getEndpointPrefix();
      await _dio.put('$prefix/notifications/$notificationId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Đánh dấu tất cả đã đọc
  Future<void> markAllAsRead() async {
    try {
      final prefix = await _getEndpointPrefix();
      await _dio.put('$prefix/notifications/read-all');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Xoá một thông báo
  Future<void> deleteNotification(String notificationId) async {
    try {
      final prefix = await _getEndpointPrefix();
      await _dio.delete('$prefix/notifications/$notificationId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Gửi thông báo toàn sàn (chỉ dành cho admin)
  Future<void> broadcastNotification({
    required String title,
    required String body,
    required String target,
  }) async {
    try {
      await _dio.post(
        '/admins/notifications/broadcast',
        data: {
          'title': title,
          'body': body,
          'target': target,
        },
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
}

