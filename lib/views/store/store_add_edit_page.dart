import 'package:flutter/material.dart';
import '../../data/models/store_model.dart';
import '../../data/services/store_api_service.dart';
import '../../data/services/auth_service.dart';

/// Form dùng chung cho thêm/sửa thông tin quán
class StoreFormPage extends StatefulWidget {
  final bool isEdit;
  final Function(String)? onNavigate;
  const StoreFormPage({super.key, this.isEdit = false, this.onNavigate});

  @override
  State<StoreFormPage> createState() => _StoreFormPageState();
}



class _StoreFormPageState extends State<StoreFormPage> {
  final StoreApiService _apiService = StoreApiService();
  final _formKey = GlobalKey<FormState>();
  
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _taxCodeCtrl = TextEditingController();
  final _businessLicenseCtrl = TextEditingController();
  final _coverUrlCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _bankAccountCtrl = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  Store? _store;
  final AuthService _authService = AuthService();
  String? _currentStoreId;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      _loadStoreData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadStoreData() async {
    try {
      _currentStoreId = await _authService.getStoreId();
      if (_currentStoreId == null) throw 'Không tìm thấy gian hàng';

      final store = await _apiService.getStoreById(_currentStoreId!);
      setState(() {
        _store = store;
        _nameCtrl.text = store.name;
        _descCtrl.text = store.description;
        _addressCtrl.text = store.address;
        _taxCodeCtrl.text = store.taxCode;
        _businessLicenseCtrl.text = store.businessLicense;
        _coverUrlCtrl.text = store.coverImageUrl ?? '';
        _logoUrlCtrl.text = store.logoUrl ?? '';
        _bankNameCtrl.text = store.bankName ?? '';
        _bankAccountCtrl.text = store.bankAccountNumber ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showNotificationDialog(context, 'Lỗi tải dữ liệu: $e', false);
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
                  if (isSuccess) {
                    if (widget.onNavigate != null) {
                      widget.onNavigate!('/store');
                    }
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)));
    }
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEdit ? 'Chỉnh sửa Gian hàng' : 'Tạo Gian hàng',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
          ),
          const SizedBox(height: 4),
          Text(
            widget.isEdit ? 'Cập nhật thông tin quán của bạn' : 'Điền thông tin để tạo quán mới',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('Thông tin cơ bản', [
                  _field('Tên quán', _nameCtrl, Icons.store_outlined, required: true),
                  _field('Mô tả', _descCtrl, Icons.description_outlined, maxLines: 3),
                  _field('Địa chỉ', _addressCtrl, Icons.location_on_outlined, required: true),
                  _field('Mã số thuế', _taxCodeCtrl, Icons.receipt_long_outlined, required: true, validator: (v) {
                    if (v != null && v.isNotEmpty && int.tryParse(v.trim()) == null) return 'Mã số thuế chỉ chứa chữ số';
                    return null;
                  }),
                  _field('Giấy phép KD', _businessLicenseCtrl, Icons.article_outlined, required: true),
                ]),
                const SizedBox(height: 20),
                _buildSection('Hình ảnh', [
                  _field('Link ảnh bìa (Cover)', _coverUrlCtrl, Icons.link, required: true, validator: (v) {
                    if (v != null && v.isNotEmpty && !v.trim().startsWith('http')) return 'Đường dẫn phải bắt đầu bằng http:// hoặc https://';
                    return null;
                  }),
                  _field('Link Logo quán', _logoUrlCtrl, Icons.link, required: true, validator: (v) {
                    if (v != null && v.isNotEmpty && !v.trim().startsWith('http')) return 'Đường dẫn phải bắt đầu bằng http:// hoặc https://';
                    return null;
                  }),
                ]),
                const SizedBox(height: 20),
                _buildSection('Tài khoản ngân hàng nhận tiền', [
                  _field('Tên ngân hàng (kèm chi nhánh)', _bankNameCtrl, Icons.account_balance_outlined, required: true),
                  _field('Số tài khoản (kèm tên chủ thẻ)', _bankAccountCtrl, Icons.credit_card_outlined, required: true),
                ]),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        if (widget.onNavigate != null) {
                          widget.onNavigate!('/store');
                        }
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
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Lưu thay đổi'),
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
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
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

  Widget _field(String label, TextEditingController ctrl, IconData icon,
      {bool required = false, int maxLines = 1, String? hint, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
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
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFFF6B35), size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF6B35)),
          ),
          filled: true,
          fillColor: const Color(0xFFF9F9F9),
        ),
      ),
    );
  }

  Widget _imagePicker(String label, String hint) {
    return const SizedBox(); // Not used anymore, replaced by URL fields
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      try {
        final store = Store(
          id: widget.isEdit ? _currentStoreId ?? '' : '',
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          taxCode: _taxCodeCtrl.text.trim(),
          businessLicense: _businessLicenseCtrl.text.trim(),
          coverImageUrl: _coverUrlCtrl.text.trim(),
          logoUrl: _logoUrlCtrl.text.trim(),
          bankName: _bankNameCtrl.text.trim(),
          bankAccountNumber: _bankAccountCtrl.text.trim(),
          isAcceptingOrders: _store?.isAcceptingOrders ?? true,
        );

        if (widget.isEdit) {
          await _apiService.updateStore(_currentStoreId!, store);
        } else {
          final uid = _authService.currentUser?.uid;
          if (uid == null) throw 'Lỗi xác thực người dùng';
          final newStore = await _apiService.createStore(uid, store);
          await _authService.saveStoreId(newStore.id!);
        }
        
        if (mounted) {
          _showNotificationDialog(context, widget.isEdit ? 'Cập nhật thành công!' : 'Tạo gian hàng thành công!', true);
        }
      } catch (e) {
        if (mounted) {
          _showNotificationDialog(context, 'Lỗi: $e', false);
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }
}
