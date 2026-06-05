import 'package:flutter/material.dart';
import '../../data/services/notification_api_service.dart';
import '../../data/services/order_api_service.dart';
import '../orders/order_detail_page.dart';

class NotificationsPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const NotificationsPage({super.key, this.onNavigate});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with SingleTickerProviderStateMixin {
  final NotificationApiService _notificationService = NotificationApiService();
  final OrderApiService _orderApiService = OrderApiService();

  late TabController _tabController;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadNotifications();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _notificationService.getNotifications();
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách thông báo: $e';
      });
    }
  }

  Future<void> _markAsRead(String id, int index) async {
    if (index < 0 || index >= _notifications.length) return;
    try {
      setState(() {
        _notifications[index]['isRead'] = true;
      });
      await _notificationService.markAsRead(id);
    } catch (e) {
      if (index >= 0 && index < _notifications.length) {
        setState(() {
          _notifications[index]['isRead'] = false;
        });
      }
      _showToast('Lỗi khi đánh dấu đã đọc: $e', Colors.red);
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      setState(() {
        for (var n in _notifications) {
          n['isRead'] = true;
        }
      });
      await _notificationService.markAllAsRead();
      _showToast('Đã đánh dấu tất cả đã đọc', Colors.green);
    } catch (e) {
      _showToast('Lỗi: $e', Colors.red);
      _loadNotifications();
    }
  }

  Future<void> _delete(String id, int index) async {
    if (index < 0 || index >= _notifications.length) {
      _showToast('Không tìm thấy thông báo', Colors.red);
      return;
    }
    try {
      setState(() {
        _notifications.removeAt(index);
      });
      await _notificationService.deleteNotification(id);
      _showToast('Đã xoá thông báo', Colors.orange);
    } catch (e) {
      _showToast('Lỗi khi xoá: $e', Colors.red);
      _loadNotifications();
    }
  }

  void _showToast(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Map<String, dynamic>> _filteredNotifications() {
    if (_tabController.index == 0) return _notifications; // Tất cả

    return _notifications.where((n) {
      final rawType = n['type'];
      final typeInt = rawType is int ? rawType : (rawType != null ? int.tryParse(rawType.toString()) : null);
      if (_tabController.index == 1) {
        // Đơn hàng: 11, 12, 13 (Driver), 21, 22, 23 (Merchant)
        return typeInt != null && [11, 12, 13, 21, 22, 23].contains(typeInt);
      } else if (_tabController.index == 2) {
        // Tài chính: 41 (Wallet/Withdrawal update)
        return typeInt != null && [41].contains(typeInt);
      } else if (_tabController.index == 3) {
        // Đánh giá: 31 (New review)
        return typeInt != null && [31].contains(typeInt);
      }
      return true;
    }).toList();
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      if (diff.inDays == 1) return 'Hôm qua';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  IconData _typeIcon(dynamic rawType) {
    final typeInt = rawType is int ? rawType : (rawType != null ? int.tryParse(rawType.toString()) : null);
    switch (typeInt) {
      case 11:
      case 12:
      case 21:
        return Icons.shopping_bag_outlined;
      case 22:
      case 41:
        return Icons.account_balance_wallet_outlined;
      case 31:
        return Icons.star_outline;
      case 13:
      case 23:
        return Icons.cancel_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(dynamic rawType) {
    final typeInt = rawType is int ? rawType : (rawType != null ? int.tryParse(rawType.toString()) : null);
    switch (typeInt) {
      case 11:
      case 12:
      case 21:
        return const Color(0xFFFF6B35);
      case 22:
      case 41:
        return Colors.green;
      case 31:
        return Colors.amber;
      case 13:
      case 23:
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _handleNotificationClick(Map<String, dynamic> n, int originalIndex) async {
    final id = n['id'] as String? ?? '';
    if (id.isEmpty) return;

    if (n['isRead'] != true) {
      await _markAsRead(id, originalIndex);
    }

    final orderId = n['orderId'] as String? ?? n['referenceId'] as String? ?? '';
    final rawType = n['type'];
    final typeInt = rawType is int ? rawType : (rawType != null ? int.tryParse(rawType.toString()) : null);

    if (orderId.isNotEmpty && typeInt != null && [11, 12, 13, 21, 22, 23].contains(typeInt) && widget.onNavigate != null) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35))),
        );
        final order = await _orderApiService.getOrderById(orderId);
        if (context.mounted) {
          Navigator.pop(context); // close loading dialog
        }
        if (order != null) {
          OrderDetailPage.currentOrder = order;
          widget.onNavigate!('/orders/detail');
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context); // close loading
        }
        _showToast('Lỗi tải chi tiết đơn hàng: $e', Colors.red);
      }
    } else if (typeInt == 41 && widget.onNavigate != null) {
      widget.onNavigate!('/finance/withdrawal');
    } else if (typeInt == 31 && widget.onNavigate != null) {
      widget.onNavigate!('/reviews');
    }
  }

  void _showBroadcastDialog() {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String target = 'all'; // default target
    bool isSending = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFFFF6B35)),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Gửi thông báo toàn sàn',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1E1E2D),
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gửi thông báo đẩy (push notification) tới ứng dụng của khách hàng và tài xế qua hệ thống FCM.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    
                    // Target Dropdown
                    const Text(
                      'Đối tượng nhận',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: target,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFFFF6B35)),
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('Tất cả mọi người (Khách hàng & Tài xế)')),
                            DropdownMenuItem(value: 'customers', child: Text('Chỉ Khách hàng (Customer App)')),
                            DropdownMenuItem(value: 'drivers', child: Text('Chỉ Tài xế (Driver App)')),
                            DropdownMenuItem(value: 'merchants', child: Text('Chỉ Cửa hàng (Merchant)')),
                          ],
                          onChanged: isSending ? null : (val) {
                            if (val != null) {
                              setDialogState(() {
                                target = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title Field
                    const Text(
                      'Tiêu đề thông báo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      enabled: !isSending,
                      decoration: InputDecoration(
                        hintText: 'Nhập tiêu đề...',
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

                    // Body Field
                    const Text(
                      'Nội dung thông báo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: bodyController,
                      enabled: !isSending,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Nhập dung chi tiết cần thông báo...',
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
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          final body = bodyController.text.trim();
                          if (title.isEmpty || body.isEmpty) {
                            _showToast('Vui lòng điền đầy đủ thông tin', Colors.red);
                            return;
                          }

                          setDialogState(() {
                            isSending = true;
                          });

                          try {
                            await _notificationService.broadcastNotification(
                              title: title,
                              body: body,
                              target: target,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              _showToast('Đã gửi thông báo thành công!', Colors.green);
                              _loadNotifications();
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSending = false;
                            });
                            _showToast('Gửi thông báo thất bại: $e', Colors.red);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6B35),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Gửi ngay'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _filteredNotifications();
    final unreadCount = _notifications.where((n) => n['isRead'] != true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo hệ thống',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý tất cả các hoạt động, giao dịch và cảnh báo toàn hệ thống ($unreadCount chưa đọc)',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showBroadcastDialog,
                  icon: const Icon(Icons.campaign_outlined, size: 18),
                  label: const Text('Gửi thông báo toàn sàn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E2D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
                const SizedBox(width: 12),
                if (unreadCount > 0) ...[
                  ElevatedButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all, size: 18),
                    label: const Text('Đánh dấu đọc tất cả'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B35),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                IconButton(
                  onPressed: _loadNotifications,
                  icon: const Icon(Icons.refresh, color: Color(0xFFFF6B35)),
                  tooltip: 'Làm mới',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shadowColor: Colors.black.withOpacity(0.05),
                    elevation: 2,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tabs
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: const Color(0xFFFF6B35),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFFFF6B35),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
            tabs: [
              Tab(text: 'Tất cả (${_notifications.length})'),
              Tab(
                text: 'Đơn hàng (${_notifications.where((n) {
                  final rawType = n['type'];
                  final typeInt = rawType is int ? rawType : (rawType != null ? int.tryParse(rawType.toString()) : null);
                  return typeInt != null && [11, 12, 13, 21, 22, 23].contains(typeInt);
                }).length})',
              ),
              Tab(
                text: 'Tài chính (${_notifications.where((n) {
                  final rawType = n['type'];
                  final typeInt = rawType is int ? rawType : (rawType != null ? int.tryParse(rawType.toString()) : null);
                  return typeInt != null && [41].contains(typeInt);
                }).length})',
              ),
              Tab(
                text: 'Đánh giá (${_notifications.where((n) {
                  final rawType = n['type'];
                  final typeInt = rawType is int ? rawType : (rawType != null ? int.tryParse(rawType.toString()) : null);
                  return typeInt != null && [31].contains(typeInt);
                }).length})',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Body Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : _errorMessage != null
                  ? _buildErrorState()
                  : filteredList.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationsList(filteredList),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadNotifications,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, color: Colors.grey[300], size: 80),
          const SizedBox(height: 16),
          Text(
            'Không có thông báo nào trong mục này!',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<Map<String, dynamic>> filteredList) {
    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final n = filteredList[index];
        final id = n['id'] as String? ?? '';
        final isRead = n['isRead'] == true;
        final rawType = n['type'];
        final typeColor = _typeColor(rawType);
        final typeIcon = _typeIcon(rawType);
        final title = n['title'] as String? ?? 'Thông báo';
        final body = n['body'] as String? ?? '';
        final timeStr = n['createdAt'] != null ? _formatTime(n['createdAt'].toString()) : '';

        // Find original index in full list for operations
        final originalIndex = _notifications.indexWhere((element) => element['id'] == id);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: isRead ? Colors.white : const Color(0xFFFFF9F6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isRead ? Colors.grey[200]! : const Color(0xFFFF6B35).withOpacity(0.15),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _handleNotificationClick(n, originalIndex),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 22),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                  color: const Color(0xFF1E1E2D),
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[450],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Action Buttons (Mark as read / delete)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isRead)
                        IconButton(
                          onPressed: () => _markAsRead(id, originalIndex),
                          icon: const Icon(Icons.done, size: 18, color: Colors.green),
                          tooltip: 'Đánh dấu đã đọc',
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.green.withOpacity(0.05),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () => _delete(id, originalIndex),
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        tooltip: 'Xoá thông báo',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.05),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
