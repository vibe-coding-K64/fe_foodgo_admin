import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/store_model.dart';
import '../../data/services/store_api_service.dart';
import '../../data/services/review_api_service.dart';

class StoresAdminPage extends StatefulWidget {
  final Function(String)? onNavigate;
  const StoresAdminPage({super.key, this.onNavigate});

  @override
  State<StoresAdminPage> createState() => _StoresAdminPageState();
}

class _StoresAdminPageState extends State<StoresAdminPage> {
  final StoreApiService _storeService = StoreApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterStatus = 'all'; // all | open | closed
  bool _isLoading = true;
  String? _errorMessage;

  List<Store> _allStores = [];

  @override
  void initState() {
    super.initState();
    _fetchStores();
  }

  Future<void> _fetchStores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _storeService.getAllStores();
      setState(() {
        _allStores = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải danh sách cửa hàng: $e';
      });
    }
  }

  List<Store> get _filteredStores {
    final query = _searchCtrl.text.toLowerCase();
    return _allStores.where((s) {
      final matchSearch = query.isEmpty ||
          s.name.toLowerCase().contains(query) ||
          s.address.toLowerCase().contains(query);
      final matchFilter = _filterStatus == 'all' ||
          (_filterStatus == 'open' && s.isAcceptingOrders && s.approvalStatus == 'approved' && s.adminLockedReason == null) ||
          (_filterStatus == 'closed' && !s.isAcceptingOrders && s.approvalStatus == 'approved' && s.adminLockedReason == null) ||
          (_filterStatus == 'pending' && s.approvalStatus == 'pending') ||
          (_filterStatus == 'approved' && s.approvalStatus == 'approved') ||
          (_filterStatus == 'rejected' && s.approvalStatus == 'rejected') ||
          (_filterStatus == 'locked' && s.adminLockedReason != null);
      return matchSearch && matchFilter;
    }).toList();
  }

  Future<void> _toggleStatus(Store store) async {
    try {
      final updated = Store(
        id: store.id,
        name: store.name,
        description: store.description,
        address: store.address,
        taxCode: store.taxCode,
        businessLicense: store.businessLicense,
        coverImageUrl: store.coverImageUrl,
        logoUrl: store.logoUrl,
        bankAccountNumber: store.bankAccountNumber,
        bankName: store.bankName,
        isAcceptingOrders: !store.isAcceptingOrders,
        approvalStatus: store.approvalStatus,
        rejectReason: store.rejectReason,
      );

      await _storeService.updateStore(store.id!, updated);

      setState(() {
        final idx = _allStores.indexWhere((s) => s.id == store.id);
        if (idx != -1) {
          _allStores[idx] = updated;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              updated.isAcceptingOrders
                  ? '${store.name} đã mở cửa'
                  : '${store.name} đã đóng cửa',
            ),
            backgroundColor: updated.isAcceptingOrders ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi cập nhật trạng thái cửa hàng: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleApproveStore(Store store) async {
    try {
      final success = await _storeService.approveStore(store.id!);
      if (success) {
        setState(() {
          final idx = _allStores.indexWhere((s) => s.id == store.id);
          if (idx != -1) {
            _allStores[idx] = Store(
              id: store.id,
              name: store.name,
              description: store.description,
              address: store.address,
              taxCode: store.taxCode,
              businessLicense: store.businessLicense,
              coverImageUrl: store.coverImageUrl,
              logoUrl: store.logoUrl,
              bankAccountNumber: store.bankAccountNumber,
              bankName: store.bankName,
              isAcceptingOrders: true,
              rating: store.rating,
              reviewCount: store.reviewCount,
              approvalStatus: 'approved',
              rejectReason: '',
            );
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã phê duyệt cửa hàng "${store.name}" thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi phê duyệt cửa hàng: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRejectDialog(Store store) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Từ chối cửa hàng "${store.name}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vui lòng nhập lý do từ chối đăng ký cửa hàng này:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lý do từ chối (*)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Lý do không được để trống';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final reason = reasonCtrl.text.trim();
                Navigator.pop(ctx);
                try {
                  final success = await _storeService.rejectStore(store.id!, reason);
                  if (success) {
                    setState(() {
                      final idx = _allStores.indexWhere((s) => s.id == store.id);
                      if (idx != -1) {
                        _allStores[idx] = Store(
                          id: store.id,
                          name: store.name,
                          description: store.description,
                          address: store.address,
                          taxCode: store.taxCode,
                          businessLicense: store.businessLicense,
                          coverImageUrl: store.coverImageUrl,
                          logoUrl: store.logoUrl,
                          bankAccountNumber: store.bankAccountNumber,
                          bankName: store.bankName,
                          isAcceptingOrders: false,
                          rating: store.rating,
                          reviewCount: store.reviewCount,
                          approvalStatus: 'rejected',
                          rejectReason: reason,
                        );
                      }
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã từ chối cửa hàng "${store.name}"!'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi từ chối cửa hàng: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchStores,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      );
    }

    final stores = _filteredStores;
    final openCount = _allStores.where((s) => s.isAcceptingOrders && s.approvalStatus == 'approved' && s.adminLockedReason == null).length;
    final closedCount = _allStores.where((s) => !s.isAcceptingOrders && s.approvalStatus == 'approved' && s.adminLockedReason == null).length;
    final lockedCount = _allStores.where((s) => s.adminLockedReason != null).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Quản lý Cửa hàng',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1E2D),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tất cả cửa hàng đang hoạt động trên hệ thống FoodGo',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _statCard('Tổng cửa hàng', '${_allStores.length}', Icons.store_outlined, const Color(0xFFFF6B35)),
              const SizedBox(width: 16),
              _statCard('Đang mở', '$openCount', Icons.check_circle_outline, Colors.green),
              const SizedBox(width: 16),
              _statCard('Đã đóng', '$closedCount', Icons.cancel_outlined, Colors.orange),
              const SizedBox(width: 16),
              _statCard('Tạm khóa', '$lockedCount', Icons.lock_outline, Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Search + Filter bar
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, địa chỉ...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Tất cả', 'all'),
                const SizedBox(width: 8),
                _filterChip('Chờ duyệt', 'pending'),
                const SizedBox(width: 8),
                _filterChip('Đã duyệt', 'approved'),
                const SizedBox(width: 8),
                _filterChip('Bị từ chối', 'rejected'),
                const SizedBox(width: 8),
                _filterChip('Bị tạm khóa', 'locked'),
                const SizedBox(width: 8),
                _filterChip('Đang mở cửa', 'open'),
                const SizedBox(width: 8),
                _filterChip('Đang đóng cửa', 'closed'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Stores grid
          stores.isEmpty
              ? _emptyState()
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.7,
                  ),
                  itemCount: stores.length,
                  itemBuilder: (_, i) => _storeCard(stores[i]),
                ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isActive = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF6B35) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFFFF6B35) : Colors.grey.shade200,
          ),
          boxShadow: isActive
              ? [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade600,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _storeCard(Store store) {
    final isOpen = store.isAcceptingOrders;
    final isPending = store.approvalStatus == 'pending';
    final isRejected = store.approvalStatus == 'rejected';
    final isApproved = store.approvalStatus == 'approved';

    return InkWell(
      onTap: () {
        if (widget.onNavigate != null) {
          widget.onNavigate!('/store/stats?id=${store.id}&name=${Uri.encodeComponent(store.name)}');
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(
          color: isApproved
              ? (isOpen ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.1))
              : isPending
                  ? Colors.amber.withOpacity(0.2)
                  : Colors.red.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: avatar + name + status badge
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: store.logoUrl != null
                    ? Image.network(
                        store.logoUrl!,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(store.name),
                      )
                    : _avatarFallback(store.name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1E1E2D),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 13, color: Colors.grey.shade400),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            store.address,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _showStoreReviews(store),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                            const SizedBox(width: 3),
                            Text(
                              '${store.rating?.toStringAsFixed(1) ?? '0.0'} (${store.reviewCount ?? 0} đánh giá)',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6B35),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _approvalBadge(store, isOpen),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Bottom row: description + actions/toggle/reason
          Row(
            children: [
              Expanded(
                child: Text(
                  store.description.isEmpty ? 'Không có mô tả' : store.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              if (isPending) ...[
                _rejectButton(store),
                const SizedBox(width: 8),
                _approveButton(store),
              ] else if (isApproved) ...[
                _toggleButton(store, isOpen),
              ] else if (isRejected) ...[
                const Text(
                  'Từ chối',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
          if (store.adminLockedReason != null && store.adminLockedReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 12, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lý do khóa: ${store.adminLockedReason}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isRejected && store.rejectReason != null && store.rejectReason!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.red.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 12, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Lý do: ${store.rejectReason}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ));
  }

  Widget _approvalBadge(Store store, bool isOpen) {
    final status = store.approvalStatus;
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    if (status == 'pending') {
      bgColor = Colors.amber.shade50;
      textColor = Colors.amber.shade800;
      label = 'Chờ duyệt';
      icon = Icons.hourglass_empty;
    } else if (status == 'rejected') {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      label = 'Bị từ chối';
      icon = Icons.cancel_outlined;
    } else if (store.adminLockedReason != null) {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      label = 'Bị tạm khóa';
      icon = Icons.lock_outline;
    } else {
      // approved
      bgColor = isOpen ? Colors.green.shade50 : Colors.grey.shade100;
      textColor = isOpen ? Colors.green.shade800 : Colors.grey.shade700;
      label = isOpen ? 'Mở cửa' : 'Đóng cửa';
      icon = isOpen ? Icons.check_circle_outline : Icons.pause_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: textColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _approveButton(Store store) {
    return InkWell(
      onTap: () => _handleApproveStore(store),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.green.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Colors.green,
            ),
            SizedBox(width: 4),
            Text(
              'Duyệt',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rejectButton(Store store) {
    return InkWell(
      onTap: () => _showRejectDialog(store),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.cancel_outlined,
              size: 14,
              color: Colors.red,
            ),
            SizedBox(width: 4),
            Text(
              'Từ chối',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'S',
        style: const TextStyle(
          color: Color(0xFFFF6B35),
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }


  Widget _toggleButton(Store store, bool isOpen) {
    final isLocked = store.adminLockedReason != null;
    return Tooltip(
      message: isLocked ? 'Mở khóa cửa hàng' : 'Tạm khóa cửa hàng',
      child: InkWell(
        onTap: () => isLocked ? _handleUnlockStore(store) : _showLockDialog(store),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isLocked
                ? Colors.green.withOpacity(0.1)
                : Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLocked ? Colors.green.shade300 : Colors.red.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLocked ? Icons.lock_open : Icons.lock_outline,
                size: 14,
                color: isLocked ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 4),
              Text(
                isLocked ? 'Mở khóa' : 'Tạm khóa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isLocked ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLockDialog(Store store) {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tạm khóa cửa hàng "${store.name}"', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vui lòng nhập lý do tạm khóa cửa hàng này:', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Lý do khóa (*)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Lý do không được để trống';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final reason = reasonCtrl.text.trim();
                Navigator.pop(ctx);
                try {
                  final success = await _storeService.lockStore(store.id!, reason);
                  if (success) {
                    setState(() {
                      final idx = _allStores.indexWhere((s) => s.id == store.id);
                      if (idx != -1) {
                        _allStores[idx] = Store(
                          id: store.id,
                          name: store.name,
                          description: store.description,
                          address: store.address,
                          taxCode: store.taxCode,
                          businessLicense: store.businessLicense,
                          coverImageUrl: store.coverImageUrl,
                          logoUrl: store.logoUrl,
                          bankAccountNumber: store.bankAccountNumber,
                          bankName: store.bankName,
                          isAcceptingOrders: false,
                          rating: store.rating,
                          reviewCount: store.reviewCount,
                          approvalStatus: store.approvalStatus,
                          rejectReason: store.rejectReason,
                          adminLockedReason: reason,
                        );
                      }
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã tạm khóa cửa hàng "${store.name}"!'),
                          backgroundColor: Colors.redAccent,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi tạm khóa cửa hàng: $e'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Tạm khóa'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleUnlockStore(Store store) async {
    try {
      final success = await _storeService.unlockStore(store.id!);
      if (success) {
        setState(() {
          final idx = _allStores.indexWhere((s) => s.id == store.id);
          if (idx != -1) {
            _allStores[idx] = Store(
              id: store.id,
              name: store.name,
              description: store.description,
              address: store.address,
              taxCode: store.taxCode,
              businessLicense: store.businessLicense,
              coverImageUrl: store.coverImageUrl,
              logoUrl: store.logoUrl,
              bankAccountNumber: store.bankAccountNumber,
              bankName: store.bankName,
              isAcceptingOrders: true,
              rating: store.rating,
              reviewCount: store.reviewCount,
              approvalStatus: store.approvalStatus,
              rejectReason: store.rejectReason,
              adminLockedReason: null,
            );
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã mở khóa cửa hàng "${store.name}" thành công!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi mở khóa cửa hàng: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _emptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_mall_directory_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Không tìm thấy cửa hàng',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Thử thay đổi từ khóa tìm kiếm hoặc bộ lọc',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  void _showStoreReviews(Store store) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 700,
            height: 650,
            padding: const EdgeInsets.all(24),
            child: StoreReviewsDialogContent(store: store),
          ),
        );
      },
    );
  }
}

class StoreReviewsDialogContent extends StatefulWidget {
  final Store store;
  const StoreReviewsDialogContent({super.key, required this.store});

  @override
  State<StoreReviewsDialogContent> createState() => _StoreReviewsDialogContentState();
}

class _StoreReviewsDialogContentState extends State<StoreReviewsDialogContent> {
  final ReviewApiService _reviewApiService = ReviewApiService();
  List<Map<String, dynamic>> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _reviewApiService.getReviewsByStore(widget.store.id!);
      setState(() {
        _reviews = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể tải đánh giá: $e';
      });
    }
  }

  Future<void> _deleteReview(String id) async {
    try {
      final success = await _reviewApiService.deleteReview(id);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa đánh giá thành công!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchReviews();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi xóa đánh giá: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(String id, String userName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa đánh giá của "$userName"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteReview(id);
            },
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đánh giá - ${widget.store.name}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.store.rating?.toStringAsFixed(1) ?? '—'} (${_reviews.length} đánh giá)',
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        const Divider(height: 24),
        // Content
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6B35)))
              : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _fetchReviews,
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    )
                  : _reviews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Text(
                                'Chưa có đánh giá nào cho cửa hàng này!',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _reviews.length,
                          separatorBuilder: (_, __) => const Divider(height: 24),
                          itemBuilder: (context, index) {
                            final review = _reviews[index];
                            final id = review['id']?.toString() ?? '';
                            final userName = review['userName']?.toString() ?? 'Ẩn danh';
                            final userAvatar = review['userAvatarUrl']?.toString();
                            final starRating = (review['starRating'] as num?)?.toInt() ?? 5;
                            final comment = review['comment']?.toString() ?? '';
                            final imageUrls = review['imageUrls'] as List? ?? [];
                            final createdAt = review['createdAt'];

                            String dateStr = 'Mới đây';
                            if (createdAt != null) {
                              try {
                                final parsed = DateTime.parse(createdAt.toString()).toLocal();
                                dateStr = DateFormat('dd/MM/yyyy HH:mm').format(parsed);
                              } catch (_) {}
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFFFFF3E0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: userAvatar != null && userAvatar.isNotEmpty && !userAvatar.contains('example.com')
                                            ? Image.network(
                                                userAvatar,
                                                width: 36,
                                                height: 36,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Text(userName.isEmpty ? '?' : userName[0].toUpperCase()),
                                              )
                                            : Text(
                                                userName.isEmpty ? '?' : userName[0].toUpperCase(),
                                                style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E1E2D))),
                                          Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (i) => Icon(
                                        i < starRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                        color: Colors.amber,
                                        size: 16,
                                      )),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _confirmDelete(id, userName),
                                      tooltip: 'Xóa đánh giá vi phạm',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 46),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(comment, style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF2D3238))),
                                      if (imageUrls.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          height: 50,
                                          child: ListView.separated(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: imageUrls.length,
                                            separatorBuilder: (_, __) => const SizedBox(width: 6),
                                            itemBuilder: (context, idx) {
                                              final imgUrl = imageUrls[idx].toString();
                                              return ClipRRect(
                                                borderRadius: BorderRadius.circular(6),
                                                child: imgUrl.contains('example.com')
                                                    ? Container(
                                                        color: Colors.grey[200],
                                                        width: 50,
                                                        height: 50,
                                                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 16),
                                                      )
                                                    : Image.network(
                                                        imgUrl,
                                                        width: 50,
                                                        height: 50,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, __, ___) => Container(
                                                          color: Colors.grey[200],
                                                          width: 50,
                                                          height: 50,
                                                          child: const Icon(Icons.broken_image, color: Colors.grey, size: 16),
                                                        ),
                                                      ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
