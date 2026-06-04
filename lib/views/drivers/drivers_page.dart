import 'package:flutter/material.dart';
import '../../data/services/driver_api_service.dart';

class DriversPage extends StatefulWidget {
  const DriversPage({super.key});

  @override
  State<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends State<DriversPage> {
  final DriverApiService _driverService = DriverApiService();
  List<Map<String, dynamic>> _drivers = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _search = '';
  String _filterStatus = 'Tất cả';

  final List<String> _statusFilters = ['Tất cả', 'Đang hoạt động', 'Bị khoá'];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final drivers = await _driverService.getAllDrivers();
      if (!mounted) return;
      setState(() {
        _drivers = drivers;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    _filtered = _drivers.where((d) {
      final name = (d['fullName'] ?? d['displayName'] ?? '').toString().toLowerCase();
      final phone = (d['phoneNumber'] ?? '').toString().toLowerCase();
      final matchSearch = _search.isEmpty ||
          name.contains(_search.toLowerCase()) ||
          phone.contains(_search.toLowerCase());

      final isActive = d['isActive'] == true;
      final matchStatus = _filterStatus == 'Tất cả' ||
          (_filterStatus == 'Đang hoạt động' && isActive) ||
          (_filterStatus == 'Bị khoá' && !isActive);

      return matchSearch && matchStatus;
    }).toList();
  }

  Future<void> _toggleActive(Map<String, dynamic> driver) async {
    final id = driver['uid'] ?? driver['id'] ?? '';
    final name = driver['fullName'] ?? driver['displayName'] ?? 'tài xế';
    final isActive = driver['isActive'] == true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isActive ? 'Khoá tài khoản' : 'Mở khoá tài khoản'),
        content: Text(
          isActive
              ? 'Bạn có chắc muốn khoá tài khoản của $name không?'
              : 'Bạn có chắc muốn mở khoá tài khoản của $name không?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Khoá' : 'Mở khoá'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _driverService.toggleDriverActive(id);
      await _loadDrivers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isActive ? 'Đã khoá tài khoản $name' : 'Đã mở khoá tài khoản $name'),
        backgroundColor: isActive ? Colors.red : Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quản lý Tài Xế',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D))),
                const SizedBox(height: 4),
                Text('${_drivers.length} tài xế trong hệ thống',
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            IconButton(
              onPressed: _loadDrivers,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6B35)),
              tooltip: 'Tải lại',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Stats row
        if (!_isLoading && _error == null) ...[
          _buildStatsRow(),
          const SizedBox(height: 20),
        ],

        // Search + Filter
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() {
                  _search = v;
                  _applyFilter();
                }),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên hoặc số điện thoại...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFFF6B35)),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ..._statusFilters.map((f) {
              final isSelected = _filterStatus == f;
              return Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    _filterStatus = f;
                    _applyFilter();
                  }),
                  selectedColor: _chipColor(f),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected ? _chipColor(f) : Colors.grey.shade300,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 16),

        // Content
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildStatsRow() {
    final total = _drivers.length;
    final active = _drivers.where((d) => d['isActive'] == true).length;
    final locked = total - active;

    return Row(
      children: [
        _statCard('Tổng tài xế', total.toString(), Icons.two_wheeler_rounded, const Color(0xFF4F46E5)),
        const SizedBox(width: 16),
        _statCard('Đang hoạt động', active.toString(), Icons.check_circle_outline, Colors.green),
        const SizedBox(width: 16),
        _statCard('Bị khoá', locked.toString(), Icons.lock_outline, Colors.red),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDrivers,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.two_wheeler_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _search.isNotEmpty || _filterStatus != 'Tất cả'
                  ? 'Không tìm thấy tài xế phù hợp'
                  : 'Chưa có tài xế nào trong hệ thống',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                SizedBox(width: 44),
                Expanded(flex: 3, child: Text('Tài xế', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Số điện thoại', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                Expanded(flex: 1, child: Text('Trạng thái', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey))),
                SizedBox(width: 100, child: Text('Thao tác', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Table body
          Expanded(
            child: ListView.separated(
              itemCount: _filtered.length,
              separatorBuilder: (_, __) => Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, i) => _buildDriverRow(_filtered[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverRow(Map<String, dynamic> driver) {
    final name = driver['fullName'] ?? driver['displayName'] ?? 'Chưa cập nhật';
    final phone = driver['phoneNumber'] ?? '—';
    final email = driver['email'] ?? '—';
    final isActive = driver['isActive'] == true;
    final photoUrl = driver['photoUrl'] ?? driver['photoURL'] ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: () => _showDriverDetails(driver),
      hoverColor: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFFFF3E0),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: photoUrl.isNotEmpty && !photoUrl.contains('example.com')
                    ? Image.network(
                        photoUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Text(initial,
                              style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                        ),
                      )
                    : Center(
                        child: Text(initial,
                            style: const TextStyle(color: Color(0xFFFF6B35), fontWeight: FontWeight.bold)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(flex: 3, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E1E2D)))),
            Expanded(flex: 2, child: Text(phone, style: const TextStyle(fontSize: 14, color: Color(0xFF1E1E2D)))),
            Expanded(flex: 2, child: Text(email, style: const TextStyle(fontSize: 13, color: Colors.grey), overflow: TextOverflow.ellipsis)),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Hoạt động' : 'Bị khoá',
                  style: TextStyle(
                    color: isActive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(
              width: 100,
              child: Center(
                child: Tooltip(
                  message: isActive ? 'Khoá tài khoản' : 'Mở khoá tài khoản',
                  child: InkWell(
                    onTap: () => _toggleActive(driver),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isActive ? Colors.red : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (isActive ? Colors.red : Colors.green).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isActive ? Icons.lock_outline : Icons.lock_open_outlined,
                            color: isActive ? Colors.red : Colors.green,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isActive ? 'Khoá' : 'Mở',
                            style: TextStyle(
                              color: isActive ? Colors.red : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDriverDetails(Map<String, dynamic> driver) {
    final id = driver['uid'] ?? driver['id'] ?? '';
    final name = driver['fullName'] ?? driver['displayName'] ?? 'tài xế';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 460,
            padding: const EdgeInsets.all(24),
            child: FutureBuilder<Map<String, dynamic>>(
              future: _driverService.getDriverProfile(id),
              builder: (ctx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 250,
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return SizedBox(
                    height: 250,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text('Không thể tải chi tiết hồ sơ tài xế.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35), foregroundColor: Colors.white),
                          child: const Text('Đóng'),
                        ),
                      ],
                    ),
                  );
                }

                final profile = snapshot.data ?? {};
                final vehicleType = profile['vehicleType'] ?? 'Chưa cập nhật';
                final vehiclePlate = profile['vehiclePlate'] ?? 'Chưa cập nhật';
                final driverLicense = profile['driverLicense'] ?? 'Chưa cập nhật';
                final totalTrips = profile['totalTrips'] ?? 0;
                final balance = profile['totalEarnings'] ?? profile['balance'] ?? 0.0;
                final rating = profile['rating'] ?? 5.0;

                final photoUrl = driver['photoUrl'] ?? driver['photoURL'] ?? '';
                final email = driver['email'] ?? '—';
                final phone = driver['phoneNumber'] ?? '—';
                final isActive = driver['isActive'] == true;

                double parsedBalance = 0.0;
                if (balance is num) {
                  parsedBalance = balance.toDouble();
                } else if (balance is String) {
                  parsedBalance = double.tryParse(balance) ?? 0.0;
                }

                double parsedRating = 5.0;
                if (rating is num) {
                  parsedRating = rating.toDouble();
                } else if (rating is String) {
                  parsedRating = double.tryParse(rating) ?? 5.0;
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Chi tiết Tài Xế',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFFF3E0),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(28),
                            child: photoUrl.isNotEmpty && !photoUrl.contains('example.com')
                                ? Image.network(
                                    photoUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                          style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 20, fontWeight: FontWeight.bold)),
                                    ),
                                  )
                                : Center(
                                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(color: Color(0xFFFF6B35), fontSize: 20, fontWeight: FontWeight.bold)),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E1E2D)),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${parsedRating.toStringAsFixed(1)} / 5.0',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E1E2D)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isActive ? Colors.green : Colors.red).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'Hoạt động' : 'Bị khoá',
                            style: TextStyle(
                              color: isActive ? Colors.green : Colors.red,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    const Text('Thông tin liên hệ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    _detailItem(Icons.phone_outlined, 'Số điện thoại', phone),
                    _detailItem(Icons.email_outlined, 'Email', email),
                    
                    const SizedBox(height: 14),
                    const Text('Phương tiện & Bằng lái', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    _detailItem(Icons.two_wheeler_outlined, 'Loại xe', vehicleType),
                    _detailItem(Icons.credit_card_outlined, 'Biển số xe', vehiclePlate),
                    _detailItem(Icons.badge_outlined, 'Số bằng lái', driverLicense),

                    const SizedBox(height: 14),
                    const Text('Thống kê & Ví', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 6),
                    _detailItem(Icons.shopping_bag_outlined, 'Tổng số chuyến', '$totalTrips chuyến'),
                    _detailItem(Icons.account_balance_wallet_outlined, 'Tổng doanh thu', '${parsedBalance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ'),

                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Đóng', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _toggleActive(driver);
                          },
                          icon: Icon(isActive ? Icons.lock_outline : Icons.lock_open_outlined, size: 16),
                          label: Text(isActive ? 'Khoá tài khoản' : 'Mở khoá'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isActive ? Colors.red : Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade400),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF1E1E2D)),
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _chipColor(String f) {
    switch (f) {
      case 'Đang hoạt động':
        return Colors.green;
      case 'Bị khoá':
        return Colors.red;
      default:
        return const Color(0xFFFF6B35);
    }
  }
}
