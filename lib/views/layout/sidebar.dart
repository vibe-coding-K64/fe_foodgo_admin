import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Sidebar extends StatefulWidget {
  final Function(String) onNavigate;
  final String currentRoute;

  const Sidebar({
    super.key,
    required this.onNavigate,
    this.currentRoute = '/dashboard',
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  List<String> _permissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _permissions = prefs.getStringList('admin_permissions') ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _hasPermission(String route) {
    if (_isLoading) return true; // Tránh flicker lúc load
    // Nếu có quyền 'all' hoặc danh sách trống (chưa setup / cũ) thì mặc định cho xem
    if (_permissions.isEmpty || _permissions.contains('all') || _permissions.contains('super_admin')) {
      return true;
    }

    if (route == '/dashboard') {
      return _permissions.contains('view_reports');
    }
    if (route == '/users') {
      return _permissions.contains('manage_users');
    }
    if (route == '/stores') {
      return _permissions.contains('manage_stores');
    }
    if (route == '/drivers') {
      return _permissions.contains('manage_users');
    }
    if (route == '/orders') {
      return _permissions.contains('manage_orders');
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2D),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // LOGO
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                const Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'FOODGO ADMIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'System Admin',
                        style: TextStyle(
                          color: Color(0xFFFF6B35),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: Colors.white10, thickness: 1),
          ),
          const SizedBox(height: 6),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                // Hệ thống
                _section('Hệ thống'),
                if (_hasPermission('/dashboard'))
                  _item(Icons.dashboard_outlined, 'Bảng điều khiển', '/dashboard'),
                if (_hasPermission('/stores'))
                  _item(Icons.store_outlined, 'Cửa hàng', '/stores'),
                _item(Icons.settings_outlined, 'Cấu hình hệ thống', '/settings'),

                // Nội dung
                _section('Nội dung'),
                _item(Icons.category_outlined, 'Danh mục', '/menu-categories'),
                _item(Icons.photo_library_outlined, 'Ảnh bìa quảng cáo', '/banners'),
                _item(Icons.notifications_active_outlined, 'Thông báo hệ thống', '/notifications'),

                // Kinh doanh
                _section('Kinh doanh'),
                if (_hasPermission('/orders'))
                  _item(Icons.shopping_bag_outlined, 'Đơn hàng toàn sàn', '/orders'),
                _item(Icons.local_offer_outlined, 'Mã giảm giá', '/vouchers'),
                _item(Icons.star_outline, 'Đánh giá', '/reviews'),

                // Tài chính
                _section('Tài chính'),
                _item(Icons.receipt_long_outlined, 'Lịch sử giao dịch', '/finance/transactions'),
                _item(Icons.account_balance_wallet_outlined, 'Duyệt rút tiền', '/finance/withdrawal'),

                // Hỗ trợ
                _section('Hỗ trợ'),
                _item(Icons.chat_bubble_outline, 'Khiếu nại & báo cáo', '/report-tickets'),
              ],
            ),
          ),

          // FOOTER
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('v1.0.0 · FoodGo Admin Portal',
                style: TextStyle(color: Colors.white24, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 20, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white38,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _item(IconData icon, String title, String route) {
    final bool isActive = widget.currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => widget.onNavigate(route),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFFF6B35).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? const Border(left: BorderSide(color: Color(0xFFFF6B35), width: 3))
                : null,
          ),
          child: Row(
            children: [
              Icon(icon,
                  color: isActive ? const Color(0xFFFF6B35) : Colors.white54,
                  size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white60,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6B35),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}