import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/services/user_api_service.dart';

class ProfilePage extends StatefulWidget {
  final Function(String)? onNavigate;
  const ProfilePage({super.key, this.onNavigate});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserApiService _apiService = UserApiService();
  
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  
  String? _photoUrl;
  List<int>? _newAvatarBytes;
  String? _newAvatarName;
  bool _isHoveringAvatar = false;

  String _dept = 'Management';
  int _adminLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Chưa xác thực tài khoản. Vui lòng đăng nhập.');
      }

      final profile = await _apiService.getCurrentProfile();
      _nameCtrl.text = profile['fullName'] ?? '';
      _emailCtrl.text = profile['email'] ?? '';
      _phoneCtrl.text = profile['phoneNumber'] ?? '--';
      
      final List<dynamic> roles = profile['roles'] ?? [];
      _roleCtrl.text = roles.contains(4) ? 'Quản trị viên hệ thống (Admin)' : 'Người dùng';
      _photoUrl = profile['photoUrl'];

      try {
        final adminProfile = await _apiService.getAdminProfile(user.uid);
        _dept = adminProfile['department'] ?? 'Management';
        _adminLevel = adminProfile['adminLevel'] ?? 1;
      } catch (_) {
        // Default admin info remains if profile fetch fails (e.g. mock admin user without admin_profile doc)
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải hồ sơ cá nhân: $e';
      });
    }
  }

  Future<void> _pickAvatar() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _newAvatarBytes = file.bytes;
            _newAvatarName = file.name;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Lỗi chọn ảnh: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProfileChanges() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.updateCurrentProfile(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        avatarBytes: _newAvatarBytes,
        avatarName: _newAvatarName,
      );
      _showSnackBar('Cập nhật hồ sơ thành công!', Colors.green);
      setState(() {
        _newAvatarBytes = null;
        _newAvatarName = null;
      });
      _loadProfile();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Cập nhật thất bại: $e', Colors.red);
    }
  }

  void _showChangePasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isChanging = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
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
                  child: const Icon(Icons.lock_rounded, color: Color(0xFFFF6B35)),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Đổi mật khẩu bảo mật',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E1E2D),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cập nhật mật khẩu tài khoản Admin. Yêu cầu nhập đúng mật khẩu cũ.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text(
                    'Mật khẩu cũ *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: oldPassCtrl,
                    obscureText: true,
                    enabled: !isChanging,
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu hiện tại...',
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
                    'Mật khẩu mới *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: newPassCtrl,
                    obscureText: true,
                    enabled: !isChanging,
                    decoration: InputDecoration(
                      hintText: 'Nhập mật khẩu mới (tối thiểu 6 ký tự)...',
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
                    'Xác nhận mật khẩu mới *',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmPassCtrl,
                    obscureText: true,
                    enabled: !isChanging,
                    decoration: InputDecoration(
                      hintText: 'Nhập lại mật khẩu mới...',
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
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
            actions: [
              if (!isChanging)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isChanging
                    ? null
                    : () async {
                        final oldPass = oldPassCtrl.text.trim();
                        final newPass = newPassCtrl.text.trim();
                        final confirmPass = confirmPassCtrl.text.trim();

                        if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                          _showSnackBar('Vui lòng điền đầy đủ thông tin', Colors.orange);
                          return;
                        }
                        if (newPass.length < 6) {
                          _showSnackBar('Mật khẩu mới phải từ 6 ký tự trở lên', Colors.orange);
                          return;
                        }
                        if (newPass != confirmPass) {
                          _showSnackBar('Mật khẩu mới và mật khẩu xác nhận không khớp', Colors.orange);
                          return;
                        }

                        setDialogState(() => isChanging = true);

                        try {
                          await _apiService.changeCurrentPassword(
                            oldPassword: oldPass,
                            newPassword: newPass,
                          );
                          if (mounted) {
                            Navigator.pop(dialogContext);
                            _showSnackBar('Đổi mật khẩu thành công!', Colors.green);
                          }
                        } catch (e) {
                          setDialogState(() => isChanging = false);
                          _showSnackBar('Đổi mật khẩu thất bại: $e', Colors.red);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: isChanging
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Đổi mật khẩu'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 60, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tải lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.person_outline,
                  color: Color(0xFFFF6B35),
                  size: 28,
                ),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hồ sơ của tôi',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2D),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text('Thông tin tài khoản quản trị viên', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar card
              SizedBox(
                width: 280,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      MouseRegion(
                        onEnter: (_) => setState(() => _isHoveringAvatar = true),
                        onExit: (_) => setState(() => _isHoveringAvatar = false),
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFF6B35).withOpacity(0.2),
                                    width: 3,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 54,
                                  backgroundColor: Colors.grey[100],
                                  backgroundImage: _newAvatarBytes != null
                                      ? MemoryImage(Uint8List.fromList(_newAvatarBytes!)) as ImageProvider
                                      : (_photoUrl != null && _photoUrl!.isNotEmpty
                                          ? NetworkImage(_photoUrl!) as ImageProvider
                                          : null),
                                  child: (_newAvatarBytes == null && (_photoUrl == null || _photoUrl!.isEmpty))
                                      ? Text(
                                          _nameCtrl.text.isNotEmpty ? _nameCtrl.text[0].toUpperCase() : 'A',
                                          style: const TextStyle(
                                            color: Color(0xFFFF6B35),
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              Positioned.fill(
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 150),
                                  opacity: _isHoveringAvatar ? 1.0 : 0.0,
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.black45,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 24),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'Quản trị viên',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Phòng: $_dept',
                        style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 13, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Cấp độ quản trị: Cấp $_adminLevel',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined, color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Đã xác minh',
                              style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              // Info form
              Expanded(
                child: Column(
                  children: [
                    _buildCard('Thông tin cá nhân', [
                      _field('Họ và tên *', _nameCtrl, Icons.person_outline),
                      _field('Email *', _emailCtrl, Icons.email_outlined),
                      _field('Số điện thoại', _phoneCtrl, Icons.phone_outlined, enabled: false),
                      _field('Nhóm quyền tài khoản', _roleCtrl, Icons.admin_panel_settings_outlined, enabled: false),
                    ]),
                    const SizedBox(height: 16),
                    _buildCard('Bảo mật tài khoản', [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B35).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.lock_open_rounded, color: Color(0xFFFF6B35)),
                        ),
                        title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text('Đổi mật khẩu định kỳ giúp bảo vệ tài khoản tốt hơn.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing: OutlinedButton(
                          onPressed: _showChangePasswordDialog,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFFF6B35),
                            side: const BorderSide(color: Color(0xFFFF6B35)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Đổi ngay'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saveProfileChanges,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Lưu thay đổi'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1E2D)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: ctrl,
            enabled: enabled,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: enabled ? const Color(0xFFFF6B35) : Colors.grey, size: 20),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: !enabled,
              fillColor: enabled ? null : const Color(0xFFF8F9FA),
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
        ],
      ),
    );
  }
}
