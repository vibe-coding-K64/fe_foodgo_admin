import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<Map<String, dynamic>> _notifications = [
    {'title': 'Đơn hàng mới #OD-006', 'body': 'Nguyễn Văn A vừa đặt 3 món - 215.000đ', 'time': '14:23', 'isRead': false, 'type': 'order'},
    {'title': 'Thanh toán thành công', 'body': 'Bạn nhận được 89.000đ từ đơn #OD-001', 'time': '14:10', 'isRead': false, 'type': 'payment'},
    {'title': 'Đánh giá mới', 'body': 'Trần Thị B đánh giá 4★ cho quán của bạn', 'time': '13:45', 'isRead': true, 'type': 'review'},
    {'title': 'Đơn hàng bị hủy', 'body': 'Khách hàng hủy đơn #OD-005 - Lý do: Đặt nhầm', 'time': '12:55', 'isRead': true, 'type': 'cancel'},
    {'title': 'Rút tiền thành công', 'body': 'Yêu cầu rút 2.000.000đ đã được duyệt', 'time': '10:00', 'isRead': true, 'type': 'wallet'},
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n['isRead']).length;
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
                    const Text('Thông báo', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                    const SizedBox(width: 12),
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFFF6B35), borderRadius: BorderRadius.circular(20)),
                        child: Text('$unreadCount mới', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Đơn hàng, thanh toán và cập nhật từ hệ thống', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                for (final n in _notifications) n['isRead'] = true;
              }),
              icon: const Icon(Icons.done_all, size: 16, color: Color(0xFFFF6B35)),
              label: const Text('Đánh dấu tất cả đã đọc', style: TextStyle(color: Color(0xFFFF6B35))),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
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
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationRow(int index) {
    final n = _notifications[index];
    final typeIcon = _typeIcon(n['type']);
    final typeColor = _typeColor(n['type']);
    return InkWell(
      onTap: () => setState(() => _notifications[index]['isRead'] = true),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: n['isRead'] ? Colors.transparent : const Color(0xFFFFF8F5),
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
                  Text(n['title'],
                      style: TextStyle(
                          fontWeight: n['isRead'] ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14,
                          color: const Color(0xFF1E1E2D))),
                  const SizedBox(height: 4),
                  Text(n['body'], style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(n['time'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 6),
                if (!n['isRead'])
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFFF6B35), shape: BoxShape.circle),
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
      case 'order': return Icons.shopping_bag_outlined;
      case 'payment': return Icons.account_balance_wallet_outlined;
      case 'review': return Icons.star_outline;
      case 'cancel': return Icons.cancel_outlined;
      case 'wallet': return Icons.savings_outlined;
      default: return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order': return const Color(0xFFFF6B35);
      case 'payment': return Colors.green;
      case 'review': return Colors.amber;
      case 'cancel': return Colors.red;
      case 'wallet': return Colors.purple;
      default: return Colors.blue;
    }
  }
}
