import 'package:dio/dio.dart';
import '../models/voucher_model.dart';
import 'api_client.dart';

class VoucherApiService {
  final Dio _dio = ApiClient().dio;

  Future<List<Voucher>> getAllVouchers({String? storeId}) async {
    try {
      final response = await _dio.get('/vouchers', queryParameters: storeId != null ? {'storeId': storeId} : null);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Voucher.fromJson(json)).toList();
      }
      throw Exception('Failed to load vouchers');
    } catch (e) {
      throw Exception('Lỗi kết nối Server: $e');
    }
  }

  Future<Voucher> getVoucher(String id) async {
    try {
      final response = await _dio.get('/vouchers/$id');
      if (response.statusCode == 200) {
        return Voucher.fromJson(response.data);
      }
      throw Exception('Failed to load voucher');
    } catch (e) {
      throw Exception('Lỗi kết nối Server: $e');
    }
  }

  Future<void> createVoucher(Voucher voucher) async {
    try {
      await _dio.post('/vouchers', data: voucher.toJson());
    } catch (e) {
      throw Exception('Lỗi tạo voucher: $e');
    }
  }

  Future<void> updateVoucher(String id, Voucher voucher) async {
    try {
      await _dio.put('/vouchers/$id', data: voucher.toJson());
    } catch (e) {
      throw Exception('Lỗi cập nhật voucher: $e');
    }
  }

  Future<void> deleteVoucher(String id) async {
    try {
      await _dio.delete('/vouchers/$id');
    } catch (e) {
      throw Exception('Lỗi xoá voucher: $e');
    }
  }
}
