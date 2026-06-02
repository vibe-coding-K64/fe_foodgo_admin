import 'package:flutter/material.dart';

import '../../data/models/order_model.dart';
import '../../data/services/order_api_service.dart';
import 'order_detail_page.dart';

class OrdersPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const OrdersPage({super.key, this.onNavigate});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final OrderApiService _apiService = OrderApiService();
  String _filterStatus = 'Tất cả';
  final List<String> _statuses = ['Tất cả', 'Chờ xác nhận', 'Đang chế biến', 'Đang giao', 'Hoàn thành', 'Đã hủy'];
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  List<Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await _apiService.getAllPlatformOrders();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showNotificationDialog(context, 'Lỗi tải đơn hàng: $e', false);
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus) async {
    try {
      await _apiService.updateOrderStatus(id, newStatus);
      _fetchOrders();
      if (mounted) _showNotificationDialog(context, 'Đã cập nhật trạng thái thành "$newStatus"', true);
    } catch (e) {
      if (mounted) _showNotificationDialog(context, 'Lỗi: $e', false);
    }
  }

  void _showNotificationDialog(BuildContext context, String message, bool isSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: isSuccess ? Colors.green : const Color(0xFFDC3545),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(isSuccess ? 'Thành công!' : 'Có lỗi xảy ra!',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSuccess ? Colors.green : const Color(0xFFDC3545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Đóng', style: TextStyle(fontSize: 16)),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Order> get _filtered => _filterStatus == 'Tất cả'
      ? _orders
      : _orders.where((o) => o.status == _filterStatus).toList();

  List<Order> get _pagedOrders {
    int start = (_currentPage - 1) * _itemsPerPage;
    return _filtered.skip(start).take(_itemsPerPage).toList();
  }

  void _setFilter(String status) {
    setState(() {
      _filterStatus = status;
      _currentPage = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quản lý Đơn hàng Toàn sàn',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
            SizedBox(height: 4),
            Text('Giám sát và can thiệp trạng thái toàn bộ đơn hàng phát sinh trên nền tảng FoodGo',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 20),
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _statuses.map((s) {
              final isSelected = _filterStatus == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(s),
                  selected: isSelected,
                  onSelected: (_) => _setFilter(s),
                  selectedColor: _statusColor(s),
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.w500),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? _statusColor(s) : Colors.grey.shade300),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(width: 110, child: Text('Mã đơn', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Khách hàng', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 80, child: Text('Số món', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 120, child: Text('Tổng tiền', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 60, child: Text('Giờ', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 140, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.bold))),
                      SizedBox(width: 130, child: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : _filtered.isEmpty 
                      ? const Center(child: Text('Không có đơn hàng nào'))
                      : ListView.separated(
                          itemCount: _pagedOrders.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (context, i) => _buildOrderRow(_pagedOrders[i]),
                        ),
                ),
                if (!_isLoading && _filtered.isNotEmpty)
                  _buildPagination(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderRow(Order order) {
    String timeStr = '--:--';
    if (order.createdAt != null) {
      timeStr = '${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')}';
    }

    return InkWell(
      onTap: () {
        OrderDetailPage.currentOrder = order;
        if (widget.onNavigate != null) widget.onNavigate!('/orders/detail');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(order.code,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B35))),
            ),
            Expanded(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFFFFF3E0),
                    child: Text(
                      order.customerName.isNotEmpty ? order.customerName[0].toUpperCase() : '?',
                      style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            SizedBox(width: 80, child: Text('${order.items.length} món', style: const TextStyle(color: Colors.grey))),
            SizedBox(
              width: 120,
              child: Text(
                '${order.totalAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(width: 60, child: Text(timeStr, style: const TextStyle(color: Colors.grey))),
            SizedBox(
              width: 140,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(order.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(color: _statusColor(order.status), fontSize: 12, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 130,
              child: Row(
                children: [
                  if (order.status == 'Chờ xác nhận') ...[
                    IconButton(
                      onPressed: () => _updateStatus(order.id!, 'Đang chế biến'),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                      tooltip: 'Xác nhận',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _updateStatus(order.id!, 'Đã hủy'),
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                      tooltip: 'Từ chối',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ] else if (order.status == 'Đang chế biến') ...[
                    IconButton(
                      onPressed: () => _updateStatus(order.id!, 'Đang giao'),
                      icon: const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 20),
                      tooltip: 'Giao cho tài xế',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ] else if (order.status == 'Đang giao') ...[
                    IconButton(
                      onPressed: () => _updateStatus(order.id!, 'Hoàn thành'),
                      icon: const Icon(Icons.check_circle, color: Colors.purple, size: 20),
                      tooltip: 'Hoàn thành',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    onPressed: () {
                      OrderDetailPage.currentOrder = order;
                      if (widget.onNavigate != null) widget.onNavigate!('/orders/detail');
                    },
                    icon: const Icon(Icons.visibility_outlined, color: Color(0xFFFF6B35), size: 20),
                    tooltip: 'Xem chi tiết',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận': return Colors.orange;
      case 'Đang chế biến': return Colors.blue;
      case 'Đang giao': return Colors.purple;
      case 'Hoàn thành': return Colors.green;
      case 'Đã hủy': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildPagination() {
    int totalPages = (_filtered.length / _itemsPerPage).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('Trang $_currentPage / $totalPages', style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
