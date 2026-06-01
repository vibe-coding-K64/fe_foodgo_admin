import 'package:flutter/material.dart';
import '../../data/models/store_model.dart';
import '../../data/services/store_api_service.dart';

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
          (_filterStatus == 'open' && s.isAcceptingOrders) ||
          (_filterStatus == 'closed' && !s.isAcceptingOrders);
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
    final openCount = _allStores.where((s) => s.isAcceptingOrders).length;
    final closedCount = _allStores.length - openCount;

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
              _statCard('Đã đóng', '$closedCount', Icons.cancel_outlined, Colors.red),
            ],
          ),
          const SizedBox(height: 24),

          // Search + Filter bar
          Row(
            children: [
              Expanded(
                child: Container(
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
              ),
              const SizedBox(width: 12),
              _filterChip('Tất cả', 'all'),
              const SizedBox(width: 8),
              _filterChip('Đang mở', 'open'),
              const SizedBox(width: 8),
              _filterChip('Đã đóng', 'closed'),
            ],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(
          color: isOpen ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.1),
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
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(isOpen),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          // Bottom row: description + toggle
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
              _toggleButton(store, isOpen),
            ],
          ),
        ],
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

  Widget _statusBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isOpen ? 'Mở cửa' : 'Đóng cửa',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOpen ? Colors.green.shade700 : Colors.red.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleButton(Store store, bool isOpen) {
    return Tooltip(
      message: isOpen ? 'Đóng cửa hàng' : 'Mở cửa hàng',
      child: InkWell(
        onTap: () => _toggleStatus(store),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOpen
                ? Colors.orange.withOpacity(0.1)
                : const Color(0xFFFF6B35).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOpen ? Colors.orange.shade300 : const Color(0xFFFF6B35).withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOpen ? Icons.pause_circle_outline : Icons.play_circle_outline,
                size: 14,
                color: isOpen ? Colors.orange : const Color(0xFFFF6B35),
              ),
              const SizedBox(width: 4),
              Text(
                isOpen ? 'Đóng' : 'Mở',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOpen ? Colors.orange : const Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
}
