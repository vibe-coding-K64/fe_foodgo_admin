import 'package:dio/dio.dart';
import '../models/store_model.dart';
import 'api_client.dart';

class StoreApiService {
  final Dio _dio = ApiClient().dio;

  // Lấy thông tin quán theo ID
  Future<Store> getStoreById(String id) async {
    try {
      final response = await _dio.get('/stores/$id');
      if (response.statusCode == 200) {
        return Store.fromJson(response.data);
      }
      throw 'Không tải được gian hàng';
    } catch (e) {
      throw 'Lỗi tải gian hàng: $e';
    }
  }

  // Cập nhật thông tin quán
  Future<Store> updateStore(String id, Store store) async {
    try {
      final response = await _dio.put('/stores/$id', data: store.toJson());
      if (response.statusCode == 200 && response.data['data'] != null) {
        return Store.fromJson(response.data['data']);
      }
      throw 'Cập nhật thất bại';
    } catch (e) {
      throw 'Lỗi cập nhật: $e';
    }
  }

  // Tạo quán mới
  Future<Store> createStore(String uid, Store store) async {
    try {
      final response = await _dio.post('/stores/merchant/$uid', data: store.toJson());
      if (response.statusCode == 200 && response.data != null) {
        return Store.fromJson(response.data);
      }
      throw 'Khởi tạo thất bại';
    } catch (e) {
      throw 'Lỗi khởi tạo: $e';
    }
  }

  // Lấy toàn bộ danh sách cửa hàng
  Future<List<Store>> getAllStores() async {
    try {
      final response = await _dio.get('/stores');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((e) => Store.fromJson(e)).toList();
      }
      throw 'Không tải được danh sách cửa hàng';
    } catch (e) {
      throw 'Lỗi tải danh sách: $e';
    }
  }

  // Duyệt cửa hàng
  Future<bool> approveStore(String id) async {
    try {
      final response = await _dio.post('/stores/$id/approve');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw 'Lỗi duyệt cửa hàng: $e';
    }
  }

  // Từ chối cửa hàng
  Future<bool> rejectStore(String id, String reason) async {
    try {
      final response = await _dio.post('/stores/$id/reject', data: {'reason': reason});
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw 'Lỗi từ chối cửa hàng: $e';
    }
  }

  // Tạm khóa cửa hàng
  Future<bool> lockStore(String id, String reason) async {
    try {
      final response = await _dio.post('/stores/$id/lock', data: {'reason': reason});
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw 'Lỗi tạm khóa cửa hàng: $e';
    }
  }

  // Mở khóa cửa hàng
  Future<bool> unlockStore(String id) async {
    try {
      final response = await _dio.post('/stores/$id/unlock');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw 'Lỗi mở khóa cửa hàng: $e';
    }
  }
}
