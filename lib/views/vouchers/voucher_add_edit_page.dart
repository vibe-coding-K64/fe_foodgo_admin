import 'package:flutter/material.dart';

import '../../data/models/voucher_model.dart';
import '../../data/services/voucher_api_service.dart';
import '../widgets/image_picker_widget.dart';

/// Form dùng chung thêm/sửa voucher
class VoucherFormPage extends StatefulWidget {
  static Voucher? selectedVoucherToEdit;

  final bool isEdit;
  final Function(String)? onNavigate;
  const VoucherFormPage({super.key, this.isEdit = false, this.onNavigate});

  @override
  State<VoucherFormPage> createState() => _VoucherFormPageState();
}

class _VoucherFormPageState extends State<VoucherFormPage> {
  final VoucherApiService _apiService = VoucherApiService();
  final _formKey = GlobalKey<FormState>();
  final _codeCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  
  // New controllers and states
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  String? _imageUrl;
  final _termsCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  final _remainingCtrl = TextEditingController();
  bool _isFreeship = false;

  int _discountType = 1; // 1: %, 2: tiền mặt
  DateTime? _expiryDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && VoucherFormPage.selectedVoucherToEdit != null) {
      final v = VoucherFormPage.selectedVoucherToEdit!;
      _codeCtrl.text = v.code;
      _discountType = v.type;
      _valueCtrl.text = v.value.toString();
      _minOrderCtrl.text = v.minOrder.toString();
      _limitCtrl.text = v.limitCount.toString();
      _expiryDate = v.expiryDate;
      
      // Initialize new fields
      _titleCtrl.text = v.title;
      _subtitleCtrl.text = v.subtitle;
      _imageUrl = v.imageUrl;
      _termsCtrl.text = v.terms;
      _pointsCtrl.text = v.pointsRequired.toString();
      _remainingCtrl.text = v.remaining.toString();
      _isFreeship = v.isFreeship;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEdit ? 'Chỉnh sửa Voucher' : 'Tạo Voucher mới',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
          ),
          const SizedBox(height: 4),
          const Text('Điền thông tin để tạo mã giảm giá ưu đãi toàn hệ thống',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Form
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Thông tin Voucher',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                        const Divider(height: 24),
                        _field('Mã voucher (VD: SAVE20)', _codeCtrl, Icons.local_offer_outlined, required: true, validator: (v) {
                          if (v != null && v.contains(' ')) return 'Mã không được chứa khoảng trắng';
                          return null;
                        }),
                        // Loại giảm giá
                        const Text('Loại giảm giá', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _typeCard(1, 'Phần trăm (%)', Icons.percent),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _typeCard(2, 'Tiền mặt (VNĐ)', Icons.attach_money),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _field(
                          _discountType == 1 ? 'Giá trị giảm (%)' : 'Số tiền giảm (VNĐ)',
                          _valueCtrl, Icons.discount_outlined,
                          required: true, keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Phải là số hợp lệ';
                            if (_discountType == 1 && double.tryParse(v ?? '') != null) {
                              if (double.parse(v!) > 100 || double.parse(v) <= 0) return 'Từ 1 đến 100%';
                            }
                            return null;
                          }
                        ),
                        _field('Đơn tối thiểu (VNĐ)', _minOrderCtrl, Icons.shopping_cart_outlined,
                            required: true,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v != null && v.isNotEmpty && double.tryParse(v) == null) return 'Phải là số hợp lệ';
                              return null;
                            }),
                        _field('Giới hạn lượt dùng', _limitCtrl, Icons.numbers_outlined,
                            required: true,
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Phải là số nguyên hợp lệ';
                              return null;
                            }),
                        Row(
                          children: [
                            Expanded(
                              child: _field('Điểm đổi (Loyalty points)', _pointsCtrl, Icons.star_border,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Phải là số nguyên';
                                    return null;
                                  }),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _field('Số lượt còn lại', _remainingCtrl, Icons.hourglass_empty_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty && int.tryParse(v) == null) return 'Phải là số nguyên';
                                    return null;
                                  }),
                            ),
                          ],
                        ),
                        _field('Tiêu đề hiển thị (VD: Giảm 20K toàn sàn)', _titleCtrl, Icons.title,
                            required: true),
                        _field('Mô tả ngắn / Phụ đề (VD: HSD 30 ngày)', _subtitleCtrl, Icons.subtitles),
                        const Text(
                          'Hình ảnh Voucher',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1E2D)),
                        ),
                        const SizedBox(height: 8),
                        ImagePickerWidget(
                          initialImageUrl: _imageUrl,
                          folder: 'vouchers',
                          label: 'Chọn ảnh voucher',
                          width: 140,
                          height: 140,
                          onImageUploaded: (url) {
                            setState(() {
                              _imageUrl = url;
                            });
                          },
                          onImageCleared: () {
                            setState(() {
                              _imageUrl = '';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        _field('Điều khoản sử dụng', _termsCtrl, Icons.description_outlined, maxLines: 3),
                        SwitchListTile(
                          title: const Text('Mã vận chuyển miễn phí (Freeship)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                          subtitle: const Text('Bật nếu đây là mã giảm phí vận chuyển'),
                          value: _isFreeship,
                          activeColor: const Color(0xFFFF6B35),
                          onChanged: (val) => setState(() => _isFreeship = val),
                        ),
                        const SizedBox(height: 16),
                        // Date picker
                        InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Ngày hết hạn',
                              prefixIcon: const Icon(Icons.event_outlined, color: Color(0xFFFF6B35), size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: const Color(0xFFF9F9F9),
                            ),
                            child: Text(
                              _expiryDate == null
                                  ? 'Chọn ngày hết hạn'
                                  : '${_expiryDate!.day.toString().padLeft(2, '0')}/${_expiryDate!.month.toString().padLeft(2, '0')}/${_expiryDate!.year}',
                              style: TextStyle(
                                  color: _expiryDate == null ? Colors.grey : const Color(0xFF1E1E2D)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Right: Preview
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPreviewCard(),
                    const SizedBox(height: 16),
                    _buildTipsCard(),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            if (widget.onNavigate != null) widget.onNavigate!('/vouchers');
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(widget.isEdit ? 'Lưu thay đổi' : 'Tạo voucher'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF6B35),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _typeCard(int type, String label, IconData icon) {
    final isSelected = _discountType == type;
    return InkWell(
      onTap: () => setState(() => _discountType = type),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF3E0) : const Color(0xFFF9F9F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFFFF6B35) : Colors.grey.shade300, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFFFF6B35) : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFFF6B35) : Colors.grey, fontWeight: FontWeight.w500, fontSize: 13))),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {bool required = false, TextInputType? keyboardType, int? maxLines = 1, String? Function(String?)? validator}) {
    final isMultiLine = maxLines != null && maxLines > 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (v) {
          if (required && (v == null || v.trim().isEmpty)) {
            return 'Vui lòng nhập $label';
          }
          if (validator != null) {
            return validator(v);
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: isMultiLine,
          prefixIcon: isMultiLine
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 14, left: 12, right: 8),
                      child: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
                    ),
                  ],
                )
              : Icon(icon, color: const Color(0xFFFF6B35), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFFF6B35))),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Xem trước', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
          const Divider(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
              image: _imageUrl != null && _imageUrl!.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(_imageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.35), BlendMode.darken),
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('🎟 VOUCHER', style: TextStyle(color: Colors.white70, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  _codeCtrl.text.isEmpty ? 'MYVOUCHER' : _codeCtrl.text.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  _valueCtrl.text.isEmpty
                      ? 'Giảm 0${_discountType == 1 ? '%' : 'đ'}'
                      : 'Giảm ${_valueCtrl.text}${_discountType == 1 ? '%' : 'đ'}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.blue, size: 18),
              SizedBox(width: 8),
              Text('Gợi ý', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          SizedBox(height: 8),
          Text('• Mã ngắn gọn dễ nhớ (VD: SAVE20)\n• Đặt giới hạn lượt để kiểm soát chi phí\n• Mã hoa không dấu để tránh nhầm lẫn',
              style: TextStyle(color: Colors.blue, fontSize: 12, height: 1.8)),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = today.add(const Duration(days: 1)); // Bắt đầu từ ngày mai (00:00:00)
    
    DateTime initDate = _expiryDate ?? today.add(const Duration(days: 30));
    if (initDate.isBefore(first)) {
      initDate = first;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initDate,
      firstDate: first,
      lastDate: today.add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expiryDate = picked);
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
                  if (isSuccess && widget.onNavigate != null) {
                    widget.onNavigate!('/vouchers');
                  }
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

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_expiryDate == null) {
        _showNotificationDialog(context, 'Vui lòng chọn ngày hết hạn', false);
        return;
      }
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_expiryDate!.isBefore(today.add(const Duration(days: 1)))) {
        _showNotificationDialog(context, 'Ngày hết hạn phải lớn hơn ngày hiện tại', false);
        return;
      }
      
      setState(() => _isSaving = true);
      
      try {
        final newVoucher = Voucher(
          storeId: widget.isEdit && VoucherFormPage.selectedVoucherToEdit != null
              ? VoucherFormPage.selectedVoucherToEdit!.storeId
              : 'system',
          code: _codeCtrl.text.trim().toUpperCase(),
          type: _discountType,
          value: double.parse(_valueCtrl.text.trim()),
          minOrder: double.parse(_minOrderCtrl.text.trim()),
          limitCount: int.parse(_limitCtrl.text.trim()),
          usedCount: widget.isEdit && VoucherFormPage.selectedVoucherToEdit != null
              ? VoucherFormPage.selectedVoucherToEdit!.usedCount
              : 0,
          expiryDate: _expiryDate!,
          isActive: true,
          title: _titleCtrl.text.trim(),
          subtitle: _subtitleCtrl.text.trim(),
          imageUrl: _imageUrl ?? '',
          pointsRequired: int.tryParse(_pointsCtrl.text.trim()) ?? 0,
          remaining: int.tryParse(_remainingCtrl.text.trim()) ?? (int.tryParse(_limitCtrl.text.trim()) ?? 0),
          terms: _termsCtrl.text.trim(),
          isFreeship: _isFreeship,
        );

        if (widget.isEdit && VoucherFormPage.selectedVoucherToEdit != null) {
          await _apiService.updateVoucher(VoucherFormPage.selectedVoucherToEdit!.id!, newVoucher);
          if (mounted) _showNotificationDialog(context, 'Cập nhật voucher thành công!', true);
        } else {
          await _apiService.createVoucher(newVoucher);
          if (mounted) _showNotificationDialog(context, 'Tạo voucher thành công!', true);
        }
      } catch (e) {
        if (mounted) _showNotificationDialog(context, e.toString(), false);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}
