import 'package:flutter/material.dart';
import '../../data/models/product_model.dart';
import '../../data/models/category_model.dart';
import '../../data/services/product_api_service.dart';
import '../../data/services/category_api_service.dart';
import '../../data/services/auth_service.dart';
import '../widgets/image_picker_widget.dart';

class ProductFormPage extends StatefulWidget {
  final bool isEdit;
  final Product? productToEdit; 
  final Function(String)? onNavigate;
  static Product? selectedProductToEdit; 
  
  const ProductFormPage({super.key, this.isEdit = false, this.productToEdit, this.onNavigate});

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController(); // Thêm controller cho image URL
  
  String? _selectedCategoryId;
  bool _isOutOfStock = false;

  final ProductApiService _productApiService = ProductApiService();
  final CategoryApiService _categoryApiService = CategoryApiService();
  final AuthService _authService = AuthService();
  
  List<Category> _categories = [];
  bool _isLoadingCategories = true;
  bool _isSaving = false;

  List<Map<String, dynamic>> _optionGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    
    if (widget.isEdit) {
      final p = widget.productToEdit ?? ProductFormPage.selectedProductToEdit;
      if (p != null) {
        _nameCtrl.text = p.name;
        _descCtrl.text = p.description;
        _priceCtrl.text = p.basePrice.toInt().toString();
        _imageUrlCtrl.text = p.imageUrl ?? '';
        _selectedCategoryId = p.categoryId;
        _isOutOfStock = p.isOutOfStock;
        
        if (p.optionGroups != null) {
          _optionGroups = p.optionGroups!.map((g) {
            return {
              'name': g.name,
              'isRequired': g.isRequired,
              'maxChoices': g.maxChoices,
              'options': g.options.map((o) => {'name': o.name, 'price': o.price}).toList(),
            };
          }).toList();
        }
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final storeId = await _authService.getStoreId();
      if (storeId == null) throw 'Không tìm thấy storeId';
      final categories = await _categoryApiService.getAllCategories(storeId);
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
        
        // Nếu không có categoryId cũ hợp lệ, chọn cái đầu tiên mặc định
        if (_selectedCategoryId == null && _categories.isNotEmpty) {
          _selectedCategoryId = _categories.first.id;
        } else if (_categories.isNotEmpty && !_categories.any((c) => c.id == _selectedCategoryId)) {
          _selectedCategoryId = _categories.first.id;
        }
      });
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      if (mounted) _showNotificationDialog(context, 'Lỗi tải danh mục: $e', false);
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
                      widget.onNavigate!('/products');
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEdit ? 'Chỉnh sửa Món ăn' : 'Thêm Món ăn mới',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
          ),
          const SizedBox(height: 4),
          const Text('Điền đầy đủ thông tin để thêm/sửa món trên thực đơn',
              style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildCard('Thông tin cơ bản', [
                        _field('Tên món ăn (*)', _nameCtrl, Icons.fastfood_outlined, required: true),
                        _field('Mô tả món', _descCtrl, Icons.description_outlined, maxLines: 3),
                        _field('Giá niêm yết (VNĐ) (*)', _priceCtrl, Icons.attach_money, required: true,
                            keyboardType: TextInputType.number),
                        const SizedBox(height: 4),
                        _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              items: _categories
                                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                                  .toList(),
                              onChanged: (v) => setState(() => _selectedCategoryId = v!),
                              validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                              decoration: InputDecoration(
                                labelText: 'Danh mục (*)',
                                prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFFFF6B35), size: 20),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9F9F9),
                              ),
                            ),
                      ]),
                      const SizedBox(height: 16),
                      _buildOptionGroupSection(),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right column
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildCard('Hình ảnh và trạng thái', [
                        ImagePickerWidget(
                          initialImageUrl: _imageUrlCtrl.text,
                          folder: 'products',
                          label: 'Chọn ảnh món ăn',
                          width: double.infinity,
                          height: 180,
                          onImageUploaded: (url) {
                            setState(() {
                              _imageUrlCtrl.text = url;
                            });
                          },
                          onImageCleared: () {
                            setState(() {
                              _imageUrlCtrl.text = '';
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Expanded(child: Text('Tình trạng món', style: TextStyle(fontWeight: FontWeight.w500))),
                            Switch(
                              value: !_isOutOfStock, 
                              onChanged: (v) => setState(() => _isOutOfStock = !v), 
                              activeColor: Colors.green
                            ),
                          ],
                        ),
                        const Text('Bật = Còn hàng, Tắt = Hết hàng', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                if (widget.onNavigate != null) {
                                  widget.onNavigate!('/products');
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Hủy'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isSaving ? null : _save,
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: _isSaving
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(widget.isEdit ? 'Lưu thay đổi' : 'Thêm món'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B35),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
      {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (v) {
          if (ctrl == _imageUrlCtrl) setState(() {});
        },
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập đầy đủ thông tin' : null : null,
        decoration: InputDecoration(
          labelText: label,
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

  Widget _buildOptionGroupSection() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nhóm Topping / Size', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
              TextButton.icon(
                onPressed: () => setState(() => _optionGroups.add({'name': 'Nhóm mới', 'isRequired': false, 'maxChoices': 1, 'options': []})),
                icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF6B35)),
                label: const Text('Thêm nhóm', style: TextStyle(color: Color(0xFFFF6B35))),
              ),
            ],
          ),
          const Divider(height: 24),
          ..._optionGroups.asMap().entries.map((e) => _buildOptionGroup(e.key, e.value)),
        ],
      ),
    );
  }

  Widget _buildOptionGroup(int gIdx, Map<String, dynamic> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: group['name'],
                  onChanged: (v) => _optionGroups[gIdx]['name'] = v,
                  decoration: InputDecoration(
                    labelText: 'Tên nhóm',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  const Text('Bắt buộc', style: TextStyle(fontSize: 13)),
                  Switch(
                    value: group['isRequired'],
                    onChanged: (v) => setState(() => _optionGroups[gIdx]['isRequired'] = v),
                    activeColor: const Color(0xFFFF6B35),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => setState(() => _optionGroups.removeAt(gIdx)),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...(group['options'] as List).asMap().entries.map((e) => _buildOption(gIdx, e.key, e.value)),
          TextButton.icon(
            onPressed: () => setState(() => (group['options'] as List).add({'name': '', 'price': 0})),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Thêm lựa chọn'),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int gIdx, int oIdx, Map<String, dynamic> option) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: option['name'],
              onChanged: (v) => (_optionGroups[gIdx]['options'] as List)[oIdx]['name'] = v,
              decoration: InputDecoration(
                labelText: 'Tên lựa chọn',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: option['price'].toString(),
              keyboardType: TextInputType.number,
              onChanged: (v) => (_optionGroups[gIdx]['options'] as List)[oIdx]['price'] = int.tryParse(v) ?? 0,
              decoration: InputDecoration(
                labelText: '+Giá (VNĐ)',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => (_optionGroups[gIdx]['options'] as List).removeAt(oIdx)),
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null) {
        _showNotificationDialog(context, 'Vui lòng chọn danh mục', false);
        return;
      }
      
      setState(() => _isSaving = true);
      
      try {
        final storeId = await _authService.getStoreId();
        if (storeId == null) throw 'Không tìm thấy storeId';
        
        final categoryName = _categories.firstWhere((c) => c.id == _selectedCategoryId).name;
        
        final newProduct = Product(
          id: widget.isEdit ? (widget.productToEdit?.id ?? ProductFormPage.selectedProductToEdit?.id) : null,
          storeId: storeId,
          categoryId: _selectedCategoryId!,
          categoryName: categoryName,
          name: _nameCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          basePrice: double.tryParse(_priceCtrl.text) ?? 0.0,
          imageUrl: _imageUrlCtrl.text.trim(),
          isOutOfStock: _isOutOfStock,
          isFeatured: widget.isEdit ? ((widget.productToEdit?.isFeatured ?? ProductFormPage.selectedProductToEdit?.isFeatured) ?? false) : false,
          optionGroups: _optionGroups.map((g) {
            return ProductOptionGroup(
              name: g['name'],
              isRequired: g['isRequired'],
              maxChoices: g['maxChoices'],
              options: (g['options'] as List).map((o) => ProductOption(
                name: o['name'],
                price: (o['price'] as num).toDouble()
              )).toList()
            );
          }).toList(),
        );

        if (widget.isEdit) {
          await _productApiService.updateProduct(newProduct.id!, newProduct);
          if (mounted) _showNotificationDialog(context, 'Cập nhật món thành công!', true);
        } else {
          await _productApiService.createProduct(newProduct);
          if (mounted) _showNotificationDialog(context, 'Thêm món thành công!', true);
        }
      } catch (e) {
        if (mounted) _showNotificationDialog(context, e.toString(), false);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }
}
