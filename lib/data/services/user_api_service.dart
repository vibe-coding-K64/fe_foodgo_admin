import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

class UserApiService {
  final Dio _dio = ApiClient().dio;
  
  static final ValueNotifier<Map<String, dynamic>?> profileNotifier = ValueNotifier<Map<String, dynamic>?>(null);

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

  Future<List<Map<String, dynamic>>> getAllUsers({int? role}) async {
    try {
      final response = await _dio.get(
        '/admin/users',
        queryParameters: role != null ? {'role': role} : null,
      );
      if (response.statusCode == 200) {
        List data = response.data;
        return data.map((json) => Map<String, dynamic>.from(json)).toList();
      }
      return [];
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<bool> toggleUserActive(String userId) async {
    try {
      final response = await _dio.post('/admin/users/$userId/toggle-active');
      if (response.statusCode == 200) {
        return response.data == true;
      }
      throw Exception('Lỗi thay đổi trạng thái tài khoản');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> createAdminUser({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String department,
    required int adminLevel,
    required List<String> permissions,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/users/create-admin',
        data: {
          'email': email,
          'password': password,
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'department': department,
          'adminLevel': adminLevel,
          'permissions': permissions,
        },
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Lỗi tạo tài khoản admin');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateUserRoles(String userId, List<int> roles) async {
    try {
      final response = await _dio.put(
        '/admin/users/$userId/roles',
        data: {'roles': roles},
      );
      if (response.statusCode != 200) {
        throw Exception('Lỗi cập nhật vai trò');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getAdminProfile(String userId) async {
    try {
      final response = await _dio.get('/admin/users/$userId/admin-profile');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      throw Exception('Lỗi lấy hồ sơ admin');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> updateAdminProfile(
    String userId, {
    required String department,
    required int adminLevel,
    required List<String> permissions,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/users/$userId/admin-profile',
        data: {
          'department': department,
          'adminLevel': adminLevel,
          'permissions': permissions,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Lỗi cập nhật phân quyền admin');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getCurrentProfile() async {
    try {
      final response = await _dio.get('/customers/profile');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          final profileData = Map<String, dynamic>.from(data['data']);
          profileNotifier.value = profileData;
          return profileData;
        }
      }
      throw Exception('Không thể tải hồ sơ cá nhân');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateCurrentProfile({
    String? password,
    String? fullName,
    String? email,
    List<int>? avatarBytes,
    String? avatarName,
  }) async {
    try {
      final Map<String, dynamic> map = {};
      if (password != null) map['password'] = password;
      if (fullName != null) map['fullName'] = fullName;
      if (email != null) map['email'] = email;
      if (avatarBytes != null && avatarName != null) {
        map['avatar'] = MultipartFile.fromBytes(avatarBytes, filename: avatarName);
      }

      final response = await _dio.put(
        '/customers/profile',
        data: FormData.fromMap(map),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map && data.containsKey('data')) {
          final profileData = Map<String, dynamic>.from(data['data']);
          profileNotifier.value = profileData;
          return profileData;
        }
      }
      throw Exception('Không thể cập nhật hồ sơ');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> changeCurrentPassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.put(
        '/customers/password',
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Lỗi đổi mật khẩu');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }
}
