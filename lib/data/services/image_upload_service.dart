import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class ImageUploadService {
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

  /// Uploads an image using byte data and a filename.
  /// This works cross-platform (iOS, Android, Web, Desktop).
  Future<String> uploadImage({
    required Uint8List bytes,
    required String fileName,
    String folder = 'general',
  }) async {
    try {
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      final response = await _dio.post(
        '/upload/image',
        queryParameters: {'folder': folder},
        data: formData,
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null && data['url'] != null) {
          return data['url'];
        }
      }
      throw response.data['message'] ?? 'Lỗi không xác định khi upload ảnh';
    } catch (e) {
      throw Exception(_handleError(e));
    }
  }
}