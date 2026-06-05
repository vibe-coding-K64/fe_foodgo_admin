import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart'; 
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/auth_service.dart';
import '../../data/services/notification_api_service.dart';
import '../../data/services/order_api_service.dart';
import '../../data/services/user_api_service.dart';
import '../../data/services/api_constants.dart';
import '../orders/order_detail_page.dart';

class AdminAppBar extends StatefulWidget implements PreferredSizeWidget { 
  final Function(String)? onNavigate;
  const AdminAppBar({super.key, this.onNavigate}); 

  @override
  State<AdminAppBar> createState() => _AdminAppBarState();

  @override 
  Size get preferredSize => const Size.fromHeight(65); 
} 

class _AdminAppBarState extends State<AdminAppBar> {
  final NotificationApiService _notificationService = NotificationApiService();
  final OrderApiService _orderApiService = OrderApiService();
  
  static List<Map<String, dynamic>> _notifications = [];
  static final List<Map<String, dynamic>> _localNotificationsList = [];
  static final Map<String, String> _lastOrderStatuses = {};
  static bool _hasLoadedInitialOrders = false;
  static bool _hasLoadedInitialNotifications = false;
  static bool _hasLoadedPersistedState = false;

  bool _isLoading = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _initAndLoadNotifications();
  }

  Future<void> _initAndLoadNotifications() async {
    await _loadPersistedState();
    _loadNotifications();
    _monitorOrders(firstLoad: !_hasLoadedInitialOrders);

    // Tải thông tin cá nhân của admin nếu chưa có sẵn
    if (UserApiService.profileNotifier.value == null) {
      UserApiService().getCurrentProfile().catchError((_) => <String, dynamic>{});
    }

    // Bắt đầu tự động làm mới mỗi 15 giây để tối ưu trải nghiệm thời gian thực
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadNotifications(silent: true);
      _monitorOrders(firstLoad: !_hasLoadedInitialOrders);
    });
  }

  String _getInitials(String? fullName) {
    if (fullName == null || fullName.trim().isEmpty) return "UA";
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0].isNotEmpty ? parts[0][0] : '';
    final last = parts[parts.length - 1].isNotEmpty ? parts[parts.length - 1][0] : '';
    final initials = '$first$last';
    return initials.isNotEmpty ? initials.toUpperCase() : "UA";
  }

  Future<void> _loadPersistedState() async {
    if (_hasLoadedPersistedState) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Load local notifications
      final localNotifsJson = prefs.getString('admin_local_notifications');
      if (localNotifsJson != null) {
        final List<dynamic> decoded = jsonDecode(localNotifsJson);
        _localNotificationsList.clear();
        _localNotificationsList.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
      }
      
      // 2. Load last order statuses
      final statusesJson = prefs.getString('admin_last_order_statuses');
      if (statusesJson != null) {
        final Map<String, dynamic> decoded = jsonDecode(statusesJson);
        _lastOrderStatuses.clear();
        _lastOrderStatuses.addAll(decoded.map((k, v) => MapEntry(k, v.toString())));
        _hasLoadedInitialOrders = true;
      }
      
      // 3. Load server/mock notifications
      final serverNotifsJson = prefs.getString('admin_server_notifications');
      if (serverNotifsJson != null) {
        final List<dynamic> decoded = jsonDecode(serverNotifsJson);
        _notifications.clear();
        _notifications.addAll(decoded.map((e) => Map<String, dynamic>.from(e)));
        _hasLoadedInitialNotifications = true;
      }
      
      _hasLoadedPersistedState = true;
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("[PersistedState] Error loading: $e");
    }
  }

  static Future<void> _savePersistedState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_local_notifications', jsonEncode(_localNotificationsList));
      await prefs.setString('admin_last_order_statuses', jsonEncode(_lastOrderStatuses));
      await prefs.setString('admin_server_notifications', jsonEncode(_notifications));
    } catch (e) {
      debugPrint("[PersistedState] Error saving: $e");
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _getMockNotifications() {
    return [
      {
        'id': 'mock_notif_001',
        'type': 'order',
        'title': 'Đơn hàng mới phát sinh #FG008',
        'body': 'Khách hàng Khôi vừa đặt đơn hàng trị giá 170.000đ tại Quán Bún Chả.',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 5)).toIso8601String(),
      },
      {
        'id': 'mock_notif_002',
        'type': 'payment',
        'title': 'Yêu cầu rút tiền từ Cửa hàng',
        'body': 'Quán Cơm Tấm Phúc Lộc Thọ gửi yêu cầu duyệt rút 500.000đ về ví liên kết.',
        'isRead': false,
        'createdAt': DateTime.now().subtract(const Duration(minutes: 32)).toIso8601String(),
      },
      {
        'id': 'mock_notif_003',
        'type': 'review',
        'title': 'Đánh giá 5 sao toàn sàn',
        'body': 'Khách hàng Khôi vừa gửi đánh giá 5 sao cho sản phẩm của Quán Bún Chả.',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'mock_notif_004',
        'type': 'cancel',
        'title': 'Đơn hàng bị huỷ toàn sàn',
        'body': 'Đơn hàng #FG005 đã bị khách hàng Khôi huỷ trực tiếp trên hệ thống.',
        'isRead': true,
        'createdAt': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      },
    ];
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }
    try {
      final data = await _notificationService.getNotifications();
      if (!mounted) return;

      setState(() {
        _notifications = data;
        _hasLoadedInitialNotifications = true;
        _savePersistedState();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải thông báo: $e");
      if (!mounted) return;
      setState(() {
        if (!_hasLoadedInitialNotifications || _notifications.isEmpty) {
          _notifications = _getMockNotifications();
          _hasLoadedInitialNotifications = true;
          _savePersistedState();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _monitorOrders({bool firstLoad = false}) async {
    try {
      debugPrint("[MonitorOrders] Polling started. firstLoad: $firstLoad. baseUrl: ${ApiConstants.baseUrl}");
      final orders = await _orderApiService.getAllPlatformOrders();
      if (!mounted) return;
      
      _hasLoadedInitialOrders = true;
      debugPrint("[MonitorOrders] Successfully loaded ${orders.length} orders");
      
      List<Map<String, dynamic>> newEvents = [];
      bool stateChanged = false;
      
      for (var order in orders) {
        final orderId = order.id ?? '';
        final orderCode = order.code;
        final customerName = order.customerName.isEmpty ? 'Khách lạ' : order.customerName;
        final finalAmount = order.finalAmount;
        final currentStatus = order.status;
        
        if (orderId.isEmpty) continue;
        
        if (!_lastOrderStatuses.containsKey(orderId)) {
          _lastOrderStatuses[orderId] = currentStatus;
          stateChanged = true;
          
          // Tạo thông báo cho đơn mới nếu không phải firstLoad, HOẶC nếu là firstLoad nhưng đơn có trạng thái "Chờ xác nhận"
          if (!firstLoad || currentStatus == 'Chờ xác nhận') {
            debugPrint("[MonitorOrders] Detected pending or new order: #$orderCode (status: $currentStatus, firstLoad: $firstLoad)");
            final notif = {
              'id': 'local_order_$orderId',
              'type': 'order',
              'title': 'Đơn hàng mới: #$orderCode',
              'body': 'Khách hàng $customerName vừa đặt đơn hàng trị giá ${finalAmount.toInt().toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}đ.',
              'isRead': false,
              'orderId': orderId,
              'createdAt': order.createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
            };
            newEvents.add(notif);
          }
        } else {
          final previousStatus = _lastOrderStatuses[orderId];
          if (previousStatus != currentStatus) {
            _lastOrderStatuses[orderId] = currentStatus;
            stateChanged = true;
            
            if (!firstLoad) {
              debugPrint("[MonitorOrders] Detected status update for order #$orderCode: $previousStatus -> $currentStatus");
              final notif = {
                'id': 'local_status_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
                'type': 'order',
                'title': 'Cập nhật đơn hàng #$orderCode',
                'body': 'Trạng thái chuyển sang: "$currentStatus".',
                'isRead': false,
                'orderId': orderId,
                'createdAt': DateTime.now().toIso8601String(),
              };
              newEvents.add(notif);
            }
          }
        }
      }
      
      if (newEvents.isNotEmpty) {
        setState(() {
          _localNotificationsList.insertAll(0, newEvents);
        });
        stateChanged = true;
      }
      
      if (stateChanged) {
        await _savePersistedState();
      }
    } catch (e) {
      debugPrint("[MonitorOrders] Error monitor orders: $e");
    }
  }


  @override 
  Widget build(BuildContext context) { 
    final combinedList = [..._localNotificationsList, ..._notifications];
    combinedList.sort((a, b) {
      final tA = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
      final tB = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
      return tB.compareTo(tA);
    });
    final unreadCount = combinedList.where((n) => n['isRead'] != true).length;

    return AppBar( 
      backgroundColor: Colors.white, 
      elevation: 0, // Bỏ bóng đổ mặc định 
      automaticallyImplyLeading: false, 
      titleSpacing: 24, 
      // Thêm một đường kẻ mảnh ở dưới AppBar 
      bottom: PreferredSize( preferredSize: const Size.fromHeight(1.0), 
        child: Container(color: Colors.grey.withOpacity(0.2), height: 1.0), 
      ), 
      title: Row( 
        children: [ 
          /// SEARCH BAR - Làm bo tròn và chuyên nghiệp hơn 
          Expanded( 
            flex: 2, 
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Container( 
                height: 42, 
                decoration: BoxDecoration( 
                  color: Colors.grey[50], 
                  borderRadius: BorderRadius.circular(12), 
                  border: Border.all(color: Colors.grey[200]!), 
                ), 
                child: TextField( 
                  decoration: InputDecoration( 
                    hintText: "Tìm kiếm hệ thống...", 
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), 
                    prefixIcon: Icon( 
                      Icons.search, 
                      color: Colors.grey[400], 
                      size: 20, 
                    ), 
                    border: InputBorder.none, 
                    contentPadding: const EdgeInsets.symmetric(vertical: 10), 
                  ), 
                ), 
              ), 
            ),
          ), 
 
          const Spacer(flex: 1), // Tạo khoảng trống giữa search và user info
 
          /// Connection Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: ApiConstants.baseUrl.contains("localhost") 
                  ? Colors.green.withOpacity(0.08) 
                  : Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ApiConstants.baseUrl.contains("localhost") 
                    ? Colors.green.withOpacity(0.3) 
                    : Colors.blue.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: ApiConstants.baseUrl.contains("localhost") ? Colors.green : Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ApiConstants.baseUrl.contains("localhost") ? "Local Backend" : "Remote Backend",
                  style: TextStyle(
                    fontSize: 11,
                    color: ApiConstants.baseUrl.contains("localhost") ? Colors.green[800] : Colors.blue[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          /// ACTIONS GROUP
          PopupMenuButton<String>(
            icon: const Icon(Icons.language, color: Colors.black54, size: 22),
            tooltip: "Ngôn ngữ",
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'vi', child: Row(
                children: [
                  Icon(Icons.check, color: Color(0xFFFF6B35), size: 16),
                  SizedBox(width: 8),
                  Text('Tiếng Việt (VI)'),
                ],
              )),
              const PopupMenuItem(value: 'en', child: Row(
                children: [
                  SizedBox(width: 24),
                  Text('English (EN)'),
                ],
              )),
            ],
            onSelected: (lang) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(lang == 'vi' ? 'Đã đổi ngôn ngữ sang Tiếng Việt!' : 'Language changed to English!'),
                  backgroundColor: const Color(0xFF1E1E2D),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PopupMenuButton<void>(
              tooltip: "Thông báo",
              offset: const Offset(0, 45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_none_outlined, color: Colors.black54, size: 22),
                  if (unreadCount > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B35),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              itemBuilder: (context) {
                return [
                  InteractivePopupMenuEntry(
                    child: _NotificationDropdownContent(
                      notifications: combinedList,
                      isLoading: _isLoading,
                      onNotificationsChanged: (updatedList) {
                        setState(() {
                          final updatedIds = updatedList.map((e) => e['id']?.toString()).toSet();
                          _localNotificationsList.removeWhere((n) => !updatedIds.contains(n['id']));
                          _notifications.removeWhere((n) => !updatedIds.contains(n['id']));
                          for (var item in updatedList) {
                            final id = item['id']?.toString() ?? '';
                            if (id.startsWith('local_')) {
                              final localIdx = _localNotificationsList.indexWhere((n) => n['id'] == id);
                              if (localIdx != -1) {
                                _localNotificationsList[localIdx]['isRead'] = item['isRead'];
                              }
                            } else {
                              final notifIdx = _notifications.indexWhere((n) => n['id'] == id);
                              if (notifIdx != -1) {
                                _notifications[notifIdx]['isRead'] = item['isRead'];
                              }
                            }
                          }
                        });
                        _savePersistedState();
                      },
                      notificationService: _notificationService,
                      onReload: () => _loadNotifications(silent: false),
                      onNavigate: widget.onNavigate,
                      orderApiService: _orderApiService,
                    ),
                  ),
                ];
              },
            ),
          ),

          const SizedBox(width: 8),
          const VerticalDivider(indent: 15, endIndent: 15, width: 20),
          const SizedBox(width: 8),

          /// USER INFO SECTION
          PopupMenuButton<String>( 
            offset: const Offset(0, 55), 
            shape: RoundedRectangleBorder( 
              borderRadius: BorderRadius.circular(12), 
            ), 
            child: MouseRegion( 
              cursor: SystemMouseCursors.click, 
              child: ValueListenableBuilder<Map<String, dynamic>?>(
                valueListenable: UserApiService.profileNotifier,
                builder: (context, profile, _) {
                  final fullName = profile?['fullName'] as String?;
                  final photoUrl = profile?['photoUrl'] as String?;
                  
                  final initials = _getInitials(fullName);
                  final displayName = (fullName != null && fullName.trim().isNotEmpty)
                      ? fullName
                      : "Quản trị viên";

                  return Row( 
                    children: [ 
                      Column( 
                        crossAxisAlignment: CrossAxisAlignment.end, 
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [ 
                          Text( 
                            displayName, 
                            style: const TextStyle( 
                              fontSize: 11, 
                              color: Color(0xFFFF6B35), 
                              fontWeight: FontWeight.bold,
                            ), 
                          ), 
                        ], 
                      ), 
                      const SizedBox(width: 12), 
                      Container( 
                        decoration: BoxDecoration( 
                          shape: BoxShape.circle, 
                          border: Border.all( 
                            color: const Color(0xFFFF6B35).withOpacity(0.2), 
                            width: 2, 
                          ), 
                        ), 
                        child: CircleAvatar( 
                          radius: 18, 
                          backgroundColor: const Color(0xFFFF6B35), 
                          backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                              ? NetworkImage(photoUrl)
                              : null,
                          child: (photoUrl == null || photoUrl.isEmpty)
                              ? Text( 
                                  initials, 
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ), 
                                )
                              : null,
                        ), 
                      ), 
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ], 
                  );
                },
              ), 
            ), 
            itemBuilder: (context) => [ 
              _buildPopupItem( 
                "profile", 
                Icons.person_outline, 
                "Thông tin cá nhân", 
              ), 
              _buildPopupItem("settings", Icons.security, "Bảo mật"), 
              const PopupMenuDivider(), 
              _buildPopupItem( 
                "logout", 
                Icons.logout, 
                "Đăng xuất", 
                color: Colors.red, 
              ), 
            ], 
            onSelected: (value) async { 
              if (value == "logout") { 
                await AuthService().logout();
              } else if (value == "profile" || value == "settings") {
                if (widget.onNavigate != null) {
                  widget.onNavigate!('/profile');
                }
              }
            }, 
          ), 
        ], 
      ), 
    ); 
  } 
 
  /// Widget bổ trợ tạo Item Menu đẹp hơn 
  PopupMenuItem<String> _buildPopupItem( 
    String value, 
    IconData icon,
    String title, { 
    Color? color, 
  }) { 
    return PopupMenuItem( 
      value: value, 
      child: Row( 
        children: [ 
          Icon(icon, size: 18, color: color ?? Colors.black54), 
          const SizedBox(width: 12), 
          Text(title, style: TextStyle(color: color, fontSize: 14)), 
        ], 
      ), 
    ); 
  } 
}

class _NotificationDropdownContent extends StatefulWidget {
  final List<Map<String, dynamic>> notifications;
  final bool isLoading;
  final Function(List<Map<String, dynamic>>) onNotificationsChanged;
  final NotificationApiService notificationService;
  final VoidCallback onReload;
  final Function(String)? onNavigate;
  final OrderApiService orderApiService;

  const _NotificationDropdownContent({
    required this.notifications,
    required this.isLoading,
    required this.onNotificationsChanged,
    required this.notificationService,
    required this.onReload,
    this.onNavigate,
    required this.orderApiService,
  });

  @override
  State<_NotificationDropdownContent> createState() => _NotificationDropdownContentState();
}

class _NotificationDropdownContentState extends State<_NotificationDropdownContent> {
  late List<Map<String, dynamic>> _localNotifications;
  bool _localIsLoading = false;

  @override
  void initState() {
    super.initState();
    _localNotifications = List.from(widget.notifications);
  }

  @override
  void didUpdateWidget(_NotificationDropdownContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.notifications != oldWidget.notifications) {
      setState(() {
        _localNotifications = List.from(widget.notifications);
      });
    }
  }

  Future<void> _markAsRead(int index) async {
    final id = _localNotifications[index]['id'] as String? ?? '';
    if (id.isEmpty || _localNotifications[index]['isRead'] == true) return;

    try {
      setState(() {
        _localNotifications[index]['isRead'] = true;
      });
      widget.onNotificationsChanged(_localNotifications);
      if (!id.startsWith('local_') && !id.startsWith('mock_')) {
        await widget.notificationService.markAsRead(id);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _localNotifications[index]['isRead'] = false;
        });
        widget.onNotificationsChanged(_localNotifications);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      setState(() {
        _localIsLoading = true;
      });
      await widget.notificationService.markAllAsRead();
      if (!mounted) return;
      setState(() {
        for (var n in _localNotifications) {
          n['isRead'] = true;
        }
        _localIsLoading = false;
      });
      widget.onNotificationsChanged(_localNotifications);
    } catch (_) {
      if (mounted) {
        setState(() {
          _localIsLoading = false;
        });
      }
    }
  }

  Future<void> _deleteNotification(int index) async {
    final id = _localNotifications[index]['id'] as String? ?? '';
    if (id.isEmpty) return;

    try {
      setState(() {
        _localNotifications.removeAt(index);
      });
      widget.onNotificationsChanged(_localNotifications);
      if (!id.startsWith('local_') && !id.startsWith('mock_')) {
        await widget.notificationService.deleteNotification(id);
      }
    } catch (_) {
      widget.onReload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _localNotifications.where((n) => n['isRead'] != true).length;

    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Thông báo',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2D),
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount mới',
                          style: const TextStyle(
                            color: Color(0xFFFF6B35),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: _localIsLoading ? null : _markAllAsRead,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Đọc tất cả',
                      style: TextStyle(
                        color: Color(0xFFFF6B35),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Container(
            constraints: const BoxConstraints(maxHeight: 340),
            child: _buildBodyContent(),
          ),
          const Divider(height: 1),
          // View all footer
          SizedBox(
            width: double.infinity,
            height: 40,
            child: TextButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context); // Close dropdown popup
                }
                if (widget.onNavigate != null) {
                  widget.onNavigate!('/notifications');
                }
              },
              child: const Text(
                'Xem tất cả thông báo',
                style: TextStyle(
                  color: Color(0xFFFF6B35),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (widget.isLoading || _localIsLoading) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFFF6B35),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (_localNotifications.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 8),
              Text(
                'Không có thông báo nào',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: _localNotifications.length,
      separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF5F5F7)),
      itemBuilder: (context, i) => _buildNotificationItem(i),
    );
  }

  Widget _buildNotificationItem(int index) {
    final n = _localNotifications[index];
    final isRead = n['isRead'] == true;
    final typeStr = n['type']?.toString() ?? '';
    final typeIcon = _typeIcon(typeStr);
    final typeColor = _typeColor(typeStr);
    final title = n['title'] as String? ?? 'Thông báo';
    final body = n['body'] as String? ?? '';
    final time = n['createdAt'] != null 
        ? _formatTime(n['createdAt'].toString()) 
        : (n['time'] as String? ?? '');

    return Material(
      color: isRead ? Colors.transparent : const Color(0xFFFFF9F6),
      child: InkWell(
        onTap: () async {
          await _markAsRead(index);
          if (Navigator.canPop(context)) {
            Navigator.pop(context); // Close dropdown popup
          }
          final type = typeStr;
          final orderId = n['orderId'] as String? ?? '';
          final referenceId = n['referenceId'] as String? ?? '';

          if ((type == '41' || type == 'payment') && widget.onNavigate != null) {
            widget.onNavigate!('/finance/withdrawal');
          } else if ((type == 'review' || type == '31') && widget.onNavigate != null) {
            widget.onNavigate!('/reviews');
          } else {
            final effectiveOrderId = orderId.isNotEmpty ? orderId : referenceId;
            if (effectiveOrderId.isNotEmpty && widget.onNavigate != null) {
              try {
                final order = await widget.orderApiService.getOrderById(effectiveOrderId);
                if (order != null) {
                  OrderDetailPage.currentOrder = order;
                  widget.onNavigate!('/orders/detail');
                }
              } catch (e) {
                debugPrint("Lỗi tải chi tiết đơn hàng: $e");
              }
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              const SizedBox(width: 12),

              // Title & Body
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 13,
                        color: const Color(0xFF1E1E2D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Actions (Unread dot & delete)
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!isRead)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _deleteNotification(index),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order':
      case '11':
      case '1':
        return Icons.shopping_bag_outlined;
      case 'payment':
      case '12':
      case '41':
        return Icons.account_balance_wallet_outlined;
      case 'review':
      case '31':
        return Icons.star_outline;
      case 'cancel':
      case '13':
        return Icons.cancel_outlined;
      case 'wallet':
        return Icons.savings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order':
      case '11':
      case '1':
        return const Color(0xFFFF6B35);
      case 'payment':
      case '12':
      case '41':
        return Colors.green;
      case 'review':
      case '31':
        return Colors.amber;
      case 'cancel':
      case '13':
        return Colors.red;
      case 'wallet':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}

/// Custom PopupMenuEntry cho phép tương tác (scroll, click) bên trong dropdown 
/// mà không bị mờ màu hay tự động đóng menu khi click.
class InteractivePopupMenuEntry extends PopupMenuEntry<void> {
  final Widget child;
  @override
  final double height;

  const InteractivePopupMenuEntry({
    super.key,
    required this.child,
    this.height = 380,
  });

  @override
  State<InteractivePopupMenuEntry> createState() => _InteractivePopupMenuEntryState();

  @override
  bool represents(void value) => false;
}

class _InteractivePopupMenuEntryState extends State<InteractivePopupMenuEntry> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}