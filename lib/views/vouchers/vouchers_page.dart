import 'package:flutter/material.dart';
import '../../data/models/voucher_model.dart';
import '../../data/services/voucher_api_service.dart';
import 'voucher_add_edit_page.dart';

class VouchersPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const VouchersPage({super.key, this.onNavigate});

  @override
  State<VouchersPage> createState() => _VouchersPageState();
}

class _VouchersPageState extends State<VouchersPage> {
  final VoucherApiService _apiService = VoucherApiService();
  List<Voucher> _vouchers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    try {
      final vouchers = await _apiService.getAllVouchers();
      setState(() {
        _vouchers = vouchers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showNotificationDialog(context, e.toString(), false);
    }
  }

  void _showNotificationDialog(BuildContext context, String message, bool isSuccess) {
    showDialog(
      context: context,
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
                onPressed: () => Navigator.pop(ctx),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    Icons.local_offer_outlined,
                    color: Color(0xFFFF6B35),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Danh sách ưu đãi và mã giảm giá', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                    SizedBox(height: 4),
                    Text('Tạo và quản lý các chương trình ưu đãi, mã giảm giá khuyến mãi toàn sàn', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.onNavigate != null) widget.onNavigate!('/vouchers/add');
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Tạo voucher'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : _vouchers.isEmpty
                  ? const Center(child: Text('Chưa có mã giảm giá nào'))
                  : ListView.separated(
                      itemCount: _vouchers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) => _buildVoucherCard(i, _vouchers[i]),
                    ),
        ),
      ],
    );
  }

  Widget _buildVoucherCard(int index, Voucher v) {
    final isPercent = v.type == 1;
    final progress = v.limitCount == 0 ? 0.0 : (v.usedCount / v.limitCount);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: v.isActive ? Colors.transparent : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Voucher icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: v.isActive
                    ? [const Color(0xFFFF6B35), const Color(0xFFFF8C42)]
                    : [Colors.grey.shade400, Colors.grey.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isPercent ? '${v.value.toInt()}%' : '${v.value ~/ 1000}K',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 4),
                const Text('GIẢM', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(v.code,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1, color: Color(0xFF1E1E2D))),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: v.isActive ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        v.isActive ? 'Đang chạy' : 'Hết lượt/Đã dừng',
                        style: TextStyle(
                            color: v.isActive ? Colors.green : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (v.isFreeship) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Freeship',
                          style: TextStyle(
                              color: Colors.blue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    if (v.pointsRequired > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Đổi ${v.pointsRequired} điểm',
                          style: const TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                if (v.title.isNotEmpty) ...[
                  Text(
                    v.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D), fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                ],
                if (v.subtitle.isNotEmpty) ...[
                  Text(
                    v.subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  'Chi tiết: ${v.discountText} | ${v.minOrderText}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontStyle: FontStyle.italic),
                ),
                Text('HSD: ${v.expiryDateFormatted}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.shade200,
                          color: progress >= 1 ? Colors.red : const Color(0xFFFF6B35),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${v.usedCount}/${v.limitCount} lượt',
                        style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          Column(
            children: [
              IconButton(
                onPressed: () {
                  VoucherFormPage.selectedVoucherToEdit = v;
                  if (widget.onNavigate != null) {
                    widget.onNavigate!('/vouchers/edit');
                  }
                },
                icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF6B35)),
                tooltip: 'Sửa',
              ),
              IconButton(
                onPressed: () => _deleteVoucher(v),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Xóa',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _deleteVoucher(Voucher v) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC3545),
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Xác nhận xóa', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Bạn có chắc chắn muốn xóa mã "${v.code}"?', textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, color: Colors.black87)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: const Text('Hủy', style: TextStyle(fontSize: 16, color: Colors.black54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await _apiService.deleteVoucher(v.id!);
                        _fetchVouchers();
                      } catch (e) {
                        if (mounted) _showNotificationDialog(context, e.toString(), false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC3545),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Xóa bỏ', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
