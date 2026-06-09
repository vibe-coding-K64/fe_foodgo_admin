# Hướng dẫn chạy dự án FoodGo Admin Portal (fe_food_go_portal)

Tài liệu này hướng dẫn cách cấu hình, cài đặt và khởi chạy dự án quản trị **FoodGo Admin Portal** viết bằng Flutter.

---

## 1. Công nghệ sử dụng
Dự án được xây dựng dựa trên các công nghệ và thư viện cốt lõi sau:
* **Framework**: Flutter (Multi-platform)
* **Ngôn ngữ**: Dart
* **Cơ sở dữ liệu & Xác thực**: Firebase (Firebase Core, Firebase Auth, Cloud Firestore)
* **Kết nối API**: Dio (HTTP Client)
* **Lưu trữ cục bộ**: SharedPreferences
* **Biểu đồ & UI**: `fl_chart`, `cupertino_icons`
* **Xử lý tệp & hình ảnh**: `image_picker`, `file_picker`
* **Định dạng dữ liệu**: `intl`

---

## 2. Phiên bản Flutter/Dart sử dụng
* **Dart SDK**: `^3.11.1`
* **Flutter SDK**: Khuyến nghị phiên bản Flutter ổn định tương thích với Dart SDK `3.11.1` trở lên.

---

## 3. Các package/dependency cần cài đặt
Các dependency chính được khai báo trong [pubspec.yaml](file:///c:/DATA.N/Data.S/Mobile/FE_MOBILE/fe_foodgo_admin/pubspec.yaml):
* `firebase_core: ^4.9.0`
* `firebase_auth: ^6.5.1`
* `dio: ^5.9.2`
* `shared_preferences: ^2.5.5`
* `fl_chart: ^0.66.0`
* `intl: ^0.19.0`
* `image_picker: ^1.1.2`
* `file_picker: ^8.1.2`
* `cupertino_icons: ^1.0.8`

---

## 4. Các bước cài đặt và chạy project

### Bước 1: Clone dự án về máy
```bash
git clone <URL_REPOS_CỦA_BẠN>
cd fe_foodgo_admin
```

### Bước 2: Tải các dependencies
Chạy lệnh sau để tải toàn bộ các gói thư viện cần thiết:
```bash
flutter pub get
```

### Bước 3: Cấu hình địa chỉ API Backend
Mở file [api_constants.dart](file:///c:/DATA.N/Data.S/Mobile/FE_MOBILE/fe_foodgo_admin/lib/data/services/api_constants.dart) và điều chỉnh giá trị `baseUrl` phù hợp với môi trường chạy của bạn:
* **Chạy trên Web hoặc iOS Simulator**:
  ```dart
  static const String baseUrl = 'http://localhost:8086/api';
  ```
* **Chạy trên máy ảo Android (Android Emulator)**:
  ```dart
  static const String baseUrl = 'http://10.0.2.2:8086/api';
  ```
* **Chạy trên thiết bị thật (Real Device)**: Thay thế bằng địa chỉ IP máy tính cục bộ của bạn trong cùng mạng Wi-Fi (VD: `http://192.168.1.X:8086/api`).

### Bước 4: Khởi chạy dự án
Chạy lệnh bên dưới hoặc chọn thiết bị chạy thông qua VS Code / Android Studio:
```bash
flutter run
```

---

## 5. Tài khoản kiểm thử (Test Account)
* Để đăng nhập vào hệ thống Admin, tài khoản của bạn cần được cấp quyền quản trị (`isAdmin == true` từ API Backend).
* Vui lòng liên hệ với người quản trị hệ thống Backend để phân quyền cho tài khoản của bạn sau khi đăng ký trên ứng dụng.
  admin@foodgo.com
  admin123
---

## 6. Các lưu ý cần thiết để project hoạt động tốt
1. **Khởi chạy Backend trước**: Hãy chắc chắn rằng dự án Backend (API Server chạy ở cổng `8086` hoặc cấu hình tương đương) đã được bật để các API đăng nhập, kiểm tra quyền admin hoạt động ổn định.
2. **Cấu hình Firebase**: Dự án đã tích hợp cấu hình Firebase thông qua file [firebase_options.dart](file:///c:/DATA.N/Data.S/Mobile/FE_MOBILE/fe_foodgo_admin/lib/firebase_options.dart). Đảm bảo kết nối mạng của bạn không chặn các dịch vụ của Google/Firebase.
3. **Quyền truy cập thư viện**: Khi chạy trên thiết bị thật hoặc máy ảo, hãy cấp các quyền truy cập máy ảnh (`Camera`) và thư viện ảnh (`Gallery/Files`) để tính năng tải lên hình ảnh cho thực đơn/quán hoạt động đúng.
