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
    if (_tabController.indexIsChanging) {
      setState(() {});
      return;
    }
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Color(0xFFFF6B35),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý người dùng và phân quyền',
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
              ],
            ),
            Row(
              children: [
                if (_tabController.index == 3)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _showCreateAdminDialog,
                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                    label: const Text('Thêm Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: _fetchUsers,
                  icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
                  tooltip: 'Tải lại',
                ),
              ],
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
              SizedBox(width: 120, child: Text('Trạng Thế', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              SizedBox(width: 180, child: Text('Thao Tác', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
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
                      width: 120,
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
                      width: 180,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Nút khoá/mở tài khoản dùng Switch
                            Switch(
                              value: isActive,
                              onChanged: (_) => _toggleUserStatus(user),
                              activeColor: const Color(0xFFFF6B35),
                              inactiveThumbColor: Colors.grey,
                            ),
                            // Đổi vai trò
                            IconButton(
                              icon: const Icon(Icons.manage_accounts, color: Colors.blueAccent, size: 20),
                              tooltip: 'Đổi vai trò',
                              onPressed: () => _showChangeRolesDialog(user),
                            ),
                            // Phân quyền Admin
                            if (_tabsConfig[_tabController.index]['role'] == 4)
                              IconButton(
                                icon: const Icon(Icons.key, color: Colors.amber, size: 20),
                                tooltip: 'Phân quyền Admin',
                                onPressed: () => _showAdminPermissionsDialog(user),
                              ),
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

  void _showChangeRolesDialog(Map<String, dynamic> user) {
    final userId = user['id']?.toString() ?? '';
    final List<dynamic> rawRoles = user['roles'] ?? [];
    List<int> currentRoles = rawRoles.map((e) => int.parse(e.toString())).toList();

    bool hasRole(int role) => currentRoles.contains(role);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Nhóm quyền của: ${user['fullName'] ?? 'Người dùng'}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Khách hàng (1)'),
                    value: hasRole(1),
                    onChanged: (val) {
                      setStateDialog(() {
                        if (val == true) {
                          if (!currentRoles.contains(1)) currentRoles.add(1);
                        } else {
                          currentRoles.remove(1);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Tài xế (2)'),
                    value: hasRole(2),
                    onChanged: (val) {
                      setStateDialog(() {
                        if (val == true) {
                          if (!currentRoles.contains(2)) currentRoles.add(2);
                        } else {
                          currentRoles.remove(2);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Cửa hàng (3)'),
                    value: hasRole(3),
                    onChanged: (val) {
                      setStateDialog(() {
                        if (val == true) {
                          if (!currentRoles.contains(3)) currentRoles.add(3);
                        } else {
                          currentRoles.remove(3);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Quản trị viên (4)'),
                    value: hasRole(4),
                    onChanged: (val) {
                      setStateDialog(() {
                        if (val == true) {
                          if (!currentRoles.contains(4)) currentRoles.add(4);
                        } else {
                          currentRoles.remove(4);
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                  onPressed: () async {
                    try {
                      await _userApiService.updateUserRoles(userId, currentRoles);
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showToast('Cập nhật vai trò thành công!', Colors.green);
                      _fetchUsers();
                    } catch (e) {
                      if (!context.mounted) return;
                      _showToast('Lỗi cập nhật vai trò: $e', Colors.red);
                    }
                  },
                  child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAdminPermissionsDialog(Map<String, dynamic> user) async {
    final userId = user['id']?.toString() ?? '';
    final stateContext = context;
    
    showDialog(
      context: stateContext,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
    );

    Map<String, dynamic>? profile;
    try {
      profile = await _userApiService.getAdminProfile(userId);
      if (!stateContext.mounted) return;
      Navigator.pop(stateContext);
    } catch (e) {
      if (!stateContext.mounted) return;
      Navigator.pop(stateContext);
      _showToast('Không thể lấy thông tin phân quyền: $e', Colors.red);
      return;
    }

    final deptController = TextEditingController(text: profile['department']?.toString() ?? 'Management');
    int adminLevel = int.tryParse(profile['adminLevel']?.toString() ?? '1') ?? 1;
    final List<dynamic> rawPerms = profile['permissions'] ?? [];
    List<String> permissions = rawPerms.map((e) => e.toString()).toList();

    bool hasPerm(String perm) => permissions.contains(perm);

    if (!stateContext.mounted) return;
    showDialog(
      context: stateContext,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Phân quyền Admin: ${user['fullName'] ?? 'Admin'}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: deptController,
                      decoration: const InputDecoration(labelText: 'Phòng ban / Bộ phận'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      value: adminLevel,
                      decoration: const InputDecoration(labelText: 'Cấp độ Admin'),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Cấp 1 - Staff')),
                        DropdownMenuItem(value: 2, child: Text('Cấp 2 - Supervisor')),
                        DropdownMenuItem(value: 3, child: Text('Cấp 3 - Manager')),
                        DropdownMenuItem(value: 4, child: Text('Cấp 4 - Super Admin')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setStateDialog(() {
                            adminLevel = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Danh sách quyền hạn:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    CheckboxListTile(
                      title: const Text('Quản lý người dùng (manage_users)'),
                      value: hasPerm('manage_users'),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            permissions.add('manage_users');
                          } else {
                            permissions.remove('manage_users');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Phê duyệt cửa hàng (manage_stores)'),
                      value: hasPerm('manage_stores'),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            permissions.add('manage_stores');
                          } else {
                            permissions.remove('manage_stores');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Xử lý đơn hàng (manage_orders)'),
                      value: hasPerm('manage_orders'),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            permissions.add('manage_orders');
                          } else {
                            permissions.remove('manage_orders');
                          }
                        });
                      },
                    ),
                    CheckboxListTile(
                      title: const Text('Xem báo cáo thống kê (view_reports)'),
                      value: hasPerm('view_reports'),
                      onChanged: (val) {
                        setStateDialog(() {
                          if (val == true) {
                            permissions.add('view_reports');
                          } else {
                            permissions.remove('view_reports');
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
                  onPressed: () async {
                    try {
                      await _userApiService.updateAdminProfile(
                        userId,
                        department: deptController.text,
                        adminLevel: adminLevel,
                        permissions: permissions,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showToast('Cập nhật phân quyền thành công!', Colors.green);
                    } catch (e) {
                      if (!context.mounted) return;
                      _showToast('Lỗi cập nhật phân quyền: $e', Colors.red);
                    }
                  },
                  child: const Text('Lưu', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateAdminDialog() {
    final emailController = TextEditingController();
    final passController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final deptController = TextEditingController(text: 'Management');
    int adminLevel = 1;
    List<String> permissions = [];

    bool hasPerm(String perm) => permissions.contains(perm);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFFF6B35)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Tạo tài khoản Admin mới',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E1E2D),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đăng ký tài khoản quản trị viên mới và cấu hình cấp độ bộ phận cũng như quyền truy cập tính năng.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Email *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          hintText: 'Nhập địa chỉ email...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Mật khẩu *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: passController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Nhập mật khẩu...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Họ và Tên *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: 'Nhập họ và tên...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Số Điện Thoại',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneController,
                        decoration: InputDecoration(
                          hintText: 'Nhập số điện thoại...',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Phòng ban',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: deptController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tên phòng ban (ví dụ: Management, Finance...)',
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'Cấp độ Admin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int>(
                        value: adminLevel,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFFF6B35), width: 1.5),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Cấp 1 - Staff')),
                          DropdownMenuItem(value: 2, child: Text('Cấp 2 - Supervisor')),
                          DropdownMenuItem(value: 3, child: Text('Cấp 3 - Manager')),
                          DropdownMenuItem(value: 4, child: Text('Cấp 4 - Super Admin')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() {
                              adminLevel = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      const Text(
                        'Danh sách quyền hạn',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              title: const Text('Quản lý người dùng (manage_users)', style: TextStyle(fontSize: 13)),
                              activeColor: const Color(0xFFFF6B35),
                              value: hasPerm('manage_users'),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    permissions.add('manage_users');
                                  } else {
                                    permissions.remove('manage_users');
                                  }
                                });
                              },
                            ),
                            const Divider(height: 1),
                            CheckboxListTile(
                              title: const Text('Phê duyệt cửa hàng (manage_stores)', style: TextStyle(fontSize: 13)),
                              activeColor: const Color(0xFFFF6B35),
                              value: hasPerm('manage_stores'),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    permissions.add('manage_stores');
                                  } else {
                                    permissions.remove('manage_stores');
                                  }
                                });
                              },
                            ),
                            const Divider(height: 1),
                            CheckboxListTile(
                              title: const Text('Xử lý đơn hàng (manage_orders)', style: TextStyle(fontSize: 13)),
                              activeColor: const Color(0xFFFF6B35),
                              value: hasPerm('manage_orders'),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    permissions.add('manage_orders');
                                  } else {
                                    permissions.remove('manage_orders');
                                  }
                                });
                              },
                            ),
                            const Divider(height: 1),
                            CheckboxListTile(
                              title: const Text('Xem báo cáo thống kê (view_reports)', style: TextStyle(fontSize: 13)),
                              activeColor: const Color(0xFFFF6B35),
                              value: hasPerm('view_reports'),
                              onChanged: (val) {
                                setStateDialog(() {
                                  if (val == true) {
                                    permissions.add('view_reports');
                                  } else {
                                    permissions.remove('view_reports');
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (emailController.text.isEmpty || passController.text.isEmpty || nameController.text.isEmpty) {
                      _showToast('Vui lòng điền đầy đủ các thông tin bắt buộc (*)', Colors.orange);
                      return;
                    }
                    try {
                      await _userApiService.createAdminUser(
                        email: emailController.text,
                        password: passController.text,
                        fullName: nameController.text,
                        phoneNumber: phoneController.text,
                        department: deptController.text,
                        adminLevel: adminLevel,
                        permissions: permissions,
                      );
                      if (!context.mounted) return;
                      Navigator.pop(context);
                      _showToast('Tạo tài khoản Admin thành công!', Colors.green);
                      _fetchUsers();
                    } catch (e) {
                      if (!context.mounted) return;
                      _showToast('Lỗi tạo Admin: $e', Colors.red);
                    }
                  },
                  child: const Text('Tạo'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
