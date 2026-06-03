import 'package:dio/dio.dart';
import 'api_client.dart';

class AdminTransactionApiService {
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

  Future<List<Map<String, dynamic>>> getPendingWithdrawals() async {
    try {
      final response = await _dio.get('/admin/transactions/withdrawals/pending');
      if (response.statusCode == 200 && response.data['success'] == true) {
        List data = response.data['data'];
        return List<Map<String, dynamic>>.from(data);
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> approveWithdrawal(String transactionId) async {
    try {
      final response = await _dio.post('/admin/transactions/withdrawals/$transactionId/approve');
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> rejectWithdrawal(String transactionId, String reason) async {
    try {
      final response = await _dio.post(
        '/admin/transactions/withdrawals/$transactionId/reject',
        queryParameters: {'reason': reason},
      );
      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      throw _handleError(e);
    }
  }
}
