import 'package:flutter/material.dart';
import '../../data/models/banner_model.dart';
import '../../data/services/banner_api_service.dart';
import '../widgets/image_picker_widget.dart';

class BannersPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const BannersPage({super.key, this.onNavigate});

  @override
  State<BannersPage> createState() => _BannersPageState();
}

class _BannersPageState extends State<BannersPage> {
  final BannerApiService _apiService = BannerApiService();
  List<BannerModel> _banners = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getAllBanners();
      setState(() {
        _banners = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách ảnh quảng cáo: $e';
      });
    }
  }

  Future<void> _toggleActive(BannerModel banner) async {
    final updated = BannerModel(
      id: banner.id,
      title: banner.title,
      imageUrl: banner.imageUrl,
      storeId: banner.storeId,
      storeName: banner.storeName,
      isActive: !banner.isActive,
      order: banner.order,
    );

    try {
      final success = await _apiService.updateBanner(banner.id!, updated);
      if (success) {
        _showToast(
          updated.isActive ? 'Đã kích hoạt ảnh quảng cáo!' : 'Đã ẩn ảnh quảng cáo!',
          Colors.green,
        );
        _fetchBanners();
      }
    } catch (e) {
      _showToast('Lỗi cập nhật ảnh quảng cáo: $e', Colors.red);
    }
  }

  void _showToast(String message, Color bgColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
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
                    Icons.photo_library_outlined,
                    color: Color(0xFFFF6B35),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản lý ảnh bìa quảng cáo',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2D),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Cấu hình ảnh quảng cáo chạy trên Carousel trang chủ App khách hàng',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showBannerDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm ảnh quảng cáo mới'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // MAIN CONTENT
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : _errorMessage != null
                  ? _buildErrorState()
                  : _banners.isEmpty
                      ? _buildEmptyState()
                      : _buildBannersGrid(),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchBanners, child: const Text('Tải lại')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có ảnh quảng cáo nào!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 6),
            Text(
              'Bấm "Thêm ảnh quảng cáo mới" ở trên để đưa ảnh chiến dịch quảng cáo lên sàn.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannersGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemCount: _banners.length,
      itemBuilder: (context, index) {
        final banner = _banners[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.network(
                        banner.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, err, st) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Thứ tự: ${banner.order}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Info & Actions
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      banner.storeName != null
                          ? 'Liên kết quán: ${banner.storeName}'
                          : 'Chiến dịch quảng cáo chung',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Switch(
                              value: banner.isActive,
                              onChanged: (_) => _toggleActive(banner),
                              activeColor: const Color(0xFFFF6B35),
                            ),
                            Text(
                              banner.isActive ? 'Kích hoạt' : 'Đang ẩn',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: banner.isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => _showBannerDialog(context, banner: banner),
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFFFF6B35)),
                              tooltip: 'Sửa',
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(banner),
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              tooltip: 'Xóa',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBannerDialog(BuildContext context, {BannerModel? banner}) {
    final formKey = GlobalKey<FormState>();
    String title = banner?.title ?? '';
    String imageUrl = banner?.imageUrl ?? '';
    String? storeId = banner?.storeId;
    String? storeName = banner?.storeName;
    int order = banner?.order ?? 0;
    bool isActive = banner?.isActive ?? true;

    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B35).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFFFF6B35)),
                ),
                const SizedBox(width: 12),
                Text(
                  banner == null ? 'Thêm ảnh quảng cáo mới' : 'Chỉnh sửa ảnh quảng cáo',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF1E1E2D),
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cấu hình thông tin ảnh quảng cáo chạy trên Carousel trang chủ App khách hàng.',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Tiêu đề quảng cáo *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: title,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          hintText: 'Nhập tiêu đề quảng cáo...',
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Tiêu đề không được để trống';
                          return null;
                        },
                        onSaved: (v) => title = v!.trim(),
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Ảnh Banner *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: ImagePickerWidget(
                          initialImageUrl: imageUrl,
                          folder: 'banners',
                          label: 'Chọn ảnh Banner (*)',
                          width: 320,
                          height: 160,
                          onImageUploaded: (url) {
                            setDialogState(() {
                              imageUrl = url;
                            });
                          },
                          onImageCleared: () {
                            setDialogState(() {
                              imageUrl = '';
                            });
                          },
                        ),
                      ),
                      if (imageUrl.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Center(
                          child: Text(
                            'Vui lòng chọn hoặc tải lên ảnh quảng cáo',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mã quán ăn (Tùy chọn)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: storeId,
                                  enabled: !isSaving,
                                  decoration: InputDecoration(
                                    hintText: 'Mã quán ăn liên kết...',
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
                                  onSaved: (v) => storeId = (v != null && v.trim().isNotEmpty) ? v.trim() : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tên quán ăn (Tùy chọn)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: storeName,
                                  enabled: !isSaving,
                                  decoration: InputDecoration(
                                    hintText: 'Tên quán ăn liên kết...',
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
                                  onSaved: (v) => storeName = (v != null && v.trim().isNotEmpty) ? v.trim() : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      const Text(
                        'Thứ tự hiển thị *',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        initialValue: order.toString(),
                        keyboardType: TextInputType.number,
                        enabled: !isSaving,
                        decoration: InputDecoration(
                          hintText: 'Nhập vị trí ưu tiên (ví dụ: 0, 1, 2...)',
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
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập thứ tự hiển thị';
                          if (int.tryParse(v) == null) return 'Phải là số nguyên';
                          return null;
                        },
                        onSaved: (v) => order = int.parse(v!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
            actions: [
              if (!isSaving)
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (imageUrl.isEmpty) {
                          return;
                        }
                        if (formKey.currentState!.validate()) {
                          formKey.currentState!.save();

                          final newBanner = BannerModel(
                            id: banner?.id,
                            title: title,
                            imageUrl: imageUrl,
                            storeId: storeId,
                            storeName: storeName,
                            isActive: isActive,
                            order: order,
                          );

                          setDialogState(() => isSaving = true);

                          try {
                            if (banner == null) {
                              await _apiService.createBanner(newBanner);
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _showToast('Thêm ảnh quảng cáo thành công!', Colors.green);
                              }
                            } else {
                              await _apiService.updateBanner(banner.id!, newBanner);
                              if (mounted) {
                                Navigator.pop(dialogContext);
                                _showToast('Đã lưu thay đổi ảnh quảng cáo!', Colors.green);
                              }
                            }
                            _fetchBanners();
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            _showToast('Lỗi khi lưu ảnh quảng cáo: $e', Colors.red);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(banner == null ? 'Thêm' : 'Lưu'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BannerModel banner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa ảnh quảng cáo'),
        content: Text('Bạn có chắc chắn muốn xóa ảnh quảng cáo "${banner.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _isLoading = true;
              });

              try {
                final success = await _apiService.deleteBanner(banner.id!);
                if (success) {
                  _showToast('Đã xóa ảnh quảng cáo!', Colors.redAccent);
                  _fetchBanners();
                }
              } catch (e) {
                setState(() {
                  _isLoading = false;
                });
                _showToast('Không thể xóa ảnh quảng cáo: $e', Colors.red);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }
}
