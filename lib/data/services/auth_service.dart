import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // Lấy User hiện tại (nếu đã login)
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream lắng nghe thay đổi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Đăng nhập và kiểm tra quyền Admin
  Future<UserCredential> login(String email, String password) async {
    try {
      final cred = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Gọi API kiểm tra quyền Admin
      final response = await _dio.get('/auth/check-admin', queryParameters: {
        'uid': cred.user!.uid,
      });

      if (response.statusCode == 200 && response.data['isAdmin'] == true) {
        final prefs = await SharedPreferences.getInstance();
        // Xóa storeId nếu có để tránh conflict do admin quản lý toàn bộ hệ thống
        await prefs.remove('storeId');

        // Fetch AdminProfile to get permissions
        try {
          final token = await cred.user!.getIdToken(true);
          final profileResponse = await Dio(BaseOptions(baseUrl: ApiConstants.baseUrl)).get(
            '/admin/users/${cred.user!.uid}/admin-profile',
            options: Options(headers: {
              'Authorization': 'Bearer $token',
              'X-Firebase-Token': token,
            }),
          );
          if (profileResponse.statusCode == 200 && profileResponse.data != null) {
            final List<dynamic> rawPermissions = profileResponse.data['permissions'] ?? [];
            final permissions = rawPermissions.map((e) => e.toString()).toList();
            await prefs.setStringList('admin_permissions', permissions);
          }
        } catch (e) {
          // If we couldn't fetch the profile (e.g. not configured yet), save empty/default permissions
          await prefs.setStringList('admin_permissions', []);
        }

        return cred;
      } else {
        await _firebaseAuth.signOut();
        throw Exception('Tài khoản của bạn không có quyền truy cập hệ thống dành cho Admin.');
      }
    } catch (e) {
      throw Exception('Lỗi đăng nhập: ${e.toString()}');
    }
  }

  // Đăng ký (gọi qua Spring Boot)
  Future<void> registerMerchant({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
  }) async {
    try {
      final response = await _dio.post('/auth/register-merchant', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phoneNumber': phoneNumber,
      });

      if (response.statusCode != 200) {
        throw Exception(response.data.toString());
      }
    } catch (e) {
      throw Exception('Lỗi đăng ký: ${e.toString()}');
    }
  }

  // Gửi email khôi phục mật khẩu
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Lỗi gửi email khôi phục: ${e.toString()}');
    }
  }

  // Lấy storeId đã lưu
  Future<String?> getStoreId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('storeId');
  }

  // Lưu storeId mới (sau khi tạo quán thành công)
  Future<void> saveStoreId(String storeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeId', storeId);
  }

  // Đăng xuất
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('storeId');
    await prefs.remove('admin_permissions');
    await _firebaseAuth.signOut();
  }
}
