import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  late final Dio dio;

  factory ApiClient() {
    return _instance;
  }

  ApiClient._internal() {
    dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Thêm Interceptor tự động lấy và gắn Firebase ID Token
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            // Lấy ID Token (JWT) từ Firebase
            final token = await user.getIdToken(true); // force refresh
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
              options.headers['X-Firebase-Token'] = token; // Gửi kèm header xác thực Firebase của Backend
            }
          }
        } catch (e) {
          // Bỏ qua nếu không lấy được token
        }
        return handler.next(options);
      },
    ));
  }
}
