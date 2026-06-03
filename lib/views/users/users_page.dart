import 'package:flutter/material.dart';
import '../../data/services/user_api_service.dart';

class UsersPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const UsersPage({super.key, this.onNavigate});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with SingleTickerProviderStateMixin {
  final UserApiService _userApiService = UserApiService();
  late TabController _tabController;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _users = [];

  // Tab mappings: 0 -> 1 (Customer), 1 -> 3 (Merchant), 2 -> 2 (Driver), 3 -> 4 (Admin)
  final List<Map<String, dynamic>> _tabsConfig = [
    {'label': 'Khách hàng', 'role': 1, 'icon': Icons.people_outline},
    {'label': 'Cửa hàng', 'role': 3, 'icon': Icons.storefront_outlined},
    {'label': 'Tài xế', 'role': 2, 'icon': Icons.local_shipping_outlined},
    {'label': 'Quản trị viên', 'role': 4, 'icon': Icons.admin_panel_settings_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabsConfig.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchUsers();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final role = _tabsConfig[_tabController.index]['role'] as int;
      final list = await _userApiService.getAllUsers(role: role);
      setState(() {
        _users = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách tài khoản: $e';
      });
    }
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';

    try {
      final newStatus = await _userApiService.toggleUserActive(userId);
      setState(() {
        user['isActive'] = newStatus;
      });
      _showToast(
        newStatus ? 'Đã kích hoạt tài khoản thành công!' : 'Đã khóa tài khoản thành công!',
        newStatus ? Colors.green : Colors.redAccent,
      );
    } catch (e) {
      _showToast('Không thể thay đổi trạng thái: $e', Colors.red);
    }
  }

  void _showToast(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý Người dùng & Phân quyền',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2D),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Giám sát tài khoản hệ thống, khóa/mở khóa các đối tác hoặc khách hàng vi phạm chính sách',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            IconButton(
              onPressed: _fetchUsers,
              icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
              tooltip: 'Tải lại',
            )
          ],
        ),
        const SizedBox(height: 24),

        // TABS BAR
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
            ],
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFFFF6B35),
            labelColor: const Color(0xFFFF6B35),
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: _tabsConfig.map((t) {
              return Tab(
                height: 50,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t['icon'] as IconData, size: 18),
                    const SizedBox(width: 8),
                    Text(t['label'] as String),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // TABLE CONTENT
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
                : _errorMessage != null
                    ? _buildErrorState()
                    : _users.isEmpty
                        ? _buildEmptyState()
                        : _buildUsersTable(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchUsers, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 70, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Không có tài khoản nào thuộc nhóm này!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable() {
    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: const Row(
            children: [
              SizedBox(width: 80, child: Text('Mã ND', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Họ và Tên', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Số Điện Thoại', style: TextStyle(fontWeight: FontWeight.bold))),
              SizedBox(width: 140, child: Text('Trạng Thái', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(width: 120, child: Text('Thao Tác', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: ListView.separated(
            itemCount: _users.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final user = _users[index];
              final id = user['id']?.toString() ?? '';
              final fullName = user['fullName']?.toString() ?? 'Người dùng';
              final email = user['email']?.toString() ?? '--';
              final phoneNumber = user['phoneNumber']?.toString() ?? '--';
              final photoUrl = user['photoUrl']?.toString();
              final isActive = user['isActive'] == true;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B35))),
                    ),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFFFF3E0),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: photoUrl != null && photoUrl.isNotEmpty && !photoUrl.contains('example.com')
                                  ? Image.network(
                                      photoUrl,
                                      width: 32,
                                      height: 32,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, err, st) => Center(
                                        child: Text(
                                          fullName.isEmpty ? '?' : fullName[0].toUpperCase(),
                                          style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Text(
                                        fullName.isEmpty ? '?' : fullName[0].toUpperCase(),
                                        style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(email, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(phoneNumber),
                    ),
                    SizedBox(
                      width: 140,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'Đang hoạt động' : 'Đã khóa',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Switch(
                              value: isActive,
                              onChanged: (_) => _toggleUserStatus(user),
                              activeColor: const Color(0xFFFF6B35),
                              inactiveThumbColor: Colors.grey,
                            ),
                            Icon(
                              isActive ? Icons.lock_open : Icons.lock_outline,
                              size: 16,
                              color: isActive ? Colors.green : Colors.grey,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
