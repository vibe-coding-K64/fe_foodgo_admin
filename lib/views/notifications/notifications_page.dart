import 'package:flutter/material.dart';
import '../../data/services/notification_api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationApiService _service = NotificationApiService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _service.getNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(int index) async {
    final id = _notifications[index]['id'] as String? ?? '';
    if (id.isEmpty || _notifications[index]['isRead'] == true) return;
    try {
      await _service.markAsRead(id);
      if (!mounted) return;
      setState(() => _notifications[index]['isRead'] = true);
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n['isRead'] = true;
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteNotification(int index) async {
    final id = _notifications[index]['id'] as String? ?? '';
    if (id.isEmpty) return;
    try {
      await _service.deleteNotification(id);
      if (!mounted) return;
      setState(() => _notifications.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Đã xoá thông báo'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['isRead'] != true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Thông báo',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                    const SizedBox(width: 12),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('$unreadCount mới',
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${_notifications.length} thông báo',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _loadNotifications,
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6B35)),
                  tooltip: 'Tải lại',
                ),
                if (unreadCount > 0)
                  TextButton.icon(
                    onPressed: _markAllAsRead,
                    icon: const Icon(Icons.done_all, size: 16, color: Color(0xFFFF6B35)),
                    label: const Text('Đánh dấu tất cả đã đọc',
                        style: TextStyle(color: Color(0xFFFF6B35))),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Không có thông báo nào', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: ListView.separated(
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
        itemBuilder: (context, i) => _buildNotificationRow(i),
      ),
    );
  }

  Widget _buildNotificationRow(int index) {
    final n = _notifications[index];
    final isRead = n['isRead'] == true;
    final typeStr = n['type']?.toString() ?? '';
    final typeIcon = _typeIcon(typeStr);
    final typeColor = _typeColor(typeStr);
    final title = n['title'] as String? ?? 'Thông báo';
    final body = n['body'] as String? ?? '';
    final time = n['createdAt'] != null ? _formatTime(n['createdAt'].toString()) : (n['time'] as String? ?? '');

    return InkWell(
      onTap: () => _markAsRead(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isRead ? Colors.transparent : const Color(0xFFFFF8F5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(typeIcon, color: typeColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF1E1E2D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                if (!isRead)
                  Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
                  ),
                const SizedBox(height: 6),
                InkWell(
                  onTap: () => _deleteNotification(index),
                  borderRadius: BorderRadius.circular(4),
                  child: Icon(Icons.delete_outline, size: 16, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order':
      case '11':
        return Icons.shopping_bag_outlined;
      case 'payment':
      case '12':
        return Icons.account_balance_wallet_outlined;
      case 'review':
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
        return const Color(0xFFFF6B35);
      case 'payment':
      case '12':
        return Colors.green;
      case 'review':
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
