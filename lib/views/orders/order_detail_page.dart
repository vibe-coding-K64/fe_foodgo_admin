import 'package:flutter/material.dart';

import '../../data/models/order_model.dart';
import '../../data/services/order_api_service.dart';

class OrderDetailPage extends StatefulWidget {
  static Order? currentOrder;
  final Function(String)? onNavigate;
  
  const OrderDetailPage({super.key, this.onNavigate});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final OrderApiService _apiService = OrderApiService();
  
  Future<void> _updateStatus(String newStatus) async {
    final order = OrderDetailPage.currentOrder;
    if (order == null || order.id == null) return;
    try {
      await _apiService.updateOrderStatus(order.id!, newStatus);
      final updatedOrder = await _apiService.getOrderById(order.id!);
      setState(() {
        OrderDetailPage.currentOrder = updatedOrder;
      });
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

  @override
  Widget build(BuildContext context) {
    final order = OrderDetailPage.currentOrder;
    if (order == null) return const Center(child: Text('Không tìm thấy đơn hàng'));
    
    String timeStr = '--:--';
    if (order.createdAt != null) {
      timeStr = '${order.createdAt!.hour.toString().padLeft(2, '0')}:${order.createdAt!.minute.toString().padLeft(2, '0')} - ${order.createdAt!.day}/${order.createdAt!.month}';
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (widget.onNavigate != null) widget.onNavigate!('/orders');
                },
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chi tiết Đơn hàng #${order.code}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                  Text('Đặt lúc $timeStr',
                      style: const TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left col
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildOrderItems(order),
                    const SizedBox(height: 16),
                    _buildCustomerInfo(order),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Right col
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildStatusCard(order),
                    const SizedBox(height: 16),
                    _buildPaymentSummary(order),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(Order order) {
    return _card('Danh sách món', [
      ...order.items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.fastfood, color: Color(0xFFFF6B35), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (item.options.isNotEmpty)
                    Text(item.options, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Text('x${item.quantity}', style: const TextStyle(color: Colors.grey)),
            const SizedBox(width: 16),
            Text(
              '${(item.price * item.quantity).toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      )),
    ]);
  }

  Widget _buildCustomerInfo(Order order) {
    return _card('Thông tin khách hàng & giao hàng', [
      _row(Icons.person_outline, 'Khách hàng', order.customerName.isEmpty ? 'Khách lạ' : order.customerName),
      _row(Icons.phone_outlined, 'Số điện thoại', order.customerPhone.isEmpty ? 'Trống' : order.customerPhone),
      _row(Icons.location_on_outlined, 'Địa chỉ giao', order.deliveryAddress.isEmpty ? 'Tại quán' : order.deliveryAddress),
      _row(Icons.delivery_dining_outlined, 'Tài xế', order.driverName.isEmpty ? 'Chưa nhận' : '${order.driverName} (${order.driverPhone})'),
    ]);
  }

  Widget _buildStatusCard(Order order) {
    bool isCanceled = order.status == 'Đã hủy';
    int step = 1;
    if (order.status == 'Đang chế biến') step = 2;
    if (order.status == 'Đang giao') step = 3;
    if (order.status == 'Hoàn thành') step = 4;
    
    return _card('Trạng thái đơn hàng', isCanceled ? [
      const Text('Đơn hàng này đã bị hủy', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
    ] : [
      _statusStep('Đặt hàng', '', step >= 1),
      _statusStep('Đang chế biến', '', step >= 2),
      _statusStep('Đang giao', '', step >= 3),
      _statusStep('Hoàn thành', '', step >= 4),
      const SizedBox(height: 16),
      if (step == 1)
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('Đang chế biến'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Bắt đầu chế biến'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => _updateStatus('Đã hủy'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Từ chối đơn'),
              ),
            ),
          ],
        ),
      if (step == 2)
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('Đang giao'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Giao cho tài xế'),
              ),
            ),
          ],
        ),
      if (step == 3)
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => _updateStatus('Hoàn thành'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Hoàn thành đơn hàng'),
              ),
            ),
          ],
        ),
    ]);
  }

  Widget _statusStep(String label, String time, bool done) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: done ? Colors.green : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            child: Icon(done ? Icons.check : Icons.circle, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(fontWeight: done ? FontWeight.w600 : FontWeight.normal, color: done ? const Color(0xFF1E1E2D) : Colors.grey))),
          if (time.isNotEmpty) Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(Order order) {
    return _card('Thanh toán', [
      _payRow('Tổng món', '${order.totalAmount.toInt()}đ'),
      _payRow('Phí giao hàng', '${order.shippingFee.toInt()}đ'),
      if (order.discountAmount > 0)
        _payRow('Giảm giá', '-${order.discountAmount.toInt()}đ', color: Colors.green),
      const Divider(height: 20),
      _payRow('Tổng cộng', '${order.finalAmount.toInt()}đ', bold: true, color: const Color(0xFFFF6B35)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.payment, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text('Thanh toán: ${order.paymentMethod}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    ]);
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFFF6B35)),
          const SizedBox(width: 12),
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _payRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: bold ? const Color(0xFF1E1E2D) : Colors.grey, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, color: color ?? const Color(0xFF1E1E2D))),
        ],
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
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
}
