class ApiConstants {
  // Thay thế bằng địa chỉ IP của máy tính nếu chạy trên máy ảo Android (VD: 192.168.1.X)
  // Nếu chạy trên Web hoặc iOS Simulator, dùng localhost là được.

  // 1. Backend chạy cục bộ (Localhost) - Dùng để test trên máy của bạn (Port 8086)
  //static const String baseUrl = 'http://localhost:8086/api';
  // static const String baseUrl = 'http://10.0.2.2:8086/api'; // Dành cho máy ảo Android (Emulator)

  // 2. Backend remote (Production/Shared)
  static const String baseUrl = 'https://be-foodgo.canluaz.io.vn/api';
}
