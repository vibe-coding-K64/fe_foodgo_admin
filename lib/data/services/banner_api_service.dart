import 'package:dio/dio.dart';
import '../models/banner_model.dart';
import 'api_constants.dart';

class BannerApiService {
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
    return e.toString().replaceAll('Exception: ', '');
  }

  Future<List<BannerModel>> getAllBanners() async {
    try {
      final response = await _dio.get('/banners');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List data = response.data['data'];
        return data.map((json) => BannerModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<String> createBanner(BannerModel banner) async {
    try {
      final response = await _dio.post('/banners', data: banner.toJson());
      if (response.statusCode == 201 && response.data['success'] == true) {
        return response.data['data'].toString();
      }
      throw Exception(response.data['message'] ?? 'Không thể tạo Banner');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> updateBanner(String id, BannerModel banner) async {
    try {
      final response = await _dio.put('/banners/$id', data: banner.toJson());
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> deleteBanner(String id) async {
    try {
      final response = await _dio.delete('/banners/$id');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
